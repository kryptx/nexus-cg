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
local function generateResourceDescription(actionEffect, resource, amount)
    local resourceName = resource:sub(1, 1):upper() .. resource:sub(2) -- Capitalize first letter
    
    if actionEffect == "addResourceToOwner" then
        return string.format("Owner gains %d %s", amount, resourceName)
    elseif actionEffect == "addResourceToActivator" then
        return string.format("Activator gains %d %s", amount, resourceName)
    elseif actionEffect == "addResourceToBoth" then
        return string.format("Owner and activator gain %d %s", amount, resourceName)
    elseif actionEffect == "addResourceToAllPlayers" then
        return string.format("All players gain %d %s", amount, resourceName)
    elseif actionEffect == "gainResourcePerNodeOwner" then
         local nodeType = "Any" -- Placeholder, actual type depends on options
         return string.format("Owner gains %d %s per %s node...", amount, resourceName, nodeType)
    elseif actionEffect == "gainResourcePerNodeActivator" then
         local nodeType = "Any" -- Placeholder
         return string.format("Activator gains %d %s per %s node...", amount, resourceName, nodeType)
    elseif actionEffect == "stealResource" then
         return string.format("Activator steals %d %s from the owner.", amount, resourceName)
    end
    
    -- Return a generic description if no match, let generateOtherDescription handle specifics
    return "Resource effect" 
end

