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
    -- Grants 1 Energy to the activating player
    activationEffect = function(player, network) 
        if player and player.addResource then 
            player:addResource("energy", 1)
            print("Reactor Activation: +1 Energy for " .. (player.name or "player " .. player.id))
        end
    end,
    -- Grants 1 Energy to the OWNER player when activated via convergence
    convergenceEffect = function(activatingPlayer, network) 
        -- Note: The effect gets the player *initiating* the convergence.
        -- We need to find the *owner* of this reactor card within the network.
        local ownerPlayer = network and network.owner
        if ownerPlayer and ownerPlayer.addResource then
            ownerPlayer:addResource("energy", 1)
            print("Reactor Convergence: +1 Energy for owner " .. (ownerPlayer.name or "player " .. ownerPlayer.id))
        else
            print("Reactor Convergence: Could not find owner to grant energy.")
        end
    end,
    vpValue = 0,
    imagePath = "assets/images/reactor-core.png",
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
    activationEffect = function(player, network) print("+1 Data.") end, -- Placeholder logic
    convergenceEffect = function(player, network) print("Opponent gets +1 Data.") end, -- Placeholder logic
    vpValue = 0,
    imagePath = "assets/images/basic-processing-unit.png",
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
    activationEffect = function(player, network) print("Draw 1 card.") end, -- Placeholder
    convergenceEffect = function(player, network) print("Opponent draws 1 card.") end, -- Placeholder
    vpValue = 1,
    imagePath = "assets/images/community-forum.png",
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
