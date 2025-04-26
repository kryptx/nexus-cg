-- src/game/data/cards/set1_knowledge.lua
-- Contains definitions for Set 1 Knowledge cards.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions = {}

definitions["NODE_KNOW_001"] = {
  id = "NODE_KNOW_001",
  title = "Data Relay",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } } }
      -- Description: "Owner gains 1 Data."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { 
        { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
        { condition = { type = "activationChainLength", count = 2 },
          effect = "drawCardsForActivator", options = { amount = 1 } }
      }
      -- Description: "Activator gains 1 Data. If 2+ card(s) were activated in this chain: Activator draws 1 card."
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

definitions["NODE_KNOW_002"] = {
  id = "NODE_KNOW_002",
  title = "Materials Analysis Lab",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 2, data = 3 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
          { condition = { type = "satisfiedInputs", count = 2 },
            effect = "drawCardsForOwner", options = { amount = 1 } }
      }
      -- Description: "Owner gains 1 Data. If 2+ input port(s) are connected: Owner draws 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
            effect = "gainResourcePerNodeActivator", options = { resource = ResourceType.DATA, amount = 1, nodeType = CardTypes.KNOWLEDGE } }
      }
      -- Description: "Activator gains 1 Data. If adjacent to 1+ Resource node(s): Activator gains 1 Data per Knowledge node in the owner's network"
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
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "forceDiscardRandomCardsOwner", options = { amount = 1 } },
          { condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
            effect = "drawCardsForOwner", options = { amount = 2 } }
      }
      -- Description: "Owner discards 1 card. If Owner pays 1 Data: Owner draws 2 cards."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } },
           { effect = "gainVPForOwner", options = { amount = 1 } }
      }
      -- Description: "Activator gains 2 Data. Owner gains 1 VP."
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

definitions["NODE_KNOW_004"] = {
  id = "NODE_KNOW_004",
  title = "AI Research Center",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 2 } },
          { condition = { type = "satisfiedInputs", count = 3 },
            effect = "gainVPForOwner", options = { amount = 1 } }
      }
      -- Description: "Owner gains 2 Data. If 3+ input port(s) are connected: Owner gains 1 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
            effect = "stealResource", options = { resource = ResourceType.DATA, amount = 1 } 
          }
      }
      -- Description: "Activator gains 1 Data. If Activator pays 1 Data: Activator steals 1 Data from the owner."
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


definitions["NODE_KNOW_005"] = {
  id = "NODE_KNOW_005",
  title = "Bio-Research Lab",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
        { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
        { condition = { type = "activatedCardType", count = 1, cardType = CardTypes.KNOWLEDGE },
          effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
      }
      -- Description: "Owner gains 1 Data. If 1+ Knowledge card(s) were activated in this chain: Owner gains 1 Data."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
           { effect = "forceDiscardRandomCardsActivator", options = { amount = 1 } },
           { condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
             effect = "drawCardsForActivator", options = { amount = 2 } }
      }
      -- Description: "Activator gains 1 Data. Activator discards 1 card. If Activator pays 1 Data: Activator draws 2 cards."
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

definitions["NODE_KNOW_006"] = {
  id = "NODE_KNOW_006",
  title = "Historical Simulation Center",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "gainVPForOwner", options = { amount = 1 } },
          { 
            condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 2 },
            effect = "drawCardsForOwner", options = { amount = 2 } 
          }
      }
      -- Description: "Owner gains 1 VP. If Owner pays 2 Data: Owner draws 2 cards."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "gainVPForActivator", options = { amount = 1 } },
           { 
             condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
             effect = "forceDiscardRandomCardsOwner", options = { amount = 1 } 
           }
      }
      -- Description: "Activator gains 1 VP. If Activator pays 1 Data: Owner discards 1 card."
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

definitions["NODE_KNOW_007"] = {
  id = "NODE_KNOW_007",
  title = "Advanced Algorithm Design",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 2, data = 5 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "convergenceLinks", count = 2 },
            effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.DATA, amount = 1, nodeType = CardTypes.KNOWLEDGE } 
          }
      }
      -- Description: "Owner gains 1 Data. If 2+ convergence link(s) attached: Owner gains 1 Data per Knowledge node in their network."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "drawCardsForAllPlayers", options = { amount = 1 } },
           { 
             condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 3 },
             effect = "gainVPForActivator", options = { amount = 2 } 
           }
      }
      -- Description: "All players draw 1 card. If Activator pays 3 Data: Activator gains 2 VP."
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

