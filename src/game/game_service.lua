-- src/game/game_service.lua
-- Provides an interface for executing core game actions and logic.

local Card = require('src.game.card') -- Needed for checking card type
local Rules = require('src.game.rules') -- Rules system for validating game actions
local Vector = require('src.utils.vector') -- Vector utilities for spatial operations
local AudioManager = require('src.audio.audio_manager') -- Audio manager for sound effects
local CardDefinitions = require('src.game.data.card_definitions') -- Card definitions
local ParadigmService = require('src.game.paradigm_service') -- Extracted paradigm management service
local DeckService = require('src.game.deck_service') -- Extracted deck management service
local ActivationService = require('src.game.activation_service') -- Extracted activation logic service

local GameService = {}
GameService.__index = GameService

-- Helper function for BFS path tracking (shallow copy)
local function shallow_copy(original)
    if type(original) ~= 'table' then return original end -- Handle non-tables
    local copy = {}
    for k, v in ipairs(original) do
        copy[k] = v
    end
    -- Also copy non-integer keys if any (though path is likely array)
    for k, v in pairs(original) do
        if type(k) ~= 'number' or k < 1 or k > #original then
            copy[k] = v
        end
    end
    return copy
end

-- Define Turn Phases
local TurnPhase = {
    ENERGY_GAIN = "Energy Gain", -- Phase for start-of-turn energy gain
    BUILD = "Build",
    ACTIVATE = "Activate",
    CONVERGE = "Converge",
    CLEANUP = "Cleanup", -- Internal phase before turn end
}

-- Local helper for port info (based on GDD 4.3)
-- Assumes standard Card module access
local function getPortInfo(portIndex)
    -- Returns { type, is_output } based on Card module data
    -- This essentially duplicates Card:getPortProperties but without needing a card instance
    local props = Card:getPortProperties(portIndex) -- Call the static helper from Card
    if props then
        return { props.type, props.is_output }
    end
    return nil
end

-- Map of compatible Output -> Input port pairs for convergence
local COMPATIBLE_PORTS = {
    [Card.Ports.TOP_LEFT] = Card.Ports.BOTTOM_LEFT,       -- Culture Output (1) -> Culture Input (3)
    [Card.Ports.BOTTOM_RIGHT] = Card.Ports.TOP_RIGHT,    -- Technology Output (4) -> Technology Input (2)
    [Card.Ports.LEFT_TOP] = Card.Ports.RIGHT_TOP,         -- Knowledge Output (5) -> Knowledge Input (7)
    [Card.Ports.RIGHT_BOTTOM] = Card.Ports.LEFT_BOTTOM,   -- Resource Output (8) -> Resource Input (6)
    -- Add inverse for convenience if needed, though validation logic might not need it
    [Card.Ports.BOTTOM_LEFT] = Card.Ports.TOP_LEFT,       -- Culture Input (3) -> Culture Output (1)
    [Card.Ports.TOP_RIGHT] = Card.Ports.BOTTOM_RIGHT,    -- Technology Input (2) -> Technology Output (4)
    [Card.Ports.RIGHT_TOP] = Card.Ports.LEFT_TOP,         -- Knowledge Input (7) -> Knowledge Output (5)
    [Card.Ports.LEFT_BOTTOM] = Card.Ports.RIGHT_BOTTOM,   -- Resource Input (6) -> Resource Output (8)
}

