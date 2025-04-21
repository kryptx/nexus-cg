-- src/game/card_effects.lua
-- Provides helper functions for creating card activation and convergence effects.

local CardEffects = {}

-- Define resource types as constants
CardEffects.ResourceType = {
    ENERGY = "energy",
    DATA = "data",
    MATERIAL = "material",
}

-- Helper function to generate descriptions for resource effects
local function generateResourceDescription(action, resource, amount, target)
    local resourceName = resource:sub(1, 1):upper() .. resource:sub(2) -- Capitalize first letter
    
    if action == "addResourceToOwner" then
        return string.format("Grants %d %s to the owner.", amount, resourceName)
    elseif action == "addResourceToActivator" then
        return string.format("Grants %d %s to the activator.", amount, resourceName)
    elseif action == "addResourceToBoth" then
        return string.format("Grants %d %s to both the owner and activator.", amount, resourceName)
    elseif action == "addResourceToAllPlayers" then
        -- TODO: This needs access to gameService to actually work correctly
        return string.format("Grants %d %s to all players.", amount, resourceName)
    end
    
    return "Unknown resource effect."
end

-- Generates descriptions for non-resource effects
local function generateOtherDescription(action, options)
    if action == "drawCardsForActivator" then
        return string.format("Activator draws %d card(s).", options.amount or 1)
    elseif action == "drawCardsForOwner" then
        return string.format("Owner draws %d card(s).", options.amount or 1)
    elseif action == "gainVPForActivator" then
        return string.format("Activator gains %d VP.", options.amount or 1)
    elseif action == "gainVPForOwner" then
        return string.format("Owner gains %d VP.", options.amount or 1)
    elseif action == "forceDiscardCardsOwner" then
        return string.format("Owner discards %d card(s).", options.amount or 1)
    elseif action == "forceDiscardCardsActivator" then
        return string.format("Activator discards %d card(s).", options.amount or 1)
    elseif action == "destroyRandomLinkOnNode" then
        return "Destroy a random convergence link on this node."
    elseif action == "stealResource" then
        local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
        return string.format("Activator steals %d %s from the owner.", options.amount or 1, resourceName)
    elseif action == "gainResourcePerNodeOwner" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any" -- Assuming nodeType is provided in options
         return string.format("Owner gains %d %s per %s node in their network.", options.amount or 1, resourceName, nodeType)
    elseif action == "gainResourcePerNodeActivator" then
         local resourceName = options.resource:sub(1, 1):upper() .. options.resource:sub(2)
         local nodeType = options.nodeType or "Any"
         return string.format("Activator gains %d %s per %s node in the owner's network.", options.amount or 1, resourceName, nodeType)
    end
    return "Unknown other effect."
end

