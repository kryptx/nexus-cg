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
    -- No activation/convergence effect for the Reactor itself
}

-- === Genesis Cards ===
-- Low cost cards designed to be playable turn 1 and guarantee an initial activation path.
-- Criteria: Cost 1M/0D, Input/Output pair on the same edge.

definitions["GENESIS_TECH_001"] = {
    id = "GENESIS_TECH_001",
    title = "Initial Circuit",
    type = CardTypes.TECHNOLOGY,
    isGenesis = true, -- Mark as a Genesis card
    buildCost = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the activator." (Changed from Owner)
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-initial-circuit.png", -- Placeholder path
    openSlots = {
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input (Reactor Edge)
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output (Reactor Edge)
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output (Top Edge)
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output (Left Edge)
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output (Right Edge)
        [CardSlots.TOP_RIGHT] = false,    -- 2
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_TOP] = false,    -- 7
    },
    art = nil,
    flavorText = "The first connection flickers to life.",
}

definitions["GENESIS_RES_001"] = {
    id = "GENESIS_RES_001",
    title = "First Spark",
    type = CardTypes.RESOURCE,
    isGenesis = true,
    buildCost = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Grants 1 Material to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Grants 1 Material to the activator." (Unchanged)
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-first-spark.png", -- Placeholder path
    openSlots = {
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input (Reactor Edge)
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output (Reactor Edge)
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input (Top Edge)
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output (Bottom Edge)
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input (Left Edge)
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.LEFT_TOP] = false,     -- 5
    },
    art = nil,
    flavorText = "A trickle becomes a potential flow.",
}

definitions["GENESIS_KNOW_001"] = {
    id = "GENESIS_KNOW_001",
    title = "Seed Thought",
    type = CardTypes.KNOWLEDGE,
    isGenesis = true,
    buildCost = { material = 1, data = 0 },
     activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the activator." (Unchanged)
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-seed-thought.png", -- Placeholder path
    openSlots = {
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output (Reactor Edge)
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input (Reactor Edge)
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output (Top Edge)
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input (Bottom Edge)
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input (Right Edge)
        [CardSlots.TOP_RIGHT] = false,    -- 2
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil,
    flavorText = "The first question asked.",
}

definitions["GENESIS_CULT_001"] = {
    id = "GENESIS_CULT_001",
    title = "Nascent Meme",
    type = CardTypes.CULTURE,
    isGenesis = true,
    buildCost = { material = 1, data = 0 },
     activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        -- actions = { { effect = "gainVPForActivator", options = { amount = 1 } } } -- Removed VP gain
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } } 
        -- Description: "Grants 1 Data to the activator." (Changed from VP gain, now consistent with other Genesis)
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-nascent-meme.png", -- Placeholder path
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output (Reactor Edge)
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input (Reactor Edge)
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input (Bottom Edge)
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output (Left Edge)
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output (Right Edge)
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_TOP] = false,    -- 7
    },
    art = nil,
    flavorText = "An idea begins to spread.",
}

-- === Core Node Cards ===

definitions["NODE_TECH_001"] = {
    id = "NODE_TECH_001",
    title = "Basic Processing Unit",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the activator." (Changed from Owner)
    }),
    vpValue = 0,
    imagePath = "assets/images/basic-processing-unit.png",
    openSlots = {
        [CardSlots.BOTTOM_RIGHT] = true, -- Tech Output
        [CardSlots.TOP_RIGHT] = true,    -- Tech Input
        [CardSlots.LEFT_BOTTOM] = true,  -- Resource Input (Added)
    },
    art = nil,
    flavorText = "Standard computational core.",
}

