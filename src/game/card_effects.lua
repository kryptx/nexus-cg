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
        return string.format("Grants %d %s to all players.", amount, resourceName)
    end
    
    return "Unknown effect."
end

-- Creates an activation effect object with description and activate function
function CardEffects.createActivationEffect(config)
    local actions = config.actions or {}
    local descriptions = {}
    
    -- Generate the activate function based on actions
    local activateFunction = function(player, network)
        for _, action in ipairs(actions) do
            local effectType = action.effect
            local options = action.options or {}
            
            if effectType == "addResourceToOwner" then
                local resource = options.resource
                local amount = options.amount or 1
                
                -- Find the owner (should be the card's owner)
                local owner = network and network.owner
                if owner and owner.addResource then
                    owner:addResource(resource, amount)
                end
            elseif effectType == "addResourceToActivator" then
                local resource = options.resource
                local amount = options.amount or 1
                
                -- The activator is passed directly as 'player'
                if player and player.addResource then
                    player:addResource(resource, amount)
                end
            elseif effectType == "addResourceToBoth" then
                local resource = options.resource
                local amount = options.amount or 1
                
                -- Add to both owner and activator
                local owner = network and network.owner
                if owner and owner.addResource then
                    owner:addResource(resource, amount)
                end
                
                if player and player.addResource and player ~= owner then
                    player:addResource(resource, amount)
                end
            elseif effectType == "addResourceToAllPlayers" then
                local resource = options.resource
                local amount = options.amount or 1
                
                -- In a real implementation, we'd need access to all players
                -- This is a placeholder that should be improved
                -- We'd need GameService to have a way to iterate all players
                if network and network.owner and network.owner.addResource then
                    network.owner:addResource(resource, amount)
                end
                
                -- For demonstration, let's add to the activating player too if different
                if player and player.addResource and player ~= network.owner then
                    player:addResource(resource, amount)
                end
                
                -- Ideally, we would iterate through all players in the game here
            end
        end
    end
    
    -- Generate descriptions for each action
    for _, action in ipairs(actions) do
        local effectType = action.effect
        local options = action.options or {}
        
        local desc = generateResourceDescription(
            effectType, 
            options.resource, 
            options.amount or 1
        )
        
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