-- Creates an activation effect object with description and activate function
-- IMPORTANT: The generated activate function now expects `gameService` as the first argument.
function CardEffects.createActivationEffect(config)
    local actions = config.actions or {}
    local descriptions = {}
    
    -- Generate the activate function based on actions
    -- Signature changed: now receives gameService, activatingPlayer, targetNetwork, targetNode
    local activateFunction = function(gameService, activatingPlayer, targetNetwork, targetNode) -- Added targetNode
        if not gameService then
            print("ERROR: Card effect executed without gameService!")
            return
        end

        -- === ADD DEBUG PRINTS ===
        print(string.format("  [EFFECT LOOP DEBUG] Processing %d action(s) for this effect.", #actions))
        for i, action in ipairs(actions) do -- Add index 'i' for clarity
            print(string.format("  [EFFECT LOOP DEBUG]   Action %d: effect=%s", i, action.effect))
            local effectType = action.effect
            local options = action.options or {}
            local owner = targetNetwork and targetNetwork.owner -- Use targetNetwork's owner
            
            -- Resource Effects (mostly target player directly)
            if effectType == "addResourceToOwner" then
                local resource = options.resource
                local amount = options.amount or 1
                
                -- === ADD DEBUG PRINTS ===
                print(string.format("  [EFFECT DEBUG] Executing addResourceToOwner for resource %s", resource))
                print(string.format("  [EFFECT DEBUG]   activatingPlayer ID: %s, Name: %s", activatingPlayer and activatingPlayer.id or "NIL", activatingPlayer and activatingPlayer.name or "NIL"))
                print(string.format("  [EFFECT DEBUG]   targetNetwork type: %s", type(targetNetwork)))
                if targetNetwork then
                    print(string.format("  [EFFECT DEBUG]   targetNetwork.owner type: %s", type(targetNetwork.owner)))
                    if targetNetwork.owner then
                         print(string.format("  [EFFECT DEBUG]   targetNetwork.owner ID: %s, Name: %s", targetNetwork.owner.id or "NIL", targetNetwork.owner.name or "NIL"))
                    end
                else
                     print("  [EFFECT DEBUG]   targetNetwork is NIL!")
                end
                -- ========================
                
                if owner and owner.addResource then
                    owner:addResource(resource, amount)
                else
                    print("Warning: Could not find owner to add resource for effect 'addResourceToOwner'")
                end
            elseif effectType == "addResourceToActivator" then
                local resource = options.resource
                local amount = options.amount or 1
                if activatingPlayer and activatingPlayer.addResource then
                    activatingPlayer:addResource(resource, amount)
                end
            elseif effectType == "addResourceToBoth" then
                local resource = options.resource
                local amount = options.amount or 1
                if owner and owner.addResource then
                    owner:addResource(resource, amount)
                end
                if activatingPlayer and activatingPlayer.addResource and activatingPlayer ~= owner then
                    activatingPlayer:addResource(resource, amount)
                end
            elseif effectType == "addResourceToAllPlayers" then
                local resource = options.resource
                local amount = options.amount or 1
                -- Delegate to GameService to handle iterating all players
                if gameService.addResourceToAllPlayers then
                    gameService:addResourceToAllPlayers(resource, amount)
                else
                    print("Warning: gameService:addResourceToAllPlayers not found!")
                end
            
            -- Other Effects (delegate to gameService or network/player)
            elseif effectType == "drawCardsForActivator" then
                local amount = options.amount or 1
                if gameService.playerDrawCards then
                    gameService:playerDrawCards(activatingPlayer, amount)
                else
                    print("Warning: gameService:playerDrawCards not found!")
                end
            elseif effectType == "drawCardsForOwner" then
                local amount = options.amount or 1
                if owner and gameService.playerDrawCards then
                    gameService:playerDrawCards(owner, amount)
                else
                    print("Warning: gameService:playerDrawCards not found or owner missing for drawCardsForOwner!")
                end
            elseif effectType == "gainVPForActivator" then
                local amount = options.amount or 1
                if gameService.awardVP then
                    gameService:awardVP(activatingPlayer, amount)
                else
                     print("Warning: gameService:awardVP not found!")
                end
            elseif effectType == "gainVPForOwner" then
                local amount = options.amount or 1
                if owner and gameService.awardVP then
                    gameService:awardVP(owner, amount)
                else
                    print("Warning: gameService:awardVP not found or owner missing for gainVPForOwner!")
                end
            -- === NEW EFFECTS START ===
            elseif effectType == "forceDiscardCardsOwner" then
                local amount = options.amount or 1
                if owner and gameService.forcePlayerDiscard then
                    gameService:forcePlayerDiscard(owner, amount)
                else
                    print("Warning: gameService:forcePlayerDiscard not found or owner missing for forceDiscardCardsOwner!")
                end
            elseif effectType == "forceDiscardCardsActivator" then
                 local amount = options.amount or 1
                if activatingPlayer and gameService.forcePlayerDiscard then
                    gameService:forcePlayerDiscard(activatingPlayer, amount)
                else
                    print("Warning: gameService:forcePlayerDiscard not found or activatingPlayer missing for forceDiscardCardsActivator!")
                end
             elseif effectType == "destroyRandomLinkOnNode" then
                if targetNode and gameService.destroyRandomLinkOnNode then
                     gameService:destroyRandomLinkOnNode(targetNode)
                 else
                     print("Warning: gameService:destroyRandomLinkOnNode not found or targetNode missing!")
                 end
             elseif effectType == "stealResource" then
                local resource = options.resource
                local amount = options.amount or 1
                if owner and activatingPlayer and owner ~= activatingPlayer and gameService.transferResource then
                    gameService:transferResource(owner, activatingPlayer, resource, amount)
                else
                    print("Warning: Could not execute stealResource. Check players and gameService:transferResource.")
                end
            elseif effectType == "gainResourcePerNodeOwner" then
                local resource = options.resource
                local nodeType = options.nodeType -- e.g., CardTypes.TECHNOLOGY
                local amountPerNode = options.amount or 1
                if owner and owner.network and owner.network.countNodesByType and owner.addResource and nodeType then
                     local count = owner.network:countNodesByType(nodeType)
                     local totalAmount = count * amountPerNode
                     if totalAmount > 0 then
                         owner:addResource(resource, totalAmount)
                     end
                 else
                     print("Warning: Could not execute gainResourcePerNodeOwner. Check owner, network, countNodesByType, addResource, or nodeType.")
                 end
             elseif effectType == "gainResourcePerNodeActivator" then
                 local resource = options.resource
                 local nodeType = options.nodeType
                 local amountPerNode = options.amount or 1
                 if owner and owner.network and owner.network.countNodesByType and activatingPlayer and activatingPlayer.addResource and nodeType then
                     local count = owner.network:countNodesByType(nodeType)
                     local totalAmount = count * amountPerNode
                     if totalAmount > 0 then
                         activatingPlayer:addResource(resource, totalAmount)
                     end
                 else
                     print("Warning: Could not execute gainResourcePerNodeActivator. Check owner, network, countNodesByType, activatingPlayer, addResource, or nodeType.")
                 end
            -- === NEW EFFECTS END ===
            else
                print(string.format("Warning: Unknown effect type '%s' encountered.", effectType))
            end
        end
    end
    
    -- Generate descriptions for each action
    for _, action in ipairs(actions) do
        local effectType = action.effect
        local options = action.options or {}
        
        local desc = ""
        -- Split resource addition/gain from other effects for description generation logic
        if effectType == "addResourceToOwner" or effectType == "addResourceToActivator" or effectType == "addResourceToBoth" or effectType == "addResourceToAllPlayers" then
             desc = generateResourceDescription(
                effectType,
                options.resource,
                options.amount or 1
            )
        else -- Handle other effect types including new ones and resource gains based on conditions
            desc = generateOtherDescription(effectType, options)
        end
        
        if desc:find("Unknown") then
            print(string.format("Warning: Could not generate description for effect type '%s'", effectType))
        end
        table.insert(descriptions, desc)
    end
    
    -- Join all descriptions
    local fullDescription = table.concat(descriptions, " ")
    
    return {
        description = fullDescription,
        activate = activateFunction
    }
end

-- Alias for convergence effects (same implementation, just an alias for clarity)
CardEffects.createConvergenceEffect = CardEffects.createActivationEffect

return CardEffects 