definitions["NODE_CULT_001"] = {
    id = "NODE_CULT_001",
    title = "Community Forum",
    type = CardTypes.CULTURE,
    buildCost = { material = 1, data = 1 }, -- Increased Data cost by 1
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "drawCardsForOwner", options = { amount = 1 } } }
        -- Description: "Owner draws 1 card." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
        -- Description: "Activator draws 1 card." (Unchanged)
    }),
    vpValue = 0, -- Reduced VP from 1 to 0 due to low cost
    imagePath = "assets/images/community-forum.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,    -- Culture Output
        [CardSlots.BOTTOM_LEFT] = true, -- Culture Input
        [CardSlots.RIGHT_TOP] = true,   -- Knowledge Input (Added)
    },
    art = nil,
    flavorText = "Where ideas are shared, connections are forged.",
}

definitions["NODE_TECH_002"] = {
    id = "NODE_TECH_002",
    title = "Advanced Processing Unit",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 1 }, 
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } } }
        -- Description: "Grants 2 Data to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToBoth", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to both the owner and activator." (Unchanged)
    }),
    vpValue = 1, -- Reduced VP from 2 to 1
    imagePath = "assets/images/advanced-processing-unit.png",
    openSlots = {
        [CardSlots.BOTTOM_RIGHT] = true, -- Tech Output
        [CardSlots.TOP_RIGHT] = true,    -- Tech Input
        [CardSlots.LEFT_TOP] = true,     -- Knowledge Output (Added)
    },
    art = nil,
    flavorText = "Twice the processing power, half the size.",
}

definitions["NODE_CULT_002"] = {
    id = "NODE_CULT_002",
    title = "Cultural Exchange",
    type = CardTypes.CULTURE,
    buildCost = { material = 2, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            -- { effect = "addResourceToAllPlayers", options = { resource = ResourceType.DATA, amount = 1 } } -- Removed global effect
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
        }
        -- Description: "Grants 1 Data to the owner." (Changed from addResourceToAllPlayers)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } } }
        -- Description: "Grants 2 Data to the activator." (Unchanged)
    }),
    vpValue = 1, -- Reduced VP from 2 to 1
    imagePath = "assets/images/cultural-exchange.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,    -- Culture Output
        [CardSlots.BOTTOM_LEFT] = true, -- Culture Input
        [CardSlots.RIGHT_BOTTOM] = true, -- Resource Output (Added)
    },
    art = nil,
    flavorText = "Sharing knowledge benefits many.",
}

definitions["NODE_KNOW_001"] = {
    id = "NODE_KNOW_001",
    title = "Data Relay",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 1, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the activator." (Changed from owner)
    }),
    vpValue = 0,
    imagePath = "assets/images/data-relay.png",
    openSlots = {
        [CardSlots.LEFT_TOP] = true,    -- Knowledge Output
        [CardSlots.RIGHT_TOP] = true,   -- Knowledge Input
        [CardSlots.LEFT_BOTTOM] = true, -- Resource Input (Added) - Can be powered
        [CardSlots.TOP_LEFT] = false, [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_LEFT] = false, [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Connecting streams of information.",
}

definitions["NODE_RES_001"] = {
    id = "NODE_RES_001",
    title = "Materials Depot",
    type = CardTypes.RESOURCE,
    buildCost = { material = 2, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { 
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } },
            { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
              effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 2 Material to the owner. If adjacent to 1+ Technology node(s): Grants 1 Energy to the owner." (Added conditional Energy)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToBoth", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Grants 1 Material to both the owner and activator." (Unchanged)
    }),
    vpValue = 0,
    imagePath = "assets/images/materials-depot.png",
    openSlots = {
        [CardSlots.LEFT_BOTTOM] = true,   -- Resource Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardSlots.TOP_RIGHT] = true,     -- Technology Input (Added) - Synergy for Energy
        [CardSlots.TOP_LEFT] = false, 
        [CardSlots.BOTTOM_LEFT] = false, [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "Storing the building blocks, awaiting the spark.",
}

-- === Intermediate Nodes ===

definitions["NODE_CULT_004"] = {
    id = "NODE_CULT_004",
    title = "Synaptic Media Hub",
    type = CardTypes.CULTURE,
    buildCost = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner draws 1 card." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } },
        }
        -- Description: "Grants 2 Data to the activator." (Unchanged)
    }),
    vpValue = 1, -- Reduced VP from 2 to 1
    imagePath = "assets/images/synaptic-media-hub.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input (Added)
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil,
    flavorText = "Broadcasting the pulse of the collective.",
}

