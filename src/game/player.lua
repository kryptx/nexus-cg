-- src/game/player.lua
-- Defines the Player class, holding state like resources, hand, VP, etc.

local Card = require('src.game.card') -- We'll need Card instances for the hand
-- local CardDefinitions = require('src.game.data.card_definitions') -- May need this later for starting cards

local Player = {}
Player.__index = Player

-- Constructor for a new Player instance
-- Note: Player object creation is now handled within GameService:initializeGame
-- to ensure network and reactor are set up correctly.
function Player:new(config)
    local instance = setmetatable({}, Player)

    instance.id = config.id or error("Player must have an ID")
    instance.name = config.name or ("Player " .. tostring(instance.id))

    -- Game State
    instance.resources = {
        energy = 0, -- Starting Energy (TBD from GDD 4.1)
        data = 0, -- Starting Data (TBD from GDD 4.1)
        material = 0, -- Starting Material (TBD from GDD 4.1)
    }
    instance.vp = 0 -- Victory Points
    instance.hand = {} -- List (table) of Card instances
    instance.network = nil -- Reference to the player's Network object (set by GameService)
    instance.reactorCard = nil -- Reference to the player's Reactor card (set by GameService)

    instance.orientation = 0 -- Rotation angle in radians, defaults to 0

    -- Convergence Links (GDD 4.1 & 4.6)
    -- Tracks whether each of the player's four link *sets* has been used.
    -- A set is consumed when initiating a link of that type.
    instance.usedConvergenceLinkSets = {
        [Card.Type.TECHNOLOGY] = false,
        [Card.Type.CULTURE]    = false,
        [Card.Type.RESOURCE]   = false,
        [Card.Type.KNOWLEDGE]  = false,
    }
    -- Track how many links this player has successfully initiated (for paradigm triggers)
    instance.initiatedLinksCount = 0

    print(string.format("Created player: %s (ID: %s)", instance.name, instance.id))
    return instance
end

-- Checks if the player has the link set of the given type available (i.e., not used yet)
function Player:hasLinkSetAvailable(linkType)
    if self.usedConvergenceLinkSets[linkType] == nil then
        print(string.format("Warning: Checking availability for unknown link type: %s", tostring(linkType)))
        return false
    end
    return not self.usedConvergenceLinkSets[linkType]
end

-- Marks the link set of the given type as used and increments the count.
function Player:useLinkSet(linkType)
    if self.usedConvergenceLinkSets[linkType] == nil then
        print(string.format("Warning: Attempting to use unknown link type: %s", tostring(linkType)))
        return false
    end
    if self.usedConvergenceLinkSets[linkType] then
        print(string.format("Warning: Player %s attempting to re-use already used %s link set.", self.name, tostring(linkType)))
        return false -- Already used
    end
    self.usedConvergenceLinkSets[linkType] = true
    self.initiatedLinksCount = self.initiatedLinksCount + 1
    print(string.format("Player %s used their %s link set. (%d total initiated)", self.name, tostring(linkType), self.initiatedLinksCount))
    return true
end

-- Returns the number of convergence links initiated by this player.
function Player:getInitiatedLinksCount()
    return self.initiatedLinksCount
end

-- Example methods (implement actual logic later)

function Player:addResource(resourceType, amount)
    if self.resources[resourceType] then
        self.resources[resourceType] = self.resources[resourceType] + amount
        print(string.format("%s gained %d %s (Total: %d)", self.name, amount, resourceType, self.resources[resourceType]))
    else
        print("Warning: Tried to add unknown resource type: " .. tostring(resourceType))
    end
end

function Player:spendResource(resourceType, amount)
    if self.resources[resourceType] and self.resources[resourceType] >= amount then
        self.resources[resourceType] = self.resources[resourceType] - amount
        print(string.format("%s spent %d %s (Remaining: %d)", self.name, amount, resourceType, self.resources[resourceType]))
        return true -- Success
    else
        print(string.format("Warning: %s failed to spend %d %s (Has: %d)", self.name, amount, resourceType, self.resources[resourceType] or 0))
        return false -- Failure
    end
end

function Player:addCardToHand(cardInstance)
    -- Check if it's a table and its metatable is the Card module table
    if not cardInstance or type(cardInstance) ~= 'table' or getmetatable(cardInstance) ~= Card then
       error("Attempted to add invalid object to hand. Expected Card instance.")
       return
    end
    table.insert(self.hand, cardInstance)
    cardInstance.owner = self -- Assign ownership
    print(string.format("%s added card '%s' (%s) to hand.", self.name, cardInstance.title, cardInstance.id))
end

-- Get the number of cards in the player's hand
function Player:getHandSize()
    return #self.hand
end

-- Get the player's current victory points
function Player:getVictoryPoints()
    return self.vp
end

-- Add VP to the player's score
function Player:addVP(amount)
    self.vp = self.vp + (amount or 0)
    print(string.format("%s VP changed by %d (Total: %d)", self.name, amount or 0, self.vp))
end

return Player
