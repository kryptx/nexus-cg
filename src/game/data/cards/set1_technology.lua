-- src/game/data/cards/set1_technology.lua
-- Contains definitions for Set 1 Technology cards.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions = {}

definitions["NODE_TECH_001"] = {
    id = "NODE_TECH_001",
    title = "Basic Processing Unit",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { 
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { condition = { type = "activationChainLength", count = 2 },
              effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Gain 1 Material. If 2+ card(s) were activated in this chain: Gain 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToBoth", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Gain 1 Material."
    }),
    vpValue = 0,
    imagePath = "assets/images/basic-processing-unit.png",
    definedPorts = {
        [CardPorts.BOTTOM_RIGHT] = true, -- Tech Output
        [CardPorts.TOP_RIGHT] = true,    -- Tech Input
        [CardPorts.LEFT_BOTTOM] = true,  -- Resource Input
    },
    art = nil,
    flavorText = "Standard computational core with efficient data routing.",
}

definitions["NODE_TECH_002"] = {
    id = "NODE_TECH_002",
    title = "Advanced Processing Unit",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 2, data = 1 }, 
    activationEffect = CardEffects.createActivationEffect({
        actions = { 
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { condition = { type = "activationChainLength", count = 2 },
              effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Gain 1 Data. If 2+ card(s) were activated in this chain: Gain 1 Energy."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { 
            { effect = "addResourceToBoth", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Owner and activator gain 1 Data."
    }),
    vpValue = 1,
    imagePath = "assets/images/advanced-processing-unit.png",
    definedPorts = {
        [CardPorts.BOTTOM_RIGHT] = true, -- Tech Output
        [CardPorts.TOP_RIGHT] = true,    -- Tech Input
        [CardPorts.LEFT_TOP] = true,     -- Knowledge Output
        [CardPorts.LEFT_BOTTOM] = true, -- Resource Input
        [CardPorts.RIGHT_BOTTOM] = true, -- Resource Output
    },
    art = nil,
    flavorText = "Adaptive processing core with dynamic resource allocation.",
}
definitions["NODE_TECH_003"] = {
    id = "NODE_TECH_003",
    title = "Applied Arts Workshop",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 3, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "satisfiedInputs", count = 2},
              effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.DATA, amount = 1, nodeType = CardTypes.CULTURE } }
        }
        -- Description: "Gain 1 Material. If 2+ input port(s) are connected: Gain 1 Data per Culture node in your network."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Gain 1 Data. Owner gains 1 Material."
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
    flavorText = "Turning inspiration into innovation through cultural integration.",
}

definitions["NODE_TECH_004"] = {
    id = "NODE_TECH_004",
    title = "Automated Fabricator",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "adjacentEmptyCells", count = 2 },
              effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } }
        }
        -- Description: "Gain 1 Material. If adjacent to 2+ empty cell(s): Gain 2 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { condition = { type = "convergenceLinks", count = 2 },
               effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
        }
        -- Description: "Gain 1 Material. If 2+ convergence link(s) attached: Owner gains 1 Energy."
    }),
    vpValue = 1,
    imagePath = "assets/images/automated-fabricator.png",
    definedPorts = {
        [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
    },
    art = nil,
    flavorText = "Optimized for expansion, thrives in open build space.",
}

definitions["NODE_TECH_005"] = {
    id = "NODE_TECH_005",
    title = "Geothermal Tap",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } },
            { condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 2 },
              effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.ENERGY, amount = 1, nodeType = CardTypes.RESOURCE } }
        }
        -- Description: "Gain 1 Energy. If adjacent to 1+ Resource node(s): Gain 1 Energy per Resource node in your network."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { 
            { effect = "addResourceToActivator", options = { resource = ResourceType.ENERGY, amount = 1 } },
        }
        -- Description: "Gain 1 Energy."
    }),
    vpValue = 1, 
    imagePath = "assets/images/geothermal-tap.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- 8: Resource Output
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
    },
    art = nil,
    flavorText = "Harnessing the planet's inner fire through advanced thermal coupling.",
}

