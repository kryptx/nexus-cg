-- src/game/data/cards/set1_culture.lua
-- Contains definitions for Set 1 Culture cards.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions = {}

definitions["NODE_CULT_001"] = {
  id = "NODE_CULT_001",
  title = "Community Forum",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "drawCardsForOwner", options = { amount = 1 } },
          -- Enhanced effect: Draw additional cards if activated after Knowledge
          {
              condition = { type = "activatedCardType", count = 1, cardType = CardTypes.KNOWLEDGE },
              effect = "drawCardsForOwner",
              options = { amount = 1 }
          }
      }
      -- Description: "Owner draws 1 card. If a Knowledge card was activated in this chain: Owner draws 1 additional card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { 
          { effect = "drawCardsForActivator", options = { amount = 1 } },
          { effect = "drawCardsForOwner", options = { amount = 1 } }
      }
      -- Description: "Activator draws 1 card. Owner draws 1 card."
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


definitions["NODE_CULT_002"] = {
  id = "NODE_CULT_002",
  title = "Cultural Exchange",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          {
              condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
              effect = "drawCardsForOwner", 
              options = { amount = 2 }
          }
      }
      -- Description: "If Owner pays 1 Data: Owner draws 2 cards."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { 
          { effect = "addResourceToBoth", options = { resource = ResourceType.DATA, amount = 1 } },
          { 
              condition = { type = "adjacency", count = 1, nodeType = CardTypes.CULTURE },
              effect = "gainVPForActivator", 
              options = { amount = 1 } 
          }
      }
      -- Description: "Owner and activator gain 1 Data. If adjacent to a Culture node: Activator gains 1 VP."
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

definitions["NODE_CULT_003"] = {
  id = "NODE_CULT_003",
  title = "Synaptic Media Hub",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 3, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { 
              condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.ENERGY, amount = 1 },
              effect = "addResourceToOwner",
              options = { resource = ResourceType.DATA, amount = 2 }
          },
          {
              condition = { type = "satisfiedInputs", count = 2 },
              effect = "drawCardsForOwner",
              options = { amount = 1 }
          }
      }
      -- Description: "If Owner pays 1 Energy: Owner gains 2 Data. If 2+ input ports are connected: Owner draws 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "drawCardsForActivator", options = { amount = 1 } },
           { 
               condition = { type = "activationChainLength", count = 3 },
               effect = "gainVPForActivator", 
               options = { amount = 1 }
           }
      }
      -- Description: "Activator draws 1 card. If 3+ cards were activated in this chain: Activator gains 1 VP."
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

definitions["NODE_CULT_004"] = {
  id = "NODE_CULT_004",
  title = "Holographic Theater",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          {
              condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.MATERIAL, amount = 1 },
              effect = "gainVPForOwner", 
              options = { amount = 2 }
          }
      }
      -- Description: "If Owner pays 1 Material: Owner gains 2 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "gainVPForActivator", options = { amount = 1 } },
           { 
               condition = { type = "adjacentEmptyCells", count = 2 },
               effect = "gainVPForActivator", 
               options = { amount = 1 }
           }
      }
      -- Description: "Activator gains 1 VP. If adjacent to 2+ empty cells: Activator gains 1 additional VP."
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

definitions["NODE_CULT_005"] = {
  id = "NODE_CULT_005",
  title = "Applied Aesthetics Studio",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 3, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          {
              condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 2 },
              effect = "gainVPForOwner", 
              options = { amount = 1 }
          }
      }
      -- Description: "If adjacent to 2+ Technology nodes: Owner gains 1 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { 
               condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.ENERGY, amount = 1 },
               effects = {
                { effect = "gainVPForActivator", options = { amount = 2 } },
                { effect = "gainVPForOwner", options = { amount = 1 } }
               }
           }
      }
      -- Description: "If Activator pays 1 Energy: Activator gains 2 VP; Owner gains 1 VP."
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

