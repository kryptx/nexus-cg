-- src/game/card.lua
-- Defines the structure and basic data for game cards.

local Card = {}
Card.__index = Card

-- Card Types (Constants)
Card.Type = {
    TECHNOLOGY = "Technology",
    CULTURE = "Culture",
    RESOURCE = "Resource",
    KNOWLEDGE = "Knowledge",
    REACTOR = "Reactor", -- Special type
}

-- Connection Slot Indices (Constants, based on GDD 4.3)
-- Top: 1 (Cult Out), 2 (Tech In)
-- Bot: 3 (Cult In),  4 (Tech Out)
-- Lft: 5 (Know Out), 6 (Res In)
-- Rgt: 7 (Res Out),  8 (Know In)
Card.Slots = {
    TOP_LEFT    = 1, TOP_RIGHT   = 2,
    BOTTOM_LEFT = 3, BOTTOM_RIGHT= 4,
    LEFT_TOP    = 5, LEFT_BOTTOM = 6,
    RIGHT_TOP   = 7, RIGHT_BOTTOM= 8,
}

-- Static helper function to get slot properties based on index
-- Returns { type = Card.Type.*, is_output = boolean } or nil
local slotPropertiesCache = {}
do -- Precompute slot properties
    local function computeSlotProperties(slotIndex)
        if slotIndex == Card.Slots.TOP_LEFT     then return { type = Card.Type.CULTURE,   is_output = true } end
        if slotIndex == Card.Slots.TOP_RIGHT    then return { type = Card.Type.TECHNOLOGY, is_output = false } end
        if slotIndex == Card.Slots.BOTTOM_LEFT  then return { type = Card.Type.CULTURE,   is_output = false } end
        if slotIndex == Card.Slots.BOTTOM_RIGHT then return { type = Card.Type.TECHNOLOGY, is_output = true } end
        if slotIndex == Card.Slots.LEFT_TOP     then return { type = Card.Type.KNOWLEDGE, is_output = true } end
        if slotIndex == Card.Slots.LEFT_BOTTOM  then return { type = Card.Type.RESOURCE,  is_output = false } end
        if slotIndex == Card.Slots.RIGHT_TOP    then return { type = Card.Type.KNOWLEDGE, is_output = false } end
        if slotIndex == Card.Slots.RIGHT_BOTTOM then return { type = Card.Type.RESOURCE,  is_output = true } end
        return nil
    end
    for i=1, 8 do slotPropertiesCache[i] = computeSlotProperties(i) end
end

function Card:getSlotProperties(slotIndex)
    return slotPropertiesCache[slotIndex]
end

-- Constructor for a new Card instance
-- data: A table containing card definition details
function Card:new(data)
    local instance = setmetatable({}, Card)

    -- Core Properties
    instance.id = data.id or error("Card must have a unique id")
    instance.title = data.title or "Untitled Card"
    instance.type = data.type or error("Card must have a type (Card.Type)")

    -- Gameplay Properties
    -- Ensure buildCost has both material and data, defaulting to 0
    local cost = data.buildCost or {}
    instance.buildCost = {
        material = cost.material or 0,
        data = cost.data or 0
    }
    
    -- Handle the two formats for effects:
    -- 1. Legacy format: function(player, network)
    -- 2. New format: { description = string, activate = function(player, network) }
    if type(data.activationEffect) == "function" then
        instance.activationEffect = {
            description = "[Legacy Effect]",
            activate = data.activationEffect
        }
    elseif type(data.activationEffect) == "table" and data.activationEffect.activate then
        instance.activationEffect = data.activationEffect
    else
        -- Default effect
        instance.activationEffect = {
            description = "No effect.",
            activate = function(player, network) print(instance.title .. " Activation Effect triggered.") end
        }
    end
    
    if type(data.convergenceEffect) == "function" then
        instance.convergenceEffect = {
            description = "[Legacy Effect]",
            activate = data.convergenceEffect
        }
    elseif type(data.convergenceEffect) == "table" and data.convergenceEffect.activate then
        instance.convergenceEffect = data.convergenceEffect
    else
        -- Default effect
        instance.convergenceEffect = {
            description = "No effect.",
            activate = function(player, network) print(instance.title .. " Convergence Effect triggered.") end
        }
    end
    
    instance.vpValue = data.vpValue or 0 -- End-game VP value

    -- Connection Slots (which of the 8 are open)
    -- Represented as a table mapping slot index (Card.Slots) to true if open
    -- Example: { [Card.Slots.TOP_LEFT] = true, [Card.Slots.RIGHT_BOTTOM] = true }
    instance.openSlots = data.openSlots or {}

    -- Visual/Flavor
    instance.imagePath = data.imagePath or "assets/images/placeholder.png"
    instance.flavorText = data.flavorText or ""

    -- Runtime State (will be added when card is in play/hand)
    instance.owner = nil -- Player object
    instance.position = nil -- {x, y} grid position in network
    instance.network = nil -- Reference to the network it belongs to

    -- Connection Management (moved from Reactor)
    instance.connections = {}

    return instance
end

