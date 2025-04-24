-- src/game/paradigm_service.lua
-- Extracted service for handling paradigm deck initialization and initial paradigm drawing.

local ParadigmDefinitions = require('src.game.data.paradigm_definitions')

-- Local helper function to shuffle a table in place (Fisher-Yates)
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = love.math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local ParadigmService = {}
ParadigmService.__index = ParadigmService

function ParadigmService:new()
    local instance = setmetatable({}, ParadigmService)
    instance.paradigmDeck = {}        -- Standard paradigm shift cards, shuffled
    instance.genesisParadigms = {}    -- Available genesis paradigms
    instance.currentParadigm = nil    -- Active paradigm object
    return instance
end

-- Initialize the paradigm decks (Standard and Genesis)
function ParadigmService:initializeParadigmDecks()
    print("Initializing paradigm decks...")
    self.paradigmDeck = ParadigmDefinitions:getByType("Standard")
    self.genesisParadigms = ParadigmDefinitions:getByType("Genesis")

    shuffle(self.paradigmDeck)
    print(string.format("Initialized %d Standard Paradigms (shuffled) and %d Genesis Paradigms.", #self.paradigmDeck, #self.genesisParadigms))
end

-- Draw and set the initial paradigm (Genesis)
function ParadigmService:drawInitialParadigm()
    print("Setting initial paradigm...")
    if #self.genesisParadigms == 0 then
        print("Warning: No Genesis Paradigms defined. Using nil paradigm.")
        self.currentParadigm = nil
        return
    end

    local randomIndex = love.math.random(#self.genesisParadigms)
    self.currentParadigm = self.genesisParadigms[randomIndex]

    print(string.format("Initial Paradigm set to: '%s' (ID: %s)", self.currentParadigm.title, self.currentParadigm.id))

    if self.currentParadigm.effect then
        print(string.format("  (Effect function exists for %s)", self.currentParadigm.id))
    end
end

-- Get the currently active paradigm
function ParadigmService:getCurrentParadigm()
    return self.currentParadigm
end

-- Draw the next standard paradigm and make it active
function ParadigmService:drawNextStandardParadigm()
    if #self.paradigmDeck == 0 then
        print("[Paradigm] No more Standard Paradigms left to draw.")
        return false
    end

    local oldParadigm = self.currentParadigm
    self.currentParadigm = table.remove(self.paradigmDeck, 1)

    print(string.format("[Paradigm] Shifted from '%s' to '%s' (%s).",
        oldParadigm and oldParadigm.title or "None",
        self.currentParadigm.title,
        self.currentParadigm.id
    ))

    return true
end

return ParadigmService 
