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
    
    -- Activation: Per user request, activation effects always benefit the owner.
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "addResourceToOwner", -- Changed from Activator
                options = { 
                    resource = ResourceType.ENERGY, 
                    amount = 1
                }
            }
        }
    }),
    
    -- Convergence: Grants Energy to the owner (no benefit to activator for base reactor)
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
                effect = "addResourceToOwner", -- Changed from Activator
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
                effect = "addResourceToOwner", -- Original design was owner benefits
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
    
    -- Activation: Owner draws 1 card.
    activationEffect = CardEffects.createActivationEffect({ -- Using new helper
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
    }),
    
    -- Convergence: Activator draws 1 card.
    convergenceEffect = CardEffects.createConvergenceEffect({ -- Using new helper
        actions = {
            { effect = "drawCardsForActivator", options = { amount = 1 } }
        }
    }),
    
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
                effect = "addResourceToOwner", -- Changed from Activator
                options = { 
                    resource = ResourceType.DATA, 
                    amount = 2
                }
            },
            {
                effect = "addResourceToOwner", -- Changed from Activator
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
                effect = "addResourceToBoth", -- Original design was both benefit
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
    
    -- Activation: Affects all players, so owner/activator distinction less relevant.
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
    
    -- Convergence: Activator gains Data.
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "addResourceToActivator", -- Original design was activator benefits
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

-- Data Relay
definitions["NODE_KNOW_001"] = {
    id = "NODE_KNOW_001",
    title = "Data Relay",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 1, data = 1 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "addResourceToOwner", -- Changed from Activator
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
                effect = "addResourceToOwner", -- Original design was owner benefits
                options = {
                    resource = ResourceType.DATA,
                    amount = 1
                }
            }
        }
    }),

    vpValue = 0,
    imagePath = "assets/images/data-relay.png",
    -- Knowledge Output (Left Top), Knowledge Input (Right Top)
    openSlots = {
        [CardSlots.LEFT_TOP] = true,    -- Knowledge Output
        [CardSlots.RIGHT_TOP] = true,   -- Knowledge Input
        [CardSlots.TOP_LEFT] = false, [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_LEFT] = false, [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil, -- Placeholder
    flavorText = "Connecting streams of information.",
}

-- Materials Depot
definitions["NODE_RES_001"] = {
    id = "NODE_RES_001",
    title = "Materials Depot",
    type = CardTypes.RESOURCE,
    buildCost = { material = 2, data = 0 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "addResourceToOwner", -- Changed from Activator
                options = {
                    resource = ResourceType.MATERIAL,
                    amount = 2
                }
            }
        }
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "addResourceToBoth", -- Original design was both benefit
                options = {
                    resource = ResourceType.MATERIAL,
                    amount = 1
                }
            }
        }
    }),

    vpValue = 0,
    imagePath = "assets/images/materials-depot.png",
    -- Resource Input (Left Bottom), Resource Output (Right Bottom)
    openSlots = {
        [CardSlots.LEFT_BOTTOM] = true,   -- Resource Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardSlots.TOP_LEFT] = false, [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_LEFT] = false, [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil, -- Placeholder
    flavorText = "Storing the building blocks of progress.",
}

-- Synaptic Media Hub
definitions["NODE_CULT_004"] = {
    id = "NODE_CULT_004",
    title = "Synaptic Media Hub",
    type = CardTypes.CULTURE,
    buildCost = { material = 3, data = 2 },

    -- Activation: Owner gains 1 VP and draws 1 card.
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 1 } }, -- Changed from gainVP (Activator)
            { effect = "drawCardsForOwner", options = { amount = 1 } } -- Changed from drawCards (Activator)
        }
    }),

    -- Convergence: Activator gains 2 Data. Owner gains 1 VP.
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } },
             { effect = "gainVPForOwner", options = { amount = 1 } } -- Use the new owner-specific VP effect
        }
    }),

    vpValue = 2, -- Endgame VP
    imagePath = "assets/images/synaptic-media-hub.png",
    -- Culture Out (1), Tech In (2), Tech Out (4), Knowledge In (7)
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil, -- Placeholder
    flavorText = "Broadcasting the pulse of the collective.",
}

definitions["NODE_TECH_003"] = {
    id = "NODE_TECH_003",
    title = "Applied Arts Workshop",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 1 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Energy to the owner. Owner gains 1 VP."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Material to the owner."
    }),

    vpValue = 1, -- Endgame VP
    imagePath = "assets/images/applied-arts-workshop.png",
    -- Culture In (3), Tech Out (4), Knowledge Out (5), Resource In (6)
    openSlots = {
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.TOP_RIGHT] = false,    -- 2
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = false,    -- 7
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil, -- Placeholder
    flavorText = "Turning inspiration into innovation.",
}

