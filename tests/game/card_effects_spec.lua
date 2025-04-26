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
        assert.are.equal("Activator gains 2 VP.", CardEffects.generateEffectDescription(config))
    end)

    it("should format multiple actions without conditions correctly", function()
        local config = {
            actions = {
                { effect = "gainVPForActivator", options = { amount = 1 } },
                { effect = "drawCardsForOwner", options = { amount = 3 } }
            }
        }
        -- Each gets its own period as they are separate blocks
        assert.are.equal("Activator gains 1 VP. Owner draws 3 cards.", CardEffects.generateEffectDescription(config))
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
        assert.are.equal("If 1+ links attached: Activator gains 1 VP.", CardEffects.generateEffectDescription(config))
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
        assert.are.equal("If 1+ links attached: Activator gains 1 VP; Activator draws 2 cards.", CardEffects.generateEffectDescription(config))
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
        assert.are.equal("If 1+ links attached: Activator gains 1 VP. If adjacent to 2+ Data nodes: Activator draws 2 cards.", CardEffects.generateEffectDescription(config))
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
        local expected = "If 1+ links attached: Activator gains 1 VP; Owner draws 1 card. Owner and activator gain 5 Energy. If adjacent to 1+ Factory nodes: Activator draws 2 cards. Owner gains 10 VP."
        assert.are.equal(expected, CardEffects.generateEffectDescription(config))
    end)
    
    it("should format offer payment effects correctly (now as conditions)", function()
        local config = {
            actions = {
                -- Action 1: Gain VP, guarded by payment
                {
                    condition = { 
                        type = "paymentOffer", 
                        payer = "Activator", 
                        resource = CardEffects.ResourceType.DATA, 
                        amount = 2 
                    },
                    effect = "gainVPForActivator", 
                    options = { amount = 3 }
                },
                -- Action 2: Draw card, guarded by the *same* payment condition
                 {
                    condition = { 
                        type = "paymentOffer", 
                        payer = "Activator", 
                        resource = CardEffects.ResourceType.DATA, 
                        amount = 2 
                    },
                    effect = "drawCardsForActivator", 
                    options = { amount = 1 }
                }
            }
        }
        -- Both actions share the same condition, so they should be joined by a semicolon.
        local expected = "If Activator pays 2 Data: Activator gains 3 VP; Activator draws 1 card."
        -- Let's use the actual effect names for clarity during refactoring, then fix if needed
        assert.are.equal(expected, CardEffects.generateEffectDescription(config))

        -- Refined expectation with generated descriptions:
        local refined_expected = "If Activator pays 2 Data: Activator gains 3 VP; Activator draws 1 card."
        assert.are.equal(refined_expected, CardEffects.generateEffectDescription(config))
    end)

    it("should handle offer payment with conditions on consequence (now condition on condition)", function()
         local config = {
             actions = {
                 -- Action 1: Gain VP, guarded by payment AND satisfied inputs
                 {
                     -- Note: Current structure doesn't support multiple conditions easily.
                     -- This test highlights a limitation or area for future design.
                     -- For now, let's assume the payment is the primary condition grouping.
                     condition = { 
                         type = "paymentOffer", 
                         payer = "Owner", 
                         resource = CardEffects.ResourceType.MATERIAL, 
                         amount = 1 
                         -- We'd ideally also have: secondary_condition = {type="satisfiedInputs", count=1}
                     },
                     effect = "gainVPForOwner", 
                     options = { amount = 2 }
                 },
                 -- Action 2: Gain resource, guarded by the *same* payment condition
                 {
                     condition = { 
                         type = "paymentOffer", 
                         payer = "Owner", 
                         resource = CardEffects.ResourceType.MATERIAL, 
                         amount = 1 
                         -- secondary_condition = {type="satisfiedInputs", count=1}
                     },
                     effect = "addResourceToOwner", 
                     options = { resource = CardEffects.ResourceType.ENERGY, amount = 1 }
                 }
             }
         }
         -- Actions share the payment condition, joined by semicolon.
         -- The *inner* condition (satisfiedInputs) isn't represented in this structure yet.
         local expected = "If Owner pays 1 Material: Owner gains 2 VP; Owner gains 1 Energy."
         -- Let's use the actual effect names for clarity during refactoring, then fix if needed
         assert.are.equal(expected, CardEffects.generateEffectDescription(config))

         -- Refined expectation (without secondary condition):
         local refined_expected = "If Owner pays 1 Material: Owner gains 2 VP; Owner gains 1 Energy."
         assert.are.equal(refined_expected, CardEffects.generateEffectDescription(config))

         -- TODO: Consider how to represent and evaluate nested/multiple conditions per action.
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
        assert.are.equal("If condition met: Activator gains 1 VP.", CardEffects.generateEffectDescription(config))
        assert.are.equal(1, #print_calls)
        assert.match("Warning: Unknown condition type 'unknownCondition' for description.", print_calls[1], 1, true)
    end)

    it("should handle offer payment with non-conditional consequences (from set1_culture)", function()
        local config = {
            actions = {
                {
                    condition = { 
                        type = "paymentOffer", 
                        payer = "Owner", 
                        resource = CardEffects.ResourceType.DATA, 
                        amount = 2 
                    },
                    effect = "forceDiscardCardsActivator", 
                    options = { amount = 2 }
                },
                {
                     condition = { 
                        type = "paymentOffer", 
                        payer = "Owner", 
                        resource = CardEffects.ResourceType.DATA, 
                        amount = 2 
                    },
                    effect = "gainVPForOwner", 
                    options = { amount = 1 }
                }
            }
        }
        -- Both actions share the same payment condition, should be joined by semicolon.
        local expected = "If Owner pays 2 Data: Activator discards 2 cards; Owner gains 1 VP."
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

end)
