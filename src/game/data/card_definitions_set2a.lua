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




return definitions 
