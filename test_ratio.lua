-- test_ratio.lua
-- Test script to verify the resource ratio calculation

local CostCalculator = require('src.utils.cost_calculator')
local ResourceType = require('src.game.card_effects').ResourceType
local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports

-- Create a simple test card with 3:1 material/data ratio
local testCard = {
    id = "TEST_CARD_3_TO_1",
    type = CardTypes.RESOURCE,
    resourceRatio = { material = 3, data = 1 },
    -- Add some ports for calculating ME
    definedPorts = {
        [CardPorts.LEFT_BOTTOM] = true,
        [CardPorts.RIGHT_BOTTOM] = true,
        [CardPorts.TOP_RIGHT] = true,
    },
    -- Add some effects worth about 3 ME
    activationEffect = {
        config = {
            actions = {
                { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = 2 } }
            }
        }
    }
}

-- Helper function to create a test card with specific ME value
local function createTestCard(id, material_ratio, data_ratio, targetME)
    local card = {
        id = id,
        type = CardTypes.RESOURCE,
        resourceRatio = { material = material_ratio, data = data_ratio },
        -- Add ports and effects
        definedPorts = {
            [CardPorts.LEFT_BOTTOM] = true,
            [CardPorts.RIGHT_BOTTOM] = true,
            [CardPorts.TOP_RIGHT] = true,
        }
    }
    
    -- Add effects to generate the desired ME value
    local effectsNeededME = targetME - 1.5 -- 1.5 ME from ports
    local materialEffects = math.ceil(effectsNeededME)
    
    card.activationEffect = {
        config = {
            actions = {
                { effect = "addResourceToOwner", options = { resource = ResourceType.MATERIAL, amount = materialEffects } }
            }
        }
    }
    
    return card
end

-- Test with different ME values and ratios
local function runTest(title, material_ratio, data_ratio, targetME)
    print("\n===== " .. title .. " =====")
    local testCard = createTestCard("TEST_" .. title, material_ratio, data_ratio, targetME)
    
    -- DEBUG: Print the resource ratio in the card
    print(string.format("  Card resourceRatio = { material = %s, data = %s }", 
        tostring(testCard.resourceRatio.material), 
        tostring(testCard.resourceRatio.data)))
    
    local cost, totalME = CostCalculator.calculateDerivedCost(testCard, testCard.resourceRatio)
    
    print(string.format("Card with %d:%d ratio at ME %.1f - Final Cost: %d Material, %d Data (Total ME: %.2f)", 
        material_ratio, data_ratio, targetME, cost.material, cost.data, totalME))
    return cost
end

-- Test 1: Original test with low ME
runTest("LOW_ME_3_TO_1", 3, 1, 3.5)

-- Test 2: Higher ME value for 3:1 ratio
runTest("HIGH_ME_3_TO_1", 3, 1, 8.0)

-- Test 3: Very high ME for 3:1 ratio
runTest("VERY_HIGH_ME_3_TO_1", 3, 1, 15.0)

-- Test 4: High ME for 5:1 ratio (very material heavy)
runTest("HIGH_ME_5_TO_1", 5, 1, 8.0)

-- Test 5: High ME for 1:3 ratio (data heavy)
runTest("HIGH_ME_1_TO_3", 1, 3, 8.0)

-- Test the example from the user's question: 3:1 that should be 5:1 or 3:2
print("\n===== CHECKING USER'S EXAMPLE =====")
local resourceRatios = {
    { m = 3, d = 1, me = 7.0 },
    { m = 3, d = 1, me = 9.0 },
    { m = 3, d = 1, me = 11.0 }
}

for i, ratioCase in ipairs(resourceRatios) do
    local cost = runTest("USER_EXAMPLE_" .. i, ratioCase.m, ratioCase.d, ratioCase.me)
    print(string.format("  Actual ratio: %.1f:%.1f", cost.material, cost.data))
end 