definitions["NODE_KNOW_008"] = {
  id = "NODE_KNOW_008",
  title = "Resource Optimization AI",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 3, data = 5 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "activatedCardType", count = 2, cardType = CardTypes.RESOURCE },
            effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } 
          }
      }
      -- Description: "Owner gains 1 Data. If 2+ Resource card(s) were activated in this chain: Owner gains 2 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
           { 
             condition = { type = "satisfiedInputs", count = 2 },
             effect = "gainResourcePerNodeActivator", options = { resource = ResourceType.MATERIAL, amount = 1, nodeType = CardTypes.RESOURCE } 
           }
      }
      -- Description: "Activator gains 1 Data. If 2+ input port(s) are connected: Activator gains 1 Material per Resource node in the owner's network."
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

definitions["NODE_KNOW_009"] = {
  id = "NODE_KNOW_009",
  title = "Information Brokerage",
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 2, data = 3 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "drawCardsForOwner", options = { amount = 1 } },
          { 
            condition = { 
                type = "paymentOffer", 
                payer = "Owner", 
                resource = ResourceType.MATERIAL, 
                amount = 2 
            },
            effect = "ownerStealResourceFromChainOwners", 
            options = { resource = ResourceType.DATA, amount = 1 } 
          }
      }
      -- New Description: "Owner draws 1 card. If Owner pays 2 Material: Owner steals 1 Data from each owner of nodes activated this chain."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { 
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.MATERIAL, amount = 1 },
            effect = "stealResource", options = { resource = ResourceType.DATA, amount = 1 } 
          },
          { 
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 2 },
            effect = "drawCardsForActivator", options = { amount = 2 } 
          }
      }
      -- Description: "If Activator pays 1 Material: Activator steals 1 Data from the owner. If Activator pays 2 Data: Activator draws 2 cards."
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

definitions["NODE_KNOW_010"] = {
  id = "NODE_KNOW_010", 
  title = "Xeno-Linguistics Lab", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 3 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { 
            condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
            effect = "drawCardsForOwner", options = { amount = 1 } 
          },
          { 
            condition = { type = "activationChainLength", count = 3 },
            effect = "forceDiscardRandomCardsActivator", options = { amount = 1 } 
          }
      }
      -- Description: "If Owner pays 1 Data: Owner draws 1 card. If 3+ card(s) were activated in this chain: Activator discards 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { 
        { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
        { 
          condition = { type = "convergenceLinks", count = 1 },
          effect = "forceDiscardRandomCardsOwner", options = { amount = 1 } 
        }
      }
      -- Description: "Activator gains 1 Data. If 1+ convergence link(s) attached: Owner discards 1 card."
  }),
  vpValue = 0, 
  imagePath = "assets/images/xeno-linguistics-lab.png", 
  flavorText = "Attempting to understand the 'other'.",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.RIGHT_TOP] = true },
}

definitions["NODE_KNOW_011"] = {
  id = "NODE_KNOW_011", 
  title = "Philosopher's Conclave", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 3 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "adjacentEmptyCells", count = 2 },
            effect = "drawCardsForOwner", options = { amount = 2 } 
          }
      }
      -- Description: "Owner gains 1 Data. If adjacent to 2+ empty cell(s): Owner draws 2 cards."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
            effect = "drawCardsForActivator", options = { amount = 1 } 
          }
      }
      -- Description: "Activator gains 1 Data. If Activator pays 1 Data: Activator draws 1 card."
  }),
  vpValue = 0, 
  imagePath = "assets/images/philosophers-conclave.png", 
  flavorText = "Debating the nature of existence, lightyears from home.",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true },
}