definitions["NODE_TECH_003"] = {
    id = "NODE_TECH_003",
    title = "Applied Arts Workshop",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "satisfiedInputs", count = 2},
            effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 Material. If 2+ input slot(s) are connected: Owner gains 1 VP." (Made VP conditional)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Material to the owner." (Unchanged)
    }),
    vpValue = 1, 
    imagePath = "assets/images/applied-arts-workshop.png",
    openSlots = {
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output (Added)
        [CardSlots.TOP_RIGHT] = false,    -- 2
        [CardSlots.RIGHT_TOP] = false,    -- 7
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil,
    flavorText = "Turning inspiration into innovation.",
}

definitions["NODE_RES_002"] = {
    id = "NODE_RES_002",
    title = "Automated Drill Site",
    type = CardTypes.RESOURCE,
    buildCost = { material = 4, data = 1 }, -- Reduced data cost
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 3 } } }
        -- Description: "Grants 3 Material to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner." (Unchanged)
    }),
    vpValue = 1, -- Reduced VP from 2 to 1
    imagePath = "assets/images/automated-drill-site.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_TOP] = false,     -- 5
    },
    art = nil,
    flavorText = "Extracting value with calculated precision.",
}

definitions["NODE_KNOW_002"] = {
    id = "NODE_KNOW_002",
    title = "Materials Analysis Lab",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }, -- Reduced data gain
        }
        -- Description: "Grants 1 Data to the owner. Owner gains 1 VP." (Reduced Data)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             -- { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } -- Removed owner Material gain
             { condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
               effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. If adjacent to 1+ Resource node(s): Grants 1 Material to the owner." (Made owner Material conditional)
    }),
    vpValue = 1, 
    imagePath = "assets/images/materials-analysis-lab.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.TOP_LEFT] = false,     -- 1
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output (Added)
    },
    art = nil,
    flavorText = "Decoding the secrets held within matter.",
}

definitions["NODE_KNOW_003"] = {
    id = "NODE_KNOW_003",
    title = "Historical Archive",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 2 Data to the activator. Owner gains 1 VP." (Unchanged)
    }),
    vpValue = 1, 
    imagePath = "assets/images/historical-archive.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.TOP_RIGHT] = false,    -- 2
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input (Added)
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil,
    flavorText = "Understanding the past to shape the future.",
}

definitions["NODE_CULT_005"] = {
    id = "NODE_CULT_005",
    title = "Holographic Theater",
    type = CardTypes.CULTURE,
    buildCost = { material = 3, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } } -- Added card draw
        }
        -- Description: "Owner draws 1 card." (Added draw)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } }
             -- { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } -- Removed owner data gain
        }
        -- Description: "Activator gains 1 VP." (Simplified)
    }),
    vpValue = 1, -- Reduced VP from 2 to 1
    imagePath = "assets/images/holographic-theater.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input (Added)
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = false,  -- 6
        [CardSlots.RIGHT_BOTTOM] = false, -- 8
    },
    art = nil,
    flavorText = "Where artifice meets artistry.",
}

definitions["NODE_RES_003"] = {
    id = "NODE_RES_003",
    title = "Monument Construction Site",
    type = CardTypes.RESOURCE,
    buildCost = { material = 5, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Owner gains 1 VP. Grants 1 Material to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Grants 1 Material to the owner." (Unchanged)
    }),
    vpValue = 2, 
    imagePath = "assets/images/monument-construction-site.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.BOTTOM_LEFT] = false,  -- 3
        [CardSlots.BOTTOM_RIGHT] = false, -- 4
        [CardSlots.LEFT_TOP] = false,     -- 5
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input (Added)
    },
    art = nil,
    flavorText = "Building legacies that echo through time.",
}

