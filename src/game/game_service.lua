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

-- Local helper for slot info (based on GDD 4.3)
-- Matches the one in renderer.lua/play_state.lua but doesn't rely on specific renderer constants
-- Assumes standard Card module access
local function getSlotInfo(slotIndex)
    -- Returns { x_offset, y_offset, type, is_output }
    -- We don't need offsets here, just type and direction.
    -- Mapping based directly on GDD 4.3 / Card.Slots constants
    if slotIndex == Card.Slots.TOP_LEFT then return { Card.Type.CULTURE, true } end       -- 1: Culture Output
    if slotIndex == Card.Slots.TOP_RIGHT then return { Card.Type.TECHNOLOGY, false } end    -- 2: Technology Input
    if slotIndex == Card.Slots.BOTTOM_LEFT then return { Card.Type.CULTURE, false } end    -- 3: Culture Input
    if slotIndex == Card.Slots.BOTTOM_RIGHT then return { Card.Type.TECHNOLOGY, true } end -- 4: Technology Output
    if slotIndex == Card.Slots.LEFT_TOP then return { Card.Type.KNOWLEDGE, true } end    -- 5: Knowledge Output
    if slotIndex == Card.Slots.LEFT_BOTTOM then return { Card.Type.RESOURCE, false } end   -- 6: Resource Input
    if slotIndex == Card.Slots.RIGHT_TOP then return { Card.Type.KNOWLEDGE, false } end    -- 7: Knowledge Input
    if slotIndex == Card.Slots.RIGHT_BOTTOM then return { Card.Type.RESOURCE, true } end   -- 8: Resource Output
    return nil
end

