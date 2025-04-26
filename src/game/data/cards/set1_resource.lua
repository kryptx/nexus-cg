-- src/game/data/cards/set1_resource.lua
-- Contains definitions for Set 1 Resource cards.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions = {}

definitions["NODE_RES_001"] = {
  id = "NODE_RES_001",
  title = "Materials Depot",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } },
          { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 2 } }
      }
      -- Description: "Owner gains 2 Material. If adjacent to 1+ Technology node(s): Owner gains 2 Energy."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { { effect = "addResourceToBoth", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
      -- Description: "You and the activator gain 1 Material."
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


definitions["NODE_RES_002"] = {
  id = "NODE_RES_002",
  title = "Automated Drill Site",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 4, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          {
             condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.ENERGY, amount = 1 },
             effect = "drawCardsForOwner",
             options = { amount = 1 }
          }
      }
      -- Description: "You gain 1 Material. If you pay 1 Energy: You draw 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You and the activator gain 1 Material."
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

definitions["NODE_RES_003"] = {
  id = "NODE_RES_003",
  title = "Monument Construction Site",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "activatedCardType", count = 2, cardType = CardTypes.CULTURE },
            effect = "gainVPForOwner", options = { amount = 1 } }
      }
      -- Description: "You gain 1 Material. If 2+ Culture card(s) were activated in this chain: You gain 1 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "gainVPForActivator", options = { amount = 1 } },
           { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You and the activator gain 1 Material."
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


definitions["NODE_RES_004"] = {
  id = "NODE_RES_004",
  title = "Reclamation Art Project",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 3, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
            effect = "drawCardsForOwner", options = { amount = 1 } }
      }
      -- Description: "You gain 1 Material. If adjacent to 1+ Culture node(s): You draw 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "gainVPForActivator", options = { amount = 1 } },
           { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You and the activator gain 1 Material."
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

definitions["NODE_RES_005"] = {
  id = "NODE_RES_005",
  title = "Materials Science R&D",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
            effect = "gainVPForOwner", options = { amount = 1 } }
      }
      -- Description: "You gain 1 Data. If adjacent to 1+ Technology node(s): You gain 1 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
           { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You gain 1 Data. The owner gains 1 Material."
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

definitions["NODE_RES_006"] = {
  id = "NODE_RES_006",
  title = "Geological Survey Outpost",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 3, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.KNOWLEDGE, count = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
      }
      -- Description: "You gain 1 Data. If adjacent to 1+ Knowledge node(s): You gain 1 Data."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
           { effect = "gainVPForOwner", options = { amount = 1 } }
      }
      -- Description: "You gain 1 Data. You gain 1 VP."
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


definitions["NODE_RES_007"] = {
  id = "NODE_RES_007",
  title = "Solar Collector Array",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 5, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } },
          { condition = { type = "adjacentEmptyCells", count = 2 },
            effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 } }
      }
      -- Description: "You gain 1 Energy. If adjacent to 2+ empty cell(s): You gain 1 Energy."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
       actions = {
           { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
       }
       -- Description: "You gain 1 Material."
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

definitions["NODE_RES_008"] = {
  id = "NODE_RES_008", title = "Asteroid Mining Claim", type = CardTypes.RESOURCE,
  resourceRatio = { material = 3, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 }
          }
      }
      -- Description: "You gain 1 Material. If adjacent to 1+ Resource node(s): You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          {
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.ENERGY, amount = 1 },
            effect = "addResourceToActivator",
            options = { resource = ResourceType.MATERIAL, amount = 2 }
          }
      }
      -- Description: "If you pay 1 Energy: You gain 2 Material."
  }),
  vpValue = 0, imagePath = "assets/images/asteroid-mining-claim.png", flavorText = "Untapped riches in the belt.",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.RIGHT_BOTTOM] = true },
}

definitions["NODE_RES_009"] = {
  id = "NODE_RES_009", title = "Hydroponics Bay", type = CardTypes.RESOURCE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
            effect = "gainVPForOwner", options = { amount = 1 }
          }
      }
      -- Description: "Owner gains 1 Material. If adjacent to 1+ Culture node(s): Owner gains 1 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
      -- Description: "Owner gains 1 Material."
  }),
  vpValue = 0, imagePath = "assets/images/hydroponics-bay.png", flavorText = "Sustenance grown under artificial suns.",
  definedPorts = { [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true },
}

definitions["NODE_RES_010"] = {
  id = "NODE_RES_010", title = "Automated Refinery", type = CardTypes.RESOURCE,
  resourceRatio = { material = 4, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          {
             condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.ENERGY, amount = 1 },
             effect = "addResourceToOwner",
             options = { resource = ResourceType.MATERIAL, amount = 2 }
          }
      }
      -- Description: "Owner gains 1 Material. If Owner pays 1 Energy: Owner gains 2 Material."
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

