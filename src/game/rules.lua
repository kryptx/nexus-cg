-- src/game/rules.lua
-- Implements core game rules validation and turn structure

local Rules = {}
Rules.__index = Rules

-- Required dependencies
local Card = require('src.game.card')

-- Constants - these could be adjusted for balance
Rules.DEFAULT_HAND_LIMIT = 5
Rules.MIN_HAND_SIZE = 3
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
    -- Check if the position is already occupied
    if network:getCardAt(x, y) then
        return false, "Position already occupied"
    end
    
    -- Check uniqueness rule: Network cannot have duplicates of the same card
    if network:hasCardWithId(card.id) then
        return false, "Card already exists in network (Uniqueness Rule)"
    end
    
    -- If this is the first card (reactor) or network is empty, allow placement
    if network:isEmpty() then
        -- NOTE: This path is unlikely now that network initializes with reactor.
        --       Placement adjacent to reactor is handled by the general adjacency/connection check.
        return true
    end
    
    -- Check if there's at least one adjacent card
    local adjacentFound = false
    local validConnectionFound = false
    local adjacentPositions = {
        {x=x, y=y-1, dirFromNew="up"},    -- Above
        {x=x, y=y+1, dirFromNew="down"},  -- Below
        {x=x-1, y=y, dirFromNew="left"},  -- Left
        {x=x+1, y=y, dirFromNew="right"}  -- Right
    }
    
    for _, posData in ipairs(adjacentPositions) do
        local adjCard = network:getCardAt(posData.x, posData.y)
        if adjCard then
            adjacentFound = true
            
            -- Check if there's a valid connection (Input->Output as per GDD 4.3)
            -- Calculate dx, dy from the new card (x,y) to the adjacent card (posData.x, posData.y)
            local dx = posData.x - x
            local dy = posData.y - y
            if self:hasValidConnection(card, adjCard, dx, dy) then
                validConnectionFound = true
                break -- Found one valid connection, no need to check others
            end
        end
    end
    
    if not adjacentFound then
        return false, "Must be adjacent to at least one card"
    end
    
    if not validConnectionFound then -- Check if a valid connection was found after checking all adjacent cards
        return false, "No valid connection found with adjacent cards"
    end

    -- If adjacent found and at least one connection is valid
    return true
end

-- Checks if two adjacent cards have a valid connection (Output -> Input match)
-- Returns: boolean
function Rules:hasValidConnection(newCard, existingCard, dx, dy)
    -- Determine which edges are facing each other based on relative positions
    -- dx, dy indicate the direction from newCard to existingCard
    
    -- Edge ports on the newCard that face the existingCard
    local newCardFacingPorts = self:getFacingPorts(dx, dy) -- Removed includeAllPorts, not needed
    
    -- Edge ports on the existingCard that face the newCard
    local existingCardFacingPorts = self:getFacingPorts(-dx, -dy) -- Removed includeAllPorts, not needed
    
    -- Check for at least one valid Output -> Input connection
    -- GDD 4.3: At least one INPUT on newCard connects to OUTPUT on existingCard
    for _, newPortIndex in ipairs(newCardFacingPorts) do
        if newCard:isPortAvailable(newPortIndex) then 
            local newPortProps = newCard:getPortProperties(newPortIndex) -- Use instance method
            
            -- For each potential port on the existing card that faces the new card
            for _, existingPortIndex in ipairs(existingCardFacingPorts) do
                if existingCard:isPortAvailable(existingPortIndex) then 
                    local existingPortProps = existingCard:getPortProperties(existingPortIndex) -- Use instance method
                    
                    -- Check if we have an Input (new) -> Output (existing) connection with matching type
                    -- AND that the ports physically align (e.g., TopLeft connects to BottomLeft)
                    if not newPortProps.is_output and existingPortProps.is_output and 
                       newPortProps.type == existingPortProps.type and
                       Card:portsAlign(newPortIndex, existingPortIndex) then -- Assuming Card has a helper for this
                        return true
                    end
                end
            end
        end
    end
    
    return false
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
