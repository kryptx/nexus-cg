-- src/game/card_effects.lua
-- Provides helper functions for creating card activation and convergence effects.

local CardEffects = {}

-- Assumed to be defined elsewhere and accessible (e.g., via require)
local Card = require("src.game.card") -- Need access to Card.Type
-- local PortTypes = require("src.game.port_types") -- If we abstract port types further

-- Define resource types as constants
CardEffects.ResourceType = {
    ENERGY = "energy",
    DATA = "data",
    MATERIAL = "material",
}

-- Helper function to generate descriptions for resource effects (NO TRAILING PERIODS)
local function generateResourceDescription(actionEffect, resource, amount, context)
    local resourceName = resource:sub(1, 1):upper() .. resource:sub(2) -- Capitalize first letter
    local isImperative = false
    
    -- Check if we should use imperative form:
    -- For activation effects, both owner and activator use imperative (you)
    -- For convergence effects, only activator uses imperative
    if context then
        if context.effectType == "activation" then
            if actionEffect:find("Owner") then
                isImperative = true
            end
        end
    end
    
    if actionEffect == "addResourceToOwner" then
        if isImperative then
            return string.format("Gain %d %s", amount, resourceName) 
        else
            return string.format("Owner gains %d %s", amount, resourceName)
        end
    elseif actionEffect == "addResourceToActivator" then
        return string.format("Gain %d %s", amount, resourceName)
    elseif actionEffect == "addResourceToBoth" then
        if isImperative then
            return string.format("You and the %s gain %d %s", 
                context.effectType == "activation" and "activator" or "owner",
                amount, resourceName)
        else
            return string.format("Owner and activator gain %d %s", amount, resourceName)
        end
    elseif actionEffect == "addResourceToAllPlayers" then
        return string.format("All players gain %d %s", amount, resourceName)
    -- Removed redundant gainResourcePerNodeOwner, gainResourcePerNodeActivator, stealResource handlers
    end
    
    -- Return a generic description if no match, let generateOtherDescription handle specifics
    return "Resource effect" 
end

