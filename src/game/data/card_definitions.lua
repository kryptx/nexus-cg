-- src/game/data/card_definitions.lua
-- Contains definitions for all cards in the game.
-- This data can be used by a CardFactory or similar system to create Card instances.

local CardTypes = require('src.game.card').Type
local CardPorts = require('src.game.card').Ports -- Use new Port constants
local CardEffects = require('src.game.card_effects')
local ResourceType = CardEffects.ResourceType

local definitions_set1_genesis = require('src.game.data.cards.set1_genesis')
local definitions_set1_culture = require('src.game.data.cards.set1_culture')
local definitions_set1_knowledge = require('src.game.data.cards.set1_knowledge')
local definitions_set1_resource = require('src.game.data.cards.set1_resource')
local definitions_set1_technology = require('src.game.data.cards.set1_technology')

local definitions = {}

-- === Reactor Card ===
definitions["REACTOR_BASE"] = {
    id = "REACTOR_BASE",
    title = "Reactor Core",
    type = CardTypes.REACTOR,
    buildCost = { material = 0, data = 0 }, -- No build cost
    vpValue = 0,
    imagePath = "assets/images/reactor-core.png",
    -- GDD 4.1: Reactor has all 8 ports present initially
    definedPorts = {
        [CardPorts.TOP_LEFT] = true, [CardPorts.TOP_RIGHT] = true,
        [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true,
        [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true,
        [CardPorts.RIGHT_TOP] = true, [CardPorts.RIGHT_BOTTOM] = true,
    },
    art = nil, -- Placeholder
    flavorText = "The heart of the network.",
    -- No activation/convergence effect for the Reactor itself
}

for k, v in pairs(definitions_set1_genesis) do
    definitions[k] = v
end

for k, v in pairs(definitions_set1_culture) do
    definitions[k] = v
end

for k, v in pairs(definitions_set1_knowledge) do
    definitions[k] = v
end

for k, v in pairs(definitions_set1_resource) do
    definitions[k] = v
end

for k, v in pairs(definitions_set1_technology) do
    definitions[k] = v
end

-- === Calculate and Add Derived Costs ===
print("Calculating derived costs for all card definitions...")
local CostCalculator = require('src.utils.cost_calculator') -- Make sure path is correct
io.stderr:write("Debug: Attempted to require CostCalculator.\n")

if CostCalculator then
    io.stderr:write("Debug: CostCalculator module loaded successfully.\n")
    local count = 0
    for _ in pairs(definitions) do count = count + 1 end
    io.stderr:write("Debug: Found " .. count .. " definitions to process.\n")
    for id, def in pairs(definitions) do
        if def.buildCost then
            io.stderr:write("Debug: Skipping definition ID: " .. (id or "NIL_ID") .. " because it has a buildCost.\n")
            goto continue
        end

        io.stderr:write("Debug: Processing definition ID: " .. (id or "NIL_ID") .. "\n") -- Check if loop is entered
        local originalCost = def.resourceRatio or { material = 0, data = 0 }
        local derivedRatio = nil

        local M = originalCost.material or 0
        local D = originalCost.data or 0

        if M > 0 and D > 0 then
            derivedRatio = { material = M, data = D }
        elseif M > 0 and D <= 0 then
            derivedRatio = { material = 1, data = 0 } -- Strong Material preference
        elseif M <= 0 and D > 0 then
            derivedRatio = { material = 0, data = 1 } -- Strong Data preference
        else -- Both M and D are 0 or less, use default split logic
            derivedRatio = nil
        end

        io.stderr:write("Debug: About to call CostCalculator.calculateDerivedCost for ID: " .. (id or "NIL_ID") .. "\n")
        -- Suppress the calculator's own print statements during this phase
        local originalPrint = print
        _G.print = function() end -- Temporarily disable print

        local calculatedCost, totalME = CostCalculator.calculateDerivedCost(def, derivedRatio)

        _G.print = originalPrint -- Restore print
        io.stderr:write("Debug: Finished call for ID: " .. (id or "NIL_ID") .. ". Result was " .. (calculatedCost and "OK" or "NIL") .. "\n")

        if calculatedCost then
             -- print(string.format("  [%s] Original: %dM %dD -> Ratio: %s -> Derived: %dM %dD (%.2f ME)",
             --    id, M, D,
             --    derivedRatio and string.format("{M=%d, D=%d}", derivedRatio.material, derivedRatio.data) or "Default",
             --    calculatedCost.material, calculatedCost.data, totalME))
             def.buildCost = calculatedCost
        else
             -- print(string.format("  [%s] Could not calculate derived cost.", id))
             def.buildCost = { material = -1, data = -1 } -- Mark as failed
        end
        ::continue::
    end
    print("Finished calculating derived costs.")
else
    io.stderr:write("Debug: CostCalculator module FAILED to load (CostCalculator is nil).\n")
    print("Warning: CostCalculator module not found. Derived costs not calculated.")
    -- Optionally add placeholder derivedCost to all definitions if calculator fails
    for id, def in pairs(definitions) do
        def.buildCost = { material = -1, data = -1 }
    end
end

return definitions 