definitions["NODE_CULT_006"] = {
  id = "NODE_CULT_006",
  title = "Ethnographic Database",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "drawCardsForOwner", options = { amount = 2 } },
          { 
              condition = { type = "activationChainLength", count = 2 },
              effect = "forceDiscardRandomCardsOwner", 
              options = { amount = 1 }
          }
      }
      -- Description: "Owner draws 2 cards. If 2+ cards were activated in this chain: Owner discards 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "drawCardsForActivator", options = { amount = 1 } },
           { 
               condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
               effects = {
                { effect = "forceDiscardRandomCardsOwner", options = { amount = 1 } },
                { effect = "gainVPForActivator", options = { amount = 1 } }
               }
           }
      }
      -- Description: "Activator draws 1 card. If Activator pays 1 Data: Owner discards 1 card; Activator gains 1 VP."
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

definitions["NODE_CULT_007"] = {
  id = "NODE_CULT_007",
  title = "Artisan Guild Workshop",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 3, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { 
              condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.MATERIAL, amount = 2 },
              effect = "gainVPForOwner", 
              options = { amount = 2 }
          }
      }
      -- Description: "Owner gains 1 Material. If Owner pays 2 Material: Owner gains 2 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
           { 
               condition = { type = "convergenceLinks", count = 2 },
               effect = "gainVPForBoth", 
               options = { amount = 1 }
           }
      }
      -- Description: "Activator gains 1 Material. If 2+ convergence links attached: Owner and Activator gain 1 VP."
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

definitions["NODE_CULT_008"] = {
  id = "NODE_CULT_008", title = "Historical Archive Access", type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
          { effect = "drawCardsForOwner", options = { amount = 1 } },
          {
              condition = { type = "adjacency", nodeType = CardTypes.KNOWLEDGE, count = 1 },
              effect = "drawCardsForOwner", 
              options = { amount = 1 }
          }
      }
      -- Description: "Owner draws 1 card. If adjacent to 1+ Knowledge node: Owner draws 1 additional card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "drawCardsForActivator", options = { amount = 1 } },
          {
              condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
              effects = {
                { effect = "drawCardsForBoth", options = { amount = 1 } }
              }
          }
      }
      -- Description: "Draw 1 card. If you pay 1 Data: Owner and Activator draw 1 card."
  }),
  vpValue = 0, imagePath = "assets/images/historical-archive-access.png", flavorText = "Lessons from Old Earth.",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true,     -- Culture Out
      [CardPorts.BOTTOM_LEFT] = true,  -- Culture In
      [CardPorts.LEFT_TOP] = true,     -- Knowledge Out
      [CardPorts.RIGHT_TOP] = true,    -- Knowledge In
  },
}
definitions["NODE_CULT_009"] = {
  id = "NODE_CULT_009", title = "Artisan Collective", type = CardTypes.CULTURE,
  resourceRatio = { material = 3, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          {
              condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 2 },
              effect = "gainVPForOwner", 
              options = { amount = 1 }
          }
      }
      -- Description: "Owner gains 1 Material. If adjacent to 2+ Culture nodes: Owner gains 1 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { 
          { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          {
              condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 1 },
              effect = "gainVPForActivator", 
              options = { amount = 1 }
          }
      }
      -- Description: "Activator gains 1 Material. If adjacent to 1+ Culture node: Activator gains 1 VP."
  }),
  vpValue = 0, imagePath = "assets/images/artisan-collective.png", flavorText = "Beauty forged from necessity.",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true, -- Culture Output
      [CardPorts.LEFT_BOTTOM] = true, -- Resource Input
      [CardPorts.RIGHT_BOTTOM] = true, -- Resource Output
      [CardPorts.BOTTOM_RIGHT] = true, -- Technology Output
      [CardPorts.BOTTOM_LEFT] = true -- Culture Input
  },
}