-- Generates descriptions for non-resource effects (or resource effects not covered above) (NO TRAILING PERIODS)
local function generateOtherDescription(actionEffect, options, context)
    local isImperative = false
    
    -- Check if we should use imperative form:
    -- For activation effects, both owner and activator use imperative (you)
    -- For convergence effects, only activator uses imperative
    if context then
        if context.effectType == "activation" then
            if actionEffect:find("Owner") then
                isImperative = true
            end
        end
    end

    if actionEffect == "drawCardsForActivator" then
            return string.format("Draw %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "drawCardsForOwner" then
        if isImperative and context and context.effectType == "activation" then
            return string.format("Draw %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
        else
            return string.format("Owner draws %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
        end
    elseif actionEffect == "drawCardsForBoth" then
        return string.format("You and the owner each draw %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "drawCardsForAllPlayers" then
        return string.format("All players draw %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "gainVPForActivator" then
        return string.format("Gain %d VP", options.amount or 1)
    elseif actionEffect == "gainVPForOwner" then
        if isImperative and context and context.effectType == "activation" then
            return string.format("Gain %d VP", options.amount or 1)
        else
            return string.format("Owner gains %d VP", options.amount or 1)
        end
    elseif actionEffect == "gainVPForBoth" then
        return string.format("You and the owner gain %d VP", options.amount or 1)
    elseif actionEffect == "forceDiscardRandomCardsOwner" then
        if isImperative and context and context.effectType == "activation" then
            return string.format("Discard %d random card%s", options.amount or 1, options.amount == 1 and "" or "s")
        else
            return string.format("Owner discards %d random card%s", options.amount or 1, options.amount == 1 and "" or "s")
        end
    elseif actionEffect == "forceDiscardRandomCardsActivator" then
        return string.format("Discard %d random card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "destroyRandomLinkOnNode" then
        return "Destroy a random convergence link on this node"
    -- === Refined Resource Descriptions handled here now ===
    elseif actionEffect == "stealResource" then
        local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
        return string.format("Steal %d %s from the owner", options.amount or 1, resourceName)
    elseif actionEffect == "gainResourcePerNodeOwner" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any" 
         if isImperative and context and context.effectType == "activation" then
             return string.format("Gain %d %s per %s in your network", options.amount or 1, resourceName, nodeType)
         else
             return string.format("Owner gains %d %s per %s in their network", options.amount or 1, resourceName, nodeType)
         end
    elseif actionEffect == "gainResourcePerNodeActivator" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any"
         return string.format("Gain %d %s per %s in the owner's network", options.amount or 1, resourceName, nodeType)
    -- === NEW EFFECT DESCRIPTIONS ===
    elseif actionEffect == "activatorStealResourceFromChainOwners" then
         local resourceName = options.resource and (options.resource:sub(1, 1):upper() .. options.resource:sub(2)) or "Resource"
         local amount = options.amount or 1
         return string.format("Steal %d %s from each owner of nodes activated this chain", amount, resourceName)
    elseif actionEffect == "ownerStealResourceFromChainOwners" then
         local resourceName = options.resource and (options.resource:sub(1, 1):upper() .. options.resource:sub(2)) or "Resource"
         local amount = options.amount or 1
         if isImperative and context and context.effectType == "activation" then
             return string.format("Steal %d %s from each owner of nodes activated this chain", amount, resourceName)
         else
             return string.format("Owner steals %d %s from each owner of nodes activated this chain", amount, resourceName)
         end
    -- === TOKEN EFFECT DESCRIPTIONS ===
    elseif actionEffect == "addToken" then
        return "Add 1 token to this node"
    elseif actionEffect == "removeTokens" then
        return "Remove all tokens from this node"
    -- =====================================================
    end
    return "Unknown other effect" -- Note: No trailing period here either
end

-- === CONDITION EVALUATION HELPERS ===

-- Checks adjacency condition
local function evaluateAdjacencyCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not sourceNetwork or not sourceNode or not sourceNode.position then return false end
    -- Network:getNeighbors returns Card instances of adjacent cards
    local neighbors = sourceNetwork:getNeighbors(sourceNode.position)
    local count = 0
    local requiredType = conditionConfig.nodeType
    local requiredCount = conditionConfig.count or 1
    for _, neighborCard in ipairs(neighbors) do
        if neighborCard and neighborCard.type == requiredType then
            count = count + 1
        end
    end
    -- Log with explicit coordinates
    print(string.format("Evaluated adjacency condition: %d/%d %s found adjacent to (%d,%d)",
        count, requiredCount, requiredType, sourceNode.position.x, sourceNode.position.y))
    return count >= requiredCount
end

-- Checks convergence link condition
local function evaluateConvergenceLinkCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not sourceNode or not sourceNode.card or not sourceNode.card.getConvergenceLinkCount then return false end
    local currentLinks = sourceNode.card:getConvergenceLinkCount()
    local requiredCount = conditionConfig.count or 1
    return currentLinks >= requiredCount
end

-- Checks satisfied inputs condition
local function evaluateSatisfiedInputsCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not sourceNetwork or not sourceNode or not sourceNode.position then return false end -- Added sourceNetwork check
    if not sourceNode.card or not sourceNode.card.getInputPorts then return false end -- Added card check
    local presentInputs = sourceNode.card:getInputPorts() 
    local satisfiedCount = 0
    local requiredCount = conditionConfig.count or 1
    for _, inputPortInfo in ipairs(presentInputs) do
        -- Call getAdjacentCoordForPort with separate x and y from sourceNode.position
        local neighborPos = sourceNetwork:getAdjacentCoordForPort(sourceNode.position.x, sourceNode.position.y, inputPortInfo.index) 
        local neighborNode = sourceNetwork:getCardAt(neighborPos.x, neighborPos.y) 
        if neighborNode and neighborNode.card and neighborNode.card.hasOutputPort then
            local opposingPortIndex = sourceNetwork:getOpposingPortIndex(inputPortInfo.index)
            if neighborNode.card:hasOutputPort(inputPortInfo.type, opposingPortIndex) then 
                satisfiedCount = satisfiedCount + 1
            end
        end
    end
    return satisfiedCount >= requiredCount
end

-- Checks activation chain length condition
local function evaluateActivationChainLengthCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not gameService then
        print("Error: gameService is required to evaluate activationChainLength condition.")
        return false -- Need gameService to check chain length
    end

    local chainInfo = nil
    -- Use the new function to get chain details
    if gameService.getActivationChainInfo then
        chainInfo = gameService:getActivationChainInfo()
    else
        -- This indicates a missing part in the GameService implementation
        print("Warning: gameService:getActivationChainInfo() not found. Cannot evaluate activationChainLength condition.")
        return false -- Fail safely if the method doesn't exist
    end

    if not chainInfo then
        print("Warning: getActivationChainInfo() returned nil.")
        return false
    end

    local currentChainLength = chainInfo.length -- Get the length from the returned table
    local requiredCount = conditionConfig.count or 1
    print(string.format("Evaluated activation chain length condition: Current=%d, Required=%d", currentChainLength, requiredCount))
    return currentChainLength >= requiredCount
end

-- NEW: Checks activated card type condition
local function evaluateActivatedCardTypeCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not gameService or not gameService.getActivationChainInfo then
        print("Error: gameService:getActivationChainInfo is required to evaluate activatedCardType condition.")
        return false
    end

    local chainInfo = gameService:getActivationChainInfo()
    if not chainInfo or not chainInfo.cards then
        print("Warning: getActivationChainInfo() returned invalid data.")
        return false
    end

    local requiredType = conditionConfig.cardType
    local requiredCount = conditionConfig.count or 1
    if not requiredType then
         print("Warning: activatedCardType condition requires 'cardType' in config.")
         return false
    end

    local currentCount = 0
    for _, cardTypeInChain in ipairs(chainInfo.cards) do
        if cardTypeInChain == requiredType then
            currentCount = currentCount + 1
        end
    end

    print(string.format("Evaluated activated card type condition: Found %d/%d '%s' cards in chain.", currentCount, requiredCount, requiredType))
    return currentCount >= requiredCount
end

-- NEW: Checks adjacent empty cells condition
local function evaluateAdjacentEmptyCellsCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not sourceNetwork or not sourceNode or not sourceNode.position then return false end
    -- We need a way to get *all* adjacent coordinates, not just linked ones.
    -- Assuming Network has a method like getAdjacentCoords(pos)
    if not sourceNetwork.getAdjacentCoords then
        print("Error: sourceNetwork:getAdjacentCoords() required for adjacentEmptyCells condition.")
        return false
    end

    local neighbors = sourceNetwork:getAdjacentCoords(sourceNode.position.x, sourceNode.position.y) -- Pass x and y explicitly
    local emptyCount = 0
    local requiredCount = conditionConfig.count or 1

    for _, neighborPos in ipairs(neighbors) do
        local nodeAtPos = sourceNetwork:getCardAt(neighborPos.x, neighborPos.y)
        if not nodeAtPos then -- Check if the cell is empty (no node)
            emptyCount = emptyCount + 1
        end
    end

    print(string.format("Evaluated adjacent empty cells condition: %d/%d empty cells found adjacent to %s", emptyCount, requiredCount, sourceNode.position))
    return emptyCount >= requiredCount
end

-- NEW: Checks if a player *can* afford a potential payment
-- Note: This only checks affordability, doesn't initiate payment.
local function evaluatePaymentOfferCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    local payerType = conditionConfig.payer -- Should be "Owner" or "Activator"
    local resource = conditionConfig.resource
    local amount = conditionConfig.amount or 1
    
    if not payerType or not resource then
        print("Warning: paymentOffer condition missing 'payer' or 'resource'.")
        return false
    end

    local playerToPay = (payerType == "Owner") and sourceNetwork.owner or activatingPlayer
    
    if not playerToPay or not playerToPay.resources or not playerToPay.resources[resource] then
         print(string.format("Warning: Cannot find player '%s' or their resources for paymentOffer.", payerType))
         return false
    end
    
    local canAfford = playerToPay.resources[resource] >= amount
    print(string.format("Evaluated paymentOffer condition for %s: Can afford %d %s? %s", payerType, amount, resource, tostring(canAfford)))
    return canAfford
end

-- NEW: Checks if a node has enough tokens accumulated
local function evaluateHasTokensCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not sourceNode or not sourceNode.card then 
        print("Error: sourceNode is required to evaluate hasTokens condition.")
        return false
    end
    
    local nodeCard = sourceNode.card
    -- Initialize tokens field on the card if it doesn't exist
    nodeCard.tokens = nodeCard.tokens or 0
    
    local requiredCount = conditionConfig.count or 1
    local currentTokens = nodeCard.tokens
    
    print(string.format("Evaluated hasTokens condition: Current=%d, Required=%d", currentTokens, requiredCount))
    return currentTokens >= requiredCount
end

-- Central condition evaluator
local function evaluateCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not conditionConfig then return true end -- No condition means it passes

    local conditionType = conditionConfig.type
    if conditionType == "adjacency" then
        return evaluateAdjacencyCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "convergenceLinks" then
        return evaluateConvergenceLinkCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "satisfiedInputs" then
        return evaluateSatisfiedInputsCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "activationChainLength" then
        return evaluateActivationChainLengthCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "activatedCardType" then
        return evaluateActivatedCardTypeCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "adjacentEmptyCells" then
        return evaluateAdjacentEmptyCellsCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "paymentOffer" then
        return evaluatePaymentOfferCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "hasTokens" then
        return evaluateHasTokensCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    else
        print(string.format("Warning: Unknown condition type '%s' to evaluate.", conditionType))
        return false -- Fail safely for unknown condition types
    end
end

-- === CONDITION DESCRIPTION HELPER (Updated for port terminology) ===

local function generateConditionDescription(conditionConfig, context)
    if not conditionConfig then return "" end
    local type = conditionConfig.type
    local count = conditionConfig.count or 1
    local useYou = false
    
    -- Check if we should use "you" instead of "Owner"/"Activator"
    if context then
        if context.effectType == "activation" then
            if conditionConfig.payer == "Owner" or conditionConfig.payer == "Activator" then
                useYou = true
            end
        elseif context.effectType == "convergence" then
            if conditionConfig.payer == "Activator" then
                useYou = true
            end
        end
    end
    
    if type == "adjacency" then
        local nodeType = conditionConfig.nodeType or "Any"
        return string.format("If adjacent to %d+ %s: ", count, nodeType)
    elseif type == "convergenceLinks" then
        return string.format("If %d+ links attached: ", count)
    elseif type == "satisfiedInputs" then
        return string.format("If %d+ inputs connected: ", count)
    elseif type == "activationChainLength" then
        return string.format("If %d+ nodes activated this chain: ", count)
    elseif type == "activatedCardType" then
        local cardType = conditionConfig.cardType or "Unknown"
        return string.format("If %d+ %s activated this chain: ", count, cardType)
    elseif type == "adjacentEmptyCells" then
        return string.format("If adjacent to %d+ empty cells: ", count)
    elseif type == "hasTokens" then
        return string.format("If %d+ tokens on this node: ", count)
    elseif type == "paymentOffer" then
        local payer = conditionConfig.payer or "Player" -- Default if missing
        if useYou and payer ~= "Player" then 
            payer = "you"
        end
        local resource = conditionConfig.resource or "Resource"
        local amount = conditionConfig.amount or 1
        local resourceName = resource:sub(1, 1):upper() .. resource:sub(2)
        return string.format("If %s pay%s %d %s: ", payer, useYou and "" or "s", amount, resourceName)
    else
        print(string.format("Warning: Unknown condition type '%s' for description.", type))
        return "If condition met: "
    end
end

-- Helper to get the raw action description without period
local function generateActionDescription(action, context)
    local effectType = action.effect
    local options = action.options or {}
    local actionText = ""
    
    -- Determine which description generator to use
    if effectType == "addResourceToOwner" or effectType == "addResourceToActivator" or effectType == "addResourceToBoth" or effectType == "addResourceToAllPlayers" then
         actionText = generateResourceDescription(effectType, options.resource, options.amount or 1, context)
    else
        actionText = generateOtherDescription(effectType, options, context)
    end
    
    if actionText:find("Unknown") then
        print(string.format("Warning: Could not generate description for effect type '%s'", effectType))
    end
    
    return actionText
end

-- === NEW HELPER for Offer Payment Logic === -> Rename and Refactor for Step 5
-- Renamed to _requestPaymentAndExecute
-- Now takes the action *to execute* as a parameter
-- playerToAsk: The player object who needs to make the choice
-- costResource, costAmount: From the conditionConfig
-- actionToExecute: The original action table {effect=..., options=...} that was guarded by the paymentOffer condition
-- gameService, activatingPlayer, sourceNetwork, sourceNode: Original execution context
local function _requestPaymentAndExecute(playerToAsk, costResource, costAmount, actionToExecute, actionIndex, actionsList, gameService, activatingPlayer, sourceNetwork, sourceNode)
    -- NOTE: We already know the player *can* pay because evaluatePaymentOfferCondition passed.
    
    -- Determine the correct context for generating the benefit description
    local owner = sourceNetwork.owner
    local benefitContext
    if playerToAsk == owner then
        -- If the owner is being asked, provide the 'activation' context 
        -- to generateActionDescription. This ensures its internal logic 
        -- uses imperative phrasing for "Owner" effects (e.g., "Draw 1 card") 
        -- from the owner's perspective during this payment step.
        benefitContext = { effectType = "activation" }
    else
        -- If the activator is being asked, use the original context derived
        -- from the effect definition (activation or convergence). This maintains
        -- correct phrasing (e.g., "Owner draws 1 card" or imperative "Gain X" 
        -- if the effect targets the activator).
        benefitContext = { effectType = actionToExecute.condition and "convergence" or "activation" }
    end
    
    -- Support grouping multiple effects under one paymentOffer condition
    local effList = actionToExecute.effects or { { effect = actionToExecute.effect, options = actionToExecute.options or {} } }
    -- Generate benefit descriptions for all effects in the group
    local benefitDescriptions = {}
    for _, effDef in ipairs(effList) do
        table.insert(benefitDescriptions, generateActionDescription({ effect = effDef.effect, options = effDef.options }, benefitContext))
    end
    local benefitDescription = table.concat(benefitDescriptions, "; ")
    
    -- Create a detailed question with payment cost and benefit
    local questionString = string.format("Pay %d %s to: %s", 
        costAmount, 
        costResource:sub(1, 1):upper() .. costResource:sub(2),
        benefitDescription)
        
    -- For single-effect resource gains, make it more visually clear
    local firstEff = effList and effList[1]
    if firstEff and firstEff.effect and type(firstEff.effect) == "string" and firstEff.effect:find("addResource") and firstEff.options and firstEff.options.resource then
        local gainedResource = firstEff.options.resource:sub(1, 1):upper() .. firstEff.options.resource:sub(2)
        local gainedAmount = firstEff.options.amount or 1
        questionString = string.format("Pay %d %s to gain %d %s", 
            costAmount, 
            costResource:sub(1, 1):upper() .. costResource:sub(2),
            gainedAmount,
            gainedResource)
    end

    -- Options to enhance the display
    local displayOptions = {
        showCard = true,        -- Show the card being activated
        cardScale = 2.0,        -- Show at 200% scale
        highlightEffect = true,  -- Highlight the effect text
        sourceNode = sourceNode -- Include the node to display
    }

    -- Create the callback function containing the logic to run *after* player chooses
    local afterChoiceCallback = function(playerWhoAnswered, answer)
        -- Handle payment agreement or decline
        if answer then
            print(string.format("[Callback] Player %d agreed to pay %d %s.", playerWhoAnswered.id, costAmount, costResource))
            if playerWhoAnswered:spendResource(costResource, costAmount) then
                print(string.format("[Callback] Player %d paid %d %s. Executing payment group actions...", playerWhoAnswered.id, costAmount, costResource))
                -- Execute each effect in the payment group
                for _, effDef in ipairs(effList) do
                    CardEffects._executeSingleAction(effDef.effect, effDef.options or {}, gameService, activatingPlayer, sourceNetwork, sourceNode)
                end
            else
                print(string.format("Warning: Failed to spend resource for player %d after passing initial check.", playerWhoAnswered.id))
            end
        else
            print(string.format("[Callback] Player %d chose not to pay %d %s.", playerWhoAnswered.id, costAmount, costResource))
        end
        -- Continue with any remaining actions in the effect
        for j = actionIndex + 1, #actionsList do
            local nextAction = actionsList[j]
            local cond = nextAction.condition
            -- Treat separate paymentOffer actions independently
            if cond and cond.type == "paymentOffer" then
                local payerType2 = cond.payer
                local playerToAsk2 = (payerType2 == "Owner") and owner or activatingPlayer
                return _requestPaymentAndExecute(playerToAsk2, cond.resource, cond.amount or 1, nextAction, j, actionsList, gameService, activatingPlayer, sourceNetwork, sourceNode)
            elseif not cond or evaluateCondition(cond, gameService, activatingPlayer, sourceNetwork, sourceNode) then
                print(string.format("[Callback] Continuing action '%s' after payment step...", nextAction.effect))
                if nextAction.effects then
                    for _, eff2 in ipairs(nextAction.effects) do
                        CardEffects._executeSingleAction(eff2.effect, eff2.options or {}, gameService, activatingPlayer, sourceNetwork, sourceNode)
                    end
                else
                    CardEffects._executeSingleAction(nextAction.effect, nextAction.options or {}, gameService, activatingPlayer, sourceNetwork, sourceNode)
                end
            end
        end
        -- After processing remaining actions, resume the activation chain if paused
        if gameService.activationService and gameService.activationService.resumeActivation then
            print("[Effect] Resuming activation chain after payment resolution...")
            local status, resumeMsg = gameService.activationService:resumeActivation()
            if resumeMsg then print(resumeMsg) end
        end
    end

    -- Request the input from the player via GameService, passing display options
    gameService:requestPlayerYesNo(playerToAsk, questionString, afterChoiceCallback, displayOptions)
    -- Use first effect name or fallback description when printing
    local printEffect = actionToExecute.effect or (effList[1] and effList[1].effect) or "<multiple>"
    print(string.format("[Effect] Requesting payment (%d %s) from player %d for effect '%s'. Waiting for response...", costAmount, costResource, playerToAsk.id, printEffect))
    -- Signal that we are now waiting for input
    return "waiting"

    -- Removed the 'cannot afford' else block as it's checked by evaluatePaymentOfferCondition now
end

-- === NEW INTERNAL HELPER for Chain Steal ===
-- beneficiary: The player object who receives the stolen resources
-- resource, amount: The type and quantity to steal from each owner
-- gameService: Reference to the game service
local function _executeChainSteal(beneficiary, resource, amount, gameService)
    if not beneficiary then print("Warning: _executeChainSteal called without a beneficiary."); return end
    if not resource then print("Warning: _executeChainSteal missing 'resource'."); return end
    amount = amount or 1
    if not gameService or not gameService.getActivationChainInfo then 
        print("Warning: _executeChainSteal requires gameService:getActivationChainInfo()."); 
        return 
    end
    if not gameService.transferResource then
        print("Warning: _executeChainSteal requires gameService:transferResource()."); 
        return
    end
    
    local chainInfo = gameService:getActivationChainInfo()
    -- Ensure chainInfo and chainInfo.nodes are valid tables
    if not chainInfo or type(chainInfo.nodes) ~= 'table' then 
        print("Warning: _executeChainSteal received invalid chain info (not a table or nil)."); 
        return
    end
    -- Handle empty chain case gracefully
    if #chainInfo.nodes == 0 then
        print("Executing ChainSteal: No nodes found in chain.")
        return
    end

    local uniqueOwners = {}
    local allOwnersInChain = {}
    for _, nodeInfo in ipairs(chainInfo.nodes) do
        if nodeInfo.owner then
            if not uniqueOwners[nodeInfo.owner.id] then
                uniqueOwners[nodeInfo.owner.id] = true
                table.insert(allOwnersInChain, nodeInfo.owner)
            end
        end
    end

    if #allOwnersInChain > 0 then
        print(string.format("Executing ChainSteal for Player %d: Targeting %d unique owners.", beneficiary.id, #allOwnersInChain))
        for _, ownerToStealFrom in ipairs(allOwnersInChain) do
            print(string.format("  - Attempting to steal %d %s from Player %d (-> to Player %d)", amount, resource, ownerToStealFrom.id, beneficiary.id))
            gameService:transferResource(ownerToStealFrom, beneficiary, resource, amount)
        end
    else
         print("Executing ChainSteal: No valid owners found in chain.")
    end
end

-- === NEW HELPER: Direct Single Action Execution ===
-- This avoids recursion issues with createActivationEffect inside the payment callback.
function CardEffects._executeSingleAction(effectType, options, gameService, activatingPlayer, sourceNetwork, sourceNode)
    local owner = sourceNetwork.owner
    print(string.format("Directly executing action: %s", effectType))

     -- Replicate the effect logic from createActivationEffect's activateFunction here...
     -- Resource Effects
    if effectType == "addResourceToOwner" then
        local resource = options.resource; local amount = options.amount or 1
        if owner and owner.addResource then owner:addResource(resource, amount) else print("Warning: Could not find owner for addResourceToOwner") end
    elseif effectType == "addResourceToActivator" then
        local resource = options.resource; local amount = options.amount or 1
        if activatingPlayer and activatingPlayer.addResource then activatingPlayer:addResource(resource, amount) end
    elseif effectType == "addResourceToBoth" then
        local resource = options.resource; local amount = options.amount or 1
        if owner and owner.addResource then owner:addResource(resource, amount) end
        if activatingPlayer and activatingPlayer.addResource and activatingPlayer ~= owner then activatingPlayer:addResource(resource, amount) end
    elseif effectType == "addResourceToAllPlayers" then
        local resource = options.resource; local amount = options.amount or 1
        if gameService.addResourceToAllPlayers then gameService:addResourceToAllPlayers(resource, amount) else print("Warning: gameService:addResourceToAllPlayers not found!") end
    
    -- Other Effects
    elseif effectType == "drawCardsForActivator" then
        local amount = options.amount or 1
        if gameService.playerDrawCards then gameService:playerDrawCards(activatingPlayer, amount) else print("Warning: gameService:playerDrawCards not found!") end
    elseif effectType == "drawCardsForAllPlayers" then
        local amount = options.amount or 1
        if gameService.getAllPlayers and gameService.playerDrawCards then
            local allPlayers = gameService:getAllPlayers()
            for _, player in ipairs(allPlayers) do
                gameService:playerDrawCards(player, amount)
            end
            print(string.format("Executed drawCardsForAllPlayers: %d card(s) for %d players.", amount, #allPlayers))
        else
            print("Warning: gameService:getAllPlayers or gameService:playerDrawCards not found for drawCardsForAllPlayers!")
        end
    elseif effectType == "drawCardsForOwner" then
        local amount = options.amount or 1
        if owner and gameService.playerDrawCards then
            gameService:playerDrawCards(owner, amount)
        else
            print("Warning: gameService:playerDrawCards not found or owner missing!")
        end
    elseif effectType == "drawCardsForBoth" then
        local amount = options.amount or 1
        if activatingPlayer and owner and gameService.playerDrawCards then
            gameService:playerDrawCards(activatingPlayer, amount)
            gameService:playerDrawCards(owner, amount)
        else
            print("Warning: gameService:playerDrawCards not found or activatingPlayer/owner missing!")
        end
    elseif effectType == "gainVPForActivator" then
        local amount = options.amount or 1
        if gameService.awardVP then gameService:awardVP(activatingPlayer, amount) else print("Warning: gameService:awardVP not found!") end
    elseif effectType == "gainVPForOwner" then
        local amount = options.amount or 1
        if owner and gameService.awardVP then gameService:awardVP(owner, amount) else print("Warning: gameService:awardVP not found or owner missing!") end
    elseif effectType == "gainVPForBoth" then
        local amount = options.amount or 1
        if activatingPlayer and gameService.awardVP then gameService:awardVP(activatingPlayer, amount) else print("Warning: gameService:awardVP not found or activatingPlayer missing!") end
        if owner and gameService.awardVP then gameService:awardVP(owner, amount) else print("Warning: gameService:awardVP not found or owner missing!") end
    elseif effectType == "forceDiscardRandomCardsOwner" then
        local amount = options.amount or 1
        if owner and gameService.forcePlayerDiscard then gameService:forcePlayerDiscard(owner, amount) else print("Warning: gameService:forcePlayerDiscard not found or owner missing!") end
    elseif effectType == "forceDiscardRandomCardsActivator" then
        local amount = options.amount or 1
        if activatingPlayer and gameService.forcePlayerDiscard then gameService:forcePlayerDiscard(activatingPlayer, amount) else print("Warning: gameService:forcePlayerDiscard not found or activatingPlayer missing!") end
    elseif effectType == "destroyRandomLinkOnNode" then
        if sourceNode and gameService.destroyRandomLinkOnNode then gameService:destroyRandomLinkOnNode(sourceNode) else print("Warning: gameService:destroyRandomLinkOnNode not found or sourceNode missing!") end
    elseif effectType == "stealResource" then
        local resource = options.resource; local amount = options.amount or 1
        if owner and activatingPlayer and owner ~= activatingPlayer and gameService.transferResource then gameService:transferResource(owner, activatingPlayer, resource, amount) else print("Warning: Could not execute stealResource.") end
    elseif effectType == "gainResourcePerNodeOwner" then
        local resource = options.resource; local nodeType = options.nodeType; local amountPerNode = options.amount or 1
        if owner and owner.network and owner.network.countNodesByType and owner.addResource and nodeType then
            local count = owner.network:countNodesByType(nodeType); local totalAmount = count * amountPerNode
            if totalAmount > 0 then owner:addResource(resource, totalAmount) end
        else print("Warning: Could not execute gainResourcePerNodeOwner.") end
    elseif effectType == "gainResourcePerNodeActivator" then
         local resource = options.resource; local nodeType = options.nodeType; local amountPerNode = options.amount or 1
        if owner and owner.network and owner.network.countNodesByType and activatingPlayer and activatingPlayer.addResource and nodeType then
            local count = owner.network:countNodesByType(nodeType); local totalAmount = count * amountPerNode
            if totalAmount > 0 then activatingPlayer:addResource(resource, totalAmount) end
        else print("Warning: Could not execute gainResourcePerNodeActivator.") end
    -- === Refactored Chain Steal Effects ===
    elseif effectType == "activatorStealResourceFromChainOwners" then
        _executeChainSteal(activatingPlayer, options.resource, options.amount, gameService)
    elseif effectType == "ownerStealResourceFromChainOwners" then
        _executeChainSteal(owner, options.resource, options.amount, gameService)
    -- === TOKEN EFFECTS ===
    elseif effectType == "addToken" then
        local nodeCard = sourceNode and sourceNode.card
        if nodeCard then
            nodeCard.tokens = (nodeCard.tokens or 0) + 1
            print(string.format("Added token to node, now has %d tokens", nodeCard.tokens))
        else
            print("Warning: Could not add token, sourceNode or card missing")
        end
    elseif effectType == "removeTokens" then
        local nodeCard = sourceNode and sourceNode.card
        if nodeCard then
            nodeCard.tokens = 0
            print("Removed all tokens from node")
        else
            print("Warning: Could not remove tokens, sourceNode or card missing")
        end
    -- ================================
    else
        print(string.format("Warning: Unknown effect type '%s' encountered during direct execution.", effectType))
    end
end

-- === PUBLIC FUNCTIONS ===

-- Public function to generate a combined description for an effect block (list of actions)
-- Groups actions by condition, joins with ";", adds period at the end of each group.
function CardEffects.generateEffectDescription(config, effectType)
    -- Only setup context when effectType is explicitly provided
    local context = nil
    if effectType then
        context = { effectType = effectType }
    end

    -- Flatten actions list to support 'effects' grouping
    local originalActions = config.actions or {}
    local actions = {}
    for _, act in ipairs(originalActions) do
        if act.effects then
            for _, eff in ipairs(act.effects) do
                table.insert(actions, {
                    orig = act,
                    condition = act.condition,
                    effect = eff.effect,
                    options = eff.options
                })
            end
        else
            table.insert(actions, {
                orig = act,
                condition = act.condition,
                effect = act.effect,
                options = act.options
            })
        end
    end
    if #actions == 0 then return "" end

    local finalDescriptions = {}
    local i = 1
    
    while i <= #actions do
        local currentAction = actions[i]
        local currentCondition = currentAction.condition
        
        local blockActionDescriptions = {}
        local conditionText = ""
        local isConditionalBlock = (currentCondition ~= nil)
        local blockHasMultipleActions = false

        if isConditionalBlock then
            conditionText = generateConditionDescription(currentCondition, context)
            -- Process the first action in the conditional block
            table.insert(blockActionDescriptions, generateActionDescription(currentAction, context))
            
            -- Look ahead for consecutive actions with the same condition
            local j = i + 1
            while j <= #actions do
                local nextAction = actions[j]
                local nextCondition = nextAction.condition
                -- Check if conditions are the same (both non-nil and same description text)
                local sameCondition = (nextCondition ~= nil and conditionText == generateConditionDescription(nextCondition, context))
                -- Only group multiple paymentOffer actions if they originate from the same original action
                local isPaymentOffer = currentCondition and currentCondition.type == "paymentOffer"
                local sameOrig = nextAction.orig == currentAction.orig
                local groupAllowed = sameCondition and (not isPaymentOffer or sameOrig)
                if groupAllowed then
                    table.insert(blockActionDescriptions, generateActionDescription(nextAction, context))
                    j = j + 1 -- Continue matching
                    blockHasMultipleActions = true
                else
                    break -- Condition changed, grouping not allowed, or became nil, stop lookahead
                end
            end
            i = j -- Move main index past the processed conditional block
        else
            -- Action has no condition, it forms its own block of one
            table.insert(blockActionDescriptions, generateActionDescription(currentAction, context))
            i = i + 1 -- Move to the next action
        end
        
        -- Join action descriptions for this block
        local joiner = (isConditionalBlock and blockHasMultipleActions) and "; " or "" -- Only use semicolon for multi-action conditional blocks
        local joinedActionText = table.concat(blockActionDescriptions, joiner)
        
        -- Construct the full description for this block (condition + actions + period)
        local blockDescription = conditionText .. joinedActionText .. "."
        table.insert(finalDescriptions, blockDescription)
    end
    
    -- Join all block descriptions with a space
    return table.concat(finalDescriptions, " ") 
end


-- Creates an activation effect object with description and activate function
-- config = { actions = { {condition={...}, effect="...", options={...}}, ... } }
-- Returns: The status of the activation (e.g., "waiting" or nil)
function CardEffects.createActivationEffect(config)
    -- Flatten actions to support per-condition multiple effects
    local originalActions = config.actions or {}
    local actions = {}
    for _, act in ipairs(originalActions) do
        if act.effects then
            -- Group multiple effects under one condition
            table.insert(actions, { condition = act.condition, effects = act.effects })
        else
            -- Single effect action
            table.insert(actions, { condition = act.condition, effects = { { effect = act.effect, options = act.options } } })
        end
    end

    local activateFunction = function(gameService, activatingPlayer, sourceNetwork, sourceNode, targetNode)
        if not gameService then print("ERROR: Card effect executed without gameService!"); return nil end
        if not sourceNetwork or not sourceNode then print("ERROR: Card effect executed without sourceNetwork or sourceNode!"); return nil end

        local overallStatus = nil 
        local owner = sourceNetwork.owner -- Defined once

        -- Process each action group (condition + one or more effects)
        for i, actionGroup in ipairs(actions) do
            local conditionConfig = actionGroup.condition
            local effList = actionGroup.effects

            -- Step 1: Evaluate the condition (if any)
            if evaluateCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode) then
                local actionStatus = nil

                -- Step 2: Check if the condition was a payment offer that just passed
                if conditionConfig and conditionConfig.type == "paymentOffer" then
                    -- Payment offer: request payment then execute all effects in group
                    print("Condition 'paymentOffer' passed for payment group. Requesting payment...")
                    local payerType = conditionConfig.payer
                    local playerToAsk = (payerType == "Owner") and owner or activatingPlayer
                    actionStatus = _requestPaymentAndExecute(
                        playerToAsk,
                        conditionConfig.resource,
                        conditionConfig.amount or 1,
                        actionGroup,
                        i,
                        actions,
                        gameService, activatingPlayer, sourceNetwork, sourceNode
                    )
                else
                    -- Unconditional or non-payment: execute each effect in group immediately
                    print("Condition passed (or no condition). Executing effects...")
                    for _, effDef in ipairs(effList) do
                        CardEffects._executeSingleAction(effDef.effect, effDef.options or {}, gameService, activatingPlayer, sourceNetwork, sourceNode)
                    end
                    actionStatus = nil
                end

                -- If this action caused a wait (only payment requests do), update overall status and stop processing further actions
                if actionStatus == "waiting" then
                    overallStatus = "waiting"
                    print("Activation yielded due to pending payment request.")
                    break -- Stop processing further actions for this node activation
                end
            else
                print("Condition failed. Skipping effects for this group.")
            end
        end

        return overallStatus 
    end
    
    local fullDescription = CardEffects.generateEffectDescription(config, "activation") -- Specify activation context

    return {
        description = fullDescription,
        activate = activateFunction,
        config = config 
    }
end

-- Create a convergence effect with the right description context
function CardEffects.createConvergenceEffect(config)
    local effect = CardEffects.createActivationEffect(config)
    -- Override the description with the convergence context
    effect.description = CardEffects.generateEffectDescription(config, "convergence")
    return effect
end

return CardEffects 