definitions["NODE_KNOW_012"] = {
  id = "NODE_KNOW_012", 
  title = "AI Ethics Committee", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 4 },
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
          { 
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
            effect = "drawCardsForActivator", options = { amount = 1 } 
          }
      }
      -- Description: "Activator gains 1 Data. If Activator pays 1 Data: Activator draws 1 card."
  }),
  vpValue = 0, 
  imagePath = "assets/images/ai-ethics-committee.png", 
  flavorText = "Guiding the minds of the future.",
  definedPorts = { [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_TOP] = true },
}

definitions["NODE_KNOW_013"] = {
  id = "NODE_KNOW_013", 
  title = "Deep Space Observatory", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
        { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
        { 
          condition = { type = "adjacency", nodeType = CardTypes.KNOWLEDGE, count = 1 },
          effect = "drawCardsForOwner", options = { amount = 1 } 
        }
      }
      -- Description: "Owner gains 1 Data. If adjacent to 1+ Knowledge node(s): Owner draws 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "convergenceLinks", count = 1 },
            effect = "gainResourcePerNodeActivator", options = { resource = ResourceType.DATA, amount = 1, nodeType = CardTypes.KNOWLEDGE } 
          }
      }
      -- Description: "Activator gains 1 Data. If 1+ convergence links attached: Activator gains 1 Data per Knowledge node in the owner's network."
  }),
  vpValue = 0, 
  imagePath = "assets/images/deep-space-observatory.png", 
  flavorText = "Mapping the unknown cosmos.",
  definedPorts = { 
    [CardPorts.LEFT_TOP] = true, -- Knowledge Output
    [CardPorts.LEFT_BOTTOM] = true, -- Resource Input
    [CardPorts.TOP_RIGHT] = true    -- Technology Input
  },
}

definitions["NODE_KNOW_014"] = {
  id = "NODE_KNOW_014", 
  title = "Quantum Entanglement Comms", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { 
            condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 2 },
            effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } 
          }
      }
      -- Description: "If Owner pays 2 Data: Owner gains 1 Energy."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "activationChainLength", count = 2 },
            effect = "drawCardsForOwner", options = { amount = 1 } 
          },
          { 
            condition = { type = "activationChainLength", count = 2 },
            effect = "drawCardsForActivator", options = { amount = 1 } 
          }
      }
      -- Description: "Activator gains 1 Data. If 2+ card(s) were activated in this chain: Owner draws 1 card. If 2+ card(s) were activated in this chain: Activator draws 1 card."
  }),
  vpValue = 1, 
  imagePath = "assets/images/quantum-entanglement-comms.png", 
  flavorText = "Instantaneous communication, unbound by distance.",
  definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true },
}

definitions["NODE_KNOW_015"] = {
  id = "NODE_KNOW_015", 
  title = "Memorial Database", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
        { effect = "forceDiscardRandomCardsOwner", options = { amount = 1 } },
        { 
          condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
          effect = "drawCardsForOwner", options = { amount = 2 } 
        }
      }
      -- Description: "Owner discards 1 card. If adjacent to 1+ Culture node(s): Owner draws 2 cards."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
           { effect = "drawCardsForOwner", options = { amount = 1 } },
           { 
             condition = { type = "convergenceLinks", count = 2 },
             effect = "drawCardsForActivator", options = { amount = 1 } 
           }
      }
      -- Description: "Activator gains 1 Data. Owner draws 1 card. If 2+ convergence link(s) attached: Activator draws 1 card."
  }),
  vpValue = 1, 
  imagePath = "assets/images/memorial-database.png", 
  flavorText = "Remembering those who came before.",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.RIGHT_TOP] = true }, -- Cult Out, Cult In, Know In
}

definitions["NODE_KNOW_016"] = {
  id = "NODE_KNOW_016", 
  title = "Resource Cartographer", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
        { effect = "drawCardsForOwner", options = { amount = 1 } },
        { 
          condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
          effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.DATA, amount = 1, nodeType = CardTypes.RESOURCE } 
        }
      }
      -- Description: "Owner draws 1 card. If adjacent to 1+ Resource node(s): Owner gains 1 Data per Resource node in their network."
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
  vpValue = 0, 
  imagePath = "assets/images/resource-cartographer.png", 
  flavorText = "Mapping the veins of the Jovian moons.",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true }, -- Cult Out, Res In, Know In
}

