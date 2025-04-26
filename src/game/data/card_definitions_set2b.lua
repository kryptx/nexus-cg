-- src/game/data/card_definitions.lua
-- Contains definitions for all cards in the game.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
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

-- === SET 2 CARDS (Generated Batch 2) ===

definitions["SET2_017"] = {
    id = "SET2_017", title = "Public Forum Interface", type = CardTypes.CULTURE,
    resourceRatio = { material = 1, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            { effect = "drawCardsForOwner", options = { amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
            }
        }
        -- Description: "Owner draws 1 card. If adjacent to 1+ Technology node(s): Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
        -- Description: "Activator draws 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/public-forum-interface.png", flavorText = "Where digital discourse meets physical presence.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true }, -- Cult Out, Tech In, Cult In
}
definitions["SET2_018"] = {
    id = "SET2_018", title = "Bio-Printer Feedstock", type = CardTypes.RESOURCE,
    resourceRatio = { material = 2, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
             {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
                }
            }
        }
        -- Description: "Activator gains 1 Material. If Activator pays 1 Data: Owner gains 1 Data."
    }),
    vpValue = 0, imagePath = "assets/images/bio-printer-feedstock.png", flavorText = "Raw materials for engineered life.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true }, -- Cult Out, Tech In, Res In
}
definitions["SET2_019"] = {
    id = "SET2_019", title = "Propaganda Broadcaster", type = CardTypes.CULTURE,
    resourceRatio = { material = 1, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "forceDiscardCardsOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. Owner discards 1 card." (Owner accepts risk for placement/activation benefit)
    }),
    vpValue = 0, imagePath = "assets/images/propaganda-broadcaster.png", flavorText = "Shaping minds, one broadcast at a time.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.RIGHT_TOP] = true }, -- Cult Out, Tech In, Know In
}
definitions["SET2_020"] = {
    id = "SET2_020", title = "Subterranean Market", type = CardTypes.CULTURE,
    resourceRatio = { material = 3, data = 1 },
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
        actions = {
            {
                effect = "offerPaymentActivator",
                options = {
                    resource = ResourceType.DATA, amount = 1,
                    consequence = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 2 } } }
                }
            }
        }
        -- Description: "If Activator pays 1 Data: Activator gains 2 Material."
    }),
    vpValue = 0, imagePath = "assets/images/subterranean-market.png", flavorText = "Dealings conducted far from prying eyes.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true }, -- Cult Out, Cult In, Res In
}
definitions["SET2_021"] = {
    id = "SET2_021", title = "Memorial Database", type = CardTypes.KNOWLEDGE,
    resourceRatio = { material = 1, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             { effect = "drawCardsForOwner", options = { amount = 1 } }
        }
        -- Description: "Activator gains 1 Data. Owner draws 1 card." (Owner benefits from convergence)
    }),
    vpValue = 1, imagePath = "assets/images/memorial-database.png", flavorText = "Remembering those who came before.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.RIGHT_TOP] = true }, -- Cult Out, Cult In, Know In
}
definitions["SET2_022"] = {
    id = "SET2_022", title = "Resource Cartographer", type = CardTypes.KNOWLEDGE,
    resourceRatio = { material = 1, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "drawCardsForOwner", options = { amount = 1 } } }
        -- Description: "Owner draws 1 card."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
                effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 }
            }
        }
        -- Description: "Activator gains 1 Data. If adjacent to 1+ Resource node(s): Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/resource-cartographer.png", flavorText = "Mapping the veins of the Jovian moons.",
    definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true }, -- Cult Out, Res In, Know In
}
definitions["SET2_023"] = {
    id = "SET2_023", title = "Predictive Algorithm", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 2, data = 3 },
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
    vpValue = 1, imagePath = "assets/images/predictive-algorithm.png", flavorText = "Forecasting the ebb and flow of the network.",
    definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true }, -- Tech In, Tech Out, Know Out
}
definitions["SET2_024"] = {
    id = "SET2_024", title = "Automated Assembly Line", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 4, data = 1 },
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
    vpValue = 0, imagePath = "assets/images/automated-assembly-line.png", flavorText = "Mass production for a burgeoning colony.",
    definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Tech In, Tech Out, Res Out
}
definitions["SET2_025"] = {
    id = "SET2_025", title = "Resource Scanner Drone", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 1, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
             {
                condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
                effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 }
             }
        }
        -- Description: "Activator gains 1 Data. If adjacent to 1+ Resource node(s): Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/resource-scanner-drone.png", flavorText = "Searching for exploitable deposits.",
    definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Tech In, Know Out, Res Out
}
definitions["SET2_026"] = {
    id = "SET2_026", title = "Educational Network", type = CardTypes.KNOWLEDGE,
    resourceRatio = { material = 1, data = 3 },
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
        -- Description: "Activator gains 1 Data. If Activator pays 1 Data: Activator draws 1 card."
    }),
    vpValue = 0, imagePath = "assets/images/educational-network.png", flavorText = "Disseminating knowledge through shared connections.",
    definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true }, -- Cult In, Tech Out, Know Out
}
definitions["SET2_027"] = {
    id = "SET2_027", title = "Cultural Artifact Factory", type = CardTypes.CULTURE,
    resourceRatio = { material = 3, data = 2 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } }
             -- Convergence doesn't give much here, maybe a VP card could leverage having access?
        }
        -- Description: "Activator gains 1 Material."
    }),
    vpValue = 1, imagePath = "assets/images/cultural-artifact-factory.png", flavorText = "Reproducing the symbols of a lost era.",
    definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Cult In, Tech Out, Res Out
}
definitions["SET2_028"] = {
    id = "SET2_028", title = "Resource Distribution Hub", type = CardTypes.RESOURCE,
    resourceRatio = { material = 2, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } }
        }
        -- Description: "Activator gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/resource-distribution-hub.png", flavorText = "Facilitating the flow of vital goods.",
    definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Cult In, Know Out, Res Out
}
definitions["SET2_029"] = {
    id = "SET2_029", title = "Experimental Fusion Injector", type = CardTypes.TECHNOLOGY,
    resourceRatio = { material = 4, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = {
            {
              effect = "offerPaymentOwner",
              options = {
                resource = ResourceType.MATERIAL, amount = 1,
                consequence = { { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } } } -- Rare Energy gain
              }
            }
        }
        -- Description: "If Owner pays 1 Material: Owner gains 1 Energy."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
             { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } }
        }
        -- Description: "Activator gains 1 Data."
    }),
    vpValue = 1, imagePath = "assets/images/experimental-fusion-injector.png", flavorText = "Pushing the boundaries of power generation.",
    definedPorts = { [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true }, -- Tech Out, Res In, Know In
}
definitions["SET2_030"] = {
    id = "SET2_030", title = "Centralized Knowledge Bank", type = CardTypes.KNOWLEDGE,
    resourceRatio = { material = 1, data = 4 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } } }
        -- Description: "Owner gains 2 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "satisfiedInputs", count = 2 }, -- Requires both inputs connected
                effect = "drawCardsForActivator", options = { amount = 1 }
            }
        }
        -- Description: "Activator gains 1 Data. If 2+ input port(s) are connected: Activator draws 1 card."
    }),
    vpValue = 1, imagePath = "assets/images/centralized-knowledge-bank.png", flavorText = "The collective memory of the colony.",
    definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true }, -- Know Out, Res In, Know In
}
definitions["SET2_031"] = {
    id = "SET2_031", title = "Geological Data Analysis", type = CardTypes.KNOWLEDGE,
    resourceRatio = { material = 2, data = 3 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
        -- Description: "Owner gains 1 Data."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
            {
                condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
                effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } -- Owner benefits from convergence if near Res
            }
        }
        -- Description: "Activator gains 1 Data. If adjacent to 1+ Resource node(s): Owner gains 1 Material."
    }),
    vpValue = 0, imagePath = "assets/images/geological-data-analysis.png", flavorText = "Translating seismic readings into resource maps.",
    definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Know Out, Know In, Res Out
}
definitions["SET2_032"] = {
    id = "SET2_032", title = "Logistics Coordination AI", type = CardTypes.KNOWLEDGE,
    resourceRatio = { material = 1, data = 1 },
    activationEffect = CardEffects.createActivationEffect({
        actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
        -- Description: "Owner gains 1 Material."
    }),
    convergenceEffect = CardEffects.createConvergenceEffect({
        actions = {
            { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
            { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } -- Mutually beneficial trade?
        }
        -- Description: "Activator gains 1 Material. Owner gains 1 Data."
    }),
    vpValue = 0, imagePath = "assets/images/logistics-coordination-ai.png", flavorText = "Optimizing the flow of goods across the network.",
    definedPorts = { [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Res In, Know In, Res Out
}

return definitions
