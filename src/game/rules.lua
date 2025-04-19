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
        return true
    end
    
    -- Check if there's at least one adjacent card
    local hasAdjacentCard = false
    local adjacentPositions = {
        {x=x, y=y-1}, -- Above
        {x=x, y=y+1}, -- Below
        {x=x-1, y=y}, -- Left
        {x=x+1, y=y}  -- Right
    }
    
    for _, pos in ipairs(adjacentPositions) do
        local adjCard = network:getCardAt(pos.x, pos.y)
        if adjCard then
            hasAdjacentCard = true
            
            -- Check if there's a valid connection between the cards
            if self:hasValidConnection(card, adjCard, pos.x - x, pos.y - y) then
                return true
            end
        end
    end
    
    if not hasAdjacentCard then
        return false, "Must be adjacent to at least one card"
    end
    
    return false, "No valid connection found with adjacent cards"
end

-- Checks if two adjacent cards have a valid connection (Output -> Input match)
-- Returns: boolean
function Rules:hasValidConnection(newCard, existingCard, dx, dy)
    -- Determine which edges are facing each other based on relative positions
    -- dx, dy indicate the direction from newCard to existingCard
    
    -- Edge slots on the newCard that face the existingCard
    local newCardFacingSlots = self:getFacingSlots(dx, dy, true)
    
    -- Edge slots on the existingCard that face the newCard
    local existingCardFacingSlots = self:getFacingSlots(-dx, -dy, true)
    
    -- Check for at least one valid Output -> Input connection
    for _, newSlotIndex in ipairs(newCardFacingSlots) do
        if newCard:isSlotOpen(newSlotIndex) then
            local newSlotProps = Card:getSlotProperties(newSlotIndex)
            
            -- For each potential slot on the existing card that faces the new card
            for _, existingSlotIndex in ipairs(existingCardFacingSlots) do
                if existingCard:isSlotOpen(existingSlotIndex) then
                    local existingSlotProps = Card:getSlotProperties(existingSlotIndex)
                    
                    -- Check if we have an Output -> Input connection with matching type
                    -- The new card's slot should be an Input and the existing card's slot should be an Output
                    if not newSlotProps.is_output and existingSlotProps.is_output and 
                       newSlotProps.type == existingSlotProps.type then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- Helper function to get slot indices that face a particular direction
function Rules:getFacingSlots(dx, dy, includeAllSlots)
    local slots = {}
    
    if dy < 0 then -- Card is above (top edge is facing)
        table.insert(slots, Card.Slots.TOP_LEFT)
        table.insert(slots, Card.Slots.TOP_RIGHT)
    elseif dy > 0 then -- Card is below (bottom edge is facing)
        table.insert(slots, Card.Slots.BOTTOM_LEFT)
        table.insert(slots, Card.Slots.BOTTOM_RIGHT)
    end
    
    if dx < 0 then -- Card is to the left (left edge is facing)
        table.insert(slots, Card.Slots.LEFT_TOP)
        table.insert(slots, Card.Slots.LEFT_BOTTOM)
    elseif dx > 0 then -- Card is to the right (right edge is facing)
        table.insert(slots, Card.Slots.RIGHT_TOP)
        table.insert(slots, Card.Slots.RIGHT_BOTTOM)
    end
    
    return slots
end

-- ===================
-- ACTIVATION VALIDATION
-- ===================

-- Validates if an activation path is legal
-- Returns: boolean, path (if successful), reason (if failed)
function Rules:isActivationPathValid(network, startNodeId, targetNodeId)
    -- If either node doesn't exist, the path is invalid
    if not network:hasCardWithId(startNodeId) or not network:hasCardWithId(targetNodeId) then
        return false, nil, "Start or target node doesn't exist"
    end
    
    -- The start node must be a Reactor
    local startNode = network:getCardById(startNodeId)
    if startNode.type ~= Card.Type.REACTOR then
        return false, nil, "Start node must be a Reactor"
    end
    
    -- Find a valid path from target back to start using Output -> Input connections
    local path, success = self:findActivationPath(network, targetNodeId, startNodeId)
    if not success then
        return false, nil, "No valid activation path exists"
    end
    
    return true, path, nil
end

-- Finds a valid activation path from target node back to source node
-- Returns: path (list of node IDs in order), success (boolean)
function Rules:findActivationPath(network, targetNodeId, sourceNodeId)
    -- This would be implemented using a graph search algorithm
    -- For simplicity, this is a placeholder
    -- In a real implementation, you'd need to trace Output -> Input connections
    
    -- TODO: Implement proper path finding between nodes
    -- For now, just return a mock success if the nodes exist
    if network:hasCardWithId(targetNodeId) and network:hasCardWithId(sourceNodeId) then
        return {targetNodeId, sourceNodeId}, true
    end
    
    return nil, false
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
    
    -- Check if the deck is depleted AND a player needs to draw
    if gameService:isDeckEmpty() then
        -- Only end if any player has less than minimum hand size
        for _, player in ipairs(gameService:getPlayers()) do
            if player:getHandSize() < Rules.MIN_HAND_SIZE then
                return true
            end
        end
    end
    
    return false
end

-- Calculate final scores for all players
function Rules:calculateFinalScores(gameService)
    local scores = {}
    
    for _, player in ipairs(gameService:getPlayers()) do
        local score = player:getVictoryPoints()
        
        -- Add 1 VP for each card in network (excluding Reactor)
        local networkSize = player:getNetwork():getSize() - 1 -- -1 for Reactor
        score = score + networkSize
        
        -- TODO: Add paradigm-specific scoring
        -- if self.currentParadigm and self.currentParadigm.endGameScoring then
        --     score = score + self.currentParadigm.endGameScoring(player)
        -- end
        
        scores[player.id] = score
    end
    
    return scores
end

return Rules
