-- src/game/data/card_definitions.lua
-- Contains definitions for all cards in the game.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardSlots = require('src.game.card').Slots
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions = {}

-- === Reactor Card ===
definitions["REACTOR_BASE"] = {
    id = "REACTOR_BASE",
    title = "Reactor Core",
    type = CardTypes.REACTOR,
    buildCost = { material = 0, data = 0 }, -- No build cost
    
    -- Use our helper to create the activation effect
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "addResourceToActivator",
                options = { 
                    resource = ResourceType.ENERGY, 
                    amount = 1
                }
            }
        }
    }),
    
    -- Use our helper to create the convergence effect
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "addResourceToOwner",
                options = { 
                    resource = ResourceType.ENERGY, 
                    amount = 1
                }
            }
        }
    }),
    
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
    
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "addResourceToActivator",
                options = { 
                    resource = ResourceType.DATA, 
                    amount = 1
                }
            }
        }
    }),
    
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "addResourceToOwner",
                options = { 
                    resource = ResourceType.DATA, 
                    amount = 1
                }
            }
        }
    }),
    
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
    
    -- For draw card effects, we're still using placeholder functions
    -- These would need a different helper implementation
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

-- Example of a more complex card with multiple effects
definitions["NODE_TECH_002"] = {
    id = "NODE_TECH_002",
    title = "Advanced Processing Unit",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 1 },
    
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "addResourceToActivator",
                options = { 
                    resource = ResourceType.DATA, 
                    amount = 2
                }
            },
            {
                effect = "addResourceToActivator",
                options = { 
                    resource = ResourceType.ENERGY, 
                    amount = 1
                }
            }
        }
    }),
    
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "addResourceToBoth",
                options = { 
                    resource = ResourceType.DATA, 
                    amount = 1
                }
            }
        }
    }),
    
    vpValue = 2,
    imagePath = "assets/images/advanced-processing-unit.png",
    openSlots = {
        [CardSlots.BOTTOM_RIGHT] = true, -- Tech Output
        [CardSlots.TOP_RIGHT] = true,    -- Tech Input
    },
    art = nil,
    flavorText = "Twice the processing power, half the size.",
}

-- Example of a card that adds resources to all players
definitions["NODE_CULT_002"] = {
    id = "NODE_CULT_002",
    title = "Cultural Exchange",
    type = CardTypes.CULTURE,
    buildCost = { material = 2, data = 2 },
    
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "addResourceToAllPlayers",
                options = { 
                    resource = ResourceType.DATA, 
                    amount = 1
                }
            }
        }
    }),
    
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "addResourceToActivator",
                options = { 
                    resource = ResourceType.DATA, 
                    amount = 2
                }
            }
        }
    }),
    
    vpValue = 2,
    imagePath = "assets/images/cultural-exchange.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,    -- Culture Output
        [CardSlots.BOTTOM_LEFT] = true, -- Culture Input
    },
    art = nil,
    flavorText = "Sharing knowledge benefits everyone.",
}

-- Add more card definitions here...

return definitions 
