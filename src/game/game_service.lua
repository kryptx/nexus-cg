-- src/game/game_service.lua
-- Provides an interface for executing core game actions and logic.

local Card = require('src.game.card') -- Needed for checking card type

local GameService = {}
GameService.__index = GameService

function GameService:new()
    local instance = setmetatable({}, GameService)
    print("Game Service Initialized.")
    return instance
end

-- Attempt Placement
function GameService:attemptPlacement(state, cardIndex, gridX, gridY)
    local currentPlayer = state.players[state.currentPlayerIndex]
    local selectedCard = currentPlayer.hand[cardIndex]

    if not selectedCard then
        return false, "Invalid card selection index."
    end

    print(string.format("[Service] Attempting placement of '%s' at (%d,%d)", selectedCard.title, gridX, gridY))

    local isValid, reason = currentPlayer.network:isValidPlacement(selectedCard, gridX, gridY)

    if isValid then
        local costM = selectedCard.buildCost.material
        local costD = selectedCard.buildCost.data
        local canAffordM = currentPlayer.resources.material >= costM
        local canAffordD = currentPlayer.resources.data >= costD

        if canAffordM and canAffordD then
            print("  Placement valid and affordable.")
            currentPlayer:spendResource('material', costM)
            currentPlayer:spendResource('data', costD)
            currentPlayer.network:placeCard(selectedCard, gridX, gridY)
            table.remove(currentPlayer.hand, cardIndex)
            -- Success! PlayState will handle resetting selection.
            return true, string.format("Placed '%s' at (%d,%d).", selectedCard.title, gridX, gridY)
        else
            print("  Placement valid but cannot afford.")
            local reasonAfford = "Cannot afford card. Cost: "
            if costM > 0 then reasonAfford = reasonAfford .. costM .. "M " end
            if costD > 0 then reasonAfford = reasonAfford .. costD .. "D " end
            reasonAfford = reasonAfford .. string.format("(Have: %dM %dD)", currentPlayer.resources.material, currentPlayer.resources.data)
            return false, reasonAfford
        end
    else
        print("  Invalid placement: " .. reason)
        return false, "Invalid placement: " .. reason
    end
end

-- Attempt Activation
function GameService:attemptActivation(state, targetGridX, targetGridY)
    local currentPlayer = state.players[state.currentPlayerIndex]
    local targetCard = currentPlayer.network:getCardAt(targetGridX, targetGridY)

    if not targetCard then
        return false, "No card at activation target."
    end

    if targetCard.type == Card.Type.REACTOR then
        return false, "Cannot activate the Reactor directly."
    end

    print(string.format("[Service] Attempting activation targeting %s (%s) at (%d,%d)", targetCard.title, targetCard.id, targetGridX, targetGridY))

    local path = currentPlayer.network:findPathToReactor(targetCard)

    if path then
        local pathLength = #path
        local energyCost = pathLength
        print(string.format("  Path found! Length: %d, Cost: %d Energy.", pathLength, energyCost))

        if currentPlayer.resources.energy >= energyCost then
             print("  Activation affordable.")
             currentPlayer:spendResource('energy', energyCost)

             -- Execute effects BACKWARDS along path (GDD 4.5)
             local activationMessages = {}
             table.insert(activationMessages, string.format("Activated path (Cost %d E):", energyCost))
             for i = 1, pathLength do -- Iterate from target (index 1) back towards reactor
                local cardToActivate = path[i]
                if cardToActivate.actionEffect then
                    -- NOTE: actionEffect might return a status string in the future
                    cardToActivate:actionEffect(currentPlayer, currentPlayer.network)
                    table.insert(activationMessages, string.format("  - %s activated!", cardToActivate.title))
                    print(string.format("    Effect for %s executed.", cardToActivate.title))
                end
             end
             return true, table.concat(activationMessages, "\n") -- Multi-line status
        else
            print("  Activation failed: Cannot afford energy cost.")
            return false, string.format("Not enough energy for activation. Cost: %d E (Have: %d E)", energyCost, currentPlayer.resources.energy)
        end
    else
        print("  Activation failed: No path found.")
        return false, string.format("No valid activation path found to %s (%d,%d).", targetCard.title, targetGridX, targetGridY)
    end
end

-- Discard Card
function GameService:discardCard(state, cardIndex)
    local currentPlayer = state.players[state.currentPlayerIndex]
    local cardToRemove = currentPlayer.hand[cardIndex]

    if cardToRemove then
        print(string.format("[Service] Discarding '%s' for 1 Material.", cardToRemove.title))
        currentPlayer:addResource('material', 1)
        table.remove(currentPlayer.hand, cardIndex)
        -- Success! PlayState handles resetting selection.
        return true, string.format("Discarded '%s' for 1 Material.", cardToRemove.title)
    else
        return false, "Cannot discard: Invalid card index."
    end
end

-- End Turn
function GameService:endTurn(state)
    local oldPlayerIndex = state.currentPlayerIndex
    state.currentPlayerIndex = (state.currentPlayerIndex % #state.players) + 1
    -- Note: PlayState will handle resetting selection via helper function
    local nextPlayer = state.players[state.currentPlayerIndex]
    print(string.format("[Service] Turn ended for Player %d. Starting turn for Player %d (%s).", oldPlayerIndex, state.currentPlayerIndex, nextPlayer.name))
    -- TODO: Cleanup Phase logic (draw cards) would go here
    return true, string.format("Player %d's turn.", state.currentPlayerIndex)
end

return GameService 
