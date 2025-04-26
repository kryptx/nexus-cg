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

local PORT_COST_ME = 0.5
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
    local sideCompletionBonusME = 0

    if definedPorts then
        -- Count total ports for base cost
        for _, present in pairs(definedPorts) do
            if present then
                count = count + 1
            end
        end

        -- Check for completed sides and add bonus ME (using the same value as PORT_COST_ME)
        -- Use numeric CardPorts indices as keys
        local CardPorts = require('src.game.card').Ports -- Require here if not available globally
        if definedPorts[CardPorts.TOP_LEFT] and definedPorts[CardPorts.TOP_RIGHT] then
            sideCompletionBonusME = sideCompletionBonusME + PORT_COST_ME
        end
        if definedPorts[CardPorts.BOTTOM_LEFT] and definedPorts[CardPorts.BOTTOM_RIGHT] then
            sideCompletionBonusME = sideCompletionBonusME + PORT_COST_ME
        end
        if definedPorts[CardPorts.LEFT_TOP] and definedPorts[CardPorts.LEFT_BOTTOM] then
            sideCompletionBonusME = sideCompletionBonusME + PORT_COST_ME
        end
        if definedPorts[CardPorts.RIGHT_TOP] and definedPorts[CardPorts.RIGHT_BOTTOM] then
            sideCompletionBonusME = sideCompletionBonusME + PORT_COST_ME
        end
    end

    local baseCost = count * PORT_COST_ME
    local totalCost = baseCost + sideCompletionBonusME
    -- print(string.format("Ports Cost: %d ports * %.2f ME/port + %.2f Side Bonus = %.2f ME", count, PORT_COST_ME, sideCompletionBonusME, totalCost))
    return totalCost
end

-- Calculate the ME contribution of a single action within an effect
-- Returns the net ME contribution to the card's calculated cost.
local function calculateActionContribution(action, isActivationEffect)
    local effectType = action.effect
    local options = action.options or {}
    local conditionConfig = action.condition
    local isConditional = (conditionConfig ~= nil)
    local contributionME = 0 -- This will be the final value added/subtracted from the card's cost ME

    local resource = options.resource
    local amount = options.amount or 1

    -- Handle Payment Offer Condition separately first
    if conditionConfig and conditionConfig.type == "paymentOffer" then
        local payerType = conditionConfig.payer -- Owner or Activator
        local paymentResource = conditionConfig.resource
        local paymentAmount = conditionConfig.amount or 1
        
        if not paymentResource then
            print(string.format("Warning: paymentOffer condition for effect '%s' missing resource. Cannot calculate cost reduction.", effectType))
            -- Proceed to calculate base benefit of the effect itself, but apply conditional multiplier
            isConditional = true -- Ensure multiplier is applied even if payment cost fails
        else
            local paymentCostME = getMEValue(paymentResource, paymentAmount)
            
            -- The cost of the payment *reduces* the card's build cost, 
            -- because the player pays it *later* during play, not upfront.
            -- This cost reduction is itself conditional on the player choosing to pay.
            local paymentCostReduction = -paymentCostME * CONDITIONAL_EFFECT_MULTIPLIER 
            contributionME = contributionME + paymentCostReduction
            -- print(string.format("  PaymentOffer Cost: Payer=%s, Res=%s, Amt=%d -> CostME=%.2f, Reduction=%.2f", payerType, paymentResource, paymentAmount, paymentCostME, paymentCostReduction))
            
            -- Now, calculate the benefit of the *actual* effect this payment enables
            -- The benefit calculation proceeds below, but it's subject to the conditionality
            isConditional = true -- The effect only happens if payment is made
        end
    end

    -- Determine Base Benefit/Harm ME of the core effect (Ignoring player payment costs handled above)
    local baseME = 0
    local target = "unknown" -- owner, activator, both, all, self, steal

    if effectType == "addResourceToOwner" then
        baseME = getMEValue(resource, amount)
        target = "owner"
    elseif effectType == "addResourceToActivator" then
        baseME = getMEValue(resource, amount)
        target = "activator"
    elseif effectType == "addResourceToBoth" then
        baseME = getMEValue(resource, amount) 
        target = "both"
    elseif effectType == "addResourceToAllPlayers" then
        baseME = getMEValue(resource, amount) 
        target = "all"
    elseif effectType == "drawCardsForOwner" then
        baseME = getMEValue("draw", amount)
        target = "owner"
    elseif effectType == "drawCardsForActivator" then
        baseME = getMEValue("draw", amount)
        target = "activator"
    elseif effectType == "drawCardsForAllPlayers" then
         baseME = getMEValue("draw", amount)
         target = "all"
    elseif effectType == "gainVPForOwner" then
        baseME = getMEValue("vp", amount)
        target = "owner"
    elseif effectType == "gainVPForActivator" then
        baseME = getMEValue("vp", amount)
        target = "activator"
    elseif effectType == "gainVPForBoth" then
        baseME = getMEValue("vp", amount) 
        target = "both"
    elseif effectType == "forceDiscardCardsOwner" then
        baseME = -getMEValue("draw", amount) 
        target = "owner"
    elseif effectType == "forceDiscardCardsActivator" then
        baseME = -getMEValue("draw", amount) 
        target = "activator"
    elseif effectType == "destroyRandomLinkOnNode" then
         baseME = -2.0 
         target = "self" 
    elseif effectType == "stealResource" then
        baseME = getMEValue(resource, amount) -- Benefit for activator, harm for owner
        target = "steal"
    -- New Chain Steal Effects
    elseif effectType == "activatorStealResourceFromChainOwners" then
        baseME = getMEValue(resource, 1.5) -- Estimated avg benefit: steal 1 resource (value based on type) from 1.5 owners
        target = "activator" -- The activator is the beneficiary
    elseif effectType == "ownerStealResourceFromChainOwners" then
        baseME = getMEValue(resource, 1.5) -- Estimated avg benefit
        target = "owner" -- The owner is the beneficiary
    -- Dynamic effects - ignore for now
    elseif effectType == "gainResourcePerNodeOwner" or effectType == "gainResourcePerNodeActivator" then
        print(string.format("Warning: Cannot calculate cost for dynamic effect '%s'. Ignoring.", effectType))
        target = "dynamic"
    else
        print(string.format("Warning: Unknown effect type '%s' for cost calculation.", effectType))
    end

    -- Calculate ME contribution from the base effect based on target and context
    local effectME = 0
    if isActivationEffect then -- Effect occurs during Owner's activation
        if target == "owner" then effectME = baseME -- Benefit/Harm to owner directly impacts cost
        elseif target == "steal" then effectME = -baseME -- Steal (benefit activator) harms owner, reduces cost
        elseif target == "self" and baseME < 0 then effectME = baseME -- Self-harm reduces cost
        -- Effects targeting activator/both/all in activation context have 0 cost contribution by default
        end
    else -- Effect occurs during Convergence (Activator is opponent)
        local multiplier = CONVERGENCE_EFFECT_MULTIPLIER
        if target == "activator" then effectME = -baseME * multiplier -- Benefit to activator reduces cost; Harm adds cost
        elseif target == "steal" then effectME = -baseME * multiplier -- Steal benefits activator, reduces cost
        elseif target == "owner" then effectME = baseME * multiplier -- Benefit/Harm to owner impacts cost (reduced)
        elseif target == "both" or target == "all" then effectME = baseME * multiplier -- Assume benefit adds cost (reduced), harm reduces cost (reduced)
        elseif target == "self" and baseME < 0 then effectME = baseME * multiplier -- Self-harm reduces cost (reduced)
        end
    end

    -- Apply Conditional Multiplier to the *effect's* contribution (payment cost reduction already handled)
    if isConditional then
        effectME = effectME * CONDITIONAL_EFFECT_MULTIPLIER
    end

    -- Add the effect's contribution to the total contribution for this action
    contributionME = contributionME + effectME

    -- print(string.format("Action '%s' (Activation: %s): BaseME=%.2f, Target=%s -> EffectME=%.2f (Conditional: %s) -> TotalContribME=%.2f", 
    --    effectType, tostring(isActivationEffect), baseME, target, effectME, tostring(isConditional), contributionME))

    return contributionME