definitions["NODE_RES_011"] = {
  id = "NODE_RES_011", title = "Prospector Drone Control", type = CardTypes.RESOURCE,
  resourceRatio = { material = 3, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.KNOWLEDGE, count = 1 },
            effect = "drawCardsForOwner", options = { amount = 1 }
          }
      }
      -- Description: "Owner gains 1 Material. If adjacent to 1+ Knowledge node(s): Owner draws 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          {
            condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
            effect = "drawCardsForActivator",
            options = { amount = 1 }
          }
      }
      -- Description: "If Activator pays 1 Data: Activator draws 1 card."
  }),
  vpValue = 0, imagePath = "assets/images/prospector-drone-control.png", flavorText = "Seeking out the veins of wealth.",
  definedPorts = { [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}

definitions["NODE_RES_012"] = {
  id = "NODE_RES_012", title = "Bio-Printer Feedstock", type = CardTypes.RESOURCE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
          }
      }
      -- Description: "Owner gains 1 Material. If adjacent to 1+ Technology node(s): Owner gains 1 Data."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
           { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
             effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 }
           }
      }
      -- Description: "Activator gains 1 Material. If adjacent to 1+ Technology node(s): Owner gains 1 Data."
  }),
  vpValue = 0, imagePath = "assets/images/bio-printer-feedstock.png", flavorText = "Raw materials for engineered life.",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true }, -- Cult Out, Tech In, Res In
}

definitions["NODE_RES_013"] = {
  id = "NODE_RES_013", title = "Resource Distribution Hub", type = CardTypes.RESOURCE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "convergenceLinks", count = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.ENERGY, amount = 1 }
          }
      }
      -- Description: "Owner gains 1 Material. If 1+ convergence link(s) attached: Owner gains 1 Energy."
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

definitions["NODE_RES_014"] = {
  id = "NODE_RES_014",
  title = "Salvage Operation",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "adjacentEmptyCells", count = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You gain 1 Material. If adjacent to 1+ empty cell(s): You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToBoth", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You and the activator gain 1 Material."
  }),
  vpValue = 0,
  imagePath = "assets/images/salvage-operation.png",
  definedPorts = {
      [CardPorts.LEFT_BOTTOM] = true,
      [CardPorts.RIGHT_BOTTOM] = true,
  },
  art = nil,
  flavorText = "Recovering scrap to fuel progress.",
}

definitions["NODE_RES_015"] = {
  id = "NODE_RES_015",
  title = "Alloy Foundry",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
           { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
           { condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
             effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You gain 1 Material. If adjacent to 1+ Technology node(s): You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { effect = "gainVPForOwner", options = { amount = 1 } }
      }
      -- Description: "Activator gains 1 Material. Owner gains 1 VP."
  }),
  vpValue = 1,
  imagePath = "assets/images/alloy-foundry.png",
  definedPorts = {
      [CardPorts.TOP_RIGHT] = true,
      [CardPorts.LEFT_BOTTOM] = true,
      [CardPorts.RIGHT_BOTTOM] = true,
  },
  art = nil,
  flavorText = "Fusing raw elements into stronger compounds.",
}

definitions["NODE_RES_016"] = {
  id = "NODE_RES_016",
  title = "Resource Exchange Terminal",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 3, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 2 },
            effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } }
      }
      -- Description: "You gain 1 Material. If you pay 2 Data: You gain 2 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
            effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 2 } },
          { effect = "gainVPForOwner", options = { amount = 1 } }
      }
      -- Description: "If Activator pays 1 Data: Activator gains 2 Material. Owner gains 1 VP."
  }),
  vpValue = 0,
  imagePath = "assets/images/resource-exchange-terminal.png",
  definedPorts = {
      [CardPorts.RIGHT_TOP] = true,
      [CardPorts.LEFT_BOTTOM] = true,
      [CardPorts.RIGHT_BOTTOM] = true,
  },
  art = nil,
  flavorText = "Trading info for raw materials.",
}

definitions["NODE_RES_017"] = {
  id = "NODE_RES_017",
  title = "Deep Shaft Excavator",
  type = CardTypes.RESOURCE,
  resourceRatio = { material = 4, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } },
          { condition = { type = "activatedCardType", count = 1, cardType = CardTypes.RESOURCE },
            effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } }
      }
      -- Description: "You gain 2 Material. If a Resource card was activated earlier in this chain: You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          { condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.ENERGY, amount = 1 },
            effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 2 } }
      }
      -- Description: "Activator gains 1 Material. If Activator pays 1 Energy: Activator gains 2 Material."
  }),
  vpValue = 2,
  imagePath = "assets/images/deep-shaft-excavator.png",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true,
      [CardPorts.LEFT_BOTTOM] = true,
      [CardPorts.RIGHT_BOTTOM] = true,
  },
  art = nil,
  flavorText = "Delving beyond the surface for rich veins.",
}

return definitions 
