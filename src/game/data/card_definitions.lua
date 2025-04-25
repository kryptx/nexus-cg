-- src/game/data/card_definitions.lua
-- Contains definitions for all cards in the game.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
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
    -- GDD 4.1: Reactor has all 8 ports present initially
    definedPorts = {
        [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true,
        [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true,
        [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true,
        [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true,
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
        -- Description: "Grants 1 Data to the activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-initial-circuit.png", -- Placeholder path
    definedPorts = {
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input (Reactor Edge)
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output (Reactor Edge)
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output (Top Edge)
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output (Left Edge)
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output (Right Edge)
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
        -- Description: "Grants 1 Material to the activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-first-spark.png", -- Placeholder path
    definedPorts = {
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input (Reactor Edge)
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output (Reactor Edge)
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input (Top Edge)
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output (Bottom Edge)
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input (Left Edge)
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
        -- Description: "Grants 1 Data to the activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-seed-thought.png", -- Placeholder path
    definedPorts = {
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output (Reactor Edge)
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input (Reactor Edge)
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output (Top Edge)
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input (Bottom Edge)
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input (Right Edge)
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
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } } 
        -- Description: "Grants 1 Data to the activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/genesis-nascent-meme.png", -- Placeholder path
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output (Reactor Edge)
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input (Reactor Edge)
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input (Bottom Edge)
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output (Left Edge)
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output (Right Edge)
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
        -- Description: "Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/basic-processing-unit.png",
    definedPorts = {
        [CardPorts.BOTTOM_RIGHT] = true, -- Tech Output
        [CardPorts.TOP_RIGHT] = true,    -- Tech Input
        [CardPorts.LEFT_BOTTOM] = true,  -- Resource Input
    },
    art = nil,
    flavorText = "Standard computational core.",
}

definitions["NODE_CULT_001"] = {
    id = "NODE_CULT_001",
    title = "Community Forum",
    type = CardTypes.CULTURE,
    buildCost = { material = 1, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } },
            -- Secondary effect: Gain energy if adjacent to Culture
            {
                condition = { type = "adjacency", count = 1, nodeType = CardTypes.CULTURE },
                effect = "addResourceToOwner",
                options = { resource = ResourceType.ENERGY, amount = 1 }
            }
        }
        -- Description: "Owner draws 1 card. If adjacent to 1+ Culture node(s): Owner gains 1 Energy."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
        -- Description: "Activator draws 1 card."
    }),
    vpValue = 0,
    imagePath = "assets/images/community-forum.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,    -- Culture Output
        [CardPorts.BOTTOM_LEFT] = true, -- Culture Input
        [CardPorts.RIGHT_TOP] = true,   -- Knowledge Input
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
        -- Description: "Grants 2 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToBoth", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to both the owner and activator."
    }),
    vpValue = 1,
    imagePath = "assets/images/advanced-processing-unit.png",
    definedPorts = {
        [CardPorts.BOTTOM_RIGHT] = true, -- Tech Output
        [CardPorts.TOP_RIGHT] = true,    -- Tech Input
        [CardPorts.LEFT_TOP] = true,     -- Knowledge Output
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
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
        }
        -- Description: "Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } } }
        -- Description: "Grants 2 Data to the activator."
    }),
    vpValue = 1,
    imagePath = "assets/images/cultural-exchange.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,    -- Culture Output
        [CardPorts.BOTTOM_LEFT] = true, -- Culture Input
        [CardPorts.RIGHT_BOTTOM] = true, -- Resource Output
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
        -- Description: "Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Grants 1 Data to the activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/data-relay.png",
    definedPorts = {
        [CardPorts.LEFT_TOP] = true,    -- Knowledge Output
        [CardPorts.RIGHT_TOP] = true,   -- Knowledge Input
        [CardPorts.LEFT_BOTTOM] = true, -- Resource Input
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
        -- Description: "Grants 2 Material to the owner. If adjacent to 1+ Technology node(s): Grants 1 Energy to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToBoth", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Grants 1 Material to both the owner and activator."
    }),
    vpValue = 0,
    imagePath = "assets/images/materials-depot.png",
    definedPorts = {
        [CardPorts.LEFT_BOTTOM] = true,   -- Resource Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardPorts.TOP_RIGHT] = true,     -- Technology Input
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
            { effect = "drawCardsForOwner", options = { amount = 1 } },
            -- Secondary effect: Gain data if Knowledge card was activated
            {
                condition = { type = "activatedCardType", count = 1, cardType = CardTypes.KNOWLEDGE },
                effect = "addResourceToOwner",
                options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "Owner draws 1 card. If 1+ Knowledge card(s) were activated in this chain: Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } },
        }
        -- Description: "Grants 2 Data to the activator."
    }),
    vpValue = 1,
    imagePath = "assets/images/synaptic-media-hub.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
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
            effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Owner gains 1 Material. If 2+ input port(s) are connected: Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Grants 1 Material to the owner."
    }),
    vpValue = 1, 
    imagePath = "assets/images/applied-arts-workshop.png",
    definedPorts = {
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
    },
    art = nil,
    flavorText = "Turning inspiration into innovation.",
}

