-- src/tools/cost_calculator.lua
-- Calculates a derived build cost for a card based on its definition.

local CostCalculator = {}

local CardTypes = require('src.game.card').Type -- Assuming path is correct relative to this tool
local CardEffects = require('src.game.card_effects') -- Assuming path is correct
local ResourceType = CardEffects.ResourceType

-- === Configuration Constants ===
local MATERIAL_EQUIVALENT = {
    [ResourceType.MATERIAL] = 1.0,
    [ResourceType.DATA] = 2.0,
    [ResourceType.ENERGY] = 2.5,
    CARD_DRAW = 2.0, -- what a deal!
    VP = 3.0,
}

local PORT_COST_ME = 1
local CONVERGENCE_EFFECT_MULTIPLIER = 0.5
local CONDITIONAL_EFFECT_MULTIPLIER = 0.5
local MINIMUM_COST_ME = 1.0

-- === Helper Functions ===

-- Get Material Equivalent value for a resource type or other benefit
local function getMEValue(benefitType, amount)
    amount = amount or 1
    local baseValue = MATERIAL_EQUIVALENT[benefitType]
    if baseValue then
        return baseValue * amount
    elseif benefitType == "draw" then -- Special case for card draw
        return MATERIAL_EQUIVALENT.CARD_DRAW * amount
    elseif benefitType == "vp" then -- Special case for VP
         return MATERIAL_EQUIVALENT.VP * amount
    else
        print(string.format("Warning: Unknown benefit type '%s' for ME calculation.", benefitType))
        return 0
    end
end

-- Calculate cost from defined ports
local function calculatePortsCost(definedPorts)
    local count = 0
    if definedPorts then
        for _, present in pairs(definedPorts) do
            if present then
                count = count + 1
            end
        end
    end
    local cost = count * PORT_COST_ME
    -- print(string.format("Ports Cost: %d ports * %.2f ME/port = %.2f ME", count, PORT_COST_ME, cost))
    return cost
end

