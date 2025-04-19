-- src/game/data/card_definitions.lua
-- Contains definitions for all cards in the game.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardSlots = require('src.game.card').Slots

local definitions = {}

-- === Reactor Card ===
definitions["REACTOR_BASE"] = {
    id = "REACTOR_BASE",
    title = "Reactor Core",
    type = CardTypes.REACTOR,
    buildCost = { material = 0, data = 0 }, -- No build cost
    actionEffect = function() print("Reactor has no action.") end,
    convergenceEffect = function() print("Reactor has no convergence effect.") end,
    vpValue = 0,
    -- GDD 4.1: Reactor has all 8 slots open initially
    openSlots = {
        [CardSlots.TOP_LEFT] = true, [CardSlots.TOP_RIGHT] = true,
        [CardSlots.BOTTOM_LEFT] = true, [CardSlots.BOTTOM_RIGHT] = true,
        [CardSlots.LEFT_TOP] = true, [CardSlots.LEFT_BOTTOM] = true,
        [CardSlots.RIGHT_TOP] = true, [CardSlots.RIGHT_BOTTOM] = true,
    },
    art = nil, -- Placeholder
    flavorText = "The heart of the network.",
}

-- === Example Node Cards ===

-- Simple Technology Node (Seed Card Example?)
definitions["NODE_TECH_001"] = {
    id = "NODE_TECH_001",
    title = "Basic Processing Unit",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 1, data = 0 },
    actionEffect = function(player, network) print("Basic Processing Unit: +1 Data (Action).") end, -- Placeholder logic
    convergenceEffect = function(player, network) print("Basic Processing Unit: Opponent gets +1 Data (Convergence).") end, -- Placeholder logic
    vpValue = 0,
    -- Example: Tech Output (Bottom Right), Tech Input (Top Right)
    openSlots = {
        [CardSlots.BOTTOM_RIGHT] = true, -- Tech Output
        [CardSlots.TOP_RIGHT] = true,    -- Tech Input
    },
    art = nil,
    flavorText = "Standard computational core.",
}

-- Simple Culture Node
definitions["NODE_CULT_001"] = {
    id = "NODE_CULT_001",
    title = "Community Forum",
    type = CardTypes.CULTURE,
    buildCost = { material = 1, data = 0 },
    actionEffect = function(player, network) print("Community Forum: Draw 1 card (Action).") end, -- Placeholder
    convergenceEffect = function(player, network) print("Community Forum: Opponent draws 1 card (Convergence).") end, -- Placeholder
    vpValue = 1,
    -- Example: Culture Output (Top Left), Culture Input (Bottom Left)
    openSlots = {
        [CardSlots.TOP_LEFT] = true,    -- Culture Output
        [CardSlots.BOTTOM_LEFT] = true, -- Culture Input
    },
    art = nil,
    flavorText = "Where ideas are shared.",
}

-- Add more card definitions here...

return definitions 