definitions["NODE_TECH_006"] = {
    id = "NODE_TECH_006",
    title = "Digital Art Synthesizer",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 2, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } },
            { condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
              effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner draws 1 card. If adjacent to 1+ Culture node(s): Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { 
            { condition = { type = "activatedCardType", cardType = CardTypes.CULTURE, count = 1 },
              effect = "drawCardsForActivator", options = { amount = 2 } }
        }
        -- Description: "If 1+ Culture card(s) were activated in this chain: Draw 2 cards."
    }),
    vpValue = 0,
    imagePath = "assets/images/digital-art-synthesizer.png",
    definedPorts = {
        [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output
        [CardPorts.TOP_RIGHT] = true,     -- 2: Technology Input
        [CardPorts.LEFT_BOTTOM] = true,   -- 6: Resource Input
        [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input
    },
    art = nil,
    flavorText = "Weaving algorithms into aesthetic experience, optimized for cultural integration.",
}

definitions["NODE_TECH_007"] = {
    id = "NODE_TECH_007",
    title = "Quantum Simulation Lab",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 3, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 2 },
                effect = "drawCardsForOwner",
                options = { amount = 2 }
            }
        }
        -- Description: "If Owner pays 2 Data: Owner draws 2 cards."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { condition = { type = "satisfiedInputs", count = 1 },
               effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. If 1+ input port(s) are connected: Owner gains 1 VP."
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
    flavorText = "Modeling reality at its most fundamental level to uncover strategic opportunities.",
}

definitions["NODE_TECH_008"] = {
    id = "NODE_TECH_008",
    title = "Fusion Reactor Prototype",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 5, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 2 } },
            { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 2 },
              effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.ENERGY, amount = 1, nodeType = CardTypes.TECHNOLOGY } }
        }
        -- Description: "Owner gains 2 Energy. If adjacent to 2+ Technology node(s): Owner gains 1 Energy per Technology node in their network."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.ENERGY, amount = 1 } },
             { condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.ENERGY, amount = 1 },
               effect = "gainVPForBoth", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Energy. If Activator pays 1 Energy: Owner and Activator gain 1 VP."
    }),
    vpValue = 2,
    imagePath = "assets/images/fusion-reactor-prototype.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- Tech Input
        [CardPorts.BOTTOM_RIGHT] = true,  -- Tech Output
        [CardPorts.RIGHT_BOTTOM] = true,  -- Resource Output
        [CardPorts.LEFT_BOTTOM] = true,   -- Resource Input
        [CardPorts.LEFT_TOP] = true,      -- Knowledge Output
    },
    art = nil,
    flavorText = "The power of a star, contained and channeled through technological synergy.",
}

definitions["NODE_TECH_009"] = {
    id = "NODE_TECH_009",
    title = "Network Hub",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { condition = { type = "satisfiedInputs", count = 3 },
              effect = "gainVPForOwner", options = { amount = 2 } }
        }
        -- Description: "If 1+ input port(s) are connected: Owner gains 1 Data. If 3+ input port(s) are connected: Owner gains 2 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { condition = { type = "convergenceLinks", count = 1 },
               effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Gain 1 Data. If 1+ convergence link(s) attached: Gain 1 Data."
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
    flavorText = "The nexus point where diverse streams converge, growing stronger with each connection.",
}