-- Calculate the ME contribution of a single action within an effect
-- Returns: { benefitME = number, costME = number, isConditional = boolean }
local function calculateActionContribution(action, isActivationEffect)
    local effectType = action.effect
    local options = action.options or {}
    local conditionConfig = action.condition
    local contribution = { benefitME = 0, costME = 0, isConditional = (conditionConfig ~= nil) }

    local resource = options.resource
    local amount = options.amount or 1

    -- Determine Base Benefit/Harm ME (Ignoring player cost for now)
    local baseME = 0
    local target = "unknown" -- owner, activator, both, all, self (for node effects)

    if effectType == "addResourceToOwner" then
        baseME = getMEValue(resource, amount)
        target = "owner"
    elseif effectType == "addResourceToActivator" then
        baseME = getMEValue(resource, amount)
        target = "activator"
    elseif effectType == "addResourceToBoth" then
        baseME = getMEValue(resource, amount) -- Value of one player's gain
        target = "both"
    elseif effectType == "addResourceToAllPlayers" then
        baseME = getMEValue(resource, amount) -- Value of one player's gain
        target = "all"
    elseif effectType == "drawCardsForOwner" then
        baseME = getMEValue("draw", amount)
        target = "owner"
    elseif effectType == "drawCardsForActivator" then
        baseME = getMEValue("draw", amount)
        target = "activator"
    elseif effectType == "drawCardsForAllPlayers" then
         baseME = getMEValue("draw", amount) -- Value of one player's gain
         target = "all"
    elseif effectType == "gainVPForOwner" then
        baseME = getMEValue("vp", amount)
        target = "owner"
    elseif effectType == "gainVPForActivator" then
        baseME = getMEValue("vp", amount)
        target = "activator"
    elseif effectType == "forceDiscardCardsOwner" then
        baseME = -getMEValue("draw", amount) -- Harm = negative benefit of drawing
        target = "owner"
    elseif effectType == "forceDiscardCardsActivator" then
        baseME = -getMEValue("draw", amount) -- Harm (considered negative benefit for activator)
        target = "activator"
    elseif effectType == "destroyRandomLinkOnNode" then
         baseME = -2.0 -- Tentative harm value
         target = "self" -- Node itself
    elseif effectType == "stealResource" then
        baseME = getMEValue(resource, amount) -- Benefit for activator, harm for owner
        target = "steal"
    elseif effectType == "gainResourcePerNodeOwner" then
        -- Hard to evaluate without game state. Assume average benefit?
        -- Or ignore for now? Let's ignore dynamic effects for v1.
        print(string.format("Warning: Cannot calculate cost for dynamic effect '%s'. Ignoring.", effectType))
        target = "owner_dynamic"
    elseif effectType == "gainResourcePerNodeActivator" then
        print(string.format("Warning: Cannot calculate cost for dynamic effect '%s'. Ignoring.", effectType))
        target = "activator_dynamic"
    elseif effectType == "offerPaymentOwner" or effectType == "offerPaymentActivator" then
        -- Handled specially below
        target = (effectType == "offerPaymentOwner") and "offer_owner" or "offer_activator"
    else
        print(string.format("Warning: Unknown effect type '%s' for cost calculation.", effectType))
        target = "unknown"
    end

    -- Handle Offer Payment specifically
    if target == "offer_owner" or target == "offer_activator" then
        local paymentCostME = getMEValue(resource, amount)
        local consequenceBenefitME = 0
        if options.consequence then
            for _, consAction in ipairs(options.consequence) do
                -- Recursively calculate contribution of consequence actions
                -- Assume consequences follow same activation/convergence context for multiplier? Yes.
                local consContrib = calculateActionContribution(consAction, isActivationEffect)
                -- Net benefit = benefit - cost. Cost part is ignored here as it's part of the offer.
                consequenceBenefitME = consequenceBenefitME + consContrib.benefitME
            end
        end
        -- Net ME = Consequence Benefit - Payment Cost
        baseME = consequenceBenefitME - paymentCostME
        -- The 'target' for cost calculation is implicitly the payer, but the *benefit* rule depends on the consequence target.
        -- This is complex. Let's simplify: the net ME contributes directly to cost, adjusted by multipliers later.
        target = "offer_net" -- Special target type for applying multipliers
    end

    -- Apply Rules based on Target and Effect Context (Activation vs Convergence)
    local finalME = 0
    if isActivationEffect then
        if target == "owner" and baseME > 0 and target ~= "offer_net" then -- Free benefit for owner adds cost
             finalME = baseME
        elseif target == "owner" and baseME < 0 then -- Harm to owner reduces cost
             finalME = baseME
        elseif target == "steal" then -- Steal harms owner, reduces cost
            finalME = -baseME -- Subtract the value stolen
        elseif target == "self" and baseME < 0 then -- Harm to self (destroy link) reduces cost
             finalME = baseME
        elseif target == "offer_net" then -- Net cost/benefit from paid effects
            finalME = baseME
        -- Effects benefiting activator, both, all in activation have 0 direct cost contribution based on rules
        end
    else -- Convergence Effect
        local multiplier = CONVERGENCE_EFFECT_MULTIPLIER
        if target == "activator" and baseME > 0 then -- Benefit to activator reduces cost
             finalME = -baseME * multiplier
        elseif target == "steal" then -- Steal benefits activator, reduces cost
             finalME = -baseME * multiplier
        elseif target == "activator" and baseME < 0 then -- Harm to activator (discard) - does this add cost? Let's say yes.
             finalME = -baseME * multiplier -- Add cost = -(negative value) * mult
        elseif target == "owner" and baseME > 0 then -- Benefit to owner adds cost (reduced)
             finalME = baseME * multiplier
         elseif target == "offer_net" then -- Paid effects apply multiplier to net value
             finalME = baseME * multiplier
        -- Harm to owner, benefit/harm to both/all in convergence - need clearer rules.
        -- Tentative: Harm to owner reduces cost by mult*harm. Benefit Both/All adds mult*benefit.
        elseif target == "owner" and baseME < 0 then
             finalME = baseME * multiplier
        elseif (target == "both" or target == "all") and baseME ~= 0 then
             finalME = baseME * multiplier -- Assume benefit adds cost (reduced)
        end
    end

    -- Apply Conditional Multiplier if applicable
    if contribution.isConditional then
        finalME = finalME * CONDITIONAL_EFFECT_MULTIPLIER
    end

    contribution.benefitME = finalME -- Use benefitME field to store the final calculated contribution
    -- print(string.format("Action '%s' (Activation: %s): BaseME=%.2f, Target=%s -> FinalME=%.2f (Conditional: %s)", effectType, tostring(isActivationEffect), baseME, target, finalME, tostring(contribution.isConditional)))

    return contribution
end


-- Calculate the total ME cost contribution from activation and convergence effects
local function calculateEffectsCost(activationEffect, convergenceEffect)
    local totalEffectsME = 0

    -- Process Activation Effects
    if activationEffect and activationEffect.config and activationEffect.config.actions then -- Look inside .config
        for _, action in ipairs(activationEffect.config.actions) do
            local contribution = calculateActionContribution(action, true)
            totalEffectsME = totalEffectsME + contribution.benefitME
        end
    end

    -- Process Convergence Effects
    if convergenceEffect and convergenceEffect.config and convergenceEffect.config.actions then -- Look inside .config
         for _, action in ipairs(convergenceEffect.config.actions) do
            local contribution = calculateActionContribution(action, false)
            totalEffectsME = totalEffectsME + contribution.benefitME
        end
    end

    -- print(string.format("Total Effects Cost: %.2f ME", totalEffectsME))
    return totalEffectsME
end