-- === Advanced Nodes ===

definitions["NODE_KNOW_004"] = {
    id = "NODE_KNOW_004",
    title = "AI Research Center",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } },
            { condition = { type = "satisfiedInputs", count = 3 },
              effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 2 Data to the owner. If 3+ input slot(s) are connected: Owner gains 1 VP." (Added VP condition)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Owner gains 1 VP." (Unchanged)
    }),
    vpValue = 1, -- Reduced VP from 2 to 1
    imagePath = "assets/images/ai-research-center.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Synthesizing intelligence, one cycle at a time.",
}

definitions["NODE_TECH_004"] = {
    id = "NODE_TECH_004",
    title = "Automated Fabricator",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 4, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } },
        }
        -- Description: "Grants 2 Material to the owner." (Increased Material)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner." (Unchanged)
    }),
    vpValue = 1, -- Reduced VP from 2 to 1
    imagePath = "assets/images/automated-fabricator.png",
    openSlots = {
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input (Added for adjacency)
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_TOP] = false,
    },
    art = nil,
    flavorText = "From raw materials to finished marvels.",
}

definitions["NODE_KNOW_005"] = {
    id = "NODE_KNOW_005",
    title = "Bio-Research Lab",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 3, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } } }
        -- Description: "Grants 2 Data to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "forceDiscardCardsActivator", options = { amount = 1 } } -- Added activator discard
        }
        -- Description: "Grants 1 Data to the activator. Activator discards 1 card(s)." (Replaced owner data gain with activator discard)
    }),
    vpValue = 1,
    imagePath = "assets/images/bio-research-lab.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input (Re-added)
    },
    art = nil,
    flavorText = "Unlocking the blueprints of life itself.",
}

definitions["NODE_TECH_RES_001"] = {
    id = "NODE_TECH_RES_001",
    title = "Geothermal Tap",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
              effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 1 Energy to the owner. Grants 1 Material to the owner. If adjacent to 1+ Resource node(s): Grants 1 Energy to the owner." (Added conditional Energy)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.ENERGY, amount = 1 } } }
        -- Description: "Grants 1 Energy to the activator." (Unchanged)
    }),
    vpValue = 1, 
    imagePath = "assets/images/geothermal-tap.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input (Added for adjacency bonus)
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "Harnessing the planet's inner fire.",
}

-- === Bridge Nodes (Combining Types/Functions) ===

definitions["NODE_TECH_CULT_001"] = {
    id = "NODE_TECH_CULT_001",
    title = "Digital Art Synthesizer",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 2, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } },
            { condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
              effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner draws 1 card. If adjacent to 1+ Culture node(s): Owner gains 1 VP." (Added conditional VP)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
        -- Description: "Activator draws 1 card." (Unchanged)
    }),
    vpValue = 0, -- Removed base VP
    imagePath = "assets/images/digital-art-synthesizer.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input (Added for adjacency)
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_TOP] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Weaving algorithms into aesthetic experience.",
}

definitions["NODE_TECH_KNOW_001"] = {
    id = "NODE_TECH_KNOW_001",
    title = "Quantum Simulation Lab",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } },
        }
        -- Description: "Grants 2 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Owner gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/quantum-simulation-lab.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Modeling reality at its most fundamental level.",
}

definitions["NODE_CULT_TECH_001"] = {
    id = "NODE_CULT_TECH_001",
    title = "Applied Aesthetics Studio",
    type = CardTypes.CULTURE,
    buildCost = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
             { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
                effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the owner. If adjacent to 1+ Technology node(s): Owner gains 1 VP." (Added conditional VP)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/applied-aesthetics-studio.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input (Added for adjacency)
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_TOP] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Function follows form, elegantly.",
}