definitions["NODE_KNOW_017"] = {
  id = "NODE_KNOW_017", 
  title = "Educational Network", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 3 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
        { effect = "addResourceToAllPlayers", options = { resource = ResourceType.DATA, amount = 1 } },
        { 
          condition = { type = "convergenceLinks", count = 3 },
          effect = "drawCardsForOwner", options = { amount = 2 } 
        }
      }
      -- Description: "All players gain 1 Data. If 3+ convergence link(s) attached: Owner draws 2 cards."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
            effect = "drawCardsForActivator", options = { amount = 1 } 
          },
          { 
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
            effect = "drawCardsForOwner", options = { amount = 1 } 
          }
      }
      -- Description: "Activator gains 1 Data. If Activator pays 1 Data: Activator draws 1 card. If Activator pays 1 Data: Owner draws 1 card."
  }),
  vpValue = 0, 
  imagePath = "assets/images/educational-network.png", 
  flavorText = "Disseminating knowledge through shared connections.",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true }, -- Cult In, Tech Out, Know Out
}

definitions["NODE_KNOW_018"] = {
  id = "NODE_KNOW_018", 
  title = "Centralized Knowledge Bank", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 4 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { 
            condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 3 },
            effect = "gainVPForOwner", options = { amount = 1 } 
          },
          { 
            condition = { type = "activatedCardType", count = 3, cardType = CardTypes.KNOWLEDGE },
            effect = "drawCardsForOwner", options = { amount = 2 } 
          }
      }
      -- Description: "If Owner pays 3 Data: Owner gains 1 VP. If 3+ Knowledge card(s) were activated in this chain: Owner draws 2 cards."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { effect = "drawCardsForActivator", options = { amount = 1 } },
          { 
            condition = { type = "activationChainLength", count = 3 },
            effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 2 } 
          }
      }
      -- Description: "Activator gains 1 Data. Activator draws 1 card. If 3+ card(s) were activated in this chain: Activator gains 2 Data."
  }),
  vpValue = 1, 
  imagePath = "assets/images/centralized-knowledge-bank.png", 
  flavorText = "The collective memory of the colony.",
  definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true }, -- Know Out, Res In, Know In
}

definitions["NODE_KNOW_019"] = {
  id = "NODE_KNOW_019", 
  title = "Geological Data Analysis", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 2, data = 3 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
            { 
              condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
              effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } 
            },
            { 
              condition = { type = "activatedCardType", count = 1, cardType = CardTypes.RESOURCE },
              effect = "drawCardsForOwner", options = { amount = 1 } 
            }
      }
      -- Description: "If Owner pays 1 Data: Owner gains 1 Material. If 1+ Resource card(s) were activated in this chain: Owner draws 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } 
          },
          { 
            condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
            effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } 
          }
      }
      -- Description: "Activator gains 1 Data. If adjacent to 1+ Resource node(s): Owner gains 1 Material. If adjacent to 1+ Resource node(s): Activator gains 1 Data."
  }),
  vpValue = 0, 
  imagePath = "assets/images/geological-data-analysis.png", 
  flavorText = "Translating seismic readings into resource maps.",
  definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Know Out, Know In, Res Out
}

definitions["NODE_KNOW_020"] = {
  id = "NODE_KNOW_020", 
  title = "Logistics Coordination AI", 
  type = CardTypes.KNOWLEDGE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
        { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
        { 
          condition = { type = "activationChainLength", count = 3 },
          effect = "gainResourcePerNodeOwner", options = { resource = ResourceType.MATERIAL, amount = 1, nodeType = CardTypes.RESOURCE } 
        }
      }
      -- Description: "Owner gains 1 Data. If 3+ card(s) were activated in this chain: Owner gains 1 Material per Resource node in their network."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
            condition = { type = "convergenceLinks", count = 2 },
            effect = "drawCardsForOwner", options = { amount = 1 } 
          }
      }
      -- Description: "Activator gains 1 Material. Owner gains 1 Data. If 2+ convergence link(s) attached: Owner draws 1 card."
  }),
  vpValue = 0, 
  imagePath = "assets/images/logistics-coordination-ai.png", 
  flavorText = "Optimizing the flow of goods across the network.",
  definedPorts = { [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Res In, Know In, Res Out
}

return definitions 
