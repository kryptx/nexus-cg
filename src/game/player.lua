-- src/game/player.lua
-- Defines the Player class, holding state like resources, hand, VP, etc.

local Card = require('src.game.card') -- We'll need Card instances for the hand
-- local CardDefinitions = require('src.game.data.card_definitions') -- May need this later for starting cards

local Player = {}
Player.__index = Player

-- Constructor for a new Player instance
function Player:new(id, name)
    local instance = setmetatable({}, Player)

    instance.id = id or error("Player must have an ID")
    instance.name = name or "Player " .. tostring(id)

    -- Game State
    instance.resources = {
        energy = 0, -- Starting Energy (TBD from GDD 4.1)
        data = 0, -- Starting Data (TBD from GDD 4.1)
        material = 0, -- Starting Material (TBD from GDD 4.1)
    }
    instance.vp = 0 -- Victory Points
    instance.hand = {} -- List (table) of Card instances
    instance.network = nil -- Reference to the player's Network object (to be created later)

    -- Convergence Links (GDD 4.1 & 4.6)
    -- Track available link sets
    instance.availableConvergenceLinks = {
        [Card.Type.TECHNOLOGY] = 4, -- Assuming 4 sets initially based on GDD reading
        [Card.Type.CULTURE] = 4,
        [Card.Type.RESOURCE] = 4,
        [Card.Type.KNOWLEDGE] = 4,
    }
    -- Track active links (more complex, maybe store pairs of {own_card_id, own_slot, target_player_id, target_card_id, target_slot})
    instance.activeConvergenceLinks = {}

    print(string.format("Created player: %s (ID: %s)", instance.name, instance.id))
    return instance
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

-- TODO: Add methods for playing cards, drawing cards, managing network, VP, convergence links

return Player
