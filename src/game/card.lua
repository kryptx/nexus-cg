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
-- Rgt: 7 (Know In),  8 (Res Out) -- CORRECTED: Swapped Res Out / Know In based on GDD 4.3
Card.Slots = {
    TOP_LEFT    = 1, TOP_RIGHT   = 2,
    BOTTOM_LEFT = 3, BOTTOM_RIGHT= 4,
    LEFT_TOP    = 5, LEFT_BOTTOM = 6,
    RIGHT_TOP   = 7, RIGHT_BOTTOM= 8, -- CORRECTED: Swapped indices 7 and 8 based on GDD 4.3
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
        if slotIndex == Card.Slots.RIGHT_TOP    then return { type = Card.Type.KNOWLEDGE, is_output = false } end -- CORRECTED based on GDD 4.3
        if slotIndex == Card.Slots.RIGHT_BOTTOM then return { type = Card.Type.RESOURCE,  is_output = true } end  -- CORRECTED based on GDD 4.3
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

    -- Connection Slots (which of the 8 are defined as potentially open by the card definition)
    instance.definedOpenSlots = data.openSlots or {}
    -- Runtime state tracking which slots are currently occupied by which link ID
    instance.occupiedSlots = {} -- Stores { [slotIndex] = linkId, ... }

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
function Card:activateEffect(gameService, activatingPlayer, targetNetworkOwnerOrNetwork)
    print(string.format("  [CARD DEBUG] >>> Entering Card:activateEffect for %s (ID: %s)", self.title, self.id))
    if self.activationEffect and self.activationEffect.activate then
        local result = self.activationEffect.activate(gameService, activatingPlayer, targetNetworkOwnerOrNetwork)
        print(string.format("  [CARD DEBUG] <<< Exiting Card:activateEffect for %s (ID: %s)", self.title, self.id))
        return result
    end
    print(string.format("  [CARD DEBUG] !!! Activation effect activate function not found for %s (ID: %s)", self.title, self.id))
end

-- Execute the convergence effect
function Card:activateConvergence(gameService, activatingPlayer, targetNetworkOwner)
    print(string.format("  [CARD DEBUG] >>> Entering Card:activateConvergence for %s (ID: %s)", self.title, self.id))
    if self.convergenceEffect and self.convergenceEffect.activate then
        -- Note: Convergence effects use the same activate function currently
        -- The distinction of who the owner/activator is happens inside the effect based on arguments
        local result = self.convergenceEffect.activate(gameService, activatingPlayer, targetNetworkOwner)
        print(string.format("  [CARD DEBUG] <<< Exiting Card:activateConvergence for %s (ID: %s)", self.title, self.id))
        return result
    end
    print(string.format("  [CARD DEBUG] !!! Convergence effect activate function not found for %s (ID: %s)", self.title, self.id))
end

-- Marks a specific slot as occupied (e.g., by a convergence link)
function Card:markSlotOccupied(slotIndex, linkId)
    if not linkId then
        print(string.format("Warning: Attempted to mark slot %s occupied without a linkId on card %s.", tostring(slotIndex), self.id or '?'))
        return
    end
    if slotIndex and slotIndex >= 1 and slotIndex <= 8 then
        if self.occupiedSlots[slotIndex] then
             print(string.format("Warning: Slot %d on card %s is already occupied by link %s. Overwriting with %s.", slotIndex, self.id or '?', self.occupiedSlots[slotIndex], linkId))
        end
        self.occupiedSlots[slotIndex] = linkId
        print(string.format("Card %s: Slot %d marked as occupied by link %s.", self.id or '?', slotIndex, linkId))
    else
        print(string.format("Warning: Attempted to mark invalid slot index %s as occupied on card %s.", tostring(slotIndex), self.id or '?'))
    end
end

-- Marks a specific slot as unoccupied
function Card:markSlotUnoccupied(slotIndex)
    if slotIndex and slotIndex >= 1 and slotIndex <= 8 then
        if self.occupiedSlots[slotIndex] then
            print(string.format("Card %s: Slot %d (occupied by %s) marked as unoccupied.", self.id or '?', slotIndex, self.occupiedSlots[slotIndex]))
            self.occupiedSlots[slotIndex] = nil -- Use nil to mark as unoccupied
        end
    else
        print(string.format("Warning: Attempted to mark invalid slot index %s as unoccupied on card %s.", tostring(slotIndex), self.id or '?'))
    end
end

-- Checks if a specific slot is currently marked as occupied by any link
function Card:isSlotOccupied(slotIndex)
    return self.occupiedSlots[slotIndex] ~= nil
end

-- Gets the ID of the link occupying the slot, or nil if unoccupied
function Card:getOccupyingLinkId(slotIndex)
    return self.occupiedSlots[slotIndex]
end

-- Helper function to check if a specific slot is available for connection
-- A slot is available if it's defined as open by the card type AND not currently occupied.
function Card:isSlotAvailable(slotIndex)
    local isDefinedOpen = self.definedOpenSlots[slotIndex] == true
    local isOccupied = self:isSlotOccupied(slotIndex)
    return isDefinedOpen and not isOccupied
end

-- Renamed original function for clarity
function Card:isSlotDefinedOpen(slotIndex)
    return self.definedOpenSlots[slotIndex] == true
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
-- This needs to be updated to use the new `isSlotAvailable` check.
function Card:canConnectTo(target, direction)
    if not target or not target.isSlotAvailable or not target.getSlotProperties then -- Updated check
        -- print("Warning: Invalid target provided to canConnectTo")
        return false, "Invalid target card"
    end

    -- Determine facing slots based on direction (from self's perspective)
    local selfSlotsIndices, targetSlotsIndices
    if direction == "down" then -- self is ABOVE target
        selfSlotsIndices = {Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT}
        targetSlotsIndices = {Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT}
    elseif direction == "up" then -- self is BELOW target
        selfSlotsIndices = {Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT}
        targetSlotsIndices = {Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT}
    elseif direction == "right" then -- self is LEFT of target
        selfSlotsIndices = {Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM}
        targetSlotsIndices = {Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM}
    elseif direction == "left" then -- self is RIGHT of target
        selfSlotsIndices = {Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM}
        targetSlotsIndices = {Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM}
    else
        -- print("Warning: Invalid direction provided to canConnectTo:", direction)
        return false, "Invalid direction"
    end

    -- Check all pairs of facing slots for a valid connection (GDD 4.3 Simplified Rule)
    -- "The placement is valid if at least one of these open Input slots [on Card B]
    -- aligns with a corresponding open Output slot on Card A's adjacent edge."
    -- Here, 'self' is Card A, 'target' is Card B.

    local foundValidLink = false
    for _, targetSlotIndex in ipairs(targetSlotsIndices) do
        if target:isSlotAvailable(targetSlotIndex) then -- Use the new check
            local targetProps = target:getSlotProperties(targetSlotIndex)
            if targetProps and not targetProps.is_output then -- Check if it's an INPUT slot on the target (Card B)
                -- Now find the corresponding slot on self (Card A)
                local correspondingSelfSlotIndex
                if targetSlotIndex == Card.Slots.TOP_LEFT then correspondingSelfSlotIndex = Card.Slots.BOTTOM_LEFT
                elseif targetSlotIndex == Card.Slots.TOP_RIGHT then correspondingSelfSlotIndex = Card.Slots.BOTTOM_RIGHT
                elseif targetSlotIndex == Card.Slots.BOTTOM_LEFT then correspondingSelfSlotIndex = Card.Slots.TOP_LEFT
                elseif targetSlotIndex == Card.Slots.BOTTOM_RIGHT then correspondingSelfSlotIndex = Card.Slots.TOP_RIGHT
                elseif targetSlotIndex == Card.Slots.LEFT_TOP then correspondingSelfSlotIndex = Card.Slots.RIGHT_TOP
                elseif targetSlotIndex == Card.Slots.LEFT_BOTTOM then correspondingSelfSlotIndex = Card.Slots.RIGHT_BOTTOM
                elseif targetSlotIndex == Card.Slots.RIGHT_TOP then correspondingSelfSlotIndex = Card.Slots.LEFT_TOP
                elseif targetSlotIndex == Card.Slots.RIGHT_BOTTOM then correspondingSelfSlotIndex = Card.Slots.LEFT_BOTTOM
                end
                
                -- Check if the corresponding slot on 'self' exists in the facing slots list
                local isFacing = false
                for _, sIdx in ipairs(selfSlotsIndices) do 
                    if sIdx == correspondingSelfSlotIndex then isFacing = true; break; end
                end
                
                if isFacing and self:isSlotAvailable(correspondingSelfSlotIndex) then -- Use new check
                    local selfProps = self:getSlotProperties(correspondingSelfSlotIndex)
                    if selfProps and selfProps.is_output then -- Check if it's an OUTPUT slot on self (Card A)
                        -- Check if types match (implicitly handled by GDD rule? No, GDD rule only requires *one* match)
                        -- The simplified rule doesn't require type matching for placement, only Input -> Output.
                        foundValidLink = true
                        break -- Found at least one valid Input->Output link, placement is valid
                    end
                end
            end
        end
    end

    if foundValidLink then
        return true
    else
        return false, "No matching open Input->Output slots found on adjacent edges"
    end
end

-- TODO: Add functions related to activation, linking, etc.

return Card