end


-- Calculate the total ME cost contribution from activation and convergence effects
local function calculateEffectsCost(activationEffect, convergenceEffect)
    local totalEffectsME = 0

    -- Process Activation Effects
    if activationEffect and activationEffect.config and activationEffect.config.actions then
        for _, action in ipairs(activationEffect.config.actions) do
            totalEffectsME = totalEffectsME + calculateActionContribution(action, true)
        end
    end

    -- Process Convergence Effects
    if convergenceEffect and convergenceEffect.config and convergenceEffect.config.actions then
         for _, action in ipairs(convergenceEffect.config.actions) do
            totalEffectsME = totalEffectsME + calculateActionContribution(action, false)
        end
    end

    -- print(string.format("Total Effects Cost: %.2f ME", totalEffectsME))
    return totalEffectsME
end

-- Convert total ME cost into a Material/Data split
-- Tries to match the target ME cost using rounding.
-- Optionally accepts a thematicRatio {material=M_ratio, data=D_ratio} to guide the split.

-- Helper function for standard rounding
local round = function(n)
	return math.floor(n + 0.5)
end

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
        
        -- Convert to actual units using rounding
        local materialUnits = round(materialME / materialValueME)
        local dataUnits = round(dataME / dataValueME)
        
        -- If we end up with material=0 or data=0 but shouldn't based on the ratio,
        -- make sure we have at least 1 of each if the ratio requires it
        if materialUnits == 0 and M_ratio > 0 then materialUnits = 1 end
        if dataUnits == 0 and D_ratio > 0 then dataUnits = 1 end
        
        -- For really small ME values where normal ratio calculation doesn't work well
        if materialUnits == 0 and dataUnits == 0 and totalME > 0 then -- Added check for totalME > 0
            materialUnits = 1 -- Default minimum if ME is positive
        end
        
        cost.material = materialUnits
        cost.data = dataUnits
    else -- Fallback logic: also use rounding
        -- Calculate ideal units based on rounding
        local dataUnits = round(totalME / dataValueME)
        local remainingME = totalME - (dataUnits * dataValueME)

        -- Cover remainder with Materials, using rounding
        local materialUnits = round(remainingME / materialValueME)

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

