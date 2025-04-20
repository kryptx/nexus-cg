-- src/game/data/paradigm_definitions.lua
-- Defines the Paradigm Shift cards

local Paradigms = {}

--[[
Paradigm Card Structure Template:
{
  id = "unique_paradigm_id",         -- Unique identifier string
  title = "Paradigm Title",          -- Display name
  type = "Genesis" / "Standard",    -- Type of paradigm
  description = "Rule text...",     -- Description of the rule modifications
  effect = function(gameState)      -- Function or data describing the actual effect
    -- This might modify global cost factors, scoring rules, etc.
    -- The exact structure of 'effect' will evolve as we integrate it.
    -- Example: gameState.activationCosts.Culture = gameState.activationCosts.Culture - 1
  end,
  -- Potentially add fields for specific types of effects for easier querying:
  -- costModifiers = { energy = { Culture = -1 } },
  -- scoringModifiers = { immediate = { activate = { Culture = 1 } }, end_game = { Resource = 1 } },
  -- etc.
}
--]]

Paradigms.Definitions = {
  -- Example Genesis Paradigm
  genesis_base = {
    id = "genesis_base",
    title = "Genesis: Standard Operations",
    type = "Genesis",
    description = "Standard operating procedures are in effect. No initial global modifications.",
    effect = function(gameState)
      -- No effect, represents the baseline state
    end,
  },
  -- Example Standard Paradigm (based on GDD 4.7 examples)
  cultural_boom = {
    id = "cultural_boom",
    title = "Cultural Boom",
    type = "Standard",
    description = "Activating Culture nodes costs 1 less Energy. Gain 1 VP immediately each time you activate a Culture node.",
    -- We will need to define how effects are actually applied later.
    -- Placeholder structure for now:
    effectData = {
      costModifiers = { activate_energy = { Culture = -1 } },
      scoringModifiers = { immediate_vp = { activate = { Culture = 1 } } }
    },
    effect = function(gameState)
      -- Logic to apply these modifiers would go here or be handled by systems querying this data.
      print("Paradigm Shift: Cultural Boom activated!")
    end,
  },
  resource_scarcity = {
    id = "resource_scarcity",
    title = "Resource Scarcity",
    type = "Standard",
    description = "Resource node actions produce 1 less Material/Energy. Gain 1 VP for each Resource node in your network at game end.",
    -- Placeholder structure:
    effectData = {
      resourceModifiers = { node_action = { Resource = { Material = -1, Energy = -1 } } },
      scoringModifiers = { end_game_vp = { node_count = { Resource = 1 } } }
    },
    effect = function(gameState)
      print("Paradigm Shift: Resource Scarcity activated!")
    end,
  },
  -- Add more paradigms here...
}

--- Returns all defined paradigms.
-- @return table A table containing all paradigm definition tables.
function Paradigms:getAll()
  return self.Definitions
end

--- Returns a specific paradigm definition by its ID.
-- @param id string The unique ID of the paradigm.
-- @return table|nil The paradigm definition table, or nil if not found.
function Paradigms:getById(id)
  return self.Definitions[id]
end

--- Returns all paradigms of a specific type ("Genesis" or "Standard").
-- @param paradigmType string The type to filter by.
-- @return table A list of paradigm definitions matching the type.
function Paradigms:getByType(paradigmType)
    local results = {}
    for _, paradigm in pairs(self.Definitions) do
        if paradigm.type == paradigmType then
            table.insert(results, paradigm)
        end
    end
    return results
end


return Paradigms 