-- Map of compatible Output -> Input slot pairs for convergence
local COMPATIBLE_SLOTS = {
    [Card.Slots.TOP_LEFT] = Card.Slots.BOTTOM_LEFT,       -- Culture Output (1) -> Culture Input (3)
    [Card.Slots.BOTTOM_RIGHT] = Card.Slots.TOP_RIGHT,    -- Technology Output (4) -> Technology Input (2)
    [Card.Slots.LEFT_TOP] = Card.Slots.RIGHT_TOP,         -- Knowledge Output (5) -> Knowledge Input (7)
    [Card.Slots.RIGHT_BOTTOM] = Card.Slots.LEFT_BOTTOM,   -- Resource Output (8) -> Resource Input (6)
    -- Add inverse for convenience if needed, though validation logic might not need it
    [Card.Slots.BOTTOM_LEFT] = Card.Slots.TOP_LEFT,       -- Culture Input (3) -> Culture Output (1)
    [Card.Slots.TOP_RIGHT] = Card.Slots.BOTTOM_RIGHT,    -- Technology Input (2) -> Technology Output (4)
    [Card.Slots.RIGHT_TOP] = Card.Slots.LEFT_TOP,         -- Knowledge Input (7) -> Knowledge Output (5)
    [Card.Slots.LEFT_BOTTOM] = Card.Slots.RIGHT_BOTTOM,   -- Resource Input (6) -> Resource Output (8)
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
        player:addResource('energy', 1)  -- Starting energy
        player:addResource('data', 1)    -- Starting data
        player:addResource('material', 3) -- Starting material
        
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
         -- Handle potential error, maybe default phase to BUILD anyway?
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
                -- Create and add to Genesis pool (assume 1 copy per definition)
                local card = Card:new(cardData)
                table.insert(genesisCardsPool, card)
                print(string.format("  Added Genesis card %s to pool.", card.id))
            else
                -- Add multiple copies of regular cards to the main deck
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
    local NUM_STARTING_CARDS = 3 -- Number of *Seed* cards to draw after Genesis card
    
    print("Shuffling Genesis card pool...")
    shuffle(self.genesisCardsPool)
    
    print("Dealing 1 Genesis card to each player...")
    for _, player in ipairs(self.players) do
        if #self.genesisCardsPool > 0 then
            local genesisCard = table.remove(self.genesisCardsPool, 1) -- Take from top
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
    
    print(string.format("Dealing %d starting Seed cards to each player...", NUM_STARTING_CARDS))
    for _, player in ipairs(self.players) do
        print(string.format("  Dealing Seed cards to %s...", player.name))
        for i = 1, NUM_STARTING_CARDS do
            local card = self:drawCard()
            if card then
                player:addCardToHand(card)
            else
                print(string.format("    Warning: Deck empty while dealing Seed cards to %s (drew %d).", player.name, i-1))
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
    
    -- Play sound effect
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

    -- Select a random Genesis paradigm
    local randomIndex = love.math.random(#self.genesisParadigms)
    self.currentParadigm = self.genesisParadigms[randomIndex]

    print(string.format("Initial Paradigm set to: '%s' (ID: %s)", self.currentParadigm.title, self.currentParadigm.id))

    -- Apply the initial effect (if any)
    -- Note: Currently the 'effect' function takes gameState, which we don't readily have here.
    -- We might need to pass 'self' (the GameService) or redesign how effects are applied.
    -- For now, we'll just print.
    if self.currentParadigm.effect then
        -- self.currentParadigm.effect(self) -- Placeholder - need to decide what state to pass
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
    -- Add phase check: Placement only allowed in Build phase
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
    
    if not isValid then -- Pass reason back if rules check failed
        return false, reason
    end
    
    return isValid -- Return true if phase and rules checks passed
end

-- Attempt Placement
function GameService:attemptPlacement(state, cardIndex, gridX, gridY)
    -- Phase check
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
    -- Phase check
    if self.currentPhase ~= TurnPhase.ACTIVATE then
        return false, "Activation not allowed in " .. self.currentPhase .. " phase."
    end

    local currentPlayer = self.players[self.currentPlayerIndex]
    local targetCard = currentPlayer.network:getCardAt(targetGridX, targetGridY)

    if not targetCard then
        return false, "No card at activation target."
    end

    -- Explicitly check if the target is the reactor itself
    if targetCard.type == Card.Type.REACTOR then -- Corrected type check
        print("[Service] Activation failed: Cannot activate the Reactor itself.")
        return false, "Cannot activate the Reactor itself."
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
        local energyCost = pathLength -- Assume Rules:isActivationPathValid returns path excluding reactor
        print(string.format("  Activation path found! Length (Nodes): %d, Cost: %d Energy.", pathLength, energyCost))

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
                 targetCard:activateEffect(self, currentPlayer, currentPlayer.network)
                 table.insert(activationMessages, string.format("  - %s activated!", targetCard.title))
                 print(string.format("    Effect for %s executed.", targetCard.title))
             end
             
             -- Activate remaining cards in path (excluding target if path not empty)
             for i = 2, pathLength do -- Start from index 2 if path exists
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
    -- Phase check (GDD 4.2: Discard is part of Build Phase action)
    if self.currentPhase ~= TurnPhase.BUILD then
        return false, "Discarding not allowed in " .. self.currentPhase .. " phase."
    end

    -- Validate resource type
    if resourceType ~= 'material' and resourceType ~= 'data' then
        return false, "Invalid resource type for discard. Must be 'material' or 'data'."
    end

    local currentPlayer = self.players[self.currentPlayerIndex]
    local cardToRemove = currentPlayer.hand[cardIndex]

    if cardToRemove then
        print(string.format("[Service] Discarding '%s' for 1 %s.", cardToRemove.title, resourceType))
        currentPlayer:addResource(resourceType, 1)
        table.remove(currentPlayer.hand, cardIndex)

        -- Play discard sound
        self.audioManager:playSound("card_draw") -- Reuse the draw sound for now

        -- Success! PlayState handles resetting selection.
        return true, string.format("Discarded '%s' for 1 %s.", cardToRemove.title, resourceType)
    else
        return false, "Cannot discard: Invalid card index."
    end
end

-- Attempt Convergence
-- Placeholder: Needs full implementation of validation logic based on GDD 4.6
function GameService:attemptConvergence(initiatingPlayerIndex, initiatingNodePos, initiatingSlotIndex, targetPlayerIndex, targetNodePos, targetSlotIndex, linkType)
    -- Access PlayState via self.playState if it was stored during init, or pass differently if needed.
    -- For now, assuming PlayState instance isn't needed directly here, or can be accessed via self.
    print(string.format("[Service] Convergence Attempt: P%d Node(%d,%d):Slot%d -> P%d Node(%d,%d):Slot%d | Type: %s",
        initiatingPlayerIndex, initiatingNodePos.x, initiatingNodePos.y, initiatingSlotIndex,
        targetPlayerIndex, targetNodePos.x, targetNodePos.y, targetSlotIndex,
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

    -- 5. Slot Validation
    local initiatingSlotInfo = getSlotInfo(initiatingSlotIndex)
    local targetSlotInfo = getSlotInfo(targetSlotIndex)

    if not initiatingSlotInfo or not targetSlotInfo then
        local msg = "Internal error: Invalid slot index provided."
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- Check Initiator Slot
    if not initiatingSlotInfo[2] then -- Must be an OUTPUT
        local msg = string.format("Initiating slot %d is not an Output slot.", initiatingSlotIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    if initiatingSlotInfo[1] ~= linkType then -- Must match link type
        local msg = string.format("Initiating slot %d type (%s) does not match link type (%s).", initiatingSlotIndex, tostring(initiatingSlotInfo[1]), tostring(linkType))
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    -- Use isSlotAvailable for the check
    if not initiatingNode:isSlotAvailable(initiatingSlotIndex) then
        local msg = string.format("Initiating slot %d is not available on card '%s'.", initiatingSlotIndex, initiatingNode.title)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    -- TODO: Check if initiating slot is already occupied by another convergence link (covered by isSlotAvailable)
    -- if initiatingNode:isSlotOccupied(initiatingSlotIndex) then ...

    -- Check Target Slot
    if targetSlotInfo[2] then -- Must be an INPUT (is_output must be false)
        local msg = string.format("Target slot %d is not an Input slot.", targetSlotIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    if targetSlotInfo[1] ~= linkType then -- Must match link type
        local msg = string.format("Target slot %d type (%s) does not match link type (%s).", targetSlotIndex, tostring(targetSlotInfo[1]), tostring(linkType))
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    -- Use isSlotAvailable for the check
    if not targetNode:isSlotAvailable(targetSlotIndex) then
        local msg = string.format("Target slot %d is not available on card '%s'.", targetSlotIndex, targetNode.title)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end
    -- TODO: Check if target slot is already occupied by another convergence link (covered by isSlotAvailable)
    -- if targetNode:isSlotOccupied(targetSlotIndex) then ...

    -- Check Slot Compatibility
    if COMPATIBLE_SLOTS[initiatingSlotIndex] ~= targetSlotIndex then
        local msg = string.format("Slot incompatibility: Initiating slot %d cannot link to target slot %d.", initiatingSlotIndex, targetSlotIndex)
        print("  Convergence Failed: " .. msg)
        return false, msg
    end

    -- All validation passed!
    print("  Convergence Slot Validation Passed!")

    -- 6. Execute Link Creation if Valid
    initiatingPlayer:useLinkSet(linkType)
    -- Mark slots as occupied on the cards, passing the link ID
    local linkId = "convLink_" .. self.nextLinkId -- Generate ID before using it
    initiatingNode:markSlotOccupied(initiatingSlotIndex, linkId)
    targetNode:markSlotOccupied(targetSlotIndex, linkId)

    -- Add link details to self.activeConvergenceLinks
    local newLink = {
        linkId = linkId, -- Use the generated ID
        initiatingPlayerIndex = initiatingPlayerIndex,
        initiatingNodeId = initiatingNode.id,
        initiatingSlotIndex = initiatingSlotIndex,
        targetPlayerIndex = targetPlayerIndex,
        targetNodeId = targetNode.id,
        targetSlotIndex = targetSlotIndex,
        linkType = linkType,
    }
    table.insert(self.activeConvergenceLinks, newLink)
    self.nextLinkId = self.nextLinkId + 1 -- Increment for next link
    print(string.format("  Added link %s to activeConvergenceLinks.", newLink.linkId))

    -- Play sound (Skipped as per user request - no sound files)
    -- self.audioManager:playSound("convergence_link")

    -- Check and trigger paradigm shifts
    local shiftOccurred = self:checkAndTriggerParadigmShifts(newLink)

    local msg_success = string.format("Convergence Link Established! (%s)", tostring(linkType))
    print("  " .. msg_success)
    -- Return success, message, and whether a paradigm shift happened
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

    -- 2. Universal Convergence Trigger (GDD 4.7) - Check after adding the new link
    -- This check is only relevant if firstConvergence has already happened and universal hasn't
    if self.paradigmShiftTriggers.firstConvergence and not self.paradigmShiftTriggers.universalConvergence then
        local allPlayersLinked = true
        local linkedPlayerIndices = {}
        -- Collect all unique player indices involved in any link
        for _, link in ipairs(self.activeConvergenceLinks) do
            linkedPlayerIndices[link.initiatingPlayerIndex] = true
            linkedPlayerIndices[link.targetPlayerIndex] = true
        end
        -- Check if every player index is in the linked set
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
    -- Check if the player who just initiated the link has completed their set (assuming 4 links total)
    if not self.paradigmShiftTriggers.individualCompletion then
        local initiatingPlayer = self.players[newLinkData.initiatingPlayerIndex]
        if initiatingPlayer and initiatingPlayer:getInitiatedLinksCount() >= 4 then -- GDD 4.6 implies 4 link sets
            print("[Paradigm] Triggering shift: Individual Completion (Player " .. newLinkData.initiatingPlayerIndex .. ")!")
            self.paradigmShiftTriggers.individualCompletion = true
            paradigmChanged = self:drawNextStandardParadigm() or paradigmChanged
        end
    end

    if paradigmChanged then
        -- TODO: Potentially apply immediate effects of the new paradigm?
        print(string.format("  New Paradigm Active: '%s'", self.currentParadigm and self.currentParadigm.title or "None"))
        -- Update status in PlayState? Requires passing state or using a callback/event system.
    end

    return paradigmChanged -- Return whether a shift happened
end

-- Helper to draw the next standard paradigm and make it active
-- Returns true if a new paradigm was successfully drawn and applied, false otherwise
function GameService:drawNextStandardParadigm()
    if #self.paradigmDeck == 0 then
        print("[Paradigm] No more Standard Paradigms left to draw.")
        return false
    end

    local oldParadigm = self.currentParadigm
    self.currentParadigm = table.remove(self.paradigmDeck, 1) -- Draw from top

    print(string.format("[Paradigm] Shifted from '%s' to '%s' (%s).",
        oldParadigm and oldParadigm.title or "None",
        self.currentParadigm.title,
        self.currentParadigm.id
    ))

    -- TODO: Apply effect of the new paradigm immediately if applicable.
    -- Need to decide what context/state the effect function receives.
    -- if self.currentParadigm.effect then self.currentParadigm.effect(self) end

    return true
end

-- Advance to the next logical phase in the turn
function GameService:advancePhase()
    local currentP = self.currentPhase

    -- If already in Cleanup, cannot advance further
    if currentP == TurnPhase.CLEANUP then
        print("[Service] Cannot advance phase: Already in Cleanup.")
        return false, "Already in final phase"
    end

    local nextP = currentP
    if currentP == TurnPhase.ENERGY_GAIN then
        -- Calculate and award energy before moving to Build
        self:performEnergyGain(self:getCurrentPlayer())
        nextP = TurnPhase.BUILD
    elseif currentP == TurnPhase.BUILD then
        nextP = TurnPhase.ACTIVATE
    elseif currentP == TurnPhase.ACTIVATE then
        nextP = TurnPhase.CONVERGE
    elseif currentP == TurnPhase.CONVERGE then
        nextP = TurnPhase.CLEANUP -- Ready to end turn
    end

    -- If the phase changed, update and return true
    if nextP ~= currentP then
        self.currentPhase = nextP
        print(string.format("[Service] Player %d advanced to %s phase.", self.currentPlayerIndex, self.currentPhase))
        return true, self.currentPhase
    end

    -- Should not be reachable if logic above is correct, but acts as a safeguard
    print("Warning: advancePhase reached unexpected state.")
    return false, "Invalid state or phase"
end

-- End Turn
function GameService:endTurn(state)
    if not state or not state.players then
        return false, "Invalid state provided"
    end
    
    -- Ensure we are in the cleanup phase or ready to end
    while self.currentPhase ~= TurnPhase.CLEANUP do
        local advanced, message = self:advancePhase()
        if not advanced then
            -- If advancePhase fails (e.g., invalid state), bubble up the error.
            -- Alternatively, could log an error and force cleanup, depending on desired strictness.
            print("Error advancing phase during endTurn: " .. (message or "Unknown error"))
            return false, message or "Failed to advance phase to end turn."
        end
        -- Add a safeguard against infinite loops, although phase transitions should prevent this
        if self.currentPhase == TurnPhase.BUILD then -- Example: if we somehow loop back to BUILD
            print("Warning: Phase advancement loop detected in endTurn. Breaking.")
            return false, "Phase advancement loop detected."
        end
    end
    -- Now guaranteed to be in Cleanup phase unless advancePhase failed above

    -- Now in Cleanup phase
    print("[Service] Entering Cleanup Phase for Player " .. self.currentPlayerIndex)

    local currentPlayer = self.players[self.currentPlayerIndex]
    if not currentPlayer then
        return false, "No current player found"
    end
    
    -- Game End Check (moved actual trigger here from triggerGameEndCheck)
    if not self.gameOver then -- Check if game over wasn't already set by VP mid-turn
        if self.rules:isGameEndTriggered(self) then 
            self.gameOver = true
            print("[End Turn] Game end condition met!")
        end
    end
    
    -- If game over is flagged, calculate scores and stop further turn logic
    if self.gameOver then
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
    
    -- Cleanup phase action: Draw cards if hand is below minimum
    if self.rules:shouldDrawCard(currentPlayer) then
        local card = self:drawCard()
        if card then
            currentPlayer:addCardToHand(card)
            print(string.format("  Player %d drew 1 card (Cleanup Phase).", oldIndex))
        end
    end
    
    -- Advance to next player (using modulo to wrap around)
    self.currentPlayerIndex = (oldIndex % #self.players) + 1
    -- Set phase for the new player to ENERGY_GAIN
    self.currentPhase = TurnPhase.ENERGY_GAIN

    -- Keep state in sync for backward compatibility
    if state then
        state.currentPlayerIndex = self.currentPlayerIndex
        state.currentPhase = self.currentPhase -- Sync PlayState to ENERGY_GAIN initially
    end

    -- Immediately advance from ENERGY_GAIN to BUILD, performing energy gain
    local advanced, message = self:advancePhase() -- This calculates energy and sets phase to BUILD
    if not advanced then
        -- Handle potential error during automatic advance
        print("Error automatically advancing phase after energy gain: " .. (message or "Unknown error"))
        -- Might need more robust error handling depending on potential failure cases
        return false, "Error during automatic phase transition."
    end

    -- Update PlayState's phase again after the automatic advance
    if state then
        state.currentPhase = self.currentPhase -- Sync PlayState to BUILD
    end

    -- Update log message to reflect the phase the player actually starts in
    print(string.format("[Service] Turn ended for Player %d. Starting turn for Player %d in %s phase.",
        oldIndex, self.currentPlayerIndex, self.currentPhase))

    return true, string.format("Player %d's turn (%s Phase).", self.currentPlayerIndex, self.currentPhase)
end

-- Clean up resources during game shutdown
function GameService:cleanup()
    -- Clean up audio resources
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

    -- Check Deck Depletion (GDD 4.8)
    -- Note: The GDD says "depleted for the first time". We might need a flag if drawCard sets one.
    -- For now, just checking if empty. The Rules:isGameEndTriggered already handles this check.
    -- We rely on the endTurn logic to call calculateFinalScores if gameOver is set.
    -- GDD 4.8: "The game end is triggered when either [...] occurs at the end of any player's turn:"
    -- So, we just set the flag here based on VP. The endTurn check handles the final trigger.
    -- Removing the deck check from here simplifies things.
    -- if self:isDeckEmpty() then
    --     endReason = "Main deck depleted!"
    -- end

    if endReason then
        print(string.format("[Game End Check] Condition met: %s. Setting gameOver = true.", endReason))
        self.gameOver = true
        -- Note: Final scoring calculation and winner determination happens in endTurn or a dedicated handler.
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
-- GLOBAL ACTIVATION (WIP)
-- ==============================

-- Attempt Activation targeting any node in any player's network
function GameService:attemptActivationGlobal(activatingPlayerIndex, targetPlayerIndex, targetGridX, targetGridY)
    -- Phase check
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

    -- Cannot activate the Reactor directly
    if targetCard.type == Card.Type.REACTOR then
        return false, "Cannot activate the Reactor itself."
    end

    print(string.format("[Service WIP] Attempting GLOBAL activation by P%d targeting P%d's %s (%s) at (%d,%d)", 
        activatingPlayerIndex, targetPlayerIndex, targetCard.title, targetCard.id, targetGridX, targetGridY))

    -- Find the activating player's reactor (destination)
    local activatorReactor = activatingPlayer.network:findReactor()
    if not activatorReactor then
        return false, "Error: Activating player's reactor not found."
    end

    local isValid, pathData, reason = self:findGlobalActivationPath(targetCard, activatorReactor, activatingPlayer)

    if isValid and pathData then
        -- pathData should ideally contain: 
        -- { path = { {card=Card, owner=Player}, ... }, cost = number, isConvergenceStart = boolean }
        local path = pathData.path
        local energyCost = pathData.cost - 1-- GDD 4.5: Cost is path length EXCLUDING reactor
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

            -- Activate target node (using convergence effect if applicable)
            local targetNodeData = path[1] -- First element is the target
            local theTargetCard = targetNodeData.card
            local theTargetOwner = targetNodeData.owner

            if isConvergenceStart then
                 print(string.format("    Activating target %s via CONVERGENCE effect...", targetNodeData.card.title))
                 -- Pass correct owner's network as 3rd arg
                 theTargetCard:activateConvergence(self, activatingPlayer, theTargetOwner.network) -- Use temp vars
            else
                 print(string.format("    Activating target %s via standard effect...", targetNodeData.card.title))
                 -- Pass correct owner's network as 3rd arg
                 theTargetCard:activateEffect(self, activatingPlayer, theTargetOwner.network) -- Use temp vars
            end
            table.insert(activationMessages, string.format("  - %s activated!", targetNodeData.card.title))

            -- Activate subsequent nodes in the path (must belong to activating player)
            for i = 2, pathLength do
                local pathElement = path[i]
                local cardToActivate = pathElement.card
                local cardOwner = pathElement.owner

                -- IMPORTANT: Only activate subsequent effects if they are owned by the activating player
                if cardOwner == activatingPlayer then
                    print(string.format("    Activating subsequent node %s via standard effect...", cardToActivate.title))
                    cardToActivate:activateEffect(self, activatingPlayer, cardOwner.network)
                    table.insert(activationMessages, string.format("  - %s activated!", cardToActivate.title))
                else
                    -- Stop processing effects once path leaves activator's network towards reactor
                    print(string.format("    Node %s belongs to P%d, stopping effect chain.", cardToActivate.title, cardOwner.id))
                    break 
                end
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
    if not targetCard or not activatorReactor or not activatingPlayer then
        return false, nil, "Invalid arguments to findGlobalActivationPath"
    end

    local queue = {}
    local visited = {} -- Keep track of visited card IDs to prevent cycles

    -- Initial state: Start at the target card
    local startOwner = targetCard.owner
    if not startOwner then
         return false, nil, string.format("Target card %s has no owner!", targetCard.id)
    end
    local initialPath = { { card = targetCard, owner = startOwner } }
    table.insert(queue, { node = targetCard, owner = startOwner, path = initialPath })
    visited[targetCard.id] = true

    while #queue > 0 do
        -- === BFS Debug ===
        -- Dequeue
        local currentState = table.remove(queue, 1)
        local currentNode = currentState.node
        local currentOwner = currentState.owner
        local currentPath = currentState.path

        -- Goal Check: Did we reach the activating player's reactor?
        if currentNode == activatorReactor then
            local isConvergenceStart = false
            if #currentPath > 1 then
                -- Check if the owner of the first node (target) is different from the second node
                isConvergenceStart = currentPath[1].owner ~= currentPath[2].owner
            end

            -- Correct Path: Exclude the reactor itself as per GDD 4.5 definition
            local activationPath = {}
            for i = 1, #currentPath do -- Copy all elements including the last one (the reactor)
                activationPath[i] = currentPath[i]
            end

            local pathData = {
                path = activationPath, -- Path including reactor
                cost = #activationPath, -- Cost IS the length of the path including the reactor
                isConvergenceStart = isConvergenceStart
            }
            return true, pathData, nil
        end

        -- Explore Neighbors (Adjacency within the same network)
        for slotIndex = 1, 8 do
            local slotProps = currentNode:getSlotProperties(slotIndex)
            -- Check if it's an available OUTPUT slot on the current node
            if slotProps and slotProps.is_output and currentNode:isSlotAvailable(slotIndex) then
                local adjacentPos = currentNode.network:getAdjacentCoordForSlot(currentNode.position.x, currentNode.position.y, slotIndex)
                if adjacentPos then
                    local neighborNode = currentOwner.network:getCardAt(adjacentPos.x, adjacentPos.y)
                    if neighborNode and not visited[neighborNode.id] then
                        -- Find the corresponding INPUT slot on the neighbor
                        local neighborSlotIndex = currentNode.network:getOpposingSlotIndex(slotIndex)
                        local neighborProps = neighborNode:getSlotProperties(neighborSlotIndex)
                        -- Check if neighbor slot is an available INPUT of the same TYPE
                        local condition = neighborProps and not neighborProps.is_output and neighborNode:isSlotAvailable(neighborSlotIndex) and neighborProps.type == slotProps.type
                        if condition then
                            -- Valid intra-network connection found
                            visited[neighborNode.id] = true
                            local newPath = shallow_copy(currentPath)
                            table.insert(newPath, { card = neighborNode, owner = currentOwner })
                            table.insert(queue, { node = neighborNode, owner = currentOwner, path = newPath })
                            -- print(string.format("    [Pathfinder] Added adjacent node %s via slot %d -> %d", neighborNode.id, slotIndex, neighborSlotIndex)) 
                        end
                    end
                end
            end
        end

        -- Explore Neighbors (Convergence Links)
        for _, link in ipairs(self.activeConvergenceLinks) do
            local neighborNode, neighborOwner, isOutgoingLink
            local neighborNodeId, neighborPlayerIndex, neighborSlotIndex, currentSlotIndex

            -- Check if current node is the OUTPUT end of this link
            if link.initiatingNodeId == currentNode.id and link.initiatingPlayerIndex == currentOwner.id then
                -- Path needs to follow Output -> Input, so this is a valid step
                neighborNodeId = link.targetNodeId
                neighborPlayerIndex = link.targetPlayerIndex
                neighborSlotIndex = link.targetSlotIndex -- The input slot on the neighbor
                currentSlotIndex = link.initiatingSlotIndex -- The output slot on current node

            -- Check if current node is the INPUT end of this link
            elseif link.targetNodeId == currentNode.id and link.targetPlayerIndex == currentOwner.id then
                -- Path needs to follow Output -> Input. Since we trace Target->Reactor, we *can* traverse Input->Output here.
                neighborNodeId = link.initiatingNodeId
                neighborPlayerIndex = link.initiatingPlayerIndex
                neighborSlotIndex = link.initiatingSlotIndex -- The output slot on the neighbor
                currentSlotIndex = link.targetSlotIndex -- The input slot on current node
            end

            -- If we found a potential neighbor via the link
            if neighborNodeId and neighborPlayerIndex then
                neighborOwner = self.players[neighborPlayerIndex]
                if neighborOwner then
                    neighborNode = neighborOwner.network:getCardById(neighborNodeId)
                else
                    neighborNode = nil -- Ensure neighborNode is nil if owner not found
                end
            else
                 neighborNode = nil -- Ensure neighborNode is nil if no potential neighbor found
            end

            -- Check if the neighbor is valid and unvisited
            if neighborNode and not visited[neighborNode.id] then
                -- Double check the slots involved (though link creation should guarantee this)
                -- Important: Check the actual connection based on how we traversed
                -- Path always follows Output->Input. So the slot on the *neighbor* must be the INPUT slot.
                local outputNode, inputNode, outputSlotIdx, inputSlotIdx
                if link.initiatingNodeId == currentNode.id then -- Current is Output end
                    outputNode, inputNode = currentNode, neighborNode
                    outputSlotIdx, inputSlotIdx = currentSlotIndex, neighborSlotIndex
                else -- Current is Input end, neighbor is Output end
                    outputNode, inputNode = neighborNode, currentNode
                    outputSlotIdx, inputSlotIdx = neighborSlotIndex, currentSlotIndex
                end

                local outputSlotProps = outputNode:getSlotProperties(outputSlotIdx)
                local inputSlotProps = inputNode:getSlotProperties(inputSlotIdx)

                local condition = outputSlotProps and outputSlotProps.is_output and
                                inputSlotProps and not inputSlotProps.is_output and
                                outputNode:isSlotAvailable(outputSlotIdx) and
                                inputNode:isSlotAvailable(inputSlotIdx) and
                                outputSlotProps.type == inputSlotProps.type

                if condition then
                    
                    -- Valid convergence connection found
                    visited[neighborNode.id] = true
                    local newPath = shallow_copy(currentPath)
                    table.insert(newPath, { card = neighborNode, owner = neighborOwner })
                    table.insert(queue, { node = neighborNode, owner = neighborOwner, path = newPath })
                    -- print(string.format("    [Pathfinder] Added converged node %s (Owner P%d) via link %s", neighborNode.id, neighborOwner.id, link.linkId))
                end
            end
        end -- End convergence link loop

    end -- End BFS loop

    -- If queue is empty and reactor not found
    return false, nil, "No valid activation path exists to the activator's reactor."
end

-- Calculate and add start-of-turn energy gain based on GDD 4.8
function GameService:performEnergyGain(player)
    if not player then return end

    local energyGain = 1 -- Base gain for Reactor
    local numOpponents = #self.players - 1
    local MAX_ENERGY_GAIN = 4 -- GDD 4.8 cap

    print(string.format("[Energy Gain] Calculating for Player %d (%s). Base gain: %d", player.id, player.name, energyGain))

    -- Calculate bonus based on convergence links
    local linkedOpponentIndices = {}
    local numLinksFromOpponents = 0
    local numUniqueOpponentsLinked = 0

    -- Iterate through all active links
    for _, link in ipairs(self.activeConvergenceLinks) do
        -- Check if the link TARGETS the current player (link.targetPlayerIndex == player.id)
        -- AND originates from an OPPONENT (link.initiatingPlayerIndex ~= player.id)
        if link.targetPlayerIndex == player.id and link.initiatingPlayerIndex ~= player.id then
            numLinksFromOpponents = numLinksFromOpponents + 1
            local opponentId = link.initiatingPlayerIndex
            if not linkedOpponentIndices[opponentId] then
                linkedOpponentIndices[opponentId] = true
                numUniqueOpponentsLinked = numUniqueOpponentsLinked + 1
                print(string.format("  - Found link FROM opponent P%d (Link ID: %s). New unique opponent.", opponentId, link.linkId))
            else
                print(string.format("  - Found link FROM opponent P%d (Link ID: %s). Already counted.", opponentId, link.linkId))
            end
        end
    end

    local bonusEnergy = 0
    local linkedFromAllOpponents = (numUniqueOpponentsLinked >= numOpponents)

    if numLinksFromOpponents > 0 then
        if linkedFromAllOpponents then
            -- Full Link Bonus: +1 Energy per link
            bonusEnergy = numLinksFromOpponents
            print(string.format("  - Linked from ALL %d opponents. Bonus: +%d E (1 per link)", numOpponents, bonusEnergy))
        else
            -- Initial Link Limitation: +1 Energy per unique opponent
            bonusEnergy = numUniqueOpponentsLinked
            print(string.format("  - Linked from %d/%d opponents. Bonus: +%d E (1 per unique opponent)", numUniqueOpponentsLinked, numOpponents, bonusEnergy))
        end
    else
         print("  - No convergence links found from opponents.")
    end

    energyGain = energyGain + bonusEnergy

    -- Apply cap
    if energyGain > MAX_ENERGY_GAIN then
        print(string.format("  - Calculated gain (%d) exceeds cap (%d). Capping to %d.", energyGain, MAX_ENERGY_GAIN, MAX_ENERGY_GAIN))
        energyGain = MAX_ENERGY_GAIN
    end

    -- Add the resource
    if energyGain > 0 then
        player:addResource('energy', energyGain)
        print(string.format("  Added %d Energy to Player %d. New total: %d", energyGain, player.id, player.resources.energy))
    else
         print("  No energy gained this turn.")
    end
end

-- Return both GameService and TurnPhase
return { GameService = GameService, TurnPhase = TurnPhase } 