definitions["NODE_RES_002"] = {
    id = "NODE_RES_002",
    title = "Automated Drill Site",
    type = CardTypes.RESOURCE,
    buildCost = { material = 4, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
                   { effect = "drawCardsForOwner", options = { amount = 1 } } }
        -- Description: "Grants 1 Material to the owner. Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner."
    }),
    vpValue = 1,
    imagePath = "assets/images/automated-drill-site.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
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
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { condition = { type = "satisfiedInputs", count = 2 },
              effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the owner. If 2+ input port(s) are connected: Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
               effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. If adjacent to 1+ Resource node(s): Grants 1 Material to the owner."
    }),
    vpValue = 1, 
    imagePath = "assets/images/materials-analysis-lab.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
    },
    art = nil,
    flavorText = "Decoding the secrets held within matter.",
}

definitions["NODE_KNOW_003"] = {
    id = "NODE_KNOW_003",
    title = "Historical Archive",
    type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 2 Data to the activator. Owner gains 1 VP."
    }),
    vpValue = 1, 
    imagePath = "assets/images/historical-archive.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
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
            {
                effect = "offerPaymentOwner",
                options = {
                    resource = CardEffects.ResourceType.MATERIAL,
                    amount = 1,
                    consequence = {
                        { effect = "drawCardsForOwner", options = { amount = 1 } },
                        { effect = "gainVPForOwner", options = { amount = 1 } }
                    }
                }
            }
        }
        -- Description: "If Owner pays 1 Material: Owner draws 1 card. Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/holographic-theater.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
    },
    art = nil,
    flavorText = "Where artifice meets artistry.",
}

definitions["NODE_RES_003"] = {
    id = "NODE_RES_003",
    title = "Monument Construction Site",
    type = CardTypes.RESOURCE,
    buildCost = { material = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "activatedCardType", count = 2, cardType = CardTypes.CULTURE },
              effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 Material. If 2+ Culture card(s) were activated in this chain: Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Grants 1 Material to the owner."
    }),
    vpValue = 2, 
    imagePath = "assets/images/monument-construction-site.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
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
        -- Description: "Grants 2 Data to the owner. If 3+ input port(s) are connected: Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Data to the activator. Owner gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/ai-research-center.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
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
        -- Description: "Grants 2 Material to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Grants 1 Material to the activator. Grants 1 Data to the owner."
    }),
    vpValue = 1,
    imagePath = "assets/images/automated-fabricator.png",
    definedPorts = {
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
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
        -- Description: "Grants 2 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "forceDiscardCardsActivator", options = { amount = 1 } } 
        }
        -- Description: "Grants 1 Data to the activator. Activator discards 1 card(s)."
    }),
    vpValue = 1,
    imagePath = "assets/images/bio-research-lab.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
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
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
              effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Grants 1 Energy to the owner. Grants 1 Material to the owner. If adjacent to 1+ Resource node(s): Grants 1 Energy to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.ENERGY, amount = 1 } } }
        -- Description: "Grants 1 Energy to the activator."
    }),
    vpValue = 1, 
    imagePath = "assets/images/geothermal-tap.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
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
        -- Description: "Owner draws 1 card. If adjacent to 1+ Culture node(s): Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
        -- Description: "Activator draws 1 card."
    }),
    vpValue = 0,
    imagePath = "assets/images/digital-art-synthesizer.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
    },
    art = nil,
    flavorText = "Weaving algorithms into aesthetic experience.",
}

definitions["NODE_TECH_KNOW_001"] = {
    id = "NODE_TECH_KNOW_001",
    title = "Quantum Simulation Lab",
    type = CardTypes.TECHNOLOGY,
    buildCost = { material = 6, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "offerPaymentOwner", options = { resource = ResourceType.DATA, amount = 2, consequence = { { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 2 } } } } }
        }
        -- Description: "If owner pays 2 data: Owner gains 2 energy."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. Owner gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/quantum-simulation-lab.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
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
             { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 2 },
                effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 Data. If adjacent to 2+ Technology node(s): Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Activator gains 1 Material. Owner gains 1 Data."
    }),
    vpValue = 1,
    imagePath = "assets/images/applied-aesthetics-studio.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
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
        -- Description: "Owner draws 1 card. Grants 1 Data to the owner."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "drawCardsForActivator", options = { amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator draws 1 card. Owner gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/ethnographic-database.png",
    definedPorts = {
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
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
        -- Description: "Owner gains 2 Material. Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Activator gains 1 Material. Owner gains 1 Data."
    }),
    vpValue = 1,
    imagePath = "assets/images/artisan-guild-workshop.png",
    definedPorts = {
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
    },
    art = nil,
    flavorText = "Master craftsmanship, tangible results.",
}

