-- src/game/data/card_definitions_set2.lua
-- Contains placeholder definitions for Set 2 cards.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions = {}

local placeholderEffect = CardEffects.createActivationEffect({
    actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
    -- Description: "Grants 1 Data to the owner."
})
local placeholderConvergence = CardEffects.createConvergenceEffect({
    actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
    -- Description: "Grants 1 Data to the activator."
})

-- === SET 2 CARDS (Generated) ===

definitions["SET2_001"] = {
    id = "SET2_001", title = "Orbital Comm Relay", type = CardTypes.TECHNOLOGY,
    buildCost = { material = 2, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Data. If adjacent to 1+ Technology node(s): Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Activator gains 1 Data."
    }),
    vpValue = 0, imagePath = "assets/images/orbital-comm-relay.png", flavorText = "Broadcasting across the void.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true },
}
definitions["SET2_002"] = {
    id = "SET2_002", title = "Historical Archive Access", type = CardTypes.CULTURE,
    buildCost = { material = 1, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "drawCardsForOwner", options = { amount = 1 } } }
        -- Description: "Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
                }
            }
        }
        -- Description: "Activator gains 1 Data. If activator pays 1 Data: Activator draws 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/historical-archive-access.png", flavorText = "Lessons from Old Earth.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true },
}
definitions["SET2_003"] = {
    id = "SET2_003", title = "Artisan Collective", type = CardTypes.CULTURE,
    buildCost = { material = 2, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Material. If adjacent to 1+ Culture node(s): Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/artisan-collective.png", flavorText = "Beauty forged from necessity.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_004"] = {
    id = "SET2_004", title = "Xeno-Linguistics Lab", type = CardTypes.KNOWLEDGE,
    buildCost = { material = 1, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            --{ -- Condition 'hasMoreVP' needs implementing in card_effects.lua
            --    condition = { type = "hasMoreVP", target = "activator" },
            --    effect = "drawCardsForOwner", options = { amount = 1 }
            --}
        }
        -- Description: "Owner gains 1 Data. If activator has more VP: Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Activator gains 1 Data."
    }),
    vpValue = 0, imagePath = "assets/images/xeno-linguistics-lab.png", flavorText = "Attempting to understand the 'other'.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_005"] = {
    id = "SET2_005", title = "High-Frequency Trading Hub", type = CardTypes.TECHNOLOGY,
    buildCost = { material = 2, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Data. If adjacent to 1+ Technology node(s): Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = { { effect = "forceDiscardCardsOwner", options = { amount = 1 } } }
                }
            }
        }
        -- Description: "Activator gains 1 Data. If activator pays 1 Data: Owner discards 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/high-frequency-trading-hub.png", flavorText = "Exploiting information asymmetry.",
    definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true },
}
definitions["SET2_006"] = {
    id = "SET2_006", title = "Planetary Defense Sensor", type = CardTypes.TECHNOLOGY,
    buildCost = { material = 2, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = {
                        { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
                        { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
                    }
                }
            }
        }
        -- Description: "If activator pays 1 Data: Activator gains 1 Data. Owner gains 1 Data."
    }),
    vpValue = 0, imagePath = "assets/images/planetary-defense-sensor.png", flavorText = "Eyes on the sky, always watching.",
    definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.LEFT_TOP] = true },
}
definitions["SET2_007"] = {
    id = "SET2_007", title = "Asteroid Mining Claim", type = CardTypes.RESOURCE,
    buildCost = { material = 3, data = 0 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Material. If adjacent to 1+ Resource node(s): Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/asteroid-mining-claim.png", flavorText = "Untapped riches in the belt.",
    definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_008"] = {
    id = "SET2_008", title = "Tunnel Bore Control", type = CardTypes.TECHNOLOGY,
    buildCost = { material = 4, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Material. If adjacent to 1+ Resource node(s): Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/tunnel-bore-control.png", flavorText = "Expanding the frontier, downwards.",
    definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true },
}
definitions["SET2_009"] = {
    id = "SET2_009", title = "Philosopher's Conclave", type = CardTypes.KNOWLEDGE,
    buildCost = { material = 1, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Owner gains 1 Data. Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
                }
            }
        }
        -- Description: "Activator gains 1 Data. If activator pays 1 Data: Activator draws 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/philosopher's-conclave.png", flavorText = "Debating the nature of existence, lightyears from home.",
    definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true },
}
definitions["SET2_010"] = {
    id = "SET2_010", title = "Smuggler's Den", type = CardTypes.CULTURE,
    buildCost = { material = 2, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = {
                        { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
                        { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
                    }
                }
            }
        }
        -- Description: "If activator pays 1 Data: Activator gains 1 Material. Owner gains 1 Data."
    }),
    vpValue = 0, imagePath = "assets/images/smugglers-den.png", flavorText = "Goods acquired through... unofficial channels.",
    definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_011"] = {
    id = "SET2_011", title = "Hydroponics Bay", type = CardTypes.RESOURCE,
    buildCost = { material = 2, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Material. If adjacent to 1+ Culture node(s): Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/hydroponics-bay.png", flavorText = "Sustenance grown under artificial suns.",
    definedPorts = { [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_012"] = {
    id = "SET2_012", title = "AI Ethics Committee", type = CardTypes.KNOWLEDGE,
    buildCost = { material = 1, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Data. If adjacent to 1+ Technology node(s): Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            --{ -- Condition 'hasMoreVP' needs implementing in card_effects.lua
            --    condition = { type = "hasMoreVP", target = "owner" },
            --    effect = "drawCardsForActivator", options = { amount = 1 }
            --}
        }
        -- Description: "Activator gains 1 Data. If Owner has more VP: Activator draws 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/ai-ethics-committee.png", flavorText = "Guiding the minds of the future.",
    definedPorts = { [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_013"] = {
    id = "SET2_013", title = "Deep Space Observatory", type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
                }
            }
        }
        -- Description: "Activator gains 1 Data. If activator pays 1 Data: Activator draws 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/deep-space-observatory.png", flavorText = "Mapping the unknown cosmos.",
    definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_014"] = {
    id = "SET2_014", title = "Quantum Entanglement Comms", type = CardTypes.KNOWLEDGE,
    buildCost = { material = 2, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } } }
        -- Description: "Owner gains 2 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. Owner gains 1 Data."
    }),
    vpValue = 1, imagePath = "assets/images/quantum-entanglement-comms.png", flavorText = "Instantaneous communication, unbound by distance.",
    definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_015"] = {
    id = "SET2_015", title = "Automated Refinery", type = CardTypes.RESOURCE,
    buildCost = { material = 4, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } } }
        -- Description: "Owner gains 2 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 Material. Owner gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/automated-refinery.png", flavorText = "Turning raw ore into usable components.",
    definedPorts = { [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_016"] = {
    id = "SET2_016", title = "Prospector Drone Control", type = CardTypes.RESOURCE,
    buildCost = { material = 3, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.KNOWLEDGE, count = 1 },
                effect = "drawCardsForOwner", options = { amount = 1 }
            }
        }
        -- Description: "Owner gains 1 Material. If adjacent to 1+ Knowledge node(s): Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/prospector-drone-control.png", flavorText = "Seeking out the veins of wealth.",
    definedPorts = { [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}


return definitions 
