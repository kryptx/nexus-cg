-- src/game/reactor.lua
-- Implements the Reactor card, which serves as the base for each player's network

local Card = require('src.game.card')

local Reactor = {}
Reactor.__index = Reactor

-- Constructor for a new Reactor
-- ownerId: ID of the player who owns this reactor
function Reactor:new(ownerId)
    -- First create a base card using the Card class
    local cardData = {
        id = "REACTOR_" .. ownerId,
        title = "Reactor Core",
        type = Card.Type.REACTOR,
        buildCost = { material = 0, data = 0 }, -- No build cost
        -- The reactor doesn't have effects, but we define empty functions
        actionEffect = function() end,
        convergenceEffect = function() end,
        vpValue = 0,
        -- All 8 slots are open as per GDD 4.1
        openSlots = {
            [Card.Slots.TOP_LEFT] = true, [Card.Slots.TOP_RIGHT] = true,
            [Card.Slots.BOTTOM_LEFT] = true, [Card.Slots.BOTTOM_RIGHT] = true,
            [Card.Slots.LEFT_TOP] = true, [Card.Slots.LEFT_BOTTOM] = true,
            [Card.Slots.RIGHT_TOP] = true, [Card.Slots.RIGHT_BOTTOM] = true,
        },
        flavorText = "The heart of your network."
    }
    
    local baseCard = Card:new(cardData)
    
    -- Create the Reactor instance as an extension of the Card
    local instance = setmetatable({}, Reactor)
    
    -- Copy all properties from the base card
    for k, v in pairs(baseCard) do
        instance[k] = v
    end
    
    -- Add Reactor-specific properties
    instance.baseIncomeEnergy = 1 -- Optional: Reactor might provide a small base income
    instance.baseResourceProduction = false -- Whether this Reactor has automatic resource generation
    
    -- Maintain a list of all connections to other cards
    instance.connections = {}
    
    return instance
end

-- Override any Card methods that need special behavior for Reactors

-- Helper function to check if a specific slot is open
-- Override Card's isSlotOpen method to ensure it's available in Reactor
function Reactor:isSlotOpen(slotIndex)
    return self.openSlots[slotIndex] == true
end

-- Reactor-specific method to provide base income (if enabled)
function Reactor:generateBaseIncome()
    local income = {
        energy = self.baseIncomeEnergy,
        data = 0,
        material = 0
    }
    
    return income
end

-- Check if this Reactor has a valid connection point to the given card
-- target: The card to check connection with
-- direction: The relative direction ("up", "down", "left", "right")
function Reactor:canConnectTo(target, direction)
    -- Reactor is special in that it allows connections without requiring
    -- matching input/output types - it only checks if the slots are open
    
    -- Map direction to the appropriate reactor edge
    local reactorSlots
    if direction == "up" then
        reactorSlots = {Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT}
    elseif direction == "down" then
        reactorSlots = {Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT}
    elseif direction == "left" then
        reactorSlots = {Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM}
    elseif direction == "right" then
        reactorSlots = {Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM}
    else
        return false
    end
    
    -- Map direction to the appropriate target card edge (opposite of reactor edge)
    local targetSlots
    if direction == "up" then
        -- Reactor is on top, so target's bottom edge faces the reactor
        targetSlots = {Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT}
    elseif direction == "down" then
        -- Reactor is below, so target's top edge faces the reactor
        targetSlots = {Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT}
    elseif direction == "left" then
        -- Reactor is to the left, so target's left edge faces the reactor
        targetSlots = {Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM}
    elseif direction == "right" then
        -- Reactor is to the right, so target's right edge faces the reactor
        targetSlots = {Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM}
    else
        return false
    end
    
    -- Check if any valid connections exist
    for _, reactorSlot in ipairs(reactorSlots) do
        if self:isSlotOpen(reactorSlot) then
            for _, targetSlot in ipairs(targetSlots) do
                if target:isSlotOpen(targetSlot) then
                    -- For Reactor, we don't need to check input/output matching
                    -- Just the fact that both slots are open is enough
                    return true
                end
            end
        end
    end
    
    return false
end

-- Register a connection to another card
function Reactor:addConnection(targetCard, reactorSlot, targetSlot)
    table.insert(self.connections, {
        target = targetCard,
        reactorSlot = reactorSlot,
        targetSlot = targetSlot
    })
end

-- Remove a connection to another card
function Reactor:removeConnection(targetCard)
    for i, conn in ipairs(self.connections) do
        if conn.target == targetCard then
            table.remove(self.connections, i)
            return true
        end
    end
    return false
end

-- Get all cards connected to this Reactor
function Reactor:getConnectedCards()
    local cards = {}
    for _, conn in ipairs(self.connections) do
        table.insert(cards, conn.target)
    end
    return cards
end

return Reactor