definitions["NODE_TECH_010"] = {
    id = "NODE_TECH_010",
    title = "Sabotage Drone Bay",
    type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.ENERGY, amount = 1 }, 
                effect = "ownerStealResourceFromChainOwners",
                options = { resource = ResourceType.MATERIAL, amount = 1 } 
            }
        }
        -- Description: "If you pay 1 Energy: Steal 1 Material from each owner of nodes activated this chain."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "stealResource", options = { resource = ResourceType.ENERGY, amount = 1 } },
             { condition = { type = "convergenceLinks", count = 1 },
               effect = "forceDiscardRandomCardsOwner", options = { amount = 1 } }
        }
        -- Description: "Gain 1 Data. Steal 1 Energy from the owner. If 1+ links attached: Owner discards 1 card."
    }),
    vpValue = 0,
    imagePath = "assets/images/sabotage-drone-bay.png",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,     -- Tech Input
        [CardPorts.RIGHT_BOTTOM] = true,  -- Resource Output
    },
    art = nil,
    flavorText = "Disruption delivered remotely, vulnerable to overextension.",
}
definitions["NODE_TECH_011"] = {
    id = "NODE_TECH_011", title = "Orbital Comm Relay", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
                effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.DATA, amount = 1, nodeType = CardTypes.TECHNOLOGY }
            }
        }
        -- Description: "Owner gains 1 Data. If adjacent to 1+ Technology node(s): Owner gains 1 Data per Technology node in their network."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { 
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            { condition = { type = "activationChainLength", count = 3 },
              effect = "drawCardsForActivator", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. If 3+ card(s) were activated in this chain: Activator draws 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/orbital-comm-relay.png", 
    flavorText = "Broadcasting across the void, strengthening technological networks.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true },
}
definitions["NODE_TECH_012"] = {
    id = "NODE_TECH_012", title = "High-Frequency Trading Hub", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 3, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "activatedCardType", cardType = CardTypes.RESOURCE, count = 2 },
                effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 }
            }
        }
        -- Description: "Gain 1 Data. If 2+ Resource card(s) were activated in this chain: Gain 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
                effect = "forceDiscardRandomCardsOwner", options = { amount = 1 }
            }
        }
        -- Description: "Activator gains 1 Data. If Activator pays 1 Data: Owner discards 1 random card."
    }),
    vpValue = 0, imagePath = "assets/images/high-frequency-trading-hub.png", 
    flavorText = "Exploiting information asymmetry through aggressive data tactics.",
    definedPorts = {
        [CardPorts.TOP_RIGHT] = true,
        [CardPorts.BOTTOM_RIGHT] = true,
        [CardPorts.RIGHT_BOTTOM] = true,
        [CardPorts.BOTTOM_LEFT] = true,
        [CardPorts.TOP_LEFT] = true,
    },
}
definitions["NODE_TECH_013"] = {
    id = "NODE_TECH_013", title = "Planetary Defense Sensor", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { 
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { condition = { type = "adjacentEmptyCells", count = 2 },
              effect = "gainVPForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 Data. If adjacent to 3+ empty cell(s): Owner gains 1 VP."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
                effect = "stealResource", options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "If Activator pays 1 Data: Activator steals 1 Data from the owner."
    }),
    vpValue = 0, imagePath = "assets/images/planetary-defense-sensor.png", 
    flavorText = "Eyes on the sky, most effective with clear sight lines.",
    definedPorts = {
        [CardPorts.LEFT_BOTTOM] = true,
        [CardPorts.LEFT_TOP] = true,
        [CardPorts.TOP_LEFT] = true,
    },
}
definitions["NODE_TECH_014"] = {
    id = "NODE_TECH_014", title = "Tunnel Bore Control", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            {
                condition = { type = "adjacentEmptyCells", count = 2 },
                effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 }
            }
        }
        -- Description: "Owner gains 1 Material. If adjacent to 2+ empty cell(s): Owner gains 2 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { 
            { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "activatedCardType", cardType = CardTypes.RESOURCE, count = 1 },
              effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 Material. If 1+ Resource card(s) were activated in this chain: Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/tunnel-bore-control.png", 
    flavorText = "Expanding the frontier downwards, most efficient in unexplored territory.",
    definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_BOTTOM] = true },
}

