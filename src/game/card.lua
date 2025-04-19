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
        if slotIndex == Card.Slots.TOP_LEFT    then return { type = Card.Type.CULTURE,   is_output = true } end
        if slotIndex == Card.Slots.TOP_RIGHT   then return { type = Card.Type.TECHNOLOGY, is_output = false } end
        if slotIndex == Card.Slots.BOTTOM_LEFT then return { type = Card.Type.CULTURE,   is_output = false } end
        if slotIndex == Card.Slots.BOTTOM_RIGHT then return { type = Card.Type.TECHNOLOGY, is_output = true } end
        if slotIndex == Card.Slots.LEFT_TOP    then return { type = Card.Type.KNOWLEDGE, is_output = true } end
        if slotIndex == Card.Slots.LEFT_BOTTOM then return { type = Card.Type.RESOURCE,  is_output = false } end
        if slotIndex == Card.Slots.RIGHT_TOP   then return { type = Card.Type.KNOWLEDGE, is_output = false } end -- Corrected
        if slotIndex == Card.Slots.RIGHT_BOTTOM then return { type = Card.Type.RESOURCE,  is_output = true } end -- Corrected
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
    instance.actionEffect = data.actionEffect or function(player, network) print(instance.title .. " Action Effect triggered.") end
    instance.convergenceEffect = data.convergenceEffect or function(player, network) print(instance.title .. " Convergence Effect triggered.") end
    instance.vpValue = data.vpValue or 0 -- End-game VP value

    -- Connection Slots (which of the 8 are open)
    -- Represented as a table mapping slot index (Card.Slots) to true if open
    -- Example: { [Card.Slots.TOP_LEFT] = true, [Card.Slots.RIGHT_BOTTOM] = true }
    instance.openSlots = data.openSlots or {}

    -- Visual/Flavor
    instance.imagePath = data.imagePath -- Use the correct key from definitions
    instance.flavorText = data.flavorText or ""

    -- Runtime State (will be added when card is in play/hand)
    instance.owner = nil -- Player object
    instance.position = nil -- {x, y} grid position in network
    instance.network = nil -- Reference to the network it belongs to

    return instance
end

-- Helper function to check if a specific slot is open
function Card:isSlotOpen(slotIndex)
    return self.openSlots[slotIndex] == true
end

-- TODO: Add functions related to activation, linking, etc.

return Card