definitions["NODE_RES_CULT_001"] = {
    id = "NODE_RES_CULT_001",
    title = "Reclamation Art Project",
    type = CardTypes.RESOURCE,
    buildCost = { material = 3, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "gainVPForOwner", options = { amount = 1 } },
            { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 VP. Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Owner gains 1 Material."
    }),
    vpValue = 1,
    imagePath = "assets/images/resource-reclamation-art-project.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
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
        -- Description: "Owner gains 1 Data. Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. Owner gains 1 Material."
    }),
    vpValue = 1,
    imagePath = "assets/images/materials-science-r&d.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
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
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. Owner gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/geological-survey-outpost.png",
    definedPorts = {
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
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
        -- Description: "Owner gains 1 VP. Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "gainVPForActivator", options = { amount = 1 } },
             { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 VP. Owner draws 1 card."
    }),
    vpValue = 1,
    imagePath = "assets/images/historical-simulation-center.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
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
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } },
            { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 2 Data. Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "drawCardsForAllPlayers", options = { amount = 1 } }
        }
        -- Description: "All players draw 1 card."
    }),
    vpValue = 2,
    imagePath = "assets/images/advanced-algorithm-design.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
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
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } },
            { condition = { type = "activatedCardType", count = 2, cardType = CardTypes.RESOURCE },
              effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Owner gains 2 Material. If 2+ Resource card(s) were activated in this chain: Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Activator gains 1 Material. Owner gains 1 Data."
    }),
    vpValue = 1,
    imagePath = "assets/images/resource-optimization-ai.png",
    definedPorts = {
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output
    },
    art = nil,
    flavorText = "Efficiency unlocked through understanding.",
}

-- === NEW CARDS ===

definitions["NODE_RES_004"] = {
    id = "NODE_RES_004",
    title = "Solar Collector Array",
    type = CardTypes.RESOURCE,
    buildCost = { material = 5, data = 1 },
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
    definedPorts = {
        [CardPorts.LEFT_BOTTOM] = true,   -- Resource Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardPorts.TOP_RIGHT] = true,     -- Technology Input
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
             { effect = "addResourceToActivator", options = { resource = ResourceType.ENERGY, amount = 1 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Grants 1 Energy to the activator. Owner gains 1 VP."
    }),
    vpValue = 2,
    imagePath = "assets/images/fusion-reactor-prototype.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- Tech Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- Tech Output
        [CardPorts.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardPorts.LEFT_BOTTOM] = true,   -- Resource Input
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
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } },
            -- Secondary effect: Gain data if chain is long
            {
                condition = { type = "activatedCardType", count = 2, cardType = CardTypes.KNOWLEDGE },
                effect = "addResourceToOwner",
                options = { resource = CardEffects.ResourceType.DATA, amount = 2 }
            }
        }
        -- Description: "Owner draws 1 card. If 2+ Knowledge card(s) were activated in this chain: Owner gains 2 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.MATERIAL,
                    amount = 1,
                    consequence = {
                        { effect = "stealResource", options = { resource = ResourceType.DATA, amount = 1 } }
                    }
                }
            }
        }
        -- Description: "If activator pays 1 Material: Activator steals 1 Data from the owner."
    }),
    vpValue = 1,
    imagePath = "assets/images/information-brokerage.png",
    definedPorts = {
        [CardPorts.LEFT_TOP] = true,      -- Knowledge Output
        [CardPorts.RIGHT_TOP] = true,     -- Knowledge Input
        [CardPorts.BOTTOM_LEFT] = true,   -- Culture Input
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
        -- Description: "Owner gains 1 Data. If 3+ input port(s) are connected: Owner gains 2 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } },
             { effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 2 Data. Owner gains 1 VP."
    }),
    vpValue = 1,
    imagePath = "assets/images/network-hub.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- Tech Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- Tech Output
        [CardPorts.LEFT_BOTTOM] = true,   -- Resource Input
        [CardPorts.BOTTOM_LEFT] = true,   -- Culture Input
        [CardPorts.RIGHT_TOP] = true,     -- Knowledge Input
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
                effect = "offerPaymentActivator", -- Offer choice to potentially harm self/others
                options = {
                    resource = ResourceType.ENERGY,
                    amount = 1,
                    consequence = {
                        { effect = "destroyRandomLinkOnNode" } -- Target is the node itself
                    }
                }
            }
        }
        -- Description: "If activator pays 1 Energy: Destroy a random convergence link on this node."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "stealResource", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. Activator steals 1 Energy from the owner."
    }),
    vpValue = 0,
    imagePath = "assets/images/sabotage-drone-bay.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- Tech Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- Tech Output
        [CardPorts.RIGHT_BOTTOM] = true,  -- Resource Output
    },
    art = nil,
    flavorText = "Disruption delivered remotely.",
}

return definitions 
