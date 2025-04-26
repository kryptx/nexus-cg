-- test_specific_card.lua
-- Test script to verify the resource ratio calculation for a specific problematic card

local CostCalculator = require('src.utils.cost_calculator')
local ResourceType = require('src.game.card_effects').ResourceType
local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports

-- Create test card with 3:1 material:data ratio and approximately 7 ME
local testCard = {
    id = "TEST_PROBLEM_CARD",
    type = CardTypes.RESOURCE,
    resourceRatio = { material = 3, data = 1 },
    -- Add some ports for calculating ME
    definedPorts = {
        [CardPorts.LEFT_BOTTOM] = true,
        [CardPorts.RIGHT_BOTTOM] = true,
        [CardPorts.TOP_RIGHT] = true,
    },
    -- Add some effects worth about 6 ME
    activationEffect = {
        config = {
            actions = {
                { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 6 } }
            }
        }
    }
}

print("===== Testing Problematic Card with 3:1 Ratio =====")
local cost, totalME = CostCalculator.calculateDerivedCost(testCard, testCard.resourceRatio)
print(string.format("Card with 3:1 ratio at total ME of %.2f - Final Cost: %d Material, %d Data", 
    totalME, cost.material, cost.data))
print(string.format("Actual ratio: %.1f:%.1f", cost.material, cost.data))

-- Try with stronger material preference
local testCard2 = {
    id = "TEST_PROBLEM_CARD_5_TO_1",
    type = CardTypes.RESOURCE,
    resourceRatio = { material = 5, data = 1 },
    definedPorts = testCard.definedPorts,
    activationEffect = testCard.activationEffect
}

print("\n===== Testing with 5:1 Ratio =====")
local cost2, totalME2 = CostCalculator.calculateDerivedCost(testCard2, testCard2.resourceRatio)
print(string.format("Card with 5:1 ratio at total ME of %.2f - Final Cost: %d Material, %d Data", 
    totalME2, cost2.material, cost2.data))
print(string.format("Actual ratio: %.1f:%.1f", cost2.material, cost2.data)) 
