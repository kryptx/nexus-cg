-- scripts/extract_cards_to_csv.lua
-- Extracts card definitions from data files into a CSV format.

local CardTypes = require('src.game.card').Type -- Needed for potentially converting type enum back to string if necessary
local CardPorts = require('src.game.card').Ports -- Needed for port names
local all_definitions = require('src.game.data.card_definitions')
local CostCalculator = require('src.utils.cost_calculator') -- Require the calculator

local output_file_path = "card_definitions.csv"
local file, err = io.open(output_file_path, "w")

if not file then
    error("Could not open file for writing: " .. output_file_path .. " (" .. (err or "unknown error") .. ")")
end

-- Helper function to safely get nested values
local function safe_get(tbl, key, default)
    if tbl and tbl[key] ~= nil then
        return tbl[key]
    end
    return default or ""
end

-- Helper to format CSV cell (basic quoting for commas)
local function csv_quote(value)
    local str = tostring(value)
    if string.find(str, ",") or string.find(str, "\"") or string.find(str, "\n") then
        -- Escape existing quotes and wrap in quotes
        str = "\"" .. string.gsub(str, "\"", "\"\"") .. "\""
    end
    return str
end

-- Ordered list of functional port headers for consistent column order
local functional_port_headers = {
    "C_IN", "C_OUT",
    "T_IN", "T_OUT",
    "K_IN", "K_OUT",
    "R_IN", "R_OUT",
}

-- Mapping from functional header to the positional key in CardPorts
local functional_to_positional_key = {
    ["C_IN"] = "BOTTOM_LEFT", ["C_OUT"] = "TOP_LEFT",
    ["T_IN"] = "TOP_RIGHT",   ["T_OUT"] = "BOTTOM_RIGHT",
    ["K_IN"] = "RIGHT_TOP",   ["K_OUT"] = "LEFT_TOP",
    ["R_IN"] = "LEFT_BOTTOM", ["R_OUT"] = "RIGHT_BOTTOM",
}

-- Define CSV Headers
local headers = {
    "id",
    "title",
    "type",
    "isGenesis",
    "buildCostMaterial",
    "buildCostData",
    "vpValue",
    "activationEffectDescription",
    "convergenceEffectDescription",
}
-- Add functional port headers
for _, header_name in ipairs(functional_port_headers) do
    table.insert(headers, header_name)
end

file:write(table.concat(headers, ",") .. "\n")

-- Process definitions
local sorted_ids = {}
for id, _ in pairs(all_definitions) do
    table.insert(sorted_ids, id)
end
table.sort(sorted_ids) -- Ensure consistent order

for _, id in ipairs(sorted_ids) do
    local def = all_definitions[id]
    local row = {}

    -- Extract basic fields
    table.insert(row, csv_quote(safe_get(def, 'id')))
    table.insert(row, csv_quote(safe_get(def, 'title')))
    -- Find the string name for the type enum
    local type_name = ""
    for name, enum_val in pairs(CardTypes) do
        if enum_val == def.type then
            type_name = name
            break
        end
    end
    table.insert(row, csv_quote(type_name))
    table.insert(row, csv_quote(safe_get(def, 'isGenesis', false))) -- Default isGenesis to false
    table.insert(row, csv_quote(safe_get(def.buildCost, 'material', 0)))
    table.insert(row, csv_quote(safe_get(def.buildCost, 'data', 0)))

    -- Calculate and insert derived cost (using default split for now)
    print(string.format("Calculating cost for: %s (%s)", def.id, def.title)) -- Add print statement before calculation

    table.insert(row, csv_quote(safe_get(def, 'vpValue', 0)))

    -- Extract Effect Descriptions
    table.insert(row, csv_quote(safe_get(def.activationEffect, 'description')))
    table.insert(row, csv_quote(safe_get(def.convergenceEffect, 'description')))

    -- Extract Defined Ports using functional headers
    for _, header_name in ipairs(functional_port_headers) do
        local positional_key = functional_to_positional_key[header_name]
        local port_enum = CardPorts[positional_key]
        if def.definedPorts and def.definedPorts[port_enum] then
            table.insert(row, csv_quote("Yes"))
        else
            table.insert(row, csv_quote("No"))
        end
    end

    -- TODO: Extract Effect Descriptions (Placeholder)

    file:write(table.concat(row, ",") .. "\n")
end

file:close()
print("Successfully wrote card definitions to " .. output_file_path) 
