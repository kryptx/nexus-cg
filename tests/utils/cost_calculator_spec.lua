-- tests/utils/cost_calculator_spec.lua

describe("CostCalculator", function()
    local CostCalculator = require('src.utils.cost_calculator')
    local Card = require('src.game.card') -- Require the main Card module
    local CardTypes = Card.Type
    local CardPorts = Card.Ports -- Access Ports from the Card table
    local CardEffects = require('src.game.card_effects')
    local ResourceType = CardEffects.ResourceType

    -- Mock card definition for Network Hub (NODE_TECH_009)
    -- Copied from set1_technology.lua for self-contained testing
    local networkHubDef = {
        id = "NODE_TECH_009",
        title = "Network Hub",
        type = CardTypes.TECHNOLOGY,
        resourceRatio = { material = 1, data = 1 },
        activationEffect = CardEffects.createActivationEffect({
            actions = {
                { condition = { type = "satisfiedInputs", count = 1 },
                  effect = "addResourceToOwner", options = { resource = ResourceType.DATA, amount = 1 } },
                { condition = { type = "satisfiedInputs", count = 3 },
                  effect = "gainVPForOwner", options = { amount = 2 } }
            }
        }),
        convergenceEffect = CardEffects.createConvergenceEffect({
            actions = {
                 { effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } },
                 { condition = { type = "convergenceLinks", count = 1 },
                   effect = "addResourceToActivator", options = { resource = ResourceType.DATA, amount = 1 } }
            }
        }),
        vpValue = 1,
        definedPorts = {
            [CardPorts.TOP_RIGHT] = true,
            [CardPorts.BOTTOM_RIGHT] = true,
            [CardPorts.LEFT_BOTTOM] = true,
            [CardPorts.BOTTOM_LEFT] = true,
            [CardPorts.RIGHT_TOP] = true,
        },
    }

    it("should calculate the derived cost for Network Hub correctly based on current logic", function()
        local expectedME = 7.3
        local expectedCost = { material = 2, data = 2 }

        -- Save original print
        local originalPrint = print

        -- Debug: Print CardPorts values using original print
        originalPrint("--- DEBUG: CardPorts Values ---")
        for name, index in pairs(CardPorts) do
            originalPrint(string.format("  %s = %s (%s)", name, tostring(index), type(index)))
        end
        originalPrint("--- DEBUG END ---")

        -- Suppress print for the calculator call
        _G.print = function() end 
        local derivedCost, totalME = CostCalculator.calculateDerivedCost(networkHubDef, networkHubDef.resourceRatio)
        
        -- Restore original print function
        _G.print = originalPrint

        local threshold = 0.01
        local diff = math.abs(expectedME - totalME)
        assert.is_true(diff < threshold, "Total ME calculation mismatch")
        assert.are.same(expectedCost, derivedCost, "Derived cost (M/D) mismatch")
    end)

    -- Add more test cases here for other cards or edge cases
end) 
