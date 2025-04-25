-- src/game/data/card_definitions_set2c.lua
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

definitions["SET2_PLACEHOLDER_033"] = {
  id = "SET2_PLACEHOLDER_033", title = "Placeholder 33", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_034"] = {
  id = "SET2_PLACEHOLDER_034", title = "Placeholder 34", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_035"] = {
  id = "SET2_PLACEHOLDER_035", title = "Placeholder 35", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_036"] = {
  id = "SET2_PLACEHOLDER_036", title = "Placeholder 36", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_037"] = {
  id = "SET2_PLACEHOLDER_037", title = "Placeholder 37", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_038"] = {
  id = "SET2_PLACEHOLDER_038", title = "Placeholder 38", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_039"] = {
  id = "SET2_PLACEHOLDER_039", title = "Placeholder 39", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_040"] = {
  id = "SET2_PLACEHOLDER_040", title = "Placeholder 40", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_041"] = {
  id = "SET2_PLACEHOLDER_041", title = "Placeholder 41", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_042"] = {
  id = "SET2_PLACEHOLDER_042", title = "Placeholder 42", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_043"] = {
  id = "SET2_PLACEHOLDER_043", title = "Placeholder 43", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_044"] = {
  id = "SET2_PLACEHOLDER_044", title = "Placeholder 44", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_045"] = {
  id = "SET2_PLACEHOLDER_045", title = "Placeholder 45", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_046"] = {
  id = "SET2_PLACEHOLDER_046", title = "Placeholder 46", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_047"] = {
  id = "SET2_PLACEHOLDER_047", title = "Placeholder 47", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_048"] = {
  id = "SET2_PLACEHOLDER_048", title = "Placeholder 48", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_049"] = {
  id = "SET2_PLACEHOLDER_049", title = "Placeholder 49", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_050"] = {
  id = "SET2_PLACEHOLDER_050", title = "Placeholder 50", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_051"] = {
  id = "SET2_PLACEHOLDER_051", title = "Placeholder 51", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_052"] = {
  id = "SET2_PLACEHOLDER_052", title = "Placeholder 52", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_053"] = {
  id = "SET2_PLACEHOLDER_053", title = "Placeholder 53", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_054"] = {
  id = "SET2_PLACEHOLDER_054", title = "Placeholder 54", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_055"] = {
  id = "SET2_PLACEHOLDER_055", title = "Placeholder 55", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_056"] = {
  id = "SET2_PLACEHOLDER_056", title = "Placeholder 56", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_057"] = {
  id = "SET2_PLACEHOLDER_057", title = "Placeholder 57", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_058"] = {
  id = "SET2_PLACEHOLDER_058", title = "Placeholder 58", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_059"] = {
  id = "SET2_PLACEHOLDER_059", title = "Placeholder 59", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_060"] = {
  id = "SET2_PLACEHOLDER_060", title = "Placeholder 60", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_061"] = {
  id = "SET2_PLACEHOLDER_061", title = "Placeholder 61", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_062"] = {
  id = "SET2_PLACEHOLDER_062", title = "Placeholder 62", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_063"] = {
  id = "SET2_PLACEHOLDER_063", title = "Placeholder 63", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_064"] = {
  id = "SET2_PLACEHOLDER_064", title = "Placeholder 64", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_065"] = {
  id = "SET2_PLACEHOLDER_065", title = "Placeholder 65", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_066"] = {
  id = "SET2_PLACEHOLDER_066", title = "Placeholder 66", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_067"] = {
  id = "SET2_PLACEHOLDER_067", title = "Placeholder 67", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_068"] = {
  id = "SET2_PLACEHOLDER_068", title = "Placeholder 68", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_069"] = {
  id = "SET2_PLACEHOLDER_069", title = "Placeholder 69", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_070"] = {
  id = "SET2_PLACEHOLDER_070", title = "Placeholder 70", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_071"] = {
  id = "SET2_PLACEHOLDER_071", title = "Placeholder 71", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_072"] = {
  id = "SET2_PLACEHOLDER_072", title = "Placeholder 72", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_073"] = {
  id = "SET2_PLACEHOLDER_073", title = "Placeholder 73", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_074"] = {
  id = "SET2_PLACEHOLDER_074", title = "Placeholder 74", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_075"] = {
  id = "SET2_PLACEHOLDER_075", title = "Placeholder 75", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_076"] = {
  id = "SET2_PLACEHOLDER_076", title = "Placeholder 76", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_077"] = {
  id = "SET2_PLACEHOLDER_077", title = "Placeholder 77", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_078"] = {
  id = "SET2_PLACEHOLDER_078", title = "Placeholder 78", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_079"] = {
  id = "SET2_PLACEHOLDER_079", title = "Placeholder 79", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_080"] = {
  id = "SET2_PLACEHOLDER_080", title = "Placeholder 80", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_081"] = {
  id = "SET2_PLACEHOLDER_081", title = "Placeholder 81", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_082"] = {
  id = "SET2_PLACEHOLDER_082", title = "Placeholder 82", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_083"] = {
  id = "SET2_PLACEHOLDER_083", title = "Placeholder 83", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_084"] = {
  id = "SET2_PLACEHOLDER_084", title = "Placeholder 84", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_085"] = {
  id = "SET2_PLACEHOLDER_085", title = "Placeholder 85", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_086"] = {
  id = "SET2_PLACEHOLDER_086", title = "Placeholder 86", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_087"] = {
  id = "SET2_PLACEHOLDER_087", title = "Placeholder 87", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_088"] = {
  id = "SET2_PLACEHOLDER_088", title = "Placeholder 88", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_089"] = {
  id = "SET2_PLACEHOLDER_089", title = "Placeholder 89", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_090"] = {
  id = "SET2_PLACEHOLDER_090", title = "Placeholder 90", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_091"] = {
  id = "SET2_PLACEHOLDER_091", title = "Placeholder 91", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_092"] = {
  id = "SET2_PLACEHOLDER_092", title = "Placeholder 92", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_093"] = {
  id = "SET2_PLACEHOLDER_093", title = "Placeholder 93", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_094"] = {
  id = "SET2_PLACEHOLDER_094", title = "Placeholder 94", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_095"] = {
  id = "SET2_PLACEHOLDER_095", title = "Placeholder 95", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_096"] = {
  id = "SET2_PLACEHOLDER_096", title = "Placeholder 96", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_097"] = {
  id = "SET2_PLACEHOLDER_097", title = "Placeholder 97", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_098"] = {
  id = "SET2_PLACEHOLDER_098", title = "Placeholder 98", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_099"] = {
  id = "SET2_PLACEHOLDER_099", title = "Placeholder 99", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_100"] = {
  id = "SET2_PLACEHOLDER_100", title = "Placeholder 100", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_101"] = {
  id = "SET2_PLACEHOLDER_101", title = "Placeholder 101", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_102"] = {
  id = "SET2_PLACEHOLDER_102", title = "Placeholder 102", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_103"] = {
  id = "SET2_PLACEHOLDER_103", title = "Placeholder 103", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_104"] = {
  id = "SET2_PLACEHOLDER_104", title = "Placeholder 104", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_105"] = {
  id = "SET2_PLACEHOLDER_105", title = "Placeholder 105", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_106"] = {
  id = "SET2_PLACEHOLDER_106", title = "Placeholder 106", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_107"] = {
  id = "SET2_PLACEHOLDER_107", title = "Placeholder 107", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_108"] = {
  id = "SET2_PLACEHOLDER_108", title = "Placeholder 108", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_109"] = {
  id = "SET2_PLACEHOLDER_109", title = "Placeholder 109", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_110"] = {
  id = "SET2_PLACEHOLDER_110", title = "Placeholder 110", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_111"] = {
  id = "SET2_PLACEHOLDER_111", title = "Placeholder 111", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_112"] = {
  id = "SET2_PLACEHOLDER_112", title = "Placeholder 112", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_113"] = {
  id = "SET2_PLACEHOLDER_113", title = "Placeholder 113", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_114"] = {
  id = "SET2_PLACEHOLDER_114", title = "Placeholder 114", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_115"] = {
  id = "SET2_PLACEHOLDER_115", title = "Placeholder 115", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_116"] = {
  id = "SET2_PLACEHOLDER_116", title = "Placeholder 116", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_117"] = {
  id = "SET2_PLACEHOLDER_117", title = "Placeholder 117", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_118"] = {
  id = "SET2_PLACEHOLDER_118", title = "Placeholder 118", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_119"] = {
  id = "SET2_PLACEHOLDER_119", title = "Placeholder 119", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_120"] = {
  id = "SET2_PLACEHOLDER_120", title = "Placeholder 120", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_121"] = {
  id = "SET2_PLACEHOLDER_121", title = "Placeholder 121", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_122"] = {
  id = "SET2_PLACEHOLDER_122", title = "Placeholder 122", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_123"] = {
  id = "SET2_PLACEHOLDER_123", title = "Placeholder 123", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_124"] = {
  id = "SET2_PLACEHOLDER_124", title = "Placeholder 124", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_125"] = {
  id = "SET2_PLACEHOLDER_125", title = "Placeholder 125", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_126"] = {
  id = "SET2_PLACEHOLDER_126", title = "Placeholder 126", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_127"] = {
  id = "SET2_PLACEHOLDER_127", title = "Placeholder 127", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_128"] = {
  id = "SET2_PLACEHOLDER_128", title = "Placeholder 128", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true },
}
definitions["SET2_PLACEHOLDER_129"] = {
  id = "SET2_PLACEHOLDER_129", title = "Placeholder 129", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_130"] = {
  id = "SET2_PLACEHOLDER_130", title = "Placeholder 130", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_131"] = {
  id = "SET2_PLACEHOLDER_131", title = "Placeholder 131", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_132"] = {
  id = "SET2_PLACEHOLDER_132", title = "Placeholder 132", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.BOTTOM_LEFT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
definitions["SET2_PLACEHOLDER_195"] = {
  id = "SET2_PLACEHOLDER_195", title = "Placeholder 195", type = CardTypes.TECHNOLOGY,
  buildCost = { material = 1, data = 1 },
  activationEffect = placeholderEffect, convergenceEffect = placeholderConvergence,
  vpValue = 0, imagePath = "assets/images/placeholder.png", flavorText = "Placeholder",
  definedPorts = { [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true, [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true, [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true, [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true },
}