definitions["NODE_RES_002"] = {
    id = "NODE_RES_002",
    title = "Automated Drill Site",
    type = CardTypes.RESOURCE,
    buildCost = { material = 4, data = 2 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 3 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 3 Material to the owner. Grants 1 Energy to the owner."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner."
    }),

    vpValue = 2, -- Endgame VP
    imagePath = "assets/images/automated-drill-site.png",
    -- Tech In (2), Resource In (6), Knowledge In (7), Resource Out (8)
    openSlots = {
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
    },
    art = nil, -- Placeholder
    flavorText = "Extracting value with calculated precision.",
}

definitions["NODE_KNOW_002"] = {
    id = "NODE_KNOW_002",
    title = "Materials Analysis Lab",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 3 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 2 Data to the owner. Owner gains 1 VP."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Material to the owner."
    }),

    vpValue = 1, -- Endgame VP
    imagePath = "assets/images/materials-analysis-lab.png",
    -- Tech In (2), Knowledge Out (5), Resource In (6), Knowledge In (7)
    openSlots = {
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil, -- Placeholder
    flavorText = "Decoding the secrets held within matter.",
}

definitions["NODE_KNOW_003"] = {
    id = "NODE_KNOW_003",
    title = "Historical Archive",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 2 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Owner gains 1 VP. Grants 1 Data to the owner."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Energy to the owner."
    }),

    vpValue = 1, -- Endgame VP
    imagePath = "assets/images/historical-archive.png",
    -- Culture Out (1), Knowledge Out (5), Resource In (6), Knowledge In (7)
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = false,    -- 2
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil, -- Placeholder
    flavorText = "Understanding the past to shape the future.",
}

definitions["NODE_CULT_005"] = {
    id = "NODE_CULT_005",
    title = "Holographic Theater",
    type = CardTypes.CULTURE,
    buildCost = { material = 3, data = 3 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Owner gains 1 VP. Grants 1 Energy to the owner."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Grants 1 Data to the owner."
    }),

    vpValue = 2, -- Endgame VP
    imagePath = "assets/images/holographic-theater.png",
    -- Culture Out (1), Tech In (2), Tech Out (4), Knowledge In (7)
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil, -- Placeholder
    flavorText = "Where artifice meets artistry.",
}

definitions["NODE_RES_003"] = {
    id = "NODE_RES_003",
    title = "Monument Construction Site",
    type = CardTypes.RESOURCE,
    buildCost = { material = 5, data = 1 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 2 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Owner gains 2 VP. Grants 1 Material to the owner."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Grants 1 Material to the owner."
    }),

    vpValue = 2, -- Endgame VP
    imagePath = "assets/images/monument-construction-site.png",
    -- Culture Out (1), Tech In (2), Knowledge In (7), Resource Out (8)
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
    },
    art = nil, -- Placeholder
    flavorText = "Building legacies that echo through time.",
}

definitions["NODE_KNOW_004"] = {
    id = "NODE_KNOW_004",
    title = "AI Research Center",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 4 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 2 Data to the owner. Grants 1 Energy to the owner."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Energy to the owner."
    }),

    vpValue = 2, -- Endgame VP
    imagePath = "assets/images/ai-research-center.png",
    -- Tech In (2), Tech Out (4), Knowledge Out (5), Knowledge In (7)
    openSlots = {
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil, -- Placeholder
    flavorText = "Synthesizing intelligence, one cycle at a time.",
}

definitions["NODE_TECH_004"] = {
    id = "NODE_TECH_004",
    title = "Automated Fabricator",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 4, data = 3 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Energy to the owner. Grants 1 Material to the owner. Owner gains 1 VP."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner."
    }),

    vpValue = 2, -- Endgame VP
    imagePath = "assets/images/automated-fabricator.png",
    -- Tech Out (4), Resource In (6), Knowledge In (7), Resource Out (8)
    openSlots = {
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.TOP_RIGHT] = false,    -- 2
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
    },
    art = nil, -- Placeholder
    flavorText = "From raw materials to finished marvels.",
}

definitions["NODE_KNOW_005"] = {
    id = "NODE_KNOW_005",
    title = "Bio-Research Lab",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 3, data = 3 },

    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 2 Data to the owner. Grants 1 Energy to the owner."
    }),

    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } -- Owner gets data from collab
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Data to the owner."
    }),

    vpValue = 1, -- Endgame VP
    imagePath = "assets/images/bio-research-lab.png",
    -- Tech In (2), Knowledge Out (5), Resource In (6), Resource Out (8)
    openSlots = {
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = false,    -- 7 -- Changed mind, removed Knowledge Input for simplicity
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
    },
    art = nil, -- Placeholder
    flavorText = "Unlocking the blueprints of life itself.",
}

return definitions 