function GameService:new()
    local instance = setmetatable({}, GameService)
    instance.rules = Rules:new() -- Initialize rules system
    instance.audioManager = AudioManager:new() -- Initialize audio manager
    instance.audioManager:loadDefaultAssets() -- Load default sounds and music
    instance.players = {} -- Will be populated during game initialization
    instance.currentPlayerIndex = 1
    instance.currentPhase = TurnPhase.BUILD -- Start in Build phase
    instance.paradigmService = ParadigmService:new() -- Manage paradigm decks and shifts
    instance.deckService = DeckService:new(instance.audioManager) -- Manage main deck, draws, and dealing
    instance.activationService = ActivationService:new(instance) -- Manage card activation logic
    instance.gameOver = false -- Game end flag
    instance.activeConvergenceLinks = {} -- Stores details of established links
    instance.paradigmShiftTriggers = { -- Tracks which paradigm shift milestones have occurred
        firstConvergence = false,
        universalConvergence = false,
        individualCompletion = false
    }
    instance.nextLinkId = 1 -- Counter for unique link IDs
    
    -- State for handling asynchronous player input
    instance.isWaitingForInput = false
    instance.pendingQuestion = nil
    instance.pendingPlayer = nil -- Which player needs to answer
    instance.pendingInputCallback = nil -- Function to call with the result

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
        player:addResource('energy', 3)
        player:addResource('data', 3)
        player:addResource('material', 5)
        
        -- Create reactor card first using Card constructor with reactor definition
        local reactorData = CardDefinitions["REACTOR_BASE"]
        player.reactorCard = Card:new(reactorData)
        if not player.reactorCard then
            error(string.format("Failed to create reactor card for Player %d", player.id))
        end
        -- Set owner and reactor-specific properties
        player.reactorCard.owner = player
        
        -- Create network and initialize it with the reactor
        local Network = require('src.game.network')
        player.network = Network:new(player)
        if not player.network then
            error("Failed to create network for player " .. player.name)
        end
        player.network:initializeWithReactor(player.reactorCard)
        
        -- Add to players list
        table.insert(self.players, player)
        print(string.format("Initialized Player %d with reactor.", i))
    end
    
    -- Initialize decks
    self:initializeMainDeck()      -- Renamed for clarity
    self:initializeParadigmDecks() -- Initialize paradigm decks
    
    -- Deal initial hands to players
    self:dealInitialHands()
    
    -- Set the first player
    self.currentPlayerIndex = 1
    
    -- Draw initial paradigm
    self:drawInitialParadigm()

    -- Initial Energy Gain for Player 1
    print("[Service] Performing initial energy gain for Player 1...")
    self.currentPhase = TurnPhase.ENERGY_GAIN -- Set phase temporarily
    local advanced, message = self:advancePhase() -- Perform gain and advance to BUILD
    if not advanced then
         print("Error during initial energy gain phase advance: " .. (message or "Unknown error"))
         self.currentPhase = TurnPhase.BUILD 
    end

    print(string.format("Game initialized with %d players. Player 1 starts in %s phase.", playerCount, self.currentPhase))

    -- Play menu music (consider moving this to PlayState:enter)
    self.audioManager:playMusic("menu")

    return true
end

-- Initialize main card deck
function GameService:initializeMainDeck()
    -- Delegate deck setup to DeckService
    return self.deckService:initializeMainDeck()
end

-- Initialize paradigm decks
function GameService:initializeParadigmDecks()
    -- Delegate paradigm deck initialization to ParadigmService
    return self.paradigmService:initializeParadigmDecks()
end

-- Deal initial hands to all players
function GameService:dealInitialHands()
    -- Delegate initial hand dealing to DeckService
    return self.deckService:dealInitialHands(self.players)
end

-- Draw a card from the main deck
function GameService:drawCard()
    -- Delegate card draw to DeckService
    return self.deckService:drawCard()
end

-- Draw and set the initial paradigm
function GameService:drawInitialParadigm()
    -- Delegate initial paradigm drawing to ParadigmService
    return self.paradigmService:drawInitialParadigm()
end

-- Check if the deck is empty (for game end condition)
function GameService:isDeckEmpty()
    -- Delegate emptiness check to DeckService
    return self.deckService:isEmpty()
end

-- Get all players
function GameService:getPlayers()
    return self.players
end

-- Get the current player
function GameService:getCurrentPlayer()
    return self.players[self.currentPlayerIndex]
end

-- Get the currently active paradigm
function GameService:getCurrentParadigm()
    return self.paradigmService:getCurrentParadigm()
end

-- Get the current turn phase
function GameService:getCurrentPhase()
    return self.currentPhase
end

-- Check if a placement is valid according to rules (without checking cost)
function GameService:isPlacementValid(playerIndex, card, gridX, gridY)
    if self.currentPhase ~= TurnPhase.BUILD then
        return false, "Placement only allowed in Build phase."
    end
    
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
    local isValid, reason = self.rules:isPlacementValid(card, player.network, gridX, gridY)
    
    if not isValid then
        return false, reason
    end
    
    return isValid