definitions["NODE_CULT_KNOW_001"] = {
    id = "NODE_CULT_KNOW_001",
    title = "Ethnographic Database",
    type = CardTypes.CULTURE,
    buildCost = { material = 2, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Owner draws 1 card. Grants 1 Data to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "drawCardsForActivator", options = { amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator draws 1 card. Owner gains 1 VP." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/ethnographic-database.png",
    openSlots = {
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output (Added)
        [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Mapping the myriad patterns of society.",
}

definitions["NODE_CULT_RES_001"] = {
    id = "NODE_CULT_RES_001",
    title = "Artisan Guild Workshop",
    type = CardTypes.CULTURE,
    buildCost = { material = 4, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 2 Material to the owner. Owner gains 1 VP." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/artisan-guild-workshop.png",
    openSlots = {
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output (Added)
        [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "Master craftsmanship, tangible results.",
}

definitions["NODE_RES_CULT_001"] = {
    id = "NODE_RES_CULT_001",
    title = "Resource Reclamation Art Project",
    type = CardTypes.RESOURCE,
    buildCost = { material = 3, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 1 } },
            { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 VP. Owner draws 1 card." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Grants 1 Material to the owner." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/resource-reclamation-art-project.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "Finding beauty in the discarded.",
}

definitions["NODE_RES_TECH_001"] = {
    id = "NODE_RES_TECH_001",
    title = "Materials Science R&D",
    type = CardTypes.RESOURCE,
    buildCost = { material = 4, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the owner. Owner gains 1 VP." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Material to the owner." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/materials-science-r&d.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "Transforming raw potential into technological advancement.",
}

definitions["NODE_RES_KNOW_001"] = {
    id = "NODE_RES_KNOW_001",
    title = "Geological Survey Outpost",
    type = CardTypes.RESOURCE,
    buildCost = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } } }
        -- Description: "Grants 2 Data to the owner." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Owner gains 1 VP." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/geological-survey-outpost.png",
    openSlots = {
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
    },
    art = nil,
    flavorText = "Charting the wealth beneath the surface.",
}

definitions["NODE_KNOW_CULT_001"] = {
    id = "NODE_KNOW_CULT_001",
    title = "Historical Simulation Center",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 1 } },
            { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 VP. Owner draws 1 card." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Owner draws 1 card." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/historical-simulation-center.png",
    openSlots = {
        [CardSlots.TOP_LEFT] = true,      -- 1: Culture Output
        [CardSlots.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Experiencing the echoes of the past.",
}

definitions["NODE_KNOW_TECH_001"] = {
    id = "NODE_KNOW_TECH_001",
    title = "Advanced Algorithm Design",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 5 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the owner. Owner gains 1 VP." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Owner gains 1 VP." (Unchanged)
    }),
    vpValue = 2,
    imagePath = "assets/images/advanced-algorithm-design.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Crafting the logic engines of tomorrow.",
}

definitions["NODE_KNOW_RES_001"] = {
    id = "NODE_KNOW_RES_001",
    title = "Resource Optimization AI",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 3, data = 5 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Material to the owner. Owner gains 1 VP." (Unchanged)
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner." (Unchanged)
    }),
    vpValue = 1,
    imagePath = "assets/images/resource-optimization-ai.png",
    openSlots = {
        [CardSlots.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardSlots.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardSlots.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
    },
    art = nil,
    flavorText = "Efficiency unlocked through understanding.",
}

-- === NEW CARDS ===

definitions["NODE_RES_004"] = {
    id = "NODE_RES_004",
    title = "Solar Collector Array",
    type = CardTypes.RESOURCE,
    buildCost = { material = 2, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } } }
        -- Description: "Grants 1 Energy to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.ENERGY, amount = 1 } } }
        -- Description: "Grants 1 Energy to the activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/solar-collector-array.png",
    openSlots = {
        [CardSlots.LEFT_BOTTOM] = true,   -- Resource Input
        [CardSlots.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardSlots.TOP_RIGHT] = true,     -- Technology Input
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "Converting light into power.",
}

definitions["NODE_TECH_005"] = {
    id = "NODE_TECH_005",
    title = "Fusion Reactor Prototype",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 5, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 2 } },
            { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 2 },
              effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 2 Energy to the owner. If adjacent to 2+ Technology node(s): Grants 1 Energy to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Owner gains 1 VP."
    }),
    vpValue = 2,
    imagePath = "assets/images/fusion-reactor-prototype.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- Tech Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- Tech Output
        [CardSlots.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardSlots.LEFT_BOTTOM] = true,   -- Resource Input
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "The power of a star, contained.",
}