-- Generates descriptions for non-resource effects (or resource effects not covered above) (NO TRAILING PERIODS)
local function generateOtherDescription(actionEffect, options)
    if actionEffect == "drawCardsForActivator" then
        return string.format("Activator draws %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "drawCardsForOwner" then
        return string.format("Owner draws %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "drawCardsForAllPlayers" then
        return string.format("All players draw %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "gainVPForActivator" then
        return string.format("Activator gains %d VP", options.amount or 1)
    elseif actionEffect == "gainVPForOwner" then
        return string.format("Owner gains %d VP", options.amount or 1)
    elseif actionEffect == "gainVPForBoth" then
        return string.format("Owner and Activator gain %d VP", options.amount or 1)
    elseif actionEffect == "forceDiscardCardsOwner" then
        return string.format("Owner discards %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "forceDiscardCardsActivator" then
        return string.format("Activator discards %d card%s", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "destroyRandomLinkOnNode" then
        return "Destroy a random convergence link on this node"
    -- === Refined Resource Descriptions handled here now ===
    elseif actionEffect == "stealResource" then
        local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
        return string.format("Activator steals %d %s from the owner", options.amount or 1, resourceName)
    elseif actionEffect == "gainResourcePerNodeOwner" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any" 
         return string.format("Owner gains %d %s per %s node in their network", options.amount or 1, resourceName, nodeType)
    elseif actionEffect == "gainResourcePerNodeActivator" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any"
         return string.format("Activator gains %d %s per %s node in the owner's network", options.amount or 1, resourceName, nodeType)
    -- === NEW EFFECT DESCRIPTIONS ===
    elseif actionEffect == "activatorStealResourceFromChainOwners" then
         local resourceName = options.resource and (options.resource:sub(1, 1):upper() .. options.resource:sub(2)) or "Resource"
         local amount = options.amount or 1
         return string.format("Activator steals %d %s from each owner of nodes activated this chain", amount, resourceName)
    elseif actionEffect == "ownerStealResourceFromChainOwners" then
         local resourceName = options.resource and (options.resource:sub(1, 1):upper() .. options.resource:sub(2)) or "Resource"
         local amount = options.amount or 1
         return string.format("Owner steals %d %s from each owner of nodes activated this chain", amount, resourceName)
    -- =====================================================
    end
    return "Unknown other effect" -- Note: No trailing period here either
end

-- === CONDITION EVALUATION HELPERS ===

-- Checks adjacency condition
local function evaluateAdjacencyCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not sourceNetwork or not sourceNode or not sourceNode.position then return false end
    -- Use the newly added Network:getNeighbors relative to the node executing the effect
    local neighbors = sourceNetwork:getNeighbors(sourceNode.position) 
    local count = 0
    local requiredType = conditionConfig.nodeType
    local requiredCount = conditionConfig.count or 1
    for _, neighborNode in ipairs(neighbors) do
        if neighborNode and neighborNode.card and neighborNode.card.type == requiredType then
            count = count + 1
        end
    end
    print(string.format("Evaluated adjacency condition: %d/%d %s nodes found adjacent to %s", count, requiredCount, requiredType, sourceNode.position))
    return count >= requiredCount
end

-- Checks convergence link condition
local function evaluateConvergenceLinkCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    if not sourceNode then return false end
    local currentLinks = sourceNode:getConvergenceLinkCount() 
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

    local neighbors = sourceNetwork:getAdjacentCoords(sourceNode.position)
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
    elseif conditionType == "adjacentEmptyCells" then -- Add new condition type check
        return evaluateAdjacentEmptyCellsCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    elseif conditionType == "paymentOffer" then -- Add new condition type check
        return evaluatePaymentOfferCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode)
    else
        print(string.format("Warning: Unknown condition type '%s' to evaluate.", conditionType))
        return false -- Fail safely for unknown condition types
    end
end

-- === CONDITION DESCRIPTION HELPER (Updated for port terminology) ===

local function generateConditionDescription(conditionConfig)
    if not conditionConfig then return "" end
    local type = conditionConfig.type
    local count = conditionConfig.count or 1
    if type == "adjacency" then
        local nodeType = conditionConfig.nodeType or "Any"
        return string.format("If adjacent to %d+ %s nodes: ", count, nodeType)
    elseif type == "convergenceLinks" then
        return string.format("If %d+ links attached: ", count)
    elseif type == "satisfiedInputs" then
        return string.format("If %d+ inputs connected: ", count)
    elseif type == "activationChainLength" then
        return string.format("If %d+ nodes activated this chain: ", count)
    elseif type == "activatedCardType" then
        local cardType = conditionConfig.cardType or "Unknown"
        return string.format("If %d+ %s nodes activated this chain: ", count, cardType)
    elseif type == "adjacentEmptyCells" then -- Add description for new condition
        return string.format("If adjacent to %d+ empty cell(s): ", count)
    elseif type == "paymentOffer" then -- Add description for payment offer
        local payer = conditionConfig.payer or "Player" -- Default if missing
        local resource = conditionConfig.resource or "Resource"
        local amount = conditionConfig.amount or 1
        local resourceName = resource:sub(1, 1):upper() .. resource:sub(2)
        return string.format("If %s pays %d %s: ", payer, amount, resourceName)
    else
        print(string.format("Warning: Unknown condition type '%s' for description.", type))
        return "If condition met: "
    end
end

-- Helper to get the raw action description without period
local function generateActionDescription(action)
    local effectType = action.effect
    local options = action.options or {}
    local actionText = ""
    
    -- Determine which description generator to use
    if effectType == "addResourceToOwner" or effectType == "addResourceToActivator" or effectType == "addResourceToBoth" or effectType == "addResourceToAllPlayers" then
         actionText = generateResourceDescription(effectType, options.resource, options.amount or 1)
    else
        actionText = generateOtherDescription(effectType, options)
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
local function _requestPaymentAndExecute(playerToAsk, costResource, costAmount, actionToExecute, gameService, activatingPlayer, sourceNetwork, sourceNode)
    -- NOTE: We already know the player *can* pay because evaluatePaymentOfferCondition passed.
    
    local questionString = string.format("Pay %d %s?", costAmount, costResource:sub(1, 1):upper() .. costResource:sub(2))

    -- Create the callback function containing the logic to run *after* player chooses
    local afterChoiceCallback = function(wantsToPay)
        if wantsToPay then
            -- Use the existing spendResource which includes the check and deduction
            local spentSuccessfully = playerToAsk:spendResource(costResource, costAmount)
            if spentSuccessfully then
                -- Execute the *original* action's effect
                print(string.format("[Callback] Player %d paid %d %s. Executing original action '%s'...", playerToAsk.id, costAmount, costResource, actionToExecute.effect))
                
                -- TEMPORARY: Create a mini-activation effect just for this one action
                -- This reuses the existing effect execution logic without needing a massive switch statement here.
                -- We pass the original context.
                -- This avoids duplicating the entire effect execution logic inside this callback.
                -- local tempEffectConfig = { actions = { actionToExecute } } -- Wrap the single action
                -- local tempEffect = CardEffects.createActivationEffect(tempEffectConfig) 
                
                -- IMPORTANT: Activate the temporary effect. It should NOT have the paymentOffer condition anymore,
                -- so it won't recurse infinitely. We pass nil for condition evaluation context if needed, 
                -- but createActivationEffect handles the logic.
                -- Need to ensure the temporary activation doesn't re-evaluate the payment condition.
                -- Modify createActivationEffect to handle this possibility, or make a simpler direct execution helper.

                -- Let's try a direct execution helper approach for simplicity first.
                -- We need a function to map effect type/options directly to game actions.
                CardEffects._executeSingleAction(actionToExecute.effect, actionToExecute.options, gameService, activatingPlayer, sourceNetwork, sourceNode)

            else
                print(string.format("Warning: Failed to spend resource in _requestPaymentAndExecute callback for player %d even after initial check.", playerToAsk.id))
            end
        else
            print(string.format("[Callback] Player %d chose not to pay %d %s.", playerToAsk.id, costAmount, costResource))
            -- If player declined, do nothing further.
        end
    end

    -- Request the input from the player via GameService
    gameService:requestPlayerYesNo(playerToAsk, questionString, afterChoiceCallback)
    print(string.format("[Effect] Requesting payment (%d %s) from player %d for action '%s'. Waiting for response...", costAmount, costResource, playerToAsk.id, actionToExecute.effect))
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
    elseif effectType == "drawCardsForOwner" then
        local amount = options.amount or 1
        if owner and gameService.playerDrawCards then gameService:playerDrawCards(owner, amount) else print("Warning: gameService:playerDrawCards not found or owner missing!") end
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
    elseif effectType == "forceDiscardCardsOwner" then
        local amount = options.amount or 1
        if owner and gameService.forcePlayerDiscard then gameService:forcePlayerDiscard(owner, amount) else print("Warning: gameService:forcePlayerDiscard not found or owner missing!") end
    elseif effectType == "forceDiscardCardsActivator" then
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
    -- ================================
    else
        print(string.format("Warning: Unknown effect type '%s' encountered during direct execution.", effectType))
    end
end

-- === PUBLIC FUNCTIONS ===

-- Public function to generate a combined description for an effect block (list of actions)
-- Groups actions by condition, joins with ";", adds period at the end of each group.
function CardEffects.generateEffectDescription(config)
    local actions = config.actions or {}
    if not actions or #actions == 0 then return "" end -- Handle empty actions

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
            conditionText = generateConditionDescription(currentCondition)
            -- Process the first action in the conditional block
            table.insert(blockActionDescriptions, generateActionDescription(currentAction))
            
            -- Look ahead for consecutive actions with the same condition
            local j = i + 1
            while j <= #actions do
                local nextAction = actions[j]
                local nextCondition = nextAction.condition
                
                -- Check if conditions are the same (both non-nil and same description text)
                local sameCondition = (nextCondition ~= nil and conditionText == generateConditionDescription(nextCondition))
                                     
                if sameCondition then
                    table.insert(blockActionDescriptions, generateActionDescription(nextAction))
                    j = j + 1 -- Continue matching
                    blockHasMultipleActions = true
                else
                    break -- Condition changed or became nil, stop lookahead
                end
            end
            i = j -- Move main index past the processed conditional block
        else
            -- Action has no condition, it forms its own block of one
            table.insert(blockActionDescriptions, generateActionDescription(currentAction))
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
    local actions = config.actions or {}

    local activateFunction = function(gameService, activatingPlayer, sourceNetwork, sourceNode, targetNode)
        if not gameService then print("ERROR: Card effect executed without gameService!"); return nil end
        if not sourceNetwork or not sourceNode then print("ERROR: Card effect executed without sourceNetwork or sourceNode!"); return nil end

        local overallStatus = nil 
        local owner = sourceNetwork.owner -- Defined once

        for i, action in ipairs(actions) do
            local conditionConfig = action.condition
            local effectType = action.effect
            local options = action.options or {}

            -- Step 1: Evaluate the condition (if any)
            if evaluateCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode) then
                local actionStatus = nil 

                -- Step 2: Check if the condition was a payment offer that just passed
                if conditionConfig and conditionConfig.type == "paymentOffer" then
                    -- Condition passed affordability check. Now, request payment and queue the action.
                    print(string.format("Condition 'paymentOffer' passed for action '%s'. Requesting payment...", effectType))
                    local payerType = conditionConfig.payer
                    local playerToAsk = (payerType == "Owner") and owner or activatingPlayer
                    actionStatus = _requestPaymentAndExecute(
                        playerToAsk, 
                        conditionConfig.resource, 
                        conditionConfig.amount or 1,
                        action, -- Pass the whole action table {condition=..., effect=..., options=...}
                        gameService, activatingPlayer, sourceNetwork, sourceNode
                    )
                else
                    -- Condition passed (or no condition), and it wasn't a payment offer. Execute directly.
                    print(string.format("Condition passed (or no condition) for action '%s'. Executing directly...", effectType))
                    CardEffects._executeSingleAction(effectType, options, gameService, activatingPlayer, sourceNetwork, sourceNode)
                    -- Note: Direct execution currently doesn't return a status. Assume nil for now.
                    actionStatus = nil 
                end


                -- If this action caused a wait (only payment requests do), update overall status and stop processing further actions
                if actionStatus == "waiting" then
                    overallStatus = "waiting"
                    print("Activation yielded due to pending payment request.")
                    break -- Stop processing further actions for this node activation
                end
            else
                 print(string.format("Condition failed for action '%s'. Skipping.", effectType))
            end
        end

        return overallStatus 
    end
    
    local fullDescription = CardEffects.generateEffectDescription(config) -- Description logic unchanged

    return {
        description = fullDescription,
        activate = activateFunction,
        config = config 
    }
end

-- Alias for convergence effects (same structure and creation logic)
CardEffects.createConvergenceEffect = CardEffects.createActivationEffect

return CardEffects 
