-- test/game/card_effects_spec.lua

-- Mock dependencies that aren't directly part of the description generation logic
-- For now, we mainly need CardEffects itself.
-- We might need to mock Card later if tests evolve.
local CardEffects = require("src.game.card_effects")

-- Mock the print function to avoid polluting test output
local print_calls = {}
_G.print = function(...)
    table.insert(print_calls, string.format(...))
end

describe("CardEffects.generateEffectDescription", function()

    before_each(function()
        -- Reset print calls before each test
        print_calls = {}
    end)

    it("should return an empty string for no actions", function()
        local config = { actions = {} }
        assert.are.equal("", CardEffects.generateEffectDescription(config))
    end)

    it("should format a single action without a condition correctly", function()
        local config = {
            actions = {
                { effect = "gainVPForActivator", options = { amount = 2 } }
            }
        }
        assert.are.equal("Gain 2 VP.", CardEffects.generateEffectDescription(config))
    end)

    it("should format multiple actions without conditions correctly", function()
        local config = {
            actions = {
                { effect = "gainVPForActivator", options = { amount = 1 } },
                { effect = "drawCardsForOwner", options = { amount = 3 } }
            }
        }
        -- Each gets its own period as they are separate blocks
        assert.are.equal("Gain 1 VP. Owner draws 3 cards.", CardEffects.generateEffectDescription(config))
    end)

    it("should format a single action with a condition correctly", function()
        local config = {
            actions = {
                { 
                    condition = { type = "convergenceLinks", count = 1 }, 
                    effect = "gainVPForActivator", 
                    options = { amount = 1 } 
                }
            }
        }
        assert.are.equal("If 1+ links attached: Gain 1 VP.", CardEffects.generateEffectDescription(config))
    end)

    it("should group multiple actions with the same condition using semicolons", function()
        local config = {
            actions = {
                { 
                    condition = { type = "convergenceLinks", count = 1 }, 
                    effect = "gainVPForActivator", 
                    options = { amount = 1 } 
                },
                { 
                    condition = { type = "convergenceLinks", count = 1 }, 
                    effect = "drawCardsForActivator", 
                    options = { amount = 2 } 
                }
            }
        }
        assert.are.equal("If 1+ links attached: Gain 1 VP; Draw 2 cards.", CardEffects.generateEffectDescription(config))
    end)
    
    it("should handle multiple actions with different conditions", function()
        local config = {
            actions = {
                { 
                    condition = { type = "convergenceLinks", count = 1 }, 
                    effect = "gainVPForActivator", 
                    options = { amount = 1 } 
                },
                { 
                    condition = { type = "adjacency", nodeType = "Data", count = 2 }, 
                    effect = "drawCardsForActivator", 
                    options = { amount = 2 } 
                }
            }
        }
        assert.are.equal("If 1+ links attached: Gain 1 VP. If adjacent to 2+ Data: Draw 2 cards.", CardEffects.generateEffectDescription(config))
    end)

    it("should correctly format mixed conditional and non-conditional actions", function()
         local config = {
            actions = {
                { 
                    condition = { type = "convergenceLinks", count = 1 }, 
                    effect = "gainVPForActivator", 
                    options = { amount = 1 } 
                },
                { 
                    condition = { type = "convergenceLinks", count = 1 }, 
                    effect = "drawCardsForOwner", 
                    options = { amount = 1 } 
                },
                { 
                    effect = "addResourceToBoth", 
                    options = { resource = CardEffects.ResourceType.ENERGY, amount = 5 } 
                },
                { 
                    condition = { type = "adjacency", nodeType = "Factory", count = 1 }, 
                    effect = "drawCardsForActivator", 
                    options = { amount = 2 } 
                },
                { 
                    effect = "gainVPForOwner", 
                    options = { amount = 10 } 
                }
            }
        }
        local expected = "If 1+ links attached: Gain 1 VP; Owner draws 1 card. Owner and activator gain 5 Energy. If adjacent to 1+ Factory: Draw 2 cards. Owner gains 10 VP."
        assert.are.equal(expected, CardEffects.generateEffectDescription(config))
    end)

    it("should handle unknown effect types gracefully (generate warning)", function()
        local config = {
            actions = { { effect = "unknownEffect", options = {} } }
        }
        assert.are.equal("Unknown other effect.", CardEffects.generateEffectDescription(config))
        assert.are.equal(1, #print_calls)
        assert.match("Warning: Could not generate description for effect type 'unknownEffect'", print_calls[1], 1, true)
    end)
    
    it("should handle unknown condition types gracefully (generate warning)", function()
        local config = {
            actions = { 
                { 
                    condition = { type = "unknownCondition" }, 
                    effect = "gainVPForActivator", 
                    options = { amount = 1 } 
                } 
            }
        }
        assert.are.equal("If condition met: Gain 1 VP.", CardEffects.generateEffectDescription(config))
        assert.are.equal(1, #print_calls)
        assert.match("Warning: Unknown condition type 'unknownCondition' for description.", print_calls[1], 1, true)
    end)

    it("should handle multiple effects with the same condition (from set1_culture)", function()
        local config = {
            actions = {
                {
                    condition = { 
                        type = "paymentOffer", 
                        payer = "Owner", 
                        resource = CardEffects.ResourceType.DATA, 
                        amount = 2 
                    },
                    effects = {
                        { effect = "forceDiscardRandomCardsActivator", options = { amount = 2 } },
                        { effect = "gainVPForOwner", options = { amount = 1 } }
                    }
                }
            }
        }
        -- Both actions share the same payment condition, should be joined by semicolon.
        local expected = "If Owner pays 2 Data: Discard 2 random cards; Owner gains 1 VP."
        assert.are.equal(expected, CardEffects.generateEffectDescription(config))
    end)

    -- Explicit context tests for imperative wording
    it("uses imperative for activator in activation context when explicit context", function()
        local config = { actions = { { effect = "drawCardsForActivator", options = { amount = 2 } } } }
        assert.are.equal("Draw 2 cards.", CardEffects.generateEffectDescription(config, "activation"))
    end)

    it("uses imperative for activator in convergence context when explicit context", function()
        local config = { actions = { { effect = "drawCardsForActivator", options = { amount = 3 } } } }
        assert.are.equal("Draw 3 cards.", CardEffects.generateEffectDescription(config, "convergence"))
    end)

    it("does not use imperative for owner in convergence context", function()
        local config = { actions = { { effect = "drawCardsForOwner", options = { amount = 1 } } } }
        assert.are.equal("Owner draws 1 card.", CardEffects.generateEffectDescription(config, "convergence"))
    end)

    it("uses imperative for activator resource effects in activation context", function()
        local config = { actions = { { effect = "addResourceToActivator", options = { resource = CardEffects.ResourceType.DATA, amount = 3 } } } }
        assert.are.equal("Gain 3 Data.", CardEffects.generateEffectDescription(config, "activation"))
    end)

    it("uses imperative for owner resource effects in activation context", function()
        local config = { actions = { { effect = "addResourceToOwner", options = { resource = CardEffects.ResourceType.ENERGY, amount = 1 } } } }
        assert.are.equal("Gain 1 Energy.", CardEffects.generateEffectDescription(config, "activation"))
    end)

    it("should flatten actions with effects array and group conditional effects correctly", function()
        local config = {
            actions = {
                {
                    condition = { type = "adjacency", nodeType = "Culture", count = 2 },
                    effects = {
                        { effect = "gainVPForActivator", options = { amount = 1 } },
                        { effect = "drawCardsForActivator", options = { amount = 2 } },
                    }
                }
            }
        }
        local expected = "If adjacent to 2+ Culture: Gain 1 VP; Draw 2 cards."
        assert.are.equal(expected, CardEffects.generateEffectDescription(config))
    end)

    it("should flatten actions with effects array without condition correctly", function()
        local config = {
            actions = {
                {
                    effects = {
                        { effect = "gainVPForActivator", options = { amount = 2 } },
                        { effect = "drawCardsForOwner", options = { amount = 1 } },
                    }
                }
            }
        }
        local expected = "Gain 2 VP. Owner draws 1 card."
        assert.are.equal(expected, CardEffects.generateEffectDescription(config))
    end)

    it("should flatten mixed effect and effects structures correctly", function()
        local config = {
            actions = {
                {
                    effects = {
                        { effect = "gainVPForActivator", options = { amount = 1 } },
                        { effect = "drawCardsForActivator", options = { amount = 1 } },
                    }
                },
                {
                    effect = "gainVPForOwner", options = { amount = 3 }
                }
            }
        }
        local expected = "Gain 1 VP. Draw 1 card. Owner gains 3 VP."
        assert.are.equal(expected, CardEffects.generateEffectDescription(config))
    end)

end)

-- Test PaymentOffer grouping under a single condition in a convergenceEffect
describe("PaymentOffer grouping in convergenceEffect", function()
    it("requests a single payment with combined question when multiple effects share condition", function()
        -- Synthetic config with multiple effects under one paymentOffer
        local config = { actions = {
            {
                condition = { type = "paymentOffer", payer = "Activator", resource = CardEffects.ResourceType.DATA, amount = 1 },
                effects = {
                    { effect = "gainVPForActivator", options = { amount = 2 } },
                    { effect = "gainVPForOwner",     options = { amount = 3 } }
                }
            }
        }}
        -- Create convergenceEffect and stub gameService
        local effect = CardEffects.createConvergenceEffect(config)
        local activator = { id = 1, resources = { data = 1 } }
        function activator:spendResource(resource, amount) return true end
        local owner = { id = 2 }
        local sourceNetwork = { owner = owner }
        local sourceNode = {}
        local calls = {}
        local gameService = {
            requestPlayerYesNo = function(self, player, question, callback, displayOptions)
                table.insert(calls, { player = player, question = question, callback = callback })
            end
        }
        -- Trigger payment request
        effect.activate(gameService, activator, sourceNetwork, sourceNode)
        -- Only one payment for grouped effects
        assert.are.equal(1, #calls)
        assert.are.same(activator, calls[1].player)
        assert.are.equal("Pay 1 Data to: Gain 2 VP; Owner gains 3 VP", calls[1].question)
    end)
end)