-- Convert total ME cost into a Material/Data split
-- Prioritizes covering cost with whole Data units first.
-- Optionally accepts a thematicRatio {material=M_ratio, data=D_ratio} to guide the split.
local function convertMEtoCostTable(totalME, thematicRatio)
    local cost = { material = 0, data = 0 }
    local dataValueME = MATERIAL_EQUIVALENT[ResourceType.DATA]
    local materialValueME = MATERIAL_EQUIVALENT[ResourceType.MATERIAL]

    local M_ratio = thematicRatio and thematicRatio.material
    local D_ratio = thematicRatio and thematicRatio.data

    -- Ensure ratio values are valid numbers > 0
    local useRatio = type(M_ratio) == "number" and M_ratio >= 0 and
                     type(D_ratio) == "number" and D_ratio >= 0 and
                     (M_ratio + D_ratio > 0) -- Avoid division by zero
    
    if useRatio then
        -- Calculate how much of the totalME should go to each resource type
        local totalRatioParts = M_ratio + D_ratio
        
        -- The trick: Adjust the ratio based on the ME cost of each resource type
        -- Since data costs 2 ME per unit, we need to adjust the ratio 
        -- If we want 3:1 material:data, and data costs 2x as much,
        -- the ME distribution should be 3:2 (not 3:1)
        local adjustedMaterialRatio = M_ratio
        local adjustedDataRatio = D_ratio * (dataValueME / materialValueME)
        local totalAdjustedRatio = adjustedMaterialRatio + adjustedDataRatio
        
        -- Calculate ME values
        local materialME = totalME * (adjustedMaterialRatio / totalAdjustedRatio)
        local dataME = totalME * (adjustedDataRatio / totalAdjustedRatio)
        
        -- Convert to actual units
        local materialUnits = math.floor(materialME / materialValueME)
        local dataUnits = math.floor(dataME / dataValueME)
        
        -- If we end up with material=0 or data=0 but shouldn't based on the ratio,
        -- make sure we have at least 1 of each if the ratio requires it
        if materialUnits == 0 and M_ratio > 0 then materialUnits = 1 end
        if dataUnits == 0 and D_ratio > 0 then dataUnits = 1 end
        
        -- One more adjustment to account for rounding - ensure the total ME doesn't exceed the limit
        local usedME = (materialUnits * materialValueME) + (dataUnits * dataValueME)
        if usedME > totalME then
            -- If we're over budget, reduce the more expensive resource (data)
            if dataUnits > 0 then
                dataUnits = dataUnits - 1
            elseif materialUnits > 1 then
                materialUnits = materialUnits - 1
            end
        end
        
        -- For really small ME values where normal ratio calculation doesn't work well
        if materialUnits == 0 and dataUnits == 0 then
            materialUnits = 1 -- Default minimum
        end
        
        cost.material = materialUnits
        cost.data = dataUnits
    else -- Fallback to default logic: prioritize Data
        local dataUnits = math.floor(totalME / dataValueME)
        local remainingME = totalME - (dataUnits * dataValueME)

        -- Cover remainder with Materials
        local materialUnits = math.ceil(remainingME / materialValueME)

        cost.data = dataUnits
        cost.material = materialUnits
    end

    -- Ensure minimum cost is met (1 Material) even if calculated is lower/negative
    if cost.material <= 0 and cost.data == 0 then
         cost.material = 1 -- Enforce minimum 1 Material if total cost ends up non-positive
    end

    return cost
end


-- === Public Function ===

-- Calculates the derived build cost for a card definition.
-- Returns a table { material = M, data = D } and the total ME calculated.
function CostCalculator.calculateDerivedCost(cardDefinition, thematicRatio) -- Add optional ratio param
    if not cardDefinition then
        print("Error: Card definition is nil.")
        return nil, 0
    end

    -- Ignore Reactors and Genesis cards for now? Or calculate anyway? Let's calculate.
    -- if cardDefinition.type == CardTypes.REACTOR or cardDefinition.isGenesis then
    --     return { material = cardDefinition.buildCost.material, data = cardDefinition.buildCost.data }, 0 -- Return original cost
    -- end

    local portsME = calculatePortsCost(cardDefinition.definedPorts)
    local effectsME = calculateEffectsCost(cardDefinition.activationEffect, cardDefinition.convergenceEffect)

    local totalME = portsME + effectsME

    -- Apply minimum cost floor (in ME) before converting
    if totalME < MINIMUM_COST_ME then
        totalME = MINIMUM_COST_ME
    end

    local derivedCost = convertMEtoCostTable(totalME, thematicRatio) -- Pass ratio down

    -- Use io.stderr for debug output that bypasses the print override - Print for ALL cards now
    io.stderr:write(string.format("CostCalc Debug [%s]: Ports=%.2f, Effects=%.2f, RawTotal=%.2f, MinAppliedTotal=%.2f\n",
        cardDefinition.id or "MISSING_ID", portsME, effectsME, portsME + effectsME, totalME))

    -- This print *will* be suppressed by the override in card_definitions.lua
    print(string.format("  Derived Cost: %d M, %d D", derivedCost.material, derivedCost.data))
    -- print(string.format("  Original Cost: %d M, %d D", cardDefinition.buildCost.material or 0, cardDefinition.buildCost.data or 0))


    return derivedCost, totalME
end

return CostCalculator

