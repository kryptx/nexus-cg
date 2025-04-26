-- src/game/data/cards/set1_genesis.lua
-- Contains definitions for Set 1 Genesis cards.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions = {}

definitions["NODE_GENESIS_RES_001"] = {
  id = "NODE_GENESIS_RES_001",
  title = "First Spark",
  type = CardTypes.RESOURCE,
  isGenesis = true,
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
      -- Description: "You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
      -- Description: "You gain 1 Material."
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

definitions["NODE_GENESIS_TECH_001"] = {
  id = "NODE_GENESIS_TECH_001",
  title = "Initial Circuit",
  type = CardTypes.TECHNOLOGY,
  isGenesis = true, -- Mark as a Genesis card
  resourceRatio = { material = 1, data = 0 },
  activationEffect = CardEffects.createActivationEffect({
      actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
      -- Description: "You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } }
      -- Description: "You gain 1 Data."
  }),
  vpValue = 0,
  imagePath = "assets/images/genesis-initial-circuit.png", -- Placeholder path
  definedPorts = {
      [CardPorts.BOTTOM_LEFT] = true,   -- 3: Culture Input (Reactor Edge)
      [CardPorts.BOTTOM_RIGHT] = true,  -- 4: Technology Output (Reactor Edge)
      [CardPorts.TOP_LEFT] = true,      -- 1: Culture Output (Top Edge)
      [CardPorts.LEFT_TOP] = true,      -- 5: Knowledge Output (Left Edge)
      [CardPorts.RIGHT_TOP] = true,     -- 7: Knowledge Input (Right Edge)
  },
  art = nil,
  flavorText = "The first connection flickers to life.",
}

definitions["NODE_GENESIS_KNOW_001"] = {
  id = "NODE_GENESIS_KNOW_001",
  title = "Seed Thought",
  type = CardTypes.KNOWLEDGE,
  isGenesis = true,
  resourceRatio = { material = 1, data = 0 },
   activationEffect = CardEffects.createActivationEffect({
      actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
      -- Description: "You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { { effect = "drawCardsForActivator", options = { amount = 1 } } }
      -- Description: "You draw 1 card."
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

definitions["NODE_GENESIS_CULT_001"] = {
  id = "NODE_GENESIS_CULT_001",
  title = "Nascent Meme",
  type = CardTypes.CULTURE,
  isGenesis = true,
  resourceRatio = { material = 1, data = 0 },
   activationEffect = CardEffects.createActivationEffect({
      actions = { { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 1 } } }
      -- Description: "You gain 1 Material."
  }),
  convergenceEffect = CardEffects.createConvergenceEffect({
      actions = { { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } } } 
      -- Description: "You gain 1 Data."
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

return definitions
