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
-- Returns: boolean, path (list of card IDs, target first), reason (if failed)
function Rules:isActivationPathValid(network, reactorId, targetNodeId)
    -- Get card objects
    local targetCard = network:getCardById(targetNodeId)
    local reactorCard = network:getCardById(reactorId)

    if not targetCard then
        return false, nil, "Target node not found in network"
    end
    if not reactorCard then
        -- This shouldn't happen if GameService found it, but check anyway
        return false, nil, "Reactor node not found in network"
    end
    if reactorCard.type ~= Card.Type.REACTOR then
        return false, nil, "Start node must be a Reactor"
    end
    if targetCard.type == Card.Type.REACTOR then
        return false, nil, "Cannot activate the Reactor itself"
    end

    -- Use the network's pathfinding logic
    local path_instances = network:findPathToReactor(targetCard)

    if not path_instances then
        return false, nil, "No valid activation path exists"
    end

    -- Convert path of card instances to path of card IDs
    -- The path returned by findPathToReactor is [target, intermediate1, ... intermediateN]
    -- This is exactly what GameService needs (it activates target separately, then loops 2 to #path)
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