definitions["NODE_KNOW_006"] = {
    id = "NODE_KNOW_006",
    title = "Information Brokerage",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "drawCardsForOwner", options = { amount = 1 } } }
        -- Description: "Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "offerPayment",
                options = {
                    resource = ResourceType.DATA,
                    amount = 1,
                    consequence = {
                        { effect = "forceDiscardCardsActivator", options = { amount = 1 } }
                    }
                }
            }
        }
        -- Description: "May pay 1 Data to: Activator discards 1 card(s)."
    }),
    vpValue = 1,
    imagePath = "assets/images/information-brokerage.png",
    openSlots = {
        [CardSlots.LEFT_TOP] = true,      -- Knowledge Output
        [CardSlots.RIGHT_TOP] = true,     -- Knowledge Input
        [CardSlots.BOTTOM_LEFT] = true,   -- Culture Input
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.TOP_RIGHT] = false,
        [CardSlots.BOTTOM_RIGHT] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "Knowledge is power, especially when selectively shared.",
}

definitions["NODE_TECH_006"] = {
    id = "NODE_TECH_006",
    title = "Network Hub",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { condition = { type = "satisfiedInputs", count = 3 },
              effect = "gainVPForOwner", options = { amount = 2 } }
        }
        -- Description: "Grants 2 Data to the owner. If 3+ input slot(s) are connected: Owner gains 2 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Owner gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/network-hub.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- Tech Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- Tech Output
        [CardSlots.LEFT_BOTTOM] = true,   -- Resource Input
        [CardSlots.BOTTOM_LEFT] = true,   -- Culture Input
        [CardSlots.RIGHT_TOP] = true,     -- Knowledge Input
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.RIGHT_BOTTOM] = false,
    },
    art = nil,
    flavorText = "The nexus point where diverse streams converge.",
}

definitions["NODE_TECH_007"] = {
    id = "NODE_TECH_007",
    title = "Sabotage Drone Bay",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                effect = "offerPayment", -- Offer choice to potentially harm self/others
                options = {
                    resource = ResourceType.ENERGY,
                    amount = 1,
                    consequence = {
                        { effect = "destroyRandomLinkOnNode" } -- Target is the node itself
                    }
                }
            }
        }
        -- Description: "May pay 1 Energy to: Destroy a random convergence link on this node."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "stealResource", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Activator steals 1 Energy from the owner."
    }),
    vpValue = 0,
    imagePath = "assets/images/sabotage-drone-bay.png",
    openSlots = {
        [CardSlots.TOP_RIGHT] = true,     -- Tech Input
        [CardSlots.BOTTOM_RIGHT] = true,  -- Tech Output
        [CardSlots.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardSlots.TOP_LEFT] = false,
        [CardSlots.BOTTOM_LEFT] = false,
        [CardSlots.LEFT_TOP] = false,
        [CardSlots.LEFT_BOTTOM] = false,
        [CardSlots.RIGHT_TOP] = false,
    },
    art = nil,
    flavorText = "Disruption delivered remotely.",
}

return definitions 
