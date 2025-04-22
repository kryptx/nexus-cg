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
        return string.format("Grants %d %s to the owner.", amount, resourceName)
    elseif actionEffect == "addResourceToActivator" then
        return string.format("Grants %d %s to the activator.", amount, resourceName)
    elseif actionEffect == "addResourceToBoth" then
        return string.format("Grants %d %s to both the owner and activator.", amount, resourceName)
    elseif actionEffect == "addResourceToAllPlayers" then
        return string.format("Grants %d %s to all players.", amount, resourceName)
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
        return string.format("Activator draws %d card(s).", options.amount or 1)
    elseif actionEffect == "drawCardsForOwner" then
        return string.format("Owner draws %d card(s).", options.amount or 1)
    elseif actionEffect == "gainVPForActivator" then
        return string.format("Activator gains %d VP.", options.amount or 1)
    elseif actionEffect == "gainVPForOwner" then
        return string.format("Owner gains %d VP.", options.amount or 1)
    elseif actionEffect == "forceDiscardCardsOwner" then
        return string.format("Owner discards %d card(s).", options.amount or 1)
    elseif actionEffect == "forceDiscardCardsActivator" then
        return string.format("Activator discards %d card(s).", options.amount or 1)
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
    elseif actionEffect == "offerPayment" then
        local costStr = string.format("%d %s", options.amount or 1, options.resource:sub(1, 1):upper() .. options.resource:sub(2))
        -- Recursively generate description for consequence actions
        local consequenceDesc = CardEffects.generateEffectDescription({ actions = options.consequence or {} }) 
        return string.format("May pay %s to: %s", costStr, consequenceDesc)
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
        local neighborPos = sourceNetwork:getAdjacentCoordForPort(sourceNode.position, inputPortInfo.index) 
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
function CardEffects.createActivationEffect(config)
    local actions = config.actions or {}

    -- 1. Generate the activate function
    -- Evaluates conditions per action inside the loop
    local activateFunction = function(gameService, activatingPlayer, sourceNetwork, sourceNode, targetNode) 
        if not gameService then
            print("ERROR: Card effect executed without gameService!")
            return
        end
        if not sourceNetwork or not sourceNode then
             print("ERROR: Card effect executed without sourceNetwork or sourceNode!")
             return
        end

        for i, action in ipairs(actions) do 
            local conditionConfig = action.condition
            local effectType = action.effect
            local options = action.options or {}
            -- Owner is determined by the network of the node whose effect is executing
            local owner = sourceNetwork.owner 

            -- Check condition for this specific action, passing sourceNetwork/sourceNode
            if evaluateCondition(conditionConfig, gameService, activatingPlayer, sourceNetwork, sourceNode) then
                -- Condition passed (or no condition), execute the action
                
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
                elseif effectType == "offerPayment" then
                    local costResource = options.resource
                    local costAmount = options.amount or 1
                    local consequenceActions = options.consequence or {}

                    if activatingPlayer and activatingPlayer.hasResource and activatingPlayer:hasResource(costResource, costAmount) then
                        local wantsToPay = gameService:askPlayerYesNo(activatingPlayer, string.format("Pay %d %s?", costAmount, costResource))
                        if wantsToPay then
                            if activatingPlayer.removeResource then 
                                activatingPlayer:removeResource(costResource, costAmount)
                                -- Execute consequence actions - RECURSIVE CALL to a temporary activate function
                                -- This recursively handles conditions on consequence actions correctly.
                                -- Pass the *current* sourceNetwork/sourceNode for context.
                                local tempEffect = CardEffects.createActivationEffect({ actions = consequenceActions })
                                tempEffect.activate(gameService, activatingPlayer, sourceNetwork, sourceNode) -- Pass current sourceNode
                            else print("Warning: Player missing removeResource method for offerPayment.") end
                        end
                    end
                else
                    print(string.format("Warning: Unknown effect type '%s' encountered.", effectType))
                end
            else
                 -- Condition failed for this action, skip it. Optionally print a message.
                 -- print(string.format("Condition failed for action %d (effect: %s)", i, effectType))
            end -- End condition check
        end -- End loop actions
    end -- End activateFunction
    
    -- 2. Generate the full description using the public helper
    local fullDescription = CardEffects.generateEffectDescription(config)
    
    -- 3. Return the effect object (no condition at this level anymore)
    return {
        description = fullDescription,
        activate = activateFunction
    }
end

-- Alias for convergence effects (same structure and creation logic)
CardEffects.createConvergenceEffect = CardEffects.createActivationEffect

return CardEffects 