end

-- Check if a player can afford to build a card
function GameService:canAffordCard(playerIndex, card)
    local player = self.players[playerIndex]
    if not player then
        print("Warning: canAffordCard called with invalid playerIndex: " .. tostring(playerIndex))
        return false, "Invalid player"
    end
    
    if not card then
        print("Warning: canAffordCard called with nil card.")
        return false, "Invalid card"
    end
    
    local costM = card.buildCost.material
    local costD = card.buildCost.data
    local canAffordM = player.resources.material >= costM
    local canAffordD = player.resources.data >= costD
    
    if canAffordM and canAffordD then
        return true
    else
        local reasonAfford = "Cannot afford card. Cost: "
        if costM > 0 then reasonAfford = reasonAfford .. costM .. "M " end
        if costD > 0 then reasonAfford = reasonAfford .. costD .. "D " end
        reasonAfford = reasonAfford .. string.format("(Have: %dM %dD)", player.resources.material, player.resources.data)
        return false, reasonAfford
    end
end

-- Attempt Placement
function GameService:attemptPlacement(state, cardIndex, gridX, gridY)
    if self.currentPhase ~= TurnPhase.BUILD then
        return false, "Placement not allowed in " .. self.currentPhase .. " phase."
    end

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
            
            self.audioManager:playSound("card_place")
            
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

-- Discard Card
function GameService:discardCard(state, cardIndex, resourceType)
    if self.currentPhase ~= TurnPhase.BUILD then
        return false, "Discarding not allowed in " .. self.currentPhase .. " phase."
    end

    if resourceType ~= 'material' and resourceType ~= 'data' then
        return false, "Invalid resource type for discard. Must be 'material' or 'data'."
    end

    local currentPlayer = self.players[self.currentPlayerIndex]
    local cardToRemove = currentPlayer.hand[cardIndex]

    if cardToRemove then
        print(string.format("[Service] Discarding '%s' for 1 %s.", cardToRemove.title, resourceType))
        currentPlayer:addResource(resourceType, 1)
        table.remove(currentPlayer.hand, cardIndex)

        self.audioManager:playSound("card_draw")

        return true, string.format("Discarded '%s' for 1 %s.", cardToRemove.title, resourceType)
    else
        return false, "Cannot discard: Invalid card index."
    end
end