definitions["NODE_CULT_010"] = {
  id = "NODE_CULT_010", title = "Smuggler's Den", type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { 
          { condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
            effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } }
      }
      -- Description: "If Owner pays 1 Data: Owner gains 2 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          {
              condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
              effect = "stealResource", 
              options = { resource = ResourceType.MATERIAL, amount = 1 }
          },
          {
              condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.DATA, amount = 1 },
              effect = "gainVPForActivator", 
              options = { amount = 1 }
          }
      }
      -- Description: "If activator pays 1 Data: Activator steals 1 Material from the owner; Activator gains 1 VP."
  }),
  vpValue = 0, imagePath = "assets/images/smugglers-den.png", flavorText = "Goods acquired through... unofficial channels.",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.RIGHT_BOTTOM] = true, [CardPorts.BOTTOM_RIGHT] = true },
}
definitions["NODE_CULT_011"] = {
  id = "NODE_CULT_011", title = "Public Forum Interface", type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "drawCardsForOwner", options = { amount = 1 } },
          {
              condition = { type = "adjacency", nodeType = CardTypes.TECHNOLOGY, count = 1 },
              effect = "drawCardsForAllPlayers", 
              options = { amount = 1 }
          }
      }
      -- Description: "Owner draws 1 card. If adjacent to 1+ Technology node: All players draw 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { 
          { effect = "drawCardsForActivator", options = { amount = 1 } },
          {
              condition = { type = "activationChainLength", count = 3 },
              effect = "gainVPForBoth", 
              options = { amount = 1 }
          }
      }
      -- Description: "Activator draws 1 card. If 3+ cards were activated in this chain: Owner and Activator gain 1 VP."
  }),
  vpValue = 0, imagePath = "assets/images/public-forum-interface.png", flavorText = "Where digital discourse meets physical presence.",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true }, -- Cult Out, Tech In, Cult In
}
definitions["NODE_CULT_012"] = {
  id = "NODE_CULT_012", title = "Propaganda Broadcaster", type = CardTypes.CULTURE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          {
            condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.DATA, amount = 1 },
            effects = {
              { effect = "forceDiscardRandomCardsActivator", options = { amount = 1 } },
              { effect = "gainVPForOwner", options = { amount = 1 } }
            }
          }
      }
      -- Description: "If you pay 1 Data: Discard 1 card; Gain 1 VP."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
           { 
               condition = { type = "convergenceLinks", count = 1 },
               effect = "forceDiscardRandomCardsOwner", 
               options = { amount = 1 }
           }
      }
      -- Description: "Activator gains 1 Data. If 1+ convergence link attached: Owner discards 1 card."
  }),
  vpValue = 0, imagePath = "assets/images/propaganda-broadcaster.png", flavorText = "Shaping minds, one broadcast at a time.",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true, -- Culture Output
      [CardPorts.TOP_RIGHT] = true, -- Technology Input
      [CardPorts.RIGHT_TOP] = true, -- Knowledge Input
      [CardPorts.BOTTOM_LEFT] = true -- Culture Input
  },
}
definitions["NODE_CULT_013"] = {
  id = "NODE_CULT_013", title = "Subterranean Market", type = CardTypes.CULTURE,
  resourceRatio = { material = 3, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          {
              condition = { type = "convergenceLinks", count = 1 },
              effect = "addResourceToOwner",
              options = { resource = ResourceType.MATERIAL, amount = 1 }
          }
      }
      -- Description: "Owner gains 1 Material. If 1+ convergence link attached: Owner gains 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          {
              condition = { type = "paymentOffer", payer = "Activator", resource = ResourceType.ENERGY, amount = 1 },
              effects = {
                { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 2 } },
                { effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } }
              }
          }
      }
      -- Description: "If you pay 1 Energy: Gain 2 Material; Owner gains 1 Data."
  }),
  vpValue = 0, imagePath = "assets/images/subterranean-market.png", flavorText = "Dealings conducted far from prying eyes.",
  definedPorts = {
    [CardPorts.TOP_LEFT] = true,
    [CardPorts.TOP_RIGHT] = true,
    [CardPorts.BOTTOM_LEFT] = true,
    [CardPorts.LEFT_BOTTOM] = true,
    [CardPorts.RIGHT_BOTTOM] = true,
  }, -- Cult Out, Tech In, Cult In, Res In, Res Out
}

