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

-- Helper function to generate descriptions for resource effects
local function generateResourceDescription(actionEffect, resource, amount)
    local resourceName = resource:sub(1, 1):upper() .. resource:sub(2) -- Capitalize first letter
    
    if actionEffect == "addResourceToOwner" then
        return string.format("Owner gains %d %s.", amount, resourceName)
    elseif actionEffect == "addResourceToActivator" then
        return string.format("Activator gains %d %s.", amount, resourceName)
    elseif actionEffect == "addResourceToBoth" then
        return string.format("Owner and activator gain %d %s.", amount, resourceName)
    elseif actionEffect == "addResourceToAllPlayers" then
        return string.format("All players gain %d %s.", amount, resourceName)
    elseif actionEffect == "gainResourcePerNodeOwner" then
         local nodeType = "Any" -- Placeholder, actual type depends on options
         return string.format("Owner gains %d %s per %s node...", amount, resourceName, nodeType)
    elseif actionEffect == "gainResourcePerNodeActivator" then
         local nodeType = "Any" -- Placeholder
         return string.format("Activator gains %d %s per %s node...", amount, resourceName, nodeType)
    elseif actionEffect == "stealResource" then
         return string.format("Activator steals %d %s from the owner.", amount, resourceName)
    end
    
    return "Unknown resource effect."
end