-- Helper function to get the activation effect description
function Card:getActivationDescription()
    if self.activationEffect and self.activationEffect.description then
        return self.activationEffect.description
    end
    return "[No Description]"
end

-- Helper function to get the convergence effect description
function Card:getConvergenceDescription()
    if self.convergenceEffect and self.convergenceEffect.description then
        return self.convergenceEffect.description
    end
    return "[No Description]"
end

-- Execute the activation effect
function Card:activateEffect(player, network)
    if self.activationEffect and self.activationEffect.activate then
        return self.activationEffect.activate(player, network)
    end
end

-- Execute the convergence effect
function Card:activateConvergence(player, network)
    if self.convergenceEffect and self.convergenceEffect.activate then
        return self.convergenceEffect.activate(player, network)
    end
end

-- Helper function to check if a specific slot is open
function Card:isSlotOpen(slotIndex)
    return self.openSlots[slotIndex] == true
end

-- === Connection Management Methods (Moved from Reactor) ===

-- Register a connection to another card
-- targetCard: The Card instance to connect to
-- selfSlotIndex: The slot index on this card used for the connection
-- targetSlotIndex: The slot index on the target card used for the connection
function Card:addConnection(targetCard, selfSlotIndex, targetSlotIndex)
    -- Ensure connections table exists (should be initialized in new, but belt-and-suspenders)
    self.connections = self.connections or {}
    table.insert(self.connections, {
        target = targetCard,
        selfSlot = selfSlotIndex,
        targetSlot = targetSlotIndex
    })
    -- Optional: Add print for debugging if needed
    -- print(string.format("Card %s: Added connection to %s (Slots: %d -> %d)", self.id or '?', targetCard.id or '?', selfSlotIndex, targetSlotIndex))
end

-- Remove a connection to another card
-- targetCard: The Card instance to disconnect from
function Card:removeConnection(targetCard)
    if not self.connections then return false end
    
    for i = #self.connections, 1, -1 do -- Iterate backwards for safe removal
        if self.connections[i].target == targetCard then
            -- Optional: Add print for debugging if needed
            -- print(string.format("Card %s: Removed connection to %s", self.id or '?', targetCard.id or '?'))
            table.remove(self.connections, i)
            -- Note: This only removes the connection from this card's perspective.
            -- The Network or GameService might need to call removeConnection on the other card too.
            return true 
        end
    end
    return false
end

-- Get all cards directly connected to this card
function Card:getConnectedCards()
    local cards = {}
    if not self.connections then return cards end
    
    for _, conn in ipairs(self.connections) do
        table.insert(cards, conn.target)
    end
    return cards
end

-- Get connection details (target card, self slot, target slot) for a specific connected card
function Card:getConnectionDetails(targetCard)
    if not self.connections then return nil end
    for _, conn in ipairs(self.connections) do
        if conn.target == targetCard then
            return conn.target, conn.selfSlot, conn.targetSlot
        end
    end
    return nil
end

-- Check if this card can connect to a target card in a specific direction
-- target: The Card instance to check connection against
-- direction: The relative direction from self to target ("up", "down", "left", "right")
function Card:canConnectTo(target, direction)
    if not target or not target.isSlotOpen or not target.getSlotProperties then
        -- print("Warning: Invalid target provided to canConnectTo")
        return false, "Invalid target card"
    end

    -- Determine facing slots based on direction (from self's perspective)
    local selfSlots, targetSlots
    if direction == "down" then -- self is ABOVE target
        selfSlots = {Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT}
        targetSlots = {Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT}
    elseif direction == "up" then -- self is BELOW target
        selfSlots = {Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT}
        targetSlots = {Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT}
    elseif direction == "right" then -- self is LEFT of target
        selfSlots = {Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM}
        targetSlots = {Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM}
    elseif direction == "left" then -- self is RIGHT of target
        selfSlots = {Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM}
        targetSlots = {Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM}
    else
        -- print("Warning: Invalid direction provided to canConnectTo:", direction)
        return false, "Invalid direction"
    end

    -- Check all pairs of facing slots for a valid connection
    for _, selfSlotIndex in ipairs(selfSlots) do
        if self:isSlotOpen(selfSlotIndex) then
            local selfProps = self:getSlotProperties(selfSlotIndex)
            if selfProps then
                for _, targetSlotIndex in ipairs(targetSlots) do
                    if target:isSlotOpen(targetSlotIndex) then
                        local targetProps = target:getSlotProperties(targetSlotIndex)
                        if targetProps then
                            -- Check GDD Rules: Matching Type AND Input/Output Mismatch
                            if selfProps.type == targetProps.type and selfProps.is_output ~= targetProps.is_output then
                                return true, string.format("Valid connection: Slot %d (%s %s) -> Slot %d (%s %s)",
                                    selfSlotIndex, selfProps.type, selfProps.is_output and "Out" or "In",
                                    targetSlotIndex, targetProps.type, targetProps.is_output and "Out" or "In")
                            end
                        end
                    end
                end
            end
        end
    end

    -- No valid connection found among facing slots
    return false, "No matching open slots (Type & In/Out)"
end

-- TODO: Add functions related to activation, linking, etc.

return Card
