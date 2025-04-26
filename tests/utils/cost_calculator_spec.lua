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
        -- Based on manual calculation in previous step:
        -- Ports: 5 base (2.5 ME) + 2 completed sides (1.0 ME) = 3.5 ME
        -- Activation: 1 Data (conditional) = 1.0 ME; 2 VP (conditional) = 3.0 ME; Total = 4.0 ME
        -- Convergence: 1 Data (unconditional) = -1.0 ME; 1 Data (conditional) = -0.5 ME; Total = -1.5 ME
        -- Total ME: 3.0 (Ports) + 4.0 (Activation) - 1.5 (Convergence) = 5.5 ME
        -- Ratio (1:1): M_adj=1, D_adj=2; Total=3.
        -- M_ME = 5.5*(1/3) = 1.83 -> round(1.83 / 1.0) = 2M.
        -- D_ME = 5.5*(2/3) = 3.66 -> round(3.66 / 2.0) = round(1.83) = 2D.
        local expectedME = 5.5
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

        assert.are.equal(expectedME, totalME, "Total ME calculation mismatch")
        assert.are.same(expectedCost, derivedCost, "Derived cost (M/D) mismatch")
    end)

    -- Add more test cases here for other cards or edge cases
end) 
