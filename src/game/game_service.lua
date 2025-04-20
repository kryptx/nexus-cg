-- src/game/game_service.lua
-- Provides an interface for executing core game actions and logic.

local Card = require('src.game.card') -- Needed for checking card type
local Rules = require('src.game.rules') -- Rules system for validating game actions
local Vector = require('src.utils.vector') -- Vector utilities for spatial operations
local AudioManager = require('src.audio.audio_manager') -- Audio manager for sound effects
local CardDefinitions = require('src.game.data.card_definitions') -- Card definitions

local GameService = {}
GameService.__index = GameService

function GameService:new()
    local instance = setmetatable({}, GameService)
    instance.rules = Rules:new() -- Initialize rules system
    instance.audioManager = AudioManager:new() -- Initialize audio manager
    instance.audioManager:loadDefaultAssets() -- Load default sounds and music
    instance.players = {} -- Will be populated during game initialization
    instance.currentPlayerIndex = 1
    instance.deck = {} -- Main card deck
    instance.paradigmDeck = {} -- Paradigm shift cards
    instance.currentParadigm = nil -- Active paradigm
    instance.gameOver = false -- Game end flag
    
    print("Game Service Initialized.")
    return instance
end

-- Initialize game with players
function GameService:initializeGame(playerCount)
    -- Create player objects
    for i = 1, playerCount do
        -- Create the player
        local player = require('src.game.player'):new({
            id = i,
            name = "Player " .. i
        })
        
        -- Set starting resources
        player:addResource('energy', 5)  -- Starting energy
        player:addResource('data', 5)    -- Starting data
        player:addResource('material', 5) -- Starting material
        
        -- Create reactor card first using Card constructor with reactor definition
        local reactorData = CardDefinitions["REACTOR_BASE"]
        player.reactorCard = Card:new(reactorData)
        if not player.reactorCard then
            error(string.format("Failed to create reactor card for Player %d", player.id))
        end
        -- Set owner and reactor-specific properties
        player.reactorCard.owner = player
        player.reactorCard.baseResourceProduction = false
        
        -- Create network and initialize it with the reactor
        local Network = require('src.game.network')
        player.network = Network:new(player)
        if not player.network then
            error("Failed to create network for player " .. player.name)
        end
        player.network:initializeWithReactor(player.reactorCard)
        
        -- Add starting hand cards (seed cards)
        local STARTING_HAND_CARD_IDS = { "NODE_TECH_001", "NODE_CULT_001" }
        print(string.format("Adding starting hand for %s:", player.name))
        for _, cardId in ipairs(STARTING_HAND_CARD_IDS) do
            local cardData = CardDefinitions[cardId]
            if cardData then
                local cardInstance = require('src.game.card'):new(cardData)
                cardInstance.owner = player
                player:addCardToHand(cardInstance)
                print(string.format("  Added %s to hand", cardInstance.title))
            else
                print(string.format("Warning: Seed card definition not found for ID: %s", cardId))
            end
        end
        
        -- Add to players list
        table.insert(self.players, player)
        print(string.format("Initialized Player %d with reactor and %d seed cards", i, #STARTING_HAND_CARD_IDS))
    end
    
    -- Initialize decks (this would load from card definitions)
    self:initializeDecks()
    
    -- Deal initial hands to players
    self:dealInitialHands()
    
    -- Set the first player
    self.currentPlayerIndex = 1
    
    -- Draw initial paradigm
    self:drawInitialParadigm()
    
    print(string.format("Game initialized with %d players.", playerCount))
    
    -- Play menu music
    self.audioManager:playMusic("menu")
    
    return true
end

-- Initialize card decks
function GameService:initializeDecks()
    print("[DEBUG] Starting deck initialization...")
    -- Create a test deck with some basic cards
    self.deck = {}
    
    -- Get the card definitions
    local CardDefinitions = require('src.game.data.card_definitions')
    
    -- Add all non-reactor cards from definitions to the deck
    -- We'll add multiple copies of each card
    for cardId, cardData in pairs(CardDefinitions) do
        if cardData.type ~= Card.Type.REACTOR then  -- Skip reactor cards
            -- Add 3 copies of each card to ensure enough cards
            for i = 1, 3 do
                local card = Card:new(cardData)
                table.insert(self.deck, card)
                print(string.format("[DEBUG] Added card to deck: %s (ID: %s)", card.title, card.id))
            end
        end
    end
    
    print(string.format("[DEBUG] Finished initializing deck with %d cards", #self.deck))
end

-- Deal initial hands to all players
function GameService:dealInitialHands()
    for _, player in ipairs(self.players) do
        -- Draw up to minimum hand size
        while player:getHandSize() < Rules.MIN_HAND_SIZE do
            local card = self:drawCard()
            if card then
                player:addCardToHand(card)
            else
                break -- No more cards
            end
        end
    end
end

-- Draw a card from the main deck
function GameService:drawCard()
    print(string.format("[DEBUG] Attempting to draw card. Current deck size: %d", #self.deck))
    if #self.deck == 0 then
        print("[DEBUG] Cannot draw: Deck is empty")
        return nil -- Deck is empty
    end
    
    local card = table.remove(self.deck, 1) -- Draw from top
    print(string.format("[DEBUG] Drew card: %s (ID: %s). Remaining deck size: %d", card.title, card.id, #self.deck))
    
    -- Play sound effect
    self.audioManager:playSound("card_draw")
    
    return card
end

-- Draw initial paradigm
function GameService:drawInitialParadigm()
    -- This would draw from a special "Genesis Paradigm" subset
    -- For now, just a placeholder
    print("Drawing initial paradigm...")
end

-- Check if the deck is empty (for game end condition)
function GameService:isDeckEmpty()
    local isEmpty = #self.deck == 0
    print(string.format("[DEBUG] Checking if deck is empty. Deck size: %d, isEmpty: %s", #self.deck, tostring(isEmpty)))
    return isEmpty
end

-- Get all players
function GameService:getPlayers()
    return self.players
end

-- Get the current player
function GameService:getCurrentPlayer()
    return self.players[self.currentPlayerIndex]
end

-- Check if a placement is valid according to rules (without checking cost)
function GameService:isPlacementValid(playerIndex, card, gridX, gridY)
    local player = self.players[playerIndex]
    if not player then
        print("Warning: isPlacementValid called with invalid playerIndex: " .. tostring(playerIndex))
        return false
    end
    if not card then
        print("Warning: isPlacementValid called with nil card.")
        return false
    end
    if not player.network then
        print("Warning: isPlacementValid - Player has no network object.")
        return false
    end

    -- Delegate the core rule check to the Rules object
    local isValid, _ = self.rules:isPlacementValid(card, player.network, gridX, gridY)
    return isValid
end

-- Attempt Placement
function GameService:attemptPlacement(state, cardIndex, gridX, gridY)
    local currentPlayer = self.players[self.currentPlayerIndex]
    local selectedCard = currentPlayer.hand[cardIndex]

    if not selectedCard then
        return false, "Invalid card selection index."
    end

    print(string.format("[Service] Attempting placement of '%s' at (%d,%d)", selectedCard.title, gridX, gridY))

    -- Use the rules system to validate placement
    local isValid, reason = self.rules:isPlacementValid(selectedCard, currentPlayer.network, gridX, gridY)

    if isValid then
        local costM = selectedCard.buildCost.material
        local costD = selectedCard.buildCost.data
        local canAffordM = currentPlayer.resources.material >= costM
        local canAffordD = currentPlayer.resources.data >= costD

        if canAffordM and canAffordD then
            print("  Placement valid and affordable.")
            currentPlayer:spendResource('material', costM)
            currentPlayer:spendResource('data', costD)
            currentPlayer.network:placeCard(selectedCard, gridX, gridY)
            table.remove(currentPlayer.hand, cardIndex)
            
            -- Play card placement sound
            self.audioManager:playSound("card_place")
            
            -- Success! PlayState will handle resetting selection.
            return true, string.format("Placed '%s' at (%d,%d).", selectedCard.title, gridX, gridY)
        else
            print("  Placement valid but cannot afford.")
            local reasonAfford = "Cannot afford card. Cost: "
            if costM > 0 then reasonAfford = reasonAfford .. costM .. "M " end
            if costD > 0 then reasonAfford = reasonAfford .. costD .. "D " end
            reasonAfford = reasonAfford .. string.format("(Have: %dM %dD)", currentPlayer.resources.material, currentPlayer.resources.data)
            return false, reasonAfford
        end
    else
        print("  Invalid placement: " .. reason)
        return false, "Invalid placement: " .. reason
    end
end

-- Attempt Activation
function GameService:attemptActivation(state, targetGridX, targetGridY)
    local currentPlayer = self.players[self.currentPlayerIndex]
    local targetCard = currentPlayer.network:getCardAt(targetGridX, targetGridY)

    if not targetCard then
        return false, "No card at activation target."
    end

    print(string.format("[Service] Attempting activation targeting %s (%s) at (%d,%d)", targetCard.title, targetCard.id, targetGridX, targetGridY))

    -- Find the reactor to trace path back from target
    local reactor = currentPlayer.network:findReactor()
    if not reactor then
        return false, "Error: Reactor not found in network."
    end
    
    -- Use rules system to validate activation path
    local isValid, path, reason = self.rules:isActivationPathValid(
        currentPlayer.network, reactor.id, targetCard.id)
        
    if isValid and path then
        local pathLength = #path
        local energyCost = pathLength
        print(string.format("  Path found! Length: %d, Cost: %d Energy.", pathLength, energyCost))

        if currentPlayer.resources.energy >= energyCost then
             print("  Activation affordable.")
             currentPlayer:spendResource('energy', energyCost)

             -- Play activation sound
             self.audioManager:playSound("activation")

             -- Execute effects BACKWARDS along path (GDD 4.5)
             local activationMessages = {}
              table.insert(activationMessages, string.format("Activated path (Cost %d E):", energyCost))

             -- Always activate the target card itself first, even if path is empty
             if targetCard then
                 targetCard:activateEffect(currentPlayer, currentPlayer.network)
                 table.insert(activationMessages, string.format("  - %s activated!", targetCard.title))
                 print(string.format("    Effect for %s executed.", targetCard.title))
             end
             
             -- Activate remaining cards in path (excluding target if path not empty)
             for i = 2, pathLength do -- Start from index 2 if path exists
                  local cardId = path[i]
                  local cardToActivate = currentPlayer.network:getCardById(cardId)
                  if cardToActivate then
                      cardToActivate:activateEffect(currentPlayer, currentPlayer.network)
                      table.insert(activationMessages, string.format("  - %s activated!", cardToActivate.title))
                      print(string.format("    Effect for %s executed.", cardToActivate.title))
                  end
             end
             return true, table.concat(activationMessages, "\n") -- Multi-line status
        else
            print("  Activation failed: Cannot afford energy cost.")
            return false, string.format("Not enough energy for activation. Cost: %d E (Have: %d E)", energyCost, currentPlayer.resources.energy)
        end
    else
        print("  Activation failed: No path found.")
        return false, string.format("No valid activation path: %s", reason or "Unknown reason")
    end
end

-- Discard Card
function GameService:discardCard(state, cardIndex)
    local currentPlayer = self.players[self.currentPlayerIndex]
    local cardToRemove = currentPlayer.hand[cardIndex]

    if cardToRemove then
        print(string.format("[Service] Discarding '%s' for 1 Material.", cardToRemove.title))
        currentPlayer:addResource('material', 1)
        table.remove(currentPlayer.hand, cardIndex)
        
        -- Play discard sound
        self.audioManager:playSound("card_draw") -- Reuse the draw sound for now
        
        -- Success! PlayState handles resetting selection.
        return true, string.format("Discarded '%s' for 1 Material.", cardToRemove.title)
    else
        return false, "Cannot discard: Invalid card index."
    end
end

-- End Turn
function GameService:endTurn(state)
    if not state or not state.players then
        return false, "Invalid state provided"
    end

    local currentPlayer = self.players[self.currentPlayerIndex]
    if not currentPlayer then
        return false, "No current player found"
    end
    
    -- Check for game end condition
    if self.rules:isGameEndTriggered(self) then
        self.gameOver = true
        local scores = self.rules:calculateFinalScores(self)
        print("Game over triggered! Final scores:")
        for playerId, score in pairs(scores) do
            print(string.format("  Player %d: %d points", playerId, score))
        end
        return true, "GAME_OVER"
    end
    
    -- Store current index before advancing
    local oldIndex = self.currentPlayerIndex
    
    -- Cleanup phase: Draw cards if hand is below minimum
    if self.rules:shouldDrawCard(currentPlayer) then
        local card = self:drawCard()
        if card then
            currentPlayer:addCardToHand(card)
            print(string.format("  Player %d drew 1 card (Cleanup Phase).", oldIndex))
        end
    end
    
    -- Advance to next player (using modulo to wrap around)
    self.currentPlayerIndex = (oldIndex % #self.players) + 1
    -- Keep state in sync for backward compatibility
    if state then
        state.currentPlayerIndex = self.currentPlayerIndex
    end
    
    print(string.format("[Service] Turn ended for Player %d. Starting turn for Player %d.", 
        oldIndex, self.currentPlayerIndex))
    
    return true, string.format("Player %d's turn.", self.currentPlayerIndex)
end

-- Clean up resources during game shutdown
function GameService:cleanup()
    -- Clean up audio resources
    if self.audioManager then
        self.audioManager:cleanup()
    end
    
    print("Game Service cleaned up.")
end

return GameService 