definitions["NODE_TECH_015"] = {
    id = "NODE_TECH_015", title = "Predictive Algorithm", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
             { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
             {
                condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
                effect = "drawCardsForOwner", options = { amount = 2 }
             }
        }
        -- Description: "Owner gains 1 Data. If Owner pays 1 Data: Owner draws 2 cards."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { condition = { type = "activationChainLength", count = 4 },
               effect = "gainVPForBoth", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. If 4+ card(s) were activated in this chain: Owner and Activator gain 1 VP."
    }),
    vpValue = 1, imagePath = "assets/images/predictive-algorithm.png", 
    flavorText = "Forecasting the ebb and flow of the network, optimizing for long activation chains.",
    definedPorts = {
        [CardPorts.RIGHT_BOTTOM] = true,
        [CardPorts.TOP_LEFT] = true,
        [CardPorts.BOTTOM_RIGHT] = true,
        [CardPorts.LEFT_TOP] = true,
    },
}
definitions["NODE_TECH_016"] = {
    id = "NODE_TECH_016", title = "Automated Assembly Line", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 4, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { 
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { condition = { type = "activatedCardType", cardType = CardTypes.TECHNOLOGY, count = 1 },
              effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } }
        }
        -- Description: "Owner gains 1 Material. If 1+ Technology card(s) were activated in this chain: Owner gains 2 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             { condition = { type = "convergenceLinks", count = 2 },
               effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } }
        }
        -- Description: "Activator gains 1 Material. If 2+ convergence link(s) attached: Owner gains 2 Material."
    }),
    vpValue = 0, imagePath = "assets/images/automated-assembly-line.png", 
    flavorText = "Mass production optimized for technological supply chains.",
    definedPorts = { 
        [CardPorts.TOP_RIGHT] = true, -- Technology Input
        [CardPorts.TOP_LEFT] = true, -- Technology Output
        [CardPorts.BOTTOM_RIGHT] = true, -- Technology Output
        [CardPorts.RIGHT_BOTTOM] = true, -- Resource Output
        [CardPorts.LEFT_BOTTOM] = true, -- Resource Input
    },
}
definitions["NODE_TECH_017"] = {
    id = "NODE_TECH_017", title = "Resource Scanner Drone", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
                effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.MATERIAL, amount = 1, nodeType = CardTypes.RESOURCE }
            }
        }
        -- Description: "If Owner pays 1 Data: Owner gains 1 Material per Resource node in their network."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             {
                condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
                effect = "gainResourcePerNodeActivator", options = { resource = ResourceType.MATERIAL, amount = 1, nodeType = CardTypes.RESOURCE }
             }
        }
        -- Description: "Activator gains 1 Data. If adjacent to 1+ Resource node(s): Activator gains 1 Material per Resource node in the owner's network."
    }),
    vpValue = 0, imagePath = "assets/images/resource-scanner-drone.png", 
    flavorText = "Searching for exploitable deposits, maximizing extraction efficiency.",
    definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["NODE_TECH_018"] = {
    id = "NODE_TECH_018", title = "Experimental Fusion Injector", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 4, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
                condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.MATERIAL, amount = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 2 }
            },
            {
                condition = { type = "satisfiedInputs", count = 2 },
                effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 }
            }
        }
        -- Description: "If Owner pays 1 Material: Owner gains 2 Energy. If 2+ input port(s) are connected: Owner gains 1 Energy."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.ENERGY, amount = 1 },
               effect = "gainVPForActivator", options = { amount = 2 } }
        }
        -- Description: "Activator gains 1 Data. If Activator pays 1 Energy: Activator gains 2 VP."
    }),
    vpValue = 1, imagePath = "assets/images/experimental-fusion-injector.png", 
    flavorText = "Pushing the boundaries of energy conversion through complex integration.",
    definedPorts = {
        [CardPorts.BOTTOM_RIGHT] = true,
        [CardPorts.LEFT_BOTTOM] = true,
        [CardPorts.RIGHT_TOP] = true,
        [CardPorts.RIGHT_BOTTOM] = true,
    },
}
return definitions 
