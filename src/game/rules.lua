-- src/game/rules.lua
-- Implements core game rules validation and turn structure

local Rules = {}
Rules.__index = Rules

-- Required dependencies
local Card = require('src.game.card')

-- Constants - these could be adjusted for balance
Rules.DEFAULT_HAND_LIMIT = 20
Rules.MIN_HAND_SIZE = 10
Rules.VICTORY_POINT_TARGET = 25

-- Constructor
function Rules:new()
    local instance = setmetatable({}, Rules)
    -- Any state the rules system needs to track
    instance.currentParadigm = nil -- Active paradigm card
    return instance
end

-- ====================
-- PLACEMENT VALIDATION
-- ====================

-- Validates if a card can be placed at a given position in a network
-- Returns: boolean, reason (if false)
function Rules:isPlacementValid(card, network, x, y)
    -- Basic Checks
    if not card then return false, "Invalid card provided" end
    if not network then return false, "Invalid network provided" end
    if network:getCardAt(x, y) then
        return false, "Target location is already occupied"
    end
    
    -- Check Uniqueness Rule (GDD 4.3)
    if network.cards[card.id] then
        return false, "Uniqueness Rule: Card already exists in network"
    end
    
    -- Reactor is always valid at (0,0) during initialization only (handled elsewhere)
    -- For regular placement, cannot place Reactor
    if card.type == Card.Type.REACTOR then 
        return false, "Cannot place Reactor card manually"
    end

    -- Check Adjacency and Connections
    local adjacentFound = false
    local validConnectionToExistingCard = false
    local adjacentPositions = {
        {x=x, y=y-1, dirFromNew="up"},    -- Above
        {x=x, y=y+1, dirFromNew="down"},  -- Below
        {x=x-1, y=y, dirFromNew="left"},  -- Left
        {x=x+1, y=y, dirFromNew="right"}  -- Right
    }
    
    for _, posData in ipairs(adjacentPositions) do
        local adjCard = network:getCardAt(posData.x, posData.y)
        if adjCard then
            adjacentFound = true -- Found at least one adjacent card
            
            -- Determine facing ports
            local dx = posData.x - x
            local dy = posData.y - y
            local newCardFacingPorts = self:getFacingPorts(dx, dy)
            local existingCardFacingPorts = self:getFacingPorts(-dx, -dy)

            -- Check for GDD 4.3 Rule: 
            -- "At least one open INPUT port on the new card must align with 
            --  an open OUTPUT port of the same type on an existing adjacent card."
            local connectionPossible = false
            for _, newPortIndex in ipairs(newCardFacingPorts) do
                if card:isPortDefined(newPortIndex) then -- Check if the new card HAS this port
                    local newPortProps = card:getPortProperties(newPortIndex)
                    if newPortProps and not newPortProps.is_output then -- Is it an INPUT on the new card?
                        for _, existingPortIndex in ipairs(existingCardFacingPorts) do
                            -- CRUCIAL: Check if existing card's OUTPUT port is DEFINED and AVAILABLE (not occupied)
                            if adjCard:isPortDefined(existingPortIndex) and adjCard:isPortAvailable(existingPortIndex) then 
                                local existingPortProps = adjCard:getPortProperties(existingPortIndex)
                                -- Is it an OUTPUT on the existing card, types match, and ports align physically?
                                if existingPortProps and existingPortProps.is_output and 
                                   newPortProps.type == existingPortProps.type and
                                   Card:portsAlign(newPortIndex, existingPortIndex) then 
                                    connectionPossible = true
                                    break -- Found a valid connection path TO this specific adjacent card
                                end
                            end
                        end
                    end
                end
                if connectionPossible then break end -- No need to check other ports on the new card facing this neighbor
            end
            
            if connectionPossible then
                validConnectionToExistingCard = true -- Mark that we found at least one valid link to ANY neighbor
            end
        end
    end
    
    if not adjacentFound then
        return false, "Must be placed adjacent to an existing card"
    end
    
    if not validConnectionToExistingCard then
        return false, "No valid connection found (requires New:Input <- Existing:Output of same type)"
    end

    -- If adjacent found and at least one connection is valid
    return true
end