-- Attempt Convergence
function GameService:attemptConvergence(initiatingPlayerIndex, initiatingNodePos, initiatingPortIndex, targetPlayerIndex, targetNodePos, targetPortIndex, linkType)
    print(string.format("[Service] Convergence Attempt: P%d Node(%d,%d):Port%d -> P%d Node(%d,%d):Port%d | Type: %s",
        initiatingPlayerIndex, initiatingNodePos.x, initiatingNodePos.y, initiatingPortIndex,
        targetPlayerIndex, targetNodePos.x, targetNodePos.y, targetPortIndex,
        tostring(linkType)))

    -- 1. Phase Check
    if self.currentPhase ~= TurnPhase.CONVERGE then
        local msg = "Convergence only allowed in Converge phase."
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    local initiatingPlayer = self.players[initiatingPlayerIndex]
    local targetPlayer = self.players[targetPlayerIndex]

    -- 2. Basic Validation (Initiator, Target)
    if not initiatingPlayer or not targetPlayer then
        local msg = "Invalid player index provided."
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    if initiatingPlayer == targetPlayer then
        local msg = "Cannot converge with yourself."
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- 3. Link Set Availability Check
    if not initiatingPlayer:hasLinkSetAvailable(linkType) then
        local msg = string.format("Initiator does not have %s link set available.", tostring(linkType))
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- 4. Node Existence Check
    local initiatingNode = initiatingPlayer.network:getCardAt(initiatingNodePos.x, initiatingNodePos.y)
    local targetNode = targetPlayer.network:getCardAt(targetNodePos.x, targetNodePos.y)
    if not initiatingNode then
        local msg = string.format("Initiating node not found at (%d,%d).", initiatingNodePos.x, initiatingNodePos.y)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
     if not targetNode then
        local msg = string.format("Target node not found at (%d,%d) for Player %d.", targetNodePos.x, targetNodePos.y, targetPlayerIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- 5. Port Validation
    local initiatingPortInfo = getPortInfo(initiatingPortIndex)
    local targetPortInfo = getPortInfo(targetPortIndex)

    if not initiatingPortInfo or not targetPortInfo then
        local msg = "Internal error: Invalid port index provided."
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- Check Initiator Port
    if not initiatingPortInfo[2] then -- Must be an OUTPUT (is_output is true)
        local msg = string.format("Initiating port %d is not an Output port.", initiatingPortIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    if initiatingPortInfo[1] ~= linkType then -- Must match link type
        local msg = string.format("Initiating port %d type (%s) does not match link type (%s).", initiatingPortIndex, tostring(initiatingPortInfo[1]), tostring(linkType))
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    if not initiatingNode:isPortAvailable(initiatingPortIndex) then
        local msg = string.format("Initiating port %d is not available on card '%s'.", initiatingPortIndex, initiatingNode.title)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- Check Target Port
    if targetPortInfo[2] then -- Must be an INPUT (is_output must be false)
        local msg = string.format("Target port %d is not an Input port.", targetPortIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    if targetPortInfo[1] ~= linkType then -- Must match link type
        local msg = string.format("Target port %d type (%s) does not match link type (%s).", targetPortIndex, tostring(targetPortInfo[1]), tostring(linkType))
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    if not targetNode:isPortAvailable(targetPortIndex) then
        local msg = string.format("Target port %d is not available on card '%s'.", targetPortIndex, targetNode.title)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- Check Port Compatibility
    if COMPATIBLE_PORTS[initiatingPortIndex] ~= targetPortIndex then
        local msg = string.format("Port incompatibility: Initiating port %d cannot link to target port %d.", initiatingPortIndex, targetPortIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    if targetNode == targetPlayer.reactorCard then
        local msg = "Cannot target the opponent's Reactor for convergence."
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- Call getAdjacentCoordForPort with separate x and y from targetNodePos table
    local targetAdjCoord = targetPlayer.network:getAdjacentCoordForPort(targetNodePos.x, targetNodePos.y, targetPortIndex)
    if targetAdjCoord and targetPlayer.network:getCardAt(targetAdjCoord.x, targetAdjCoord.y) then
        local msg = string.format("Target port %d is blocked by an adjacent card in target network.", targetPortIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    print("  Convergence Port Validation Passed!")

    -- 6. Execute Link Creation if Valid
    initiatingPlayer:useLinkSet(linkType)
    local linkId = "convLink_" .. self.nextLinkId
    initiatingNode:markPortOccupied(initiatingPortIndex, linkId)
    targetNode:markPortOccupied(targetPortIndex, linkId)

    local newLink = {
        linkId = linkId,
        initiatingPlayerIndex = initiatingPlayerIndex,
        initiatingNodeId = initiatingNode.id,
        initiatingPortIndex = initiatingPortIndex,
        targetPlayerIndex = targetPlayerIndex,
        targetNodeId = targetNode.id,
        targetPortIndex = targetPortIndex,
        linkType = linkType,
    }
    table.insert(self.activeConvergenceLinks, newLink)
    self.nextLinkId = self.nextLinkId + 1
    print(string.format("  Added link %s to activeConvergenceLinks.", newLink.linkId))

    local shiftOccurred = self:checkAndTriggerParadigmShifts(newLink)

    local msg_success = string.format("Convergence Link Established! (%s)", tostring(linkType))
    print("  " .. msg_success)
    return true, msg_success, shiftOccurred
end

-- Check for and trigger Paradigm Shifts based on convergence events
-- Returns: true if a shift occurred, false otherwise
function GameService:checkAndTriggerParadigmShifts(newLinkData)
    local paradigmChanged = false

    -- 1. First Convergence Trigger (GDD 4.7)
    if not self.paradigmShiftTriggers.firstConvergence and #self.activeConvergenceLinks > 0 then
        print("[Paradigm] Triggering shift: First Convergence!")
        self.paradigmShiftTriggers.firstConvergence = true
        paradigmChanged = self:drawNextStandardParadigm() or paradigmChanged
    end

    -- 2. Universal Convergence Trigger (GDD 4.7)
    if self.paradigmShiftTriggers.firstConvergence and not self.paradigmShiftTriggers.universalConvergence then
        local allPlayersLinked = true
        local linkedPlayerIndices = {}
        for _, link in ipairs(self.activeConvergenceLinks) do
            linkedPlayerIndices[link.initiatingPlayerIndex] = true
            linkedPlayerIndices[link.targetPlayerIndex] = true
        end
        for i = 1, #self.players do
            if not linkedPlayerIndices[i] then
                allPlayersLinked = false
                break
            end
        end

        if allPlayersLinked then
            print("[Paradigm] Triggering shift: Universal Convergence!")
            self.paradigmShiftTriggers.universalConvergence = true
            paradigmChanged = self:drawNextStandardParadigm() or paradigmChanged
        end
    end

    -- 3. Individual Completion Trigger (GDD 4.7)
    if not self.paradigmShiftTriggers.individualCompletion then
        local initiatingPlayer = self.players[newLinkData.initiatingPlayerIndex]
        if initiatingPlayer and initiatingPlayer:getInitiatedLinksCount() >= 4 then
            print("[Paradigm] Triggering shift: Individual Completion (Player " .. newLinkData.initiatingPlayerIndex .. ")!")
            self.paradigmShiftTriggers.individualCompletion = true
            paradigmChanged = self:drawNextStandardParadigm() or paradigmChanged
        end
    end

    if paradigmChanged then
        local cp = self.paradigmService:getCurrentParadigm()
        print(string.format("  New Paradigm Active: '%s'", cp and cp.title or "None"))
    end

    return paradigmChanged
end

-- Helper to draw the next standard paradigm and make it active
-- Returns true if a new paradigm was successfully drawn and applied, false otherwise
function GameService:drawNextStandardParadigm()
    -- Delegate standard paradigm drawing to ParadigmService
    return self.paradigmService:drawNextStandardParadigm()
end

-- Advance to the next logical phase in the turn
function GameService:advancePhase()
    local currentP = self.currentPhase

    if currentP == TurnPhase.CLEANUP then
        print("[Service] Cannot advance phase: Already in Cleanup.")
        return false, "Already in final phase"
    end

    local nextP = currentP
    if currentP == TurnPhase.ENERGY_GAIN then
        self:performEnergyGain(self:getCurrentPlayer())
        nextP = TurnPhase.BUILD
    elseif currentP == TurnPhase.BUILD then
        nextP = TurnPhase.ACTIVATE
    elseif currentP == TurnPhase.ACTIVATE then
        nextP = TurnPhase.CONVERGE
    elseif currentP == TurnPhase.CONVERGE then
        nextP = TurnPhase.CLEANUP
    end

    if nextP ~= currentP then
        self.currentPhase = nextP
        print(string.format("[Service] Player %d advanced to %s phase.", self.currentPlayerIndex, self.currentPhase))
        return true, self.currentPhase
    end

    print("Warning: advancePhase reached unexpected state.")
    return false, "Invalid state or phase"
end

-- End Turn
function GameService:endTurn(state)
    if not state or not state.players then
        return false, "Invalid state provided"
    end
    
    while self.currentPhase ~= TurnPhase.CLEANUP do
        local advanced, message = self:advancePhase()
        if not advanced then
            print("Error advancing phase during endTurn: " .. (message or "Unknown error"))
            return false, message or "Failed to advance phase to end turn."
        end
        if self.currentPhase == TurnPhase.BUILD then 
            print("Warning: Phase advancement loop detected in endTurn. Breaking.")
            return false, "Phase advancement loop detected."
        end
    end

    print("[Service] Entering Cleanup Phase for Player " .. self.currentPlayerIndex)

    local currentPlayer = self.players[self.currentPlayerIndex]
    if not currentPlayer then
        return false, "No current player found"
    end
    
    if not self.gameOver then
        if self.rules:isGameEndTriggered(self) then 
            self.gameOver = true
            print("[End Turn] Game end condition met!")
        end
    end
    
    if self.gameOver then
        self.gameOver = true
        local scores = self.rules:calculateFinalScores(self)
        print("Game over triggered! Final scores:")
        for playerId, score in pairs(scores) do
            print(string.format("  Player %d: %d points", playerId, score))
        end
        return true, "GAME_OVER"
    end
    
    local oldIndex = self.currentPlayerIndex
    
    if self.rules:shouldDrawCard(currentPlayer) then
        local card = self:drawCard()
        if card then
            currentPlayer:addCardToHand(card)
            print(string.format("  Player %d drew 1 card (Cleanup Phase).", oldIndex))
        end
    end
    
    self.currentPlayerIndex = (oldIndex % #self.players) + 1
    self.currentPhase = TurnPhase.ENERGY_GAIN

    if state then
        state.currentPlayerIndex = self.currentPlayerIndex
        state.currentPhase = self.currentPhase
    end

    local advanced, message = self:advancePhase() 
    if not advanced then
        print("Error automatically advancing phase after energy gain: " .. (message or "Unknown error"))
        return false, "Error during automatic phase transition."
    end

    if state then
        state.currentPhase = self.currentPhase
    end

    print(string.format("[Service] Turn ended for Player %d. Starting turn for Player %d in %s phase.",
        oldIndex, self.currentPlayerIndex, self.currentPhase))

    return true, string.format("Player %d's turn (%s Phase).", self.currentPlayerIndex, self.currentPhase)
end

-- Clean up resources during game shutdown
function GameService:cleanup()
    if self.audioManager then
        self.audioManager:cleanup()
    end
    
    print("Game Service cleaned up.")
end

-- =============================
-- NEW METHODS for Card Effects
-- =============================

-- Award Victory Points to a player and check for game end
function GameService:awardVP(player, amount)
    if not player or not player.addVP then
        print("Warning: awardVP called with invalid player object.")
        return
    end
    player:addVP(amount) -- Delegate actual increment to Player method
    print(string.format("  Awarded %d VP to %s (Total: %d)", amount, player.name, player:getVictoryPoints()))
    self:triggerGameEndCheck() -- Check if this action triggered game end
end

-- Have a player draw a specified number of cards from the deck
function GameService:playerDrawCards(player, amount)
    if not player or not player.addCardToHand then
        print("Warning: playerDrawCards called with invalid player object.")
        return
    end
    print(string.format("  %s attempts to draw %d card(s)...", player.name, amount))
    local drawnCount = 0
    for i = 1, amount do
        local card = self:drawCard() -- Use existing draw method
        if card then
            player:addCardToHand(card)
            drawnCount = drawnCount + 1
        else
            print(string.format("  Deck empty. Could only draw %d card(s).", drawnCount))
            break -- Stop drawing if deck runs out
        end
    end
    print(string.format("  %s finished drawing %d card(s).", player.name, drawnCount))
end

-- Add a resource to all players in the game
function GameService:addResourceToAllPlayers(resourceType, amount)
    print(string.format("  Adding %d %s to all players...", amount, resourceType))
    for _, player in ipairs(self.players) do
        if player.addResource then
            player:addResource(resourceType, amount)
        end
    end
end

-- Checks if the game end conditions are met and sets the gameOver flag
function GameService:triggerGameEndCheck()
    if self.gameOver then return end -- Already over

    local endReason = nil

    -- Check VP Threshold (GDD 4.8)
    for _, player in ipairs(self.players) do
        if player:getVictoryPoints() >= Rules.VICTORY_POINT_TARGET then
            endReason = string.format("Player %s reached %d VP!", player.name, Rules.VICTORY_POINT_TARGET)
            break
        end
    end

    if endReason then
        print(string.format("[Game End Check] Condition met: %s. Setting gameOver = true.", endReason))
        self.gameOver = true
    end
end

-- Placeholder for calculating final scores (should probably live in rules.lua)
function GameService:calculateFinalScores()
    print("Warning: GameService:calculateFinalScores called. Should be in Rules.")
    local scores = {}
    for _, p in ipairs(self.players) do
        scores[p.id] = p:getVictoryPoints() -- Basic VP for now
    end
    return scores
end

-- Calculate and add start-of-turn energy gain based on GDD 4.8
function GameService:performEnergyGain(player)
    if not player then return end
    -- If waiting for input, do nothing (prevents potential issues during paused state)
    if self.isWaitingForInput then
        print("[Energy Gain] Skipped for Player " .. player.id .. " - Waiting for input.")
        return
    end

    local energyGain = 1 -- Base gain for Reactor
    local numOpponents = #self.players - 1
    local MAX_ENERGY_GAIN = 4 -- GDD 4.8 cap

    print(string.format("[Energy Gain] Calculating for Player %d (%s). Base gain: %d", player.id, player.name, energyGain))

    local linkedOpponentIndices = {}
    local numLinksToOpponents = 0
    local numUniqueOpponentsLinked = 0

    for _, link in ipairs(self.activeConvergenceLinks) do
        if link.initiatingPlayerIndex == player.id and link.targetPlayerIndex ~= player.id then
            numLinksToOpponents = numLinksToOpponents + 1
            local opponentId = link.targetPlayerIndex
            if not linkedOpponentIndices[opponentId] then
                linkedOpponentIndices[opponentId] = true
                numUniqueOpponentsLinked = numUniqueOpponentsLinked + 1
                print(string.format("  - Found link TO opponent P%d (Link ID: %s). New unique opponent.", opponentId, link.linkId))
            else
                print(string.format("  - Found link TO opponent P%d (Link ID: %s). Already counted.", opponentId, link.linkId))
            end
        end
    end

    local bonusEnergy = 0
    local linkedToAllOpponents = numOpponents > 0 and (numUniqueOpponentsLinked >= numOpponents)

    if numLinksToOpponents > 0 then
        if linkedToAllOpponents then
            bonusEnergy = numLinksToOpponents
            print(string.format("  - Linked TO ALL %d opponents. Bonus: +%d E (1 per link)", numOpponents, bonusEnergy))
        else
            bonusEnergy = numUniqueOpponentsLinked
            print(string.format("  - Linked TO %d/%d opponents. Bonus: +%d E (1 per unique opponent)", numUniqueOpponentsLinked, numOpponents, bonusEnergy))
        end
    else
         print("  - No convergence links found TO opponents.")
    end

    energyGain = energyGain + bonusEnergy

    if energyGain > MAX_ENERGY_GAIN then
        print(string.format("  - Calculated gain (%d) exceeds cap (%d). Capping to %d.", energyGain, MAX_ENERGY_GAIN, MAX_ENERGY_GAIN))
        energyGain = MAX_ENERGY_GAIN
    end

    if energyGain > 0 then
        player:addResource('energy', energyGain)
        print(string.format("  Added %d Energy to Player %d. New total: %d", energyGain, player.id, player.resources.energy))
    else
         print("  No energy gained this turn.")
    end
end

-- NEW: Request Yes/No input from a player
function GameService:requestPlayerYesNo(player, question, callback)
    if self.isWaitingForInput then
        print("Warning: GameService already waiting for input. Ignoring new request.")
        return -- Avoid overwriting a pending request
    end
    if not player or not question or not callback then
        print("Error: Invalid arguments for requestPlayerYesNo.")
        return
    end

    print(string.format("[GameService] Requesting Yes/No input from Player %d: '%s'", player.id, question))
    self.isWaitingForInput = true
    self.pendingPlayer = player
    self.pendingQuestion = question
    self.pendingInputCallback = callback

    -- NOTE: The game state (e.g., PlayState) needs to observe 'isWaitingForInput'
    -- and 'pendingQuestion'/'pendingPlayer' to display the prompt.
end

-- NEW: Handle Yes/No answer from player input
function GameService:providePlayerYesNoAnswer(answer)
    if not self.isWaitingForInput then
        print("Warning: GameService received answer but was not waiting for input.")
        return
    end
    
    print(string.format("[GameService] Received answer: %s", answer and "Yes" or "No"))
    
    -- Store the callback and reset state before calling
    local callback = self.pendingInputCallback
    local player = self.pendingPlayer
    
    -- Reset the prompt state
    self.isWaitingForInput = false
    self.pendingQuestion = nil
    self.pendingPlayer = nil
    self.pendingInputCallback = nil
    
    -- Call the callback with the answer
    if callback and type(callback) == "function" then
        callback(player, answer)
    else
        print("Warning: No valid callback found for player answer.")
    end
end

-- NEW: Delegate global activation to ActivationService
function GameService:attemptActivationGlobal(activatingPlayerIndex, targetPlayerIndex, targetGridX, targetGridY)
    return self.activationService:attemptActivationGlobal(activatingPlayerIndex, targetPlayerIndex, targetGridX, targetGridY)
end

-- NEW: Destroy a random link connected to the given node
function GameService:destroyRandomLinkOnNode(sourceNode)
    if not sourceNode then
        print("Warning: destroyRandomLinkOnNode called with nil sourceNode")
        return false
    end
    
    print(string.format("[GameService] Attempting to destroy a random link on node '%s' (%s)", sourceNode.title, sourceNode.id))
    
    -- 1. Find all links connected to this node
    local connectedLinks = {}
    for _, link in ipairs(self.activeConvergenceLinks) do
        if (link.initiatingNodeId == sourceNode.id) or (link.targetNodeId == sourceNode.id) then
            table.insert(connectedLinks, link)
        end
    end
    
    if #connectedLinks == 0 then
        print("  No links found connected to this node.")
        return false
    end
    
    -- 2. Choose a random link to destroy
    local randomIndex = math.random(1, #connectedLinks)
    local linkToDestroy = connectedLinks[randomIndex]
    
    -- 3. Find the nodes connected by this link
    local initiatingPlayer = self.players[linkToDestroy.initiatingPlayerIndex]
    local targetPlayer = self.players[linkToDestroy.targetPlayerIndex]
    
    if not initiatingPlayer or not initiatingPlayer.network then
        print("  Warning: Could not find initiating player or network")
        return false
    end
    
    if not targetPlayer or not targetPlayer.network then
        print("  Warning: Could not find target player or network")
        return false
    end
    
    -- 4. Find the cards at the link's endpoints
    local initiatingNode = nil
    for _, card in pairs(initiatingPlayer.network.cards) do
        if card.id == linkToDestroy.initiatingNodeId then
            initiatingNode = card
            break
        end
    end
    
    local targetNode = nil
    for _, card in pairs(targetPlayer.network.cards) do
        if card.id == linkToDestroy.targetNodeId then
            targetNode = card
            break
        end
    end
    
    if not initiatingNode then
        print("  Warning: Could not find initiating node for link", linkToDestroy.linkId)
        return false
    end
    
    if not targetNode then
        print("  Warning: Could not find target node for link", linkToDestroy.linkId)
        return false
    end
    
    -- 5. Free the ports on both nodes
    print(string.format("  Destroying link %s: P%d:%s Port%d -> P%d:%s Port%d", 
        linkToDestroy.linkId,
        linkToDestroy.initiatingPlayerIndex, initiatingNode.title, linkToDestroy.initiatingPortIndex,
        linkToDestroy.targetPlayerIndex, targetNode.title, linkToDestroy.targetPortIndex))
    
    initiatingNode:clearPort(linkToDestroy.initiatingPortIndex)
    targetNode:clearPort(linkToDestroy.targetPortIndex)
    
    -- 6. Remove the link from the active links list
    for i, link in ipairs(self.activeConvergenceLinks) do
        if link.linkId == linkToDestroy.linkId then
            table.remove(self.activeConvergenceLinks, i)
            break
        end
    end
    
    -- 7. Play a sound effect if available
    if self.audioManager then
        self.audioManager:playSound("link_break")
    end
    
    print("  Link successfully destroyed!")
    return true
end

-- Force a player to discard a number of random cards from their hand
function GameService:forcePlayerDiscard(player, amount)
    if not player or type(player.hand) ~= 'table' then
        print("Warning: forcePlayerDiscard called with invalid player or hand")
        return
    end
    local discardCount = amount or 1
    for i = 1, discardCount do
        if #player.hand == 0 then
            print(string.format("%s has no cards to discard.", player.name or 'Player'))
            break
        end
        local idx = math.random(1, #player.hand)
        local card = table.remove(player.hand, idx)
        if card then
            print(string.format("%s discards random card '%s'.", player.name or 'Player', card.title or card.id or 'Unknown'))
        end
    end
end

return { GameService = GameService, TurnPhase = TurnPhase } 

