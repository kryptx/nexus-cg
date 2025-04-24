-- src/game/deck_service.lua
-- Service for handling main card deck and Genesis card pool operations

local Card = require('src.game.card') -- Needed to instantiate card instances
local CardDefinitions = require('src.game.data.card_definitions') -- Card definitions

local DeckService = {}
DeckService.__index = DeckService

-- Helper to shuffle a table in place (Fisher-Yates)
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = love.math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

-- Create new DeckService
-- audioManager: optional, to play draw sound
function DeckService:new(audioManager)
    local instance = setmetatable({}, DeckService)
    instance.deck = {}            -- Main card deck (excluding Genesis initially)
    instance.genesisPool = {}     -- Temporary Genesis card pool
    instance.audioManager = audioManager
    return instance
end

-- Initialize the main deck and separate Genesis cards
function DeckService:initializeMainDeck()
    print("Initializing main deck...")
    self.deck = {}
    local pool = {}
    for cardId, cardData in pairs(CardDefinitions) do
        if cardData.type ~= Card.Type.REACTOR then
            if cardData.isGenesis then
                table.insert(pool, Card:new(cardData))
                print(string.format("  Collected Genesis card %s", cardData.id or cardId))
            else
                for i = 1, 3 do
                    table.insert(self.deck, Card:new(cardData))
                end
            end
        end
    end
    self.genesisPool = pool
    print(string.format("Separated %d Genesis cards.", #self.genesisPool))

    shuffle(self.deck)
    print(string.format("Main deck initialized with %d regular cards.", #self.deck))
end

-- Deal initial hands: one Genesis each, then standard cards
-- players: array of player objects
-- numStarting: number of standard cards to draw after Genesis
function DeckService:dealInitialHands(players, numStarting)
    numStarting = numStarting or 6
    print("Shuffling Genesis card pool...")
    shuffle(self.genesisPool)

    -- Deal one Genesis card to each player
    print("Dealing 1 Genesis card to each player...")
    for _, player in ipairs(players) do
        if #self.genesisPool > 0 then
            local card = table.remove(self.genesisPool, 1)
            player:addCardToHand(card)
            print(string.format("  Dealt Genesis card '%s' to %s.", card.title, player.name))
        else
            print(string.format("  Warning: Not enough Genesis cards for %s.", player.name))
        end
    end

    -- Merge any remaining Genesis cards into main deck
    print(string.format("Shuffling %d remaining Genesis cards into deck...", #self.genesisPool))
    for _, card in ipairs(self.genesisPool) do
        table.insert(self.deck, card)
    end
    shuffle(self.deck)
    self.genesisPool = nil
    print(string.format("Deck now contains %d cards (including Genesis).", #self.deck))

    -- Deal standard cards to each player
    print(string.format("Dealing %d starting cards to each player...", numStarting))
    for _, player in ipairs(players) do
        for i = 1, numStarting do
            if #self.deck == 0 then
                print(string.format("  Warning: Deck empty while dealing to %s (drew %d).", player.name, i-1))
                break
            end
            local card = table.remove(self.deck, 1)
            player:addCardToHand(card)
        end
    end
    print("Finished dealing initial hands.")
end

-- Draw a card from the deck
-- Returns: card instance or nil
function DeckService:drawCard()
    print(string.format("[DEBUG] Attempting to draw card. Current deck size: %d", #self.deck))
    if #self.deck == 0 then
        print("[DEBUG] Cannot draw: Deck is empty")
        return nil
    end
    local card = table.remove(self.deck, 1)
    print(string.format("[DEBUG] Drew card: %s (ID: %s). Remaining deck size: %d", card.title, card.id, #self.deck))
    if self.audioManager then
        self.audioManager:playSound("card_draw")
    end
    return card
end

-- Check if the deck is empty
function DeckService:isEmpty()
    local empty = #self.deck == 0
    print(string.format("[DEBUG] Checking if deck is empty. Deck size: %d, isEmpty: %s", #self.deck, tostring(empty)))
    return empty
end

return DeckService 