-- Helper function to get port indices that face a particular direction
-- dx, dy: direction FROM the card calling this TO the other card
function Rules:getFacingPorts(dx, dy)
    local ports = {}
    
    if dy < 0 then -- Other card is above (Top edge is facing)
        table.insert(ports, Card.Ports.TOP_LEFT)
        table.insert(ports, Card.Ports.TOP_RIGHT)
    elseif dy > 0 then -- Other card is below (Bottom edge is facing)
        table.insert(ports, Card.Ports.BOTTOM_LEFT)
        table.insert(ports, Card.Ports.BOTTOM_RIGHT)
    elseif dx < 0 then -- Other card is to the left (Left edge is facing)
        table.insert(ports, Card.Ports.LEFT_TOP)
        table.insert(ports, Card.Ports.LEFT_BOTTOM)
    elseif dx > 0 then -- Other card is to the right (Right edge is facing)
        table.insert(ports, Card.Ports.RIGHT_TOP)
        table.insert(ports, Card.Ports.RIGHT_BOTTOM)
    end
    
    return ports
end

-- ===================
-- ACTIVATION VALIDATION
-- ===================

-- Validates if an activation path is legal
-- Returns: boolean, path (list of card IDs, target first), reason (if failed)
function Rules:isActivationPathValid(network, reactorId, targetNodeId)
    -- Get card objects
    local targetCard = network:getCardById(targetNodeId)
    local reactorCard = network:getCardById(reactorId)

    if not targetCard then
        return false, nil, "Target node not found in network"
    end
    if not reactorCard then
        return false, nil, "Reactor node not found in network"
    end
    if reactorCard.type ~= Card.Type.REACTOR then
        return false, nil, "Start node must be a Reactor" -- Should be Destination Node, but path starts from target
    end
    if targetCard.type == Card.Type.REACTOR then
        return false, nil, "Cannot activate the Reactor itself"
    end

    -- Use the network's pathfinding logic (which finds path from target -> reactor)
    local path_instances = network:findPathToReactor(targetCard)

    if not path_instances then
        return false, nil, "No valid activation path exists"
    end

    -- Convert path of card instances to path of card IDs
    -- Path returned by findPathToReactor is [target, intermediate1, ..., intermediateN]
    -- This is the order needed for GameService activation sequence (GDD 4.5)
    local path_ids = {}
    for _, cardInstance in ipairs(path_instances) do
        table.insert(path_ids, cardInstance.id)
    end

    return true, path_ids, nil
end

-- ===================
-- TURN STRUCTURE
-- ===================

-- Check if a player is eligible to draw a card at end of turn
function Rules:shouldDrawCard(player)
    return player:getHandSize() < Rules.MIN_HAND_SIZE
end

-- Check if the game end has been triggered
function Rules:isGameEndTriggered(gameService)
    -- Check if any player has reached the victory point target
    for _, player in ipairs(gameService:getPlayers()) do
        if player:getVictoryPoints() >= Rules.VICTORY_POINT_TARGET then
            return true
        end
    end
    
    -- Check if the deck is depleted (GDD 4.8 Trigger)
    if gameService:isDeckEmpty() then
        return true 
    end
    
    return false
end

-- Calculate final scores for all players
function Rules:calculateFinalScores(gameService)
    local scores = {}
    
    for _, player in ipairs(gameService:getPlayers()) do
        local score = player:getVictoryPoints()
        
        -- Add 1 VP for each card in network (excluding Reactor) (GDD 4.8)
        local networkSize = player.network:getSize() - 1 -- -1 for Reactor
        score = score + math.max(0, networkSize) -- Ensure score doesn't go negative if network is somehow only reactor
        
        -- TODO: Add endgame objective scoring (GDD 4.8)
        -- score = score + calculateEndgameObjectives(player)
        
        -- TODO: Add paradigm-specific scoring (GDD 4.8)
        local currentParadigm = gameService:getCurrentParadigm()
        if currentParadigm and currentParadigm.endGameScoring then
            score = score + currentParadigm.endGameScoring(player, gameService) -- Pass gameService for context
        end
        
        -- TODO: Add optional resource conversion (GDD 4.8)
        -- score = score + calculateResourceConversion(player)
        
        scores[player.id] = score
    end
    
    return scores
end

return Rules
