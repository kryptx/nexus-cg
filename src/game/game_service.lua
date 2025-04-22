-- src/game/game_service.lua
-- Provides an interface for executing core game actions and logic.

local Card = require('src.game.card') -- Needed for checking card type
local Rules = require('src.game.rules') -- Rules system for validating game actions
local Vector = require('src.utils.vector') -- Vector utilities for spatial operations
local AudioManager = require('src.audio.audio_manager') -- Audio manager for sound effects
local CardDefinitions = require('src.game.data.card_definitions') -- Card definitions
local ParadigmDefinitions = require('src.game.data.paradigm_definitions') -- Paradigm definitions

local GameService = {}
GameService.__index = GameService

-- Helper function to shuffle a table in place (Fisher-Yates)
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = love.math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
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
    instance.deck = {} -- Main card deck
    instance.paradigmDeck = {} -- Standard paradigm shift cards, shuffled
    instance.genesisParadigms = {} -- Available genesis paradigms
    instance.currentParadigm = nil -- Active paradigm object
    instance.gameOver = false -- Game end flag
    instance.activeConvergenceLinks = {} -- Stores details of established links
    instance.paradigmShiftTriggers = { -- Tracks which paradigm shift milestones have occurred
        firstConvergence = false,
        universalConvergence = false, -- Will need logic to check this
        individualCompletion = false -- Will need logic to check this
    }
    instance.nextLinkId = 1 -- Counter for unique link IDs
    
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
        player:addResource('energy', 10)
        player:addResource('data', 20)
        player:addResource('material', 20)
        
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
    print("Initializing main deck...")
    self.deck = {}
    local genesisCardsPool = {} -- Temporary pool for Genesis cards
    
    local cardDefinitions = require('src.game.data.card_definitions')
    
    -- Separate Genesis cards and add regular cards to the deck
    for cardId, cardData in pairs(cardDefinitions) do
        if cardData.type ~= Card.Type.REACTOR then  -- Skip reactor cards
            if cardData.isGenesis then
                local card = Card:new(cardData)
                table.insert(genesisCardsPool, card)
                print(string.format("  Added Genesis card %s to pool.", card.id))
            else
                for i = 1, 3 do 
                    local card = Card:new(cardData)
                    table.insert(self.deck, card)
                end
            end
        end
    end
    
    -- Store the Genesis pool for dealing
    self.genesisCardsPool = genesisCardsPool 
    print(string.format("Separated %d Genesis cards.", #self.genesisCardsPool))
    
    -- Shuffle the main deck (excluding Genesis cards for now)
    shuffle(self.deck)
    print(string.format("Main deck initialized with %d regular cards (before adding remaining Genesis).", #self.deck))
end

-- Initialize paradigm decks
function GameService:initializeParadigmDecks()
    print("Initializing paradigm decks...")
    self.paradigmDeck = ParadigmDefinitions:getByType("Standard")
    self.genesisParadigms = ParadigmDefinitions:getByType("Genesis")

    -- Shuffle the standard paradigm deck
    shuffle(self.paradigmDeck)
    
    print(string.format("Initialized %d Standard Paradigms (shuffled) and %d Genesis Paradigms.", #self.paradigmDeck, #self.genesisParadigms))
end

-- Deal initial hands to all players
function GameService:dealInitialHands()
    local NUM_STARTING_CARDS = 6 -- Number of cards to draw after Genesis card
    
    print("Shuffling Genesis card pool...")
    shuffle(self.genesisCardsPool)
    
    print("Dealing 1 Genesis card to each player...")
    for _, player in ipairs(self.players) do
        if #self.genesisCardsPool > 0 then
            local genesisCard = table.remove(self.genesisCardsPool, 1)
            player:addCardToHand(genesisCard)
            print(string.format("  Dealt Genesis card '%s' to %s.", genesisCard.title, player.name))
        else
            print(string.format("    Warning: Not enough Genesis cards to deal to %s!", player.name))
        end
    end
    
    print(string.format("Shuffling %d remaining Genesis card(s) into main deck...", #self.genesisCardsPool))
    for _, remainingGenesisCard in ipairs(self.genesisCardsPool) do
        table.insert(self.deck, remainingGenesisCard)
    end
    shuffle(self.deck) -- Shuffle again after adding remaining Genesis cards
    self.genesisCardsPool = nil -- Clear the temporary pool
    print(string.format("Main deck now contains %d cards (including remaining Genesis).", #self.deck))
    
    print(string.format("Dealing %d starting cards to each player...", NUM_STARTING_CARDS))
    for _, player in ipairs(self.players) do
        print(string.format("  Dealing cards to %s...", player.name))
        for i = 1, NUM_STARTING_CARDS do
            local card = self:drawCard()
            if card then
                player:addCardToHand(card)
            else
                print(string.format("    Warning: Deck empty while dealing cards to %s (drew %d).", player.name, i-1))
                break -- No more cards
            end
        end
    end
    print("Finished dealing initial hands.")
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
    
    self.audioManager:playSound("card_draw")
    
    return card
end

-- Draw and set the initial paradigm
function GameService:drawInitialParadigm()
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

-- Get the currently active paradigm
function GameService:getCurrentParadigm()
    return self.currentParadigm
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

-- Attempt Activation
function GameService:attemptActivation(state, targetGridX, targetGridY)
    if self.currentPhase ~= TurnPhase.ACTIVATE then
        return false, "Activation not allowed in " .. self.currentPhase .. " phase."
    end

    local currentPlayer = self.players[self.currentPlayerIndex]
    local targetCard = currentPlayer.network:getCardAt(targetGridX, targetGridY)

    if not targetCard then
        return false, "No card at activation target."
    end

    if targetCard.type == Card.Type.REACTOR then
        print("[Service] Activation failed: Cannot activate the Reactor itself.")
        return false, "Cannot activate the Reactor itself."
    end

    print(string.format("[Service] Attempting activation targeting %s (%s) at (%d,%d)", 
        targetCard.title, targetCard.id, targetGridX, targetGridY))

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
        print(string.format("  Activation path found! Length (Nodes): %d, Cost: %d Energy.", pathLength, energyCost))

        if currentPlayer.resources.energy >= energyCost then
            print("  Activation affordable.")
            currentPlayer:spendResource('energy', energyCost)
            self.audioManager:playSound("activation")

            -- Execute effects along path (target first, then towards reactor)
            local activationMessages = {}
             table.insert(activationMessages, string.format("Activated path (Cost %d E):", energyCost))

            -- Activate target card
            if targetCard then
                targetCard:activateEffect(self, currentPlayer, currentPlayer.network)
                table.insert(activationMessages, string.format("  - %s activated!", targetCard.title))
                print(string.format("    Effect for %s executed.", targetCard.title))
            end
            
            -- Activate remaining cards in path
            for i = 2, pathLength do 
                 local cardId = path[i]
                 local cardToActivate = currentPlayer.network:getCardById(cardId)
                 if cardToActivate then
                     cardToActivate:activateEffect(self, currentPlayer, currentPlayer.network)
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
        print(string.format("  New Paradigm Active: '%s'", self.currentParadigm and self.currentParadigm.title or "None"))
    end

    return paradigmChanged
end

-- Helper to draw the next standard paradigm and make it active
-- Returns true if a new paradigm was successfully drawn and applied, false otherwise
function GameService:drawNextStandardParadigm()
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

-- ==============================
-- GLOBAL ACTIVATION (Updated)
-- ==============================

-- Attempt Activation targeting any node in any player's network
function GameService:attemptActivationGlobal(activatingPlayerIndex, targetPlayerIndex, targetGridX, targetGridY)
    if self.currentPhase ~= TurnPhase.ACTIVATE then
        return false, "Activation not allowed in " .. self.currentPhase .. " phase."
    end

    local activatingPlayer = self.players[activatingPlayerIndex]
    local targetPlayer = self.players[targetPlayerIndex]

    if not activatingPlayer or not targetPlayer then
        return false, "Invalid player index provided."
    end

    local targetCard = targetPlayer.network:getCardAt(targetGridX, targetGridY)

    if not targetCard then
        return false, "No card at target location."
    end

    if targetCard.type == Card.Type.REACTOR then
        return false, "Cannot activate the Reactor itself."
    end

    print(string.format("[Service] Attempting GLOBAL activation by P%d targeting P%d's %s (%s) at (%d,%d)", 
        activatingPlayerIndex, targetPlayerIndex, targetCard.title, targetCard.id, targetGridX, targetGridY))

    local activatorReactor = activatingPlayer.network:findReactor()
    if not activatorReactor then
        return false, "Error: Activating player's reactor not found."
    end

    local isValid, pathData, reason = self:findGlobalActivationPath(targetCard, activatorReactor, activatingPlayer)

    if isValid and pathData then
        local path = pathData.path
        local energyCost = pathData.cost - 1
        local isConvergenceStart = pathData.isConvergenceStart
        local pathLength = #path -- Full path length including reactor

        print(string.format("  Global path found! Length (incl. reactor): %d, Nodes in Path (Cost): %d Energy. Convergence Start: %s", 
            pathLength, energyCost, tostring(isConvergenceStart)))

        if activatingPlayer.resources.energy >= energyCost then
            print("  Activation affordable.")
            activatingPlayer:spendResource('energy', energyCost)
            self.audioManager:playSound("activation")

            local activationMessages = {}
            table.insert(activationMessages, string.format("Activated global path (Cost %d E):", energyCost))

            -- Activate target node
            local targetNodeData = path[1]
            local theTargetCard = targetNodeData.card
            local theTargetOwner = targetNodeData.owner

            if isConvergenceStart then
                 print(string.format("    Activating target %s via CONVERGENCE effect...", targetNodeData.card.title))
                 theTargetCard:activateConvergence(self, activatingPlayer, theTargetOwner.network)
            else
                 print(string.format("    Activating target %s via standard effect...", targetNodeData.card.title))
                 theTargetCard:activateEffect(self, activatingPlayer, theTargetOwner.network)
            end
            table.insert(activationMessages, string.format("  - %s activated!", targetNodeData.card.title))

            -- Activate subsequent nodes in the path (checking owner for correct effect)
            for i = 2, pathLength do
                local pathElement = path[i]
                local cardToActivate = pathElement.card
                local cardOwner = pathElement.owner -- Need owner to check and for network context

                if cardOwner == activatingPlayer then
                    -- Node belongs to the activator: Use standard effect
                    print(string.format("    Activating subsequent node %s (Owned by P%d) via standard effect...", 
                                        cardToActivate.title, cardOwner.id))
                    -- Pass activatingPlayer and the actual owner's network
                    cardToActivate:activateEffect(self, activatingPlayer, cardOwner.network, cardToActivate) 
                else
                    -- Node belongs to another player: Use convergence effect
                    print(string.format("    Activating subsequent node %s (Owned by P%d) via CONVERGENCE effect...", 
                                        cardToActivate.title, cardOwner.id))
                    -- Pass activatingPlayer and the actual owner's network
                    cardToActivate:activateConvergence(self, activatingPlayer, cardOwner.network, cardToActivate) 
                end
                
                table.insert(activationMessages, string.format("  - %s activated!", cardToActivate.title))
                
                -- No break needed here, activation proceeds along the paid path
            end
            
            return true, table.concat(activationMessages, "\n")
        else
            print("  Activation failed: Cannot afford energy cost.")
            return false, string.format("Not enough energy. Cost: %d E (Have: %d E)", energyCost, activatingPlayer.resources.energy)
        end
    else
        print("  Activation failed: No global path found.")
        return false, string.format("No valid global activation path: %s", reason or "Unknown reason")
    end
end

-- Helper function for BFS path tracking (shallow copy)
local function shallow_copy(original)
    local copy = {}
    for k, v in ipairs(original) do
        copy[k] = v
    end
    return copy
end

-- Find Activation Path (Global BFS)
-- Searches across networks using adjacency and convergence links.
-- Returns: boolean (isValid), pathData { path={ {card=Card, owner=Player}, ... }, cost=int, isConvergenceStart=bool }, reason (string)
function GameService:findGlobalActivationPath(targetCard, activatorReactor, activatingPlayer)
    print(string.format("[Pathfinder] START: Target=%s (%s, P%d), Reactor=%s (%s, P%d), Activator=P%d", 
        targetCard and targetCard.title or "NIL",
        targetCard and targetCard.id or "NIL",
        targetCard and targetCard.owner and targetCard.owner.id or -1,
        activatorReactor and activatorReactor.title or "NIL",
        activatorReactor and activatorReactor.id or "NIL",
        activatorReactor and activatorReactor.owner and activatorReactor.owner.id or -1,
        activatingPlayer and activatingPlayer.id or -1
    ))

    if not targetCard or not activatorReactor or not activatingPlayer then
        print("[Pathfinder] FAIL: Invalid arguments.")
        return false, nil, "Invalid arguments to findGlobalActivationPath"
    end

    local queue = {}
    local visited = {} -- Track visited card INSTANCES to prevent cycles

    local startOwner = targetCard.owner
    if not startOwner then
        print(string.format("[Pathfinder] FAIL: Target card %s has no owner!", targetCard.id))
        return false, nil, string.format("Target card %s has no owner!", targetCard.id)
    end
    local initialPath = { { card = targetCard, owner = startOwner } }
    table.insert(queue, { node = targetCard, owner = startOwner, path = initialPath })
    
    -- Use composite key for visited set: playerID_cardID
    local startVisitedKey = startOwner.id .. "_" .. targetCard.id
    visited[startVisitedKey] = true 
    print(string.format("[Pathfinder] Initial Queue: Target %s (P%d). Visited Key: %s", targetCard.id, startOwner.id, startVisitedKey))

    while #queue > 0 do
        local currentState = table.remove(queue, 1)
        local currentNode = currentState.node
        local currentOwner = currentState.owner
        local currentPath = currentState.path
        local currentVisitedKey = currentOwner.id .. "_" .. currentNode.id
        print(string.format("[Pathfinder] Dequeue: Current=%s (P%d), PathLen=%d, VisitedKey=%s", currentNode.id, currentOwner.id, #currentPath, currentVisitedKey))

        if currentNode == activatorReactor then
            local isConvergenceStart = false
            if #currentPath > 1 then
                isConvergenceStart = currentPath[1].owner ~= currentPath[2].owner
            end

            local activationPath = shallow_copy(currentPath)

            local pathData = {
                path = activationPath,
                cost = #activationPath, 
                isConvergenceStart = isConvergenceStart
            }
            print(string.format("[Pathfinder] SUCCESS: Reached Reactor %s. Path Cost=%d, ConvStart=%s", activatorReactor.id, pathData.cost, tostring(isConvergenceStart)))
            return true, pathData, nil
        end

        -- Explore Neighbors (Adjacency within the same network)
        print(string.format("  [Pathfinder Adjacency] Exploring neighbors of %s (P%d)...", currentNode.id, currentOwner.id))
        for portIndex = 1, 8 do
            local portProps = currentNode:getPortProperties(portIndex)
            -- Check if it's an available OUTPUT port on the current node
            if portProps and portProps.is_output and currentNode:isPortAvailable(portIndex) then
                local adjacentPos = currentNode.network:getAdjacentCoordForPort(currentNode.position.x, currentNode.position.y, portIndex)
                if adjacentPos then
                    local neighborNode = currentOwner.network:getCardAt(adjacentPos.x, adjacentPos.y)
                    -- Check if neighbor exists AND its INSTANCE has not been visited
                    local neighborVisitedKey = neighborNode and (currentOwner.id .. "_" .. neighborNode.id) or nil
                    if neighborNode and not visited[neighborVisitedKey] then 
                        -- Find the corresponding INPUT port on the neighbor
                        local neighborPortIndex = currentNode.network:getOpposingPortIndex(portIndex)
                        local neighborProps = neighborNode:getPortProperties(neighborPortIndex)
                        
                        local currentPortAvail = currentNode:isPortAvailable(portIndex) 
                        local neighborPortAvail = neighborNode:isPortAvailable(neighborPortIndex)
                        local typesMatch = neighborProps and portProps.type == neighborProps.type
                        print(string.format("    - Adj Check: %s(P%d)[Port %d Out %s, Avail:%s] -> %s(P%d)[Port %d In %s, Avail:%s] | Types Match: %s | VisitedKey: %s",
                            currentNode.id, currentOwner.id, portIndex, portProps.type, tostring(currentPortAvail),
                            neighborNode.id, currentOwner.id, neighborPortIndex, neighborProps and neighborProps.type or "NIL", tostring(neighborPortAvail),
                            tostring(typesMatch), neighborVisitedKey))

                        -- Check if neighbor port is an available INPUT of the same TYPE
                        local condition = neighborProps and not neighborProps.is_output and neighborNode:isPortAvailable(neighborPortIndex) and neighborProps.type == portProps.type
                        if condition then
                            visited[neighborVisitedKey] = true -- Mark neighbor INSTANCE visited HERE
                            local newPath = shallow_copy(currentPath)
                            table.insert(newPath, { card = neighborNode, owner = currentOwner })
                            print(string.format("      >> Enqueueing ADJACENT: %s (P%d)", neighborNode.id, currentOwner.id))
                            table.insert(queue, { node = neighborNode, owner = currentOwner, path = newPath })
                        end
                    end
                end
            end
        end

        -- Explore Neighbors (Convergence Links)
        print(string.format("  [Pathfinder Convergence] Exploring links for %s (P%d)...", currentNode.id, currentOwner.id))
        for _, link in ipairs(self.activeConvergenceLinks) do
            local neighborNode, neighborOwner
            local neighborNodeId, neighborPlayerIndex, neighborPortIndex, currentPortIndex

            -- Determine potential neighbor based on the link and current node
            if link.initiatingNodeId == currentNode.id and link.initiatingPlayerIndex == currentOwner.id then
                neighborNodeId = link.targetNodeId
                neighborPlayerIndex = link.targetPlayerIndex
                neighborPortIndex = link.targetPortIndex 
                currentPortIndex = link.initiatingPortIndex 
            elseif link.targetNodeId == currentNode.id and link.targetPlayerIndex == currentOwner.id then
                neighborNodeId = link.initiatingNodeId
                neighborPlayerIndex = link.initiatingPlayerIndex
                neighborPortIndex = link.initiatingPortIndex 
                currentPortIndex = link.targetPortIndex 
            else
                neighborNodeId = nil 
            end

            if neighborNodeId and neighborPlayerIndex then
                neighborOwner = self.players[neighborPlayerIndex]
                neighborNode = neighborOwner and neighborOwner.network:getCardById(neighborNodeId) or nil
            else
                 neighborNode = nil
            end

            -- Check if neighbor exists AND its INSTANCE has not been visited
            local neighborVisitedKeyConv = neighborNode and (neighborOwner.id .. "_" .. neighborNode.id) or nil
            if neighborNode and not visited[neighborVisitedKeyConv] then
                local outputNode, inputNode, outputPortIdx, inputPortIdx
                -- Determine which is the output node based on link direction
                if link.initiatingNodeId == currentNode.id then 
                    outputNode, inputNode = currentNode, neighborNode
                    outputPortIdx, inputPortIdx = currentPortIndex, neighborPortIndex 
                else 
                    outputNode, inputNode = neighborNode, currentNode
                    outputPortIdx, inputPortIdx = neighborPortIndex, currentPortIndex 
                end

                local outputPortProps = outputNode:getPortProperties(outputPortIdx)
                local inputPortProps = inputNode:getPortProperties(inputPortIdx)
                
                -- Check traversability based on link ID (allows traversing the link even if occupied by *this* link)
                local isOutputPortTraversable = outputNode:isPortDefined(outputPortIdx) and 
                                                 (outputNode:getOccupyingLinkId(outputPortIdx) == nil or outputNode:getOccupyingLinkId(outputPortIdx) == link.linkId)
                                                 
                local isInputPortTraversable = inputNode:isPortDefined(inputPortIdx) and 
                                                (inputNode:getOccupyingLinkId(inputPortIdx) == nil or inputNode:getOccupyingLinkId(inputPortIdx) == link.linkId)

                local typesMatchConv = outputPortProps and inputPortProps and outputPortProps.type == inputPortProps.type
                print(string.format("    - Conv Check (Link %s): %s(P%d)[Port %d Out %s, Trav:%s] -> %s(P%d)[Port %d In %s, Trav:%s] | Types Match: %s | VisitedKey: %s",
                    link.linkId,
                    outputNode.id, outputNode.owner.id, outputPortIdx, outputPortProps and outputPortProps.type or "NIL", tostring(isOutputPortTraversable),
                    inputNode.id, inputNode.owner.id, inputPortIdx, inputPortProps and inputPortProps.type or "NIL", tostring(isInputPortTraversable),
                    tostring(typesMatchConv), neighborVisitedKeyConv))
                
                local condition = outputPortProps and outputPortProps.is_output and
                                inputPortProps and not inputPortProps.is_output and
                                isOutputPortTraversable and isInputPortTraversable and 
                                outputPortProps.type == inputPortProps.type
                
                if condition then
                    visited[neighborVisitedKeyConv] = true -- Mark neighbor INSTANCE visited HERE
                    local newPath = shallow_copy(currentPath)
                    table.insert(newPath, { card = neighborNode, owner = neighborOwner })
                    print(string.format("      >> Enqueueing CONVERGENCE: %s (P%d) via Link %s", neighborNode.id, neighborOwner.id, link.linkId))
                    table.insert(queue, { node = neighborNode, owner = neighborOwner, path = newPath })
                end
            end
        end

    end

    print("[Pathfinder] FAIL: Queue empty, Reactor not found.")
    return false, nil, "No valid activation path exists to the activator's reactor."
end

-- Calculate and add start-of-turn energy gain based on GDD 4.8
function GameService:performEnergyGain(player)
    if not player then return end

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

-- Return both GameService and TurnPhase
return { GameService = GameService, TurnPhase = TurnPhase } 