-- Generates descriptions for non-resource effects (or resource effects not covered above)
local function generateOtherDescription(actionEffect, options)
    if actionEffect == "drawCardsForActivator" then
        return string.format("Activator draws %d card%s.", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "drawCardsForOwner" then
        return string.format("Owner draws %d card%s.", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "drawCardsForAllPlayers" then
        return string.format("All players draw %d card%s.", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "gainVPForActivator" then
        return string.format("Activator gains %d VP.", options.amount or 1)
    elseif actionEffect == "gainVPForOwner" then
        return string.format("Owner gains %d VP.", options.amount or 1)
    elseif actionEffect == "forceDiscardCardsOwner" then
        return string.format("Owner discards %d card%s.", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "forceDiscardCardsActivator" then
        return string.format("Activator discards %d card%s.", options.amount or 1, options.amount == 1 and "" or "s")
    elseif actionEffect == "destroyRandomLinkOnNode" then
        return "Destroy a random convergence link on this node."
    -- === Refined Resource Descriptions handled here now ===
    elseif actionEffect == "stealResource" then
        local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
        return string.format("Activator steals %d %s from the owner.", options.amount or 1, resourceName)
    elseif actionEffect == "gainResourcePerNodeOwner" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any" 
         return string.format("Owner gains %d %s per %s node in their network.", options.amount or 1, resourceName, nodeType)
    elseif actionEffect == "gainResourcePerNodeActivator" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any"
         return string.format("Activator gains %d %s per %s node in the owner's network.", options.amount or 1, resourceName, nodeType)
    -- =====================================================
    elseif actionEffect == "offerPaymentActivator" or actionEffect == "offerPaymentOwner" then -- Update description generation
        local payer = (actionEffect == "offerPaymentOwner") and "Owner" or "Activator"
        local costStr = string.format("%d %s", options.amount or 1, options.resource:sub(1, 1):upper() .. options.resource:sub(2))
        -- Recursively generate description for consequence actions
        local consequenceDesc = CardEffects.generateEffectDescription({ actions = options.consequence or {} }) 
        return string.format("If %s pays %s: %s", payer, costStr, consequenceDesc)
    end
    return "Unknown other effect."
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
        return string.format("If adjacent to %d+ %s node(s): ", count, nodeType)
    elseif type == "convergenceLinks" then
        return string.format("If %d+ convergence link(s) attached: ", count)
    elseif type == "satisfiedInputs" then
        return string.format("If %d+ input port(s) are connected: ", count)
    else
        print(string.format("Warning: Unknown condition type '%s' for description.", type))
        return "If condition met: "
    end
end

-- === NEW HELPER for Offer Payment Logic ===
-- playerToAsk: The player object who needs to make the choice (activatingPlayer or owner)
-- costResource, costAmount, consequenceActions: From the effect definition
-- gameService, activatingPlayer, sourceNetwork, sourceNode: Original execution context for callback
local function _handleOfferPayment(playerToAsk, costResource, costAmount, consequenceActions, gameService, activatingPlayer, sourceNetwork, sourceNode)
    -- Check if the player who needs to pay *can* pay first
    if playerToAsk and playerToAsk.resources[costResource] and playerToAsk.resources[costResource] >= costAmount then
        local questionString = string.format("Pay %d %s?", costAmount, costResource)

        -- Create the callback function containing the logic to run *after* player chooses
        local afterChoiceCallback = function(wantsToPay)
            if wantsToPay then
                -- Use the existing spendResource which includes the check and deduction
                -- Make sure to call it on the player who was asked (playerToAsk)
                local spentSuccessfully = playerToAsk:spendResource(costResource, costAmount)
                if spentSuccessfully then
                    -- Execute consequence actions - RECURSIVE CALL to a temporary activate function
                    -- Pass the *original* activatingPlayer and sourceNetwork/sourceNode context.
                    print(string.format("[Callback] Player %d paid %d %s. Executing consequences...", playerToAsk.id, costAmount, costResource))
                    local tempEffect = CardEffects.createActivationEffect({ actions = consequenceActions })
                    -- Pass the original context (gameService, activatingPlayer, sourceNetwork, sourceNode)
                    -- to the recursively activated effect.
                    tempEffect.activate(gameService, activatingPlayer, sourceNetwork, sourceNode)
                else
                    print(string.format("Warning: Failed to spend resource in _handleOfferPayment callback for player %d even after initial check.", playerToAsk.id))
                end
            else
                print(string.format("[Callback] Player %d chose not to pay %d %s.", playerToAsk.id, costAmount, costResource))
                -- If player declined, do nothing further for this consequence chain.
            end
        end

        -- Request the input from the player via GameService
        gameService:requestPlayerYesNo(playerToAsk, questionString, afterChoiceCallback)
        print(string.format("[Effect] Requested payment (%d %s) from player %d. Waiting for response...", costAmount, costResource, playerToAsk.id))
        -- Signal that we are now waiting for input
        return "waiting"

    else
        -- Player cannot afford the cost, skip the offer.
        print(string.format("[Effect] Skipping payment offer for player %d (cannot afford %d %s).", playerToAsk and playerToAsk.id or -1, costAmount, costResource))
        -- Return nil (or nothing) as we are not waiting
        return nil
    end
end

-- === PUBLIC FUNCTIONS ===

-- Public function to generate a combined description for an effect block (list of actions)
function CardEffects.generateEffectDescription(config)
    local actions = config.actions or {}
    local descriptions = {}
    
    for _, action in ipairs(actions) do
        local conditionConfig = action.condition -- Condition is now per-action
        local effectType = action.effect
        local options = action.options or {}
        
        local conditionText = generateConditionDescription(conditionConfig)
        local actionText = ""
        
        -- Determine which description generator to use
        -- Simplified: Using generateOtherDescription for most, refined later if needed
        if effectType == "addResourceToOwner" or effectType == "addResourceToActivator" or effectType == "addResourceToBoth" or effectType == "addResourceToAllPlayers" then
             actionText = generateResourceDescription(effectType, options.resource, options.amount or 1)
        else
            actionText = generateOtherDescription(effectType, options)
        end
        
        if actionText:find("Unknown") then
            print(string.format("Warning: Could not generate description for effect type '%s'", effectType))
        end

        -- Combine condition (if any) and action description
        table.insert(descriptions, conditionText .. actionText)
    end
    
    -- Join all action descriptions for the effect block
    return table.concat(descriptions, " ") 
end


-- Creates an activation effect object with description and activate function
-- config = { actions = { {condition={...}, effect="...", options={...}}, ... } }
-- Returns: The status of the activation (e.g., "waiting" or nil)
function CardEffects.createActivationEffect(config)
    local actions = config.actions or {}

    -- 1. Generate the activate function
    -- Evaluates conditions per action inside the loop
    -- Returns "waiting" if any action initiates a wait, otherwise nil
    local activateFunction = function(gameService, activatingPlayer, sourceNetwork, sourceNode, targetNode)
        if not gameService then
            print("ERROR: Card effect executed without gameService!")
            return nil
        end
        if not sourceNetwork or not sourceNode then
             print("ERROR: Card effect executed without sourceNetwork or sourceNode!")
             return nil
        end

        local overallStatus = nil -- Track if any action caused a wait

        for i, action in ipairs(actions) do
            local conditionConfig = action.condition
            local effectType = action.effect
            local options = action.options or {}
            local owner = sourceNetwork.owner

            if evaluateCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode) then
                local actionStatus = nil -- Status for this specific action
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
                elseif effectType == "forceDiscardCardsOwner" then
                    local amount = options.amount or 1
                    if owner and gameService.forcePlayerDiscard then gameService:forcePlayerDiscard(owner, amount) else print("Warning: gameService:forcePlayerDiscard not found or owner missing!") end
                elseif effectType == "forceDiscardCardsActivator" then
                    local amount = options.amount or 1
                    if activatingPlayer and gameService.forcePlayerDiscard then gameService:forcePlayerDiscard(activatingPlayer, amount) else print("Warning: gameService:forcePlayerDiscard not found or activatingPlayer missing!") end
                elseif effectType == "destroyRandomLinkOnNode" then
                    -- This effect specifically targets the NODE where the effect resides.
                    if sourceNode and gameService.destroyRandomLinkOnNode then gameService:destroyRandomLinkOnNode(sourceNode) else print("Warning: gameService:destroyRandomLinkOnNode not found or sourceNode missing!") end
                elseif effectType == "stealResource" then
                    local resource = options.resource; local amount = options.amount or 1
                    -- 'owner' here refers to the owner of the sourceNode (the node with this effect)
                    if owner and activatingPlayer and owner ~= activatingPlayer and gameService.transferResource then gameService:transferResource(owner, activatingPlayer, resource, amount) else print("Warning: Could not execute stealResource.") end
                elseif effectType == "gainResourcePerNodeOwner" then
                    local resource = options.resource; local nodeType = options.nodeType; local amountPerNode = options.amount or 1
                    -- 'owner' here is the owner of the sourceNode
                    if owner and owner.network and owner.network.countNodesByType and owner.addResource and nodeType then
                        local count = owner.network:countNodesByType(nodeType); local totalAmount = count * amountPerNode
                        if totalAmount > 0 then owner:addResource(resource, totalAmount) end
                    else print("Warning: Could not execute gainResourcePerNodeOwner.") end
                elseif effectType == "gainResourcePerNodeActivator" then
                     local resource = options.resource; local nodeType = options.nodeType; local amountPerNode = options.amount or 1
                    -- 'owner' here is the owner of the sourceNode, we count nodes in their network
                    if owner and owner.network and owner.network.countNodesByType and activatingPlayer and activatingPlayer.addResource and nodeType then
                        local count = owner.network:countNodesByType(nodeType); local totalAmount = count * amountPerNode
                        if totalAmount > 0 then activatingPlayer:addResource(resource, totalAmount) end
                    else print("Warning: Could not execute gainResourcePerNodeActivator.") end

                -- Offer Payment Handlers
                elseif effectType == "offerPaymentActivator" then
                    local costResource = options.resource
                    local costAmount = options.amount or 1
                    local consequenceActions = options.consequence or {}
                    actionStatus = _handleOfferPayment(activatingPlayer, costResource, costAmount, consequenceActions, gameService, activatingPlayer, sourceNetwork, sourceNode)
                elseif effectType == "offerPaymentOwner" then
                    local costResource = options.resource
                    local costAmount = options.amount or 1
                    local consequenceActions = options.consequence or {}
                    actionStatus = _handleOfferPayment(owner, costResource, costAmount, consequenceActions, gameService, activatingPlayer, sourceNetwork, sourceNode)
                else
                    print(string.format("Warning: Unknown effect type '%s' encountered.", effectType))
                end

                -- If this action caused a wait, update overall status and stop processing further actions in this effect block
                if actionStatus == "waiting" then
                    overallStatus = "waiting"
                    break -- Stop processing actions for this node
                end
            end
        end

        return overallStatus -- Return the overall status for this node activation
    end

    local fullDescription = CardEffects.generateEffectDescription(config)

    return {
        description = fullDescription,
        activate = activateFunction
    }
end

-- Alias for convergence effects (same structure and creation logic)
CardEffects.createConvergenceEffect = CardEffects.createActivationEffect

return CardEffects 