definitions["NODE_CULT_014"] = {
  id = "NODE_CULT_014", title = "Cultural Artifact Factory", type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } },
          {
              condition = { type = "adjacency", nodeType = CardTypes.CULTURE, count = 2 },
              effect = "drawCardsForOwner",
              options = { amount = 1 }
          }
      }
      -- Description: "Owner gains 1 Material. If adjacent to 2+ Culture nodes: Owner draws 1 card."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
           { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } },
           {
               condition = { type = "adjacency", nodeType = CardTypes.RESOURCE, count = 1 },
               effect = "gainVPForActivator", 
               options = { amount = 1 }
           }
      }
      -- Description: "Activator gains 1 Material. If adjacent to 1+ Resource node: Activator gains 1 VP."
  }),
  vpValue = 1, imagePath = "assets/images/cultural-artifact-factory.png", flavorText = "Reproducing the symbols of a lost era.",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_BOTTOM] = true }, -- Cult In, Tech Out, Res Out
}

-- Adding four new culture cards to reach 18 and improve port balance

definitions["NODE_CULT_015"] = {
  id = "NODE_CULT_015",
  title = "Interactive Mural",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "drawCardsForOwner", options = { amount = 1 } },
      }
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "gainVPForActivator", options = { amount = 1 } },
      }
  }),
  vpValue = 0,
  imagePath = "assets/images/interactive-mural.png",
  flavorText = "Art that responds to its audience.",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true,      -- Culture Output
      [CardPorts.TOP_RIGHT] = true,     -- Technology Input
      [CardPorts.BOTTOM_LEFT] = true,   -- Culture Input
      [CardPorts.BOTTOM_RIGHT] = true,  -- Technology Output
      [CardPorts.RIGHT_TOP] = true,     -- Knowledge Input
  },
}

definitions["NODE_CULT_016"] = {
  id = "NODE_CULT_016",
  title = "Cultural Symposium",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 2, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "gainVPForOwner", options = { amount = 1 } },
      }
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "drawCardsForActivator", options = { amount = 1 } },
      }
  }),
  vpValue = 1,
  imagePath = "assets/images/cultural-symposium.png",
  flavorText = "Ideas converge to forge new paths.",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true,      -- Culture Output
      [CardPorts.BOTTOM_LEFT] = true,   -- Culture Input
      [CardPorts.LEFT_TOP] = true,      -- Knowledge Output
      [CardPorts.BOTTOM_RIGHT] = true,  -- Technology Output
  },
}

definitions["NODE_CULT_017"] = {
  id = "NODE_CULT_017",
  title = "Virtual Coliseum",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 2 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { condition = { type = "paymentOffer", payer = "Owner", resource = ResourceType.MATERIAL, amount = 2 },
            effect = "gainVPForOwner", options = { amount = 1 }
          }
          -- Description: "If Owner pays 2 Material: Owner gains 1 VP."
      }
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "gainVPForActivator", options = { amount = 1 } },
      }
  }),
  vpValue = 0,
  imagePath = "assets/images/virtual-coliseum.png",
  flavorText = "Spectacles that transcend space-time.",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true,      -- Culture Output
      [CardPorts.BOTTOM_LEFT] = true,   -- Culture Input
      [CardPorts.LEFT_TOP] = true,      -- Knowledge Output
  },
}

definitions["NODE_CULT_018"] = {
  id = "NODE_CULT_018",
  title = "Cultural Archive",
  type = CardTypes.CULTURE,
  resourceRatio = { material = 1, data = 1 },
  activationEffect = CardEffects.createActivationEffect({
      actions = {
          { effect = "drawCardsForOwner", options = { amount = 2 } },
      }
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = {
          { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
      }
  }),
  vpValue = 1,
  imagePath = "assets/images/cultural-archive.png",
  flavorText = "Preserving the echoes of civilization.",
  definedPorts = {
      [CardPorts.TOP_LEFT] = true,      -- Culture Output
      [CardPorts.BOTTOM_LEFT] = true,   -- Culture Input
      [CardPorts.LEFT_TOP] = true,      -- Knowledge Output
      [CardPorts.RIGHT_TOP] = true,     -- Knowledge Input
  },
}

return definitions 
