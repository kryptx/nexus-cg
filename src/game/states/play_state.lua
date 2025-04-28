-- src/game/states/play_state.lua
-- The main gameplay state

local Card = require('src.game.card')
local Renderer = require('src.rendering.renderer')
local Button = require('src.ui.button') -- Require the Button module
local ServiceModule = require('src.game.game_service') -- Require GameService module
local GameService = ServiceModule.GameService -- Extract the actual GameService table
local TurnPhase = ServiceModule.TurnPhase -- Extract TurnPhase constants
local StyleGuide = require('src.rendering.styles') -- Require the styles
local Text = require('src.ui.text') -- Need Text for wrapping
local SequencePicker = require('src.ui.sequence_picker')
local CameraUtil = require('src.utils.camera') -- Import Camera utility for coordinate and zoom handling
local Vector = require('src.utils.vector') -- Import Vector utility for orientation math
local Animations = require('src.game.animations')

-- Define port compatibility (Output Port -> Input Port)
local COMPATIBLE_PORTS = {
    [Card.Ports.TOP_LEFT]     = Card.Ports.BOTTOM_LEFT,  -- Culture Out -> Culture In
    [Card.Ports.BOTTOM_RIGHT] = Card.Ports.TOP_RIGHT,    -- Technology Out -> Technology In
    [Card.Ports.LEFT_TOP]     = Card.Ports.RIGHT_TOP,    -- Knowledge Out -> Knowledge In
    [Card.Ports.RIGHT_BOTTOM] = Card.Ports.LEFT_BOTTOM,  -- Resource Out -> Resource In
}

local PlayState = {}

-- Constants for Setup (adjust as needed)
local NUM_PLAYERS = 3
local KEYBOARD_PAN_SPEED = 600 -- Base pixels per second at zoom 1.0

-- UI Constants (mirrored from Renderer for input checking)
local UI_ICON_SIZE = 18
local LINK_UI_ICON_SIZE = UI_ICON_SIZE * 0.8
local LINK_UI_BOX_SIZE = LINK_UI_ICON_SIZE + 4
local LINK_UI_ICON_SPACING = 3
local LINK_UI_GROUP_SPACING = 5
local LINK_UI_START_X = 10
local LINK_UI_Y_OFFSET = 21 -- Relative to resource line Y
local BUTTON_GAP = 10 -- Moved here as an UPVALUE constant

-- Define Card module here for use in getPortInfo, or require it
local Card = require('src.game.card')

-- Helper function for phase descriptions
local function getPhaseDescription(phase)
    if phase == TurnPhase.BUILD then
        return [[Build Phase:
- Place 1 Node: Click a card in hand, then click a valid grid location. Cost: Material/Data.
- Discard 1 Card: Select a card, then click 'Discard' for 1 Material OR 1 Data.
- Pass: Click 'Next Phase'.]]
    elseif phase == TurnPhase.ACTIVATE then
        return [[Activate Phase:
- Activate Path: Right-click a Node (yours or opponent's via link) to activate the path back to your Reactor. Cost: Energy per Node in path.
- Pass: Click 'Next Phase'.]]
    elseif phase == TurnPhase.CONVERGE then
        return [[Converge Phase:
- Create Link: Click a Link icon in the Link menu, then click a valid Output port on your network, then a valid Input port on an opponent's network. Uses a Link Set.
- Pass: Click 'End Turn'.]]
    else
        return "Unknown Phase"
    end
end

-- Helper function to get port position and implicit type based on GDD 4.3 (Corrected)
-- Note: This version uses renderer instance for dimensions
local function getPortInfo(renderer, portIndex)
    if not renderer then return nil end -- Need renderer for constants
    -- Returns { x_offset, y_offset, type, is_output }
    local cardW = renderer.CARD_WIDTH
    local cardH = renderer.CARD_HEIGHT
    local halfW = cardW / 2
    local halfH = cardH / 2
    local quartW = cardW / 4
    local quartH = cardH / 4

    if portIndex == Card.Ports.TOP_LEFT then return { quartW, 0, Card.Type.CULTURE, true } end
    if portIndex == Card.Ports.TOP_RIGHT then return { halfW + quartW, 0, Card.Type.TECHNOLOGY, false } end
    if portIndex == Card.Ports.BOTTOM_LEFT then return { quartW, cardH, Card.Type.CULTURE, false } end
    if portIndex == Card.Ports.BOTTOM_RIGHT then return { halfW + quartW, cardH, Card.Type.TECHNOLOGY, true } end
    if portIndex == Card.Ports.LEFT_TOP then return { 0, quartH, Card.Type.KNOWLEDGE, true } end
    if portIndex == Card.Ports.LEFT_BOTTOM then return { 0, halfH + quartH, Card.Type.RESOURCE, false } end
    if portIndex == Card.Ports.RIGHT_TOP then return { cardW, quartH, Card.Type.KNOWLEDGE, false } end
    if portIndex == Card.Ports.RIGHT_BOTTOM then return { cardW, halfH + quartH, Card.Type.RESOURCE, true } end
    return nil
end

function PlayState:new(animationController, gameService) -- Accept animationController and gameService
    local instance = setmetatable({}, { __index = PlayState })
    instance:init(animationController, gameService) -- Pass it to init
    return instance
end

function PlayState:init(animationController, gameService) -- Accept animationController and gameService
    -- Initialize state variables
    self.players = {}
    self.sequencePicker = nil -- NEW: Sequence picker overlay
    self.renderer = Renderer:new() -- Create renderer instance
    self.animationController = animationController -- Store the controller
    self.selectedHandIndex = nil -- Track selected card in hand
    self.hoveredHandIndex = nil -- Add this
    self.handCardBounds = {} -- Store bounding boxes returned by renderer
    self.statusMessage = "" -- For displaying feedback
    self.activeParadigm = nil -- Track the currently active Paradigm Shift card object
    self.currentPhase = nil -- Track the current turn phase locally
    self.playerWorldOrigins = {}
    self.isPaused = false
    self.showHelpBox = true -- Enable help box by default
    self.BOTTOM_BUTTON_AREA_HEIGHT = 60 -- <<< STORE CONSTANT ON INSTANCE

    -- Camera State
    self.cameraX = -love.graphics.getWidth() / 2 -- Center initial view roughly
    self.cameraY = -love.graphics.getHeight() / 2
    self.cameraRotation = 0 -- Initialize camera rotation in radians
    self.cameraZoom = 1.0
    self.minZoom = 0.2
    self.maxZoom = 3.0
    self.isPanning = false
    self.lastMouseX = 0
    self.lastMouseY = 0

    -- Convergence Selection State
    self.convergenceSelectionState = nil -- nil, "selecting_own_output", "selecting_opponent_input"
    self.selectedConvergenceLinkType = nil -- Card.Type.TECHNOLOGY, etc.
    self.hoveredLinkType = nil -- Track which link UI element is hovered
    self.initiatingConvergenceNodePos = nil -- {x, y} table
    self.initiatingConvergencePortIndex = nil -- 1-8
    self.targetConvergencePlayerIndex = nil
    self.targetConvergenceNodePos = nil -- {x, y} table
    self.targetConvergencePortIndex = nil -- 1-8

    -- Hover State for Debugging
    self.debugDrawPortHitboxes = false -- NEW: Toggle for drawing port hitboxes
    self.hoverGridX = nil
    self.hoverGridY = nil

    -- State for Yes/No Prompt
    self.isDisplayingPrompt = false -- NEW: Flag if prompt is active
    self.promptQuestion = nil       -- NEW: Text of the question
    self.promptYesBounds = nil      -- NEW: Bounding box for Yes button (set by renderer)
    self.promptNoBounds = nil       -- NEW: Bounding box for No button (set by renderer)

    -- Initialize Game Service (using injected or create new)
    self.gameService = gameService or GameService:new() -- Use the injected gameService if provided
    -- Ensure activationService exists for tests injecting mockGameService without activationService
    if not self.gameService.activationService then
        self.gameService.activationService = self.gameService
    end

    -- Create UI elements (initial placeholder creation, positions set in _recalculateLayout)
    local uiFonts = self.renderer.fonts -- Get the fonts table
    local uiStyleGuide = self.renderer.styleGuide -- Get the style guide

    -- End Turn / Next Phase buttons (Placeholder creation)
    self.buttonEndTurn = Button:new(0, 0, "End Turn", function() self:endTurn() end, 0, 0, uiFonts, uiStyleGuide)
    self.buttonAdvancePhase = Button:new(0, 0, "Next Phase", function() self:advancePhase() end, 0, 0, uiFonts, uiStyleGuide)

    -- Create discard buttons (Placeholder creation)
    local discardText = "Discard for 1 "
    self.buttonDiscardMaterial = Button:new(0, 0, discardText, function() self:discardSelected('material') end, 0, 0, uiFonts, uiStyleGuide, nil, self.renderer.icons.material)
    self.buttonDiscardData = Button:new(0, 0, discardText, function() self:discardSelected('data') end, 0, 0, uiFonts, uiStyleGuide, nil, self.renderer.icons.data)

    -- Help Toggle button (Placeholder creation)
    self.buttonToggleHelp = Button:new(0, 0, "Toggle Help", function()
        self.showHelpBox = not self.showHelpBox
        print("Help Box Toggled: ", self.showHelpBox)
    end, 0, 0, uiFonts, uiStyleGuide)

    -- Update uiElements list
    self.uiElements = { self.buttonEndTurn, self.buttonAdvancePhase, self.buttonDiscardMaterial, self.buttonDiscardData, self.buttonToggleHelp }

    -- Pause Menu Buttons (Placeholder creation)
    self.pauseMenuButtons = {
        Button:new(0, 0, "Resume Game", function() self.isPaused = false end, 0, 0, uiFonts, uiStyleGuide),
        Button:new(0, 0, "Main Menu", function() print("TODO: Transition to Main Menu state") end, 0, 0, uiFonts, uiStyleGuide),
        Button:new(0, 0, "Quit Game", function() love.event.quit() end, 0, 0, uiFonts, uiStyleGuide)
    }

    -- Calculate initial layout using current window size
    self:_recalculateLayout(love.graphics.getWidth(), love.graphics.getHeight())
    print("Initial layout calculated using window size: " .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight())

    -- After existing methods, add helper to start each activation step
    self.highlightedActivationCard = nil  -- Track the card being highlighted during activation
    self.activationSequence = nil         -- Store pending activation sequence
end

-- Generic camera centering and rotation helper
function PlayState:centerCameraOnPlayer(playerIndex)
    local origin = self.playerWorldOrigins[playerIndex] or { x = 0, y = 0 }
    local player = self.players[playerIndex]
    local targetRotation = (player and player.orientation) or 0
    local targetZoom = 1.0 -- Standard zoom level to always animate to

    -- Use CameraUtil to handle the animation or instant move
    CameraUtil.animateToTarget(
        self, -- Pass the state object (PlayState instance)
        self.animationController,
        origin.x,
        origin.y,
        targetRotation,
        targetZoom,
        0.8 -- Animation duration
    )
end

-- Add this method to update camera position during animations
function PlayState:updateCamera(dt)
    -- Delegate update logic to CameraUtil
    CameraUtil.updateFromAnimation(self, self.animationController)
end

-- Add this helper function to PlayState
function PlayState:_calculatePlayerWorldOrigins()
    -- Example: Arrange players in a circle in world space
    -- Radius might depend on number of players or be fixed
    local worldRadius = 1000 -- Adjust as needed
    self.playerWorldOrigins = {} -- Ensure this table exists on self
    local numPlayers = #self.players
    if numPlayers == 0 then return end -- Avoid division by zero

    print("[DEBUG] Calculating world origins...")
    for i = 1, numPlayers do
        local player = self.players[i]
        if not player or player.orientation == nil then
             print(string.format("Warning: Player %d or orientation is nil during layout calculation.", i))
             -- Assign a default based on index if needed for robustness
             player.orientation = (i-1) * (2 * math.pi / numPlayers) 
        end
        -- Use player.orientation directly (assuming it's radians and 0 means player's +Y points East)
        local angle = player.orientation + math.pi/2
        local originVec = Vector.rotate(Vector.new(worldRadius, 0), angle)
        self.playerWorldOrigins[i] = originVec
        print(string.format("[DEBUG] Player %d world origin set to (%f, %f) for orientation %f rad", i, originVec.x, originVec.y, angle))
    end
end

function PlayState:enter()
    print("Entering Play State - Initializing Game...")
    
    -- Initialize the game service first
    self.gameService:initializeGame(NUM_PLAYERS)
    
    -- Sync our state with GameService
    self.players = self.gameService:getPlayers()
    self.activeParadigm = self.gameService:getCurrentParadigm() -- Get the active paradigm
    self.currentPhase = self.gameService:getCurrentPhase() -- Get initial phase

    -- Calculate fixed world origins AFTER players are initialized
    self:_calculatePlayerWorldOrigins() 
    -- Center camera on the current player after computing origins
    self:centerCameraOnPlayer(self.gameService.currentPlayerIndex)
    
    -- Force layout recalculation based on current window size
    self:_recalculateLayout(love.graphics.getWidth(), love.graphics.getHeight())
    
    self:updateStatusMessage() -- Update status initially
    
    print("Play State Initialization Complete.")
end

-- Helper to update the status message including the current phase
function PlayState:updateStatusMessage(message)
    local baseStatus = message or ""
    if baseStatus == "" then -- Construct default if no message passed
         baseStatus = string.format("Player %d's turn.", self.gameService.currentPlayerIndex)
    end
    
    local phaseStr = self.currentPhase or "Unknown Phase"
    local paradigmStr = ""
    if self.activeParadigm then
        paradigmStr = string.format(" | Paradigm: %s", self.activeParadigm.title)
    end
    
    self.statusMessage = string.format("%s (%s Phase)%s", baseStatus, phaseStr, paradigmStr)
end

-- Action: End the current turn (Delegates to service)
function PlayState:endTurn()
    local success, message = self.gameService:endTurn(self) -- Pass self to allow GameService to update state.currentPhase
    if success then
        self.currentPhase = self.gameService:getCurrentPhase() -- Re-sync phase after successful turn end
        self:resetSelectionAndStatus()
        self:updateStatusMessage() -- Update status for new turn/phase

        -- Center camera on the new active player's grid origin and orientation
        local newPlayerIndex = self.gameService.currentPlayerIndex
        self:centerCameraOnPlayer(newPlayerIndex)

        print(string.format("Camera centered on Player %d for their turn.", newPlayerIndex))

    else
        self:updateStatusMessage(message) -- Show error message
    end
end

-- Action: Advance to the next phase (Delegates to service)
function PlayState:advancePhase()
    local success, newPhaseOrMessage = self.gameService:advancePhase()
    if success then
        self.currentPhase = newPhaseOrMessage
        self:updateStatusMessage() -- Update display
        print("Advanced to phase: " .. self.currentPhase)
    else
        self:updateStatusMessage(newPhaseOrMessage) -- Show error/info
        print("Could not advance phase: " .. newPhaseOrMessage)
    end
end

-- Action: Discard the selected card (Delegates to service)
function PlayState:discardSelected(resourceType)
    if self.selectedHandIndex then
        -- Pass the resourceType to the game service
        local success, message = self.gameService:discardCard(self, self.selectedHandIndex, resourceType)
        if success then
            self:resetSelectionAndStatus()
             self:updateStatusMessage(message) -- Show discard success message
        else
            self:updateStatusMessage(message) -- Show error message
        end
    end
end

-- Helper to reset selection state
function PlayState:resetSelectionAndStatus()
    self.selectedHandIndex = nil
    self.hoveredHandIndex = nil
    self.handCardBounds = {}
    -- Ensure both discard buttons are disabled
    self.buttonDiscardMaterial:setEnabled(false)
    self.buttonDiscardData:setEnabled(false)
    -- self.statusMessage = newStatus or "" -- Status is now handled by updateStatusMessage
end

function PlayState:update(stateManager, dt)
    local mx, my = love.mouse.getPosition()
    if self.sequencePicker then
        self.sequencePicker:update()
        return
    end
    local mouseDown = love.mouse.isDown(1)

    -- If displaying prompt, only update essential UI or nothing game-related
    if self.isDisplayingPrompt then
        -- Optionally update prompt buttons if they have hover states
        -- For now, no updates needed while prompt is up, handled in draw/mousepressed
        return
    end

    if self.isPaused then
        -- Update only pause menu buttons when paused
        for _, button in ipairs(self.pauseMenuButtons) do
            if button.update then
                button:update(mx, my, mouseDown)
            end
        end
        return -- Don't update game elements or handle game input when paused
    end

    -- If not paused, proceed with regular updates:
    -- Update UI elements (buttons)
    for _, element in ipairs(self.uiElements) do
        if element.update then
            element:update(mx, my, mouseDown)
        end
    end

    -- Keyboard Panning Logic (only if not paused and not displaying prompt)
    local dx, dy = 0, 0 -- Camera-local desired movement
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then dy = dy - 1 end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then dy = dy + 1 end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then dx = dx - 1 end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then dx = dx + 1 end

    if dx ~= 0 or dy ~= 0 then
        local effectivePanSpeed = KEYBOARD_PAN_SPEED / self.cameraZoom
        local moveSpeed = effectivePanSpeed * dt
        
        -- Normalize if moving diagonally
        if dx ~= 0 and dy ~= 0 then
            moveSpeed = moveSpeed / math.sqrt(2)
        end

        -- Rotate and scale the movement vector using Vector utility
        local movement = Vector.new(dx, dy)
        local worldMovement = Vector.scale(Vector.rotate(movement, self.cameraRotation or 0), moveSpeed)
        self.cameraX = self.cameraX + worldMovement.x
        self.cameraY = self.cameraY + worldMovement.y
    end

    -- Update camera position during animations
    self:updateCamera(dt)
    -- Update highlight pulse timer
    if self.highlightedActivationCard then
        self.highlightedActivationCard.elapsed = (self.highlightedActivationCard.elapsed or 0) + dt
    end
end

function PlayState:draw(stateManager)
    love.graphics.clear(0.3, 0.3, 0.3, 1)
    if self.sequencePicker then
        -- Draw resource UI behind sequence picker so the player can still see their resources
        local currentPlayer = self.players[self.gameService.currentPlayerIndex]
        -- Render the UI (VP, resources, links) in the foreground
        self.sequencePicker:draw()
        self.renderer:drawUI(currentPlayer, nil, self.currentPhase, nil)
        return
    end
    if not self.players or #self.players == 0 or not self.renderer then return end

    -- Get current player for UI/Hand drawing later
    local currentPlayer = self.players[self.gameService.currentPlayerIndex]
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Get cards currently being animated
    local animatingCardIds = {}
    if self.animationController then
        animatingCardIds = self.animationController:getAnimatingCardIds()
    end

    -- Apply camera transform before drawing the table: pivot to center, rotate, zoom, then translate camera
    love.graphics.push()
    -- Pivot to screen center for rotation
    love.graphics.translate(screenW/2, screenH/2)
    love.graphics.rotate(-(self.cameraRotation or 0))
    -- Apply zoom
    love.graphics.scale(self.cameraZoom, self.cameraZoom)
    -- Translate the world so cameraX, cameraY land at screen center
    love.graphics.translate(-self.cameraX, -self.cameraY)

    -- Draw ALL player networks using rotated table wrapper
    local activeLinks = self.gameService.activeConvergenceLinks -- Get active links
    -- Prepare highlight box data (if needed)
    local highlightMargin = 30 -- <<< MOVED DECLARATION HERE
    local highlightBoxData = nil
    local highlightBoxX0, highlightBoxY0, highlightBoxWidth, highlightBoxHeight

    -- Calculate network bounds in the player's *local* grid space
    local minGridX, maxGridX, minGridY, maxGridY = nil, nil, nil, nil
    if currentPlayer and currentPlayer.network and currentPlayer.network.cards then
        for _, card in pairs(currentPlayer.network.cards) do
            if type(card) == "table" and card.position then
                if not minGridX or card.position.x < minGridX then minGridX = card.position.x end
                if not maxGridX or card.position.x > maxGridX then maxGridX = card.position.x end
                if not minGridY or card.position.y < minGridY then minGridY = card.position.y end
                if not maxGridY or card.position.y > maxGridY then maxGridY = card.position.y end
            end
        end
    end

    if minGridX then -- Check if any cards were found
        -- Convert grid coords to world coords relative to player's LOCAL origin (0,0)
        local minWorldX0, minWorldY0 = self.renderer:gridToWorldCoords(minGridX, minGridY, 0, 0)
        local maxCellWorldX0, maxCellWorldY0 = self.renderer:gridToWorldCoords(maxGridX, maxGridY, 0, 0)
        local maxWorldX0 = maxCellWorldX0 + self.renderer.CARD_WIDTH -- Use renderer instance
        local maxWorldY0 = maxCellWorldY0 + self.renderer.CARD_HEIGHT -- Use renderer instance

        highlightBoxX0 = minWorldX0 - highlightMargin
        highlightBoxY0 = minWorldY0 - highlightMargin
        highlightBoxWidth = (maxWorldX0 + highlightMargin) - highlightBoxX0
        highlightBoxHeight = (maxWorldY0 + highlightMargin) - highlightBoxY0
    else
        -- Default box around local origin (0,0) if no cards placed yet
        highlightBoxX0 = 0 - highlightMargin
        highlightBoxY0 = 0 - highlightMargin
        highlightBoxWidth = self.renderer.CARD_WIDTH + (2 * highlightMargin) -- Use renderer instance
        highlightBoxHeight = self.renderer.CARD_HEIGHT + (2 * highlightMargin) -- Use renderer instance
    end

    -- Prepare highlight box data (if needed and calculated correctly)
    if type(highlightBoxX0) == "number" and type(highlightBoxY0) == "number" and 
       type(highlightBoxWidth) == "number" and type(highlightBoxHeight) == "number" then
        highlightBoxData = {
            x = highlightBoxX0, y = highlightBoxY0, 
            w = highlightBoxWidth, h = highlightBoxHeight
        }
    else
        print("Warning: Highlight box dimensions were not calculated correctly. Skipping highlight box.")
        print(string.format("Values: x=%s, y=%s, w=%s, h=%s", 
            tostring(highlightBoxX0), tostring(highlightBoxY0), 
            tostring(highlightBoxWidth), tostring(highlightBoxHeight)))
    end
    
    self.renderer:drawTable(
        self.players,
        self.gameService.currentPlayerIndex, -- Pass the local player index
        activeLinks,
        animatingCardIds,
        highlightBoxData, -- Pass highlight box data
        self.cameraZoom, -- <<< Pass cameraZoom for line width calculation
        self.playerWorldOrigins -- <<< CORRECTED VARIABLE NAME
    )

    -- Draw the highlighted activation card
    if self.highlightedActivationCard then
        local hl = self.highlightedActivationCard
        -- Animated pulsing, rotation, and scale for activation highlight
        local speed = 4.0
        local scaleAmp = 0.2
        local baseScale = 1.1
        local pulse = math.cos(hl.elapsed * speed) * scaleAmp + baseScale  -- scale [1,1.2]
        local alpha = math.cos(hl.elapsed * speed + math.pi/2) * 0.15 + 0.85  -- opacity [0.7,1.0]

        love.graphics.push()
        -- Apply camera transform and highlight orientation
        love.graphics.translate(hl.center.x, hl.center.y)
        love.graphics.rotate(hl.orientation or 0)
        love.graphics.scale(pulse, pulse)
        love.graphics.setColor(0, 0.5, 1, alpha)
        -- Set line width so final width remains constant under scaling
        love.graphics.setLineWidth((2 / self.cameraZoom) / pulse)
        love.graphics.rectangle('line', -hl.halfW, -hl.halfH, hl.halfW * 2, hl.halfH * 2)
        love.graphics.pop()
    end

    -- Restore camera transform after drawing the table
    love.graphics.pop()

    -- Draw any active card animations (after networks, before UI)
    if self.animationController then
        local activeAnimations = self.animationController:getActiveAnimations()
        for id, animation in pairs(activeAnimations) do
            if animation.type == 'cardPlay' then
                -- Need to re-apply camera for world-space animations (Correct Order)
                love.graphics.push()
                local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
                love.graphics.translate(sw/2, sh/2)
                love.graphics.rotate(-(self.cameraRotation or 0))
                love.graphics.scale(self.cameraZoom, self.cameraZoom)
                love.graphics.translate(-self.cameraX, -self.cameraY)
                self.renderer:drawCardAnimation(animation)
                love.graphics.pop()
            elseif animation.type == 'shudder' then
                -- Shudder might also be world-space, apply camera (Correct Order)
                love.graphics.push()
                local sw2, sh2 = love.graphics.getWidth(), love.graphics.getHeight()
                love.graphics.translate(sw2/2, sh2/2)
                love.graphics.rotate(-(self.cameraRotation or 0))
                love.graphics.scale(self.cameraZoom, self.cameraZoom)
                love.graphics.translate(-self.cameraX, -self.cameraY)
                self.renderer:drawCardAnimation(animation)
                love.graphics.pop()
            end
            -- handShudder animations will be drawn after the safe area and hand (screen space)
        end
    end

    -- Draw highlight box around the active player's grid area
    local activePlayerIndex = self.gameService.currentPlayerIndex
    local activePlayer = self.players[activePlayerIndex]
    -- local highlightMargin = 30 -- Reduced margin slightly -- <<< REMOVED FROM HERE

    -- Draw grid hover highlight (only for current player's grid space)
    -- Calculate isInSafeArea again here for clarity
    local screenH = love.graphics.getHeight()
    local handCardH_Draw = self.renderer.HAND_CARD_HEIGHT or (140 * 0.6)
    local safeAreaTopY_Draw = screenH - self.BOTTOM_BUTTON_AREA_HEIGHT - handCardH_Draw - 20 -- <<< USE self.
    local mouseX, mouseY = love.mouse.getPosition() -- Get current mouse position
    local isInSafeArea_Draw = (mouseY >= safeAreaTopY_Draw)

    if not self.isDisplayingPrompt and not isInSafeArea_Draw then -- <<< Added check for not isInSafeArea_Draw
        local selectedCard = self.selectedHandIndex and currentPlayer.hand[self.selectedHandIndex] or nil
        -- Only draw highlight if a card is selected AND we are hovering over the grid (hoverGridX/Y won't be nil if not in safe area)
        if selectedCard and self.hoverGridX ~= nil and self.hoverGridY ~= nil and self.currentPhase == TurnPhase.BUILD then
            -- local currentOrigin = self.playerOrigins[self.gameService.currentPlayerIndex] or {x=0, y=0} -- REMOVED
            local isValid = self.gameService:isPlacementValid(self.gameService.currentPlayerIndex, selectedCard, self.hoverGridX, self.hoverGridY)
            -- Apply full camera transform: pivot to screen center, rotate, zoom, pan
            local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
            love.graphics.push()
            love.graphics.translate(sw/2, sh/2)
            love.graphics.rotate(-(self.cameraRotation or 0))
            love.graphics.scale(self.cameraZoom, self.cameraZoom)
            love.graphics.translate(-self.cameraX, -self.cameraY)
            local origin = self.playerWorldOrigins[self.gameService.currentPlayerIndex] or { x = 0, y = 0 }
            self.renderer:drawHoverHighlight(
                self.hoverGridX,
                self.hoverGridY,
                selectedCard,
                isValid,
                origin.x,
                origin.y,
                activePlayer.orientation or 0 -- Pass player orientation
            )
            love.graphics.pop()
        end
    end

    -- [[[ Draw UI Safe Area Background ]]]
    local screenW = love.graphics.getWidth()
    -- Use the same safeAreaTopY calculation as in the highlight check
    local safeAreaHeight = screenH - safeAreaTopY_Draw -- This uses the already calculated safeAreaTopY_Draw
    local originalColor = {love.graphics.getColor()}
    love.graphics.setColor(0.1, 0.1, 0.1, 0.6) -- Dark, semi-transparent
    love.graphics.rectangle('fill', 0, safeAreaTopY_Draw, screenW, safeAreaHeight)
    love.graphics.setColor(originalColor) -- Restore color
    -- [[[ End Draw UI Safe Area Background ]]]

    -- Ensure default line width for screen-space UI (Hand)
    love.graphics.setLineWidth(1)
    -- Now draw the actual hand (will draw over the grid highlight and preview)
    -- Pass animatingCardIds to skip cards being animated
    self.handCardBounds = self.renderer:drawHand(currentPlayer, self.selectedHandIndex, animatingCardIds)
    
    -- Draw any handShudder animations AFTER the safe area and hand are drawn
    if self.animationController then
        local activeAnimations = self.animationController:getActiveAnimations()
        for id, animation in pairs(activeAnimations) do
            if animation.type == 'handShudder' then
                self.renderer:drawHandCardAnimation(animation)
            end
        end
    end
    
    -- Draw hovered hand card preview near the mouse
    if not self.isDisplayingPrompt and self.hoveredHandIndex then
        local hoveredCard = currentPlayer.hand[self.hoveredHandIndex]
        if hoveredCard then
            local mouseX, mouseY = love.mouse.getPosition()
            local cardW = self.renderer.CARD_WIDTH or 100
            local cardH = self.renderer.CARD_HEIGHT or 140
            local previewScale = 2.0 -- Define scale factor
            local previewCardW = cardW * previewScale
            local previewCardH = cardH * previewScale

            -- Calculate position centered above cursor
            local gap = 15
            local previewX = mouseX - previewCardW / 2 -- Center using scaled width
            local previewY = mouseY - previewCardH - gap -- Position above using scaled height

            self.renderer:drawHoveredHandCard(hoveredCard, previewX, previewY, previewScale) -- Pass scale
        end
    end

    -- Pass additional state for UI rendering
    self.renderer:drawUI(currentPlayer, self.hoveredLinkType, self.currentPhase, self.convergenceSelectionState)

    -- Ensure default line width for screen-space UI (Buttons)
    love.graphics.setLineWidth(1)
    -- Draw UI elements (buttons)
    for _, element in ipairs(self.uiElements) do
        element:draw()
    end

    -- Set UI font for status/debug text
    local originalFont = love.graphics.getFont()
    love.graphics.setFont(self.renderer.fonts.uiStandard) -- Access via fonts sub-table

    -- Draw status message (Top Center)
    love.graphics.setColor(1, 1, 1, 1)
    -- Calculate position for top-center display
    local statusText = self.statusMessage or ""
    local statusWidth = love.graphics.getFont():getWidth(statusText) -- Uses currently set font
    local statusX = (screenW - statusWidth) / 2
    local statusY = 10 -- Position near the top
    love.graphics.print(statusText, statusX, statusY)

    -- Draw turn indicator & Other Debug Info
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(string.format("Current Turn: Player %d (%s)", self.gameService.currentPlayerIndex, currentPlayer.name), 10, 10)
    love.graphics.print("MMB Drag / WASD: Pan | Wheel: Zoom | P: Next Phase", screenW / 2 - 200, screenH - 20)

    -- [[[ Draw Help Box (if enabled) ]]]
    if self.showHelpBox and self.currentPhase and not self.isDisplayingPrompt then
        local helpText = getPhaseDescription(self.currentPhase)
        local helpPadding = 10
        local helpBoxMaxWidth = 250 -- Max width before text wraps
        local helpFont = self.renderer.fonts.uiSmall or self.renderer.fonts.uiStandard -- Use smaller font if available

        love.graphics.setFont(helpFont) -- Set font for width/height calculation

        -- Use the Text utility to wrap and calculate height
        local wrappedHelpText, helpLines = Text.wrapText(helpFont, helpText, helpBoxMaxWidth)
        local helpBoxHeight = helpLines * helpFont:getHeight() + (2 * helpPadding)
        local helpBoxWidth = helpBoxMaxWidth + (2 * helpPadding) -- Use max width for box size

        -- Position the box (e.g., below the help toggle button)
        local helpBoxX = screenW - helpBoxWidth - BUTTON_GAP
        local helpBoxY = self.buttonToggleHelp.y + self.buttonToggleHelp.height + BUTTON_GAP

        -- Draw background
        local originalColor = {love.graphics.getColor()}
        love.graphics.setColor(StyleGuide.HELP_BOX_BACKGROUND_COLOR) -- Use StyleGuide color
        love.graphics.rectangle('fill', helpBoxX, helpBoxY, helpBoxWidth, helpBoxHeight)

        -- Draw border
        love.graphics.setLineWidth(1)
        love.graphics.setColor(StyleGuide.HELP_BOX_BORDER_COLOR) -- Use StyleGuide color
        love.graphics.rectangle('line', helpBoxX, helpBoxY, helpBoxWidth, helpBoxHeight)

        -- Draw wrapped text
        love.graphics.setColor(StyleGuide.HELP_BOX_TEXT_COLOR) -- Use StyleGuide color
        love.graphics.printf(wrappedHelpText, helpBoxX + helpPadding, helpBoxY + helpPadding, helpBoxMaxWidth, 'left')

        love.graphics.setColor(originalColor) -- Restore original color
    end
    -- [[[ End Draw Help Box ]]]

    -- NEW: Check if we need to display the prompt
    if self.gameService.isWaitingForInput then
        self.isDisplayingPrompt = true -- Sync state
        self.promptQuestion = self.gameService.pendingQuestion
        if self.renderer.drawYesNoPrompt then
            -- Draw the prompt and store the button bounds it returns
            self.promptYesBounds, self.promptNoBounds = self.renderer:drawYesNoPrompt(
                self.promptQuestion, 
                self.gameService.pendingDisplayOptions
            )
        else
            -- Fallback if renderer function doesn't exist yet
            love.graphics.setColor(1,0,0,1)
            love.graphics.print("ERROR: Renderer:drawYesNoPrompt not implemented!", screenW/2 - 150, screenH/2)
        end
    else
        -- Clear prompt state if GameService is no longer waiting
        if self.isDisplayingPrompt then
            self.isDisplayingPrompt = false
            self.promptQuestion = nil
            self.promptYesBounds = nil
            self.promptNoBounds = nil
        end
    end

    -- Restore original font before drawing pause menu (if needed)
    love.graphics.setFont(originalFont)

    -- [[[ Draw Pause Menu (if paused) ]]]
    if self.isPaused then
        -- Draw semi-transparent overlay
        local originalColor = {love.graphics.getColor()}
        love.graphics.setColor(0, 0, 0, 0.7) -- Black, 70% opacity
        love.graphics.rectangle('fill', 0, 0, screenW, screenH)

        -- Draw "Paused" title
        love.graphics.setFont(self.renderer.fonts.uiStandard) -- Use a suitable font
        love.graphics.setColor(1, 1, 1, 1) -- White text
        local titleText = "Paused"
        local titleWidth = love.graphics.getFont():getWidth(titleText)
        local titleX = (screenW - titleWidth) / 2
        local titleY = 50 -- Position near the top
        love.graphics.print(titleText, titleX, titleY)

        -- Draw pause menu buttons
        for _, button in ipairs(self.pauseMenuButtons) do
            button:draw()
        end

        -- Restore original color and font
        love.graphics.setColor(originalColor)
        love.graphics.setFont(originalFont)
    end
    -- [[[ End Draw Pause Menu ]]]

    -- [[[ DEBUG: Draw Port Hitboxes (World Space) ]]]
    if self.debugDrawPortHitboxes then
        love.graphics.push()
        -- Re-apply camera transform
        local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
        love.graphics.translate(sw/2, sh/2)
        love.graphics.rotate(-(self.cameraRotation or 0))
        love.graphics.scale(self.cameraZoom, self.cameraZoom)
        love.graphics.translate(-self.cameraX, -self.cameraY)
 
        local clickRadius = 10 -- Match _getClickedPort
        local origR, origG, origB, origA = love.graphics.getColor()
        local origLineWidth = love.graphics.getLineWidth()
        love.graphics.setColor(1, 0, 1, 0.8) -- Magenta, slightly transparent
        love.graphics.setLineWidth(1 / self.cameraZoom)
 
        local cardW = self.renderer.CARD_WIDTH
        local cardH = self.renderer.CARD_HEIGHT
        local gridSpacing = self.renderer.GRID_SPACING

        for pIdx, player in ipairs(self.players) do
            if player.network and player.network.cards then
                local origin = self.playerWorldOrigins[pIdx] or {x=0, y=0}
                local theta = player.orientation or 0 
                for _, card in pairs(player.network.cards) do
                    if card and card.position then
                        local gridX, gridY = card.position.x, card.position.y
                        local cardLocalX = gridX * (cardW + gridSpacing)
                        local cardLocalY = gridY * (cardH + gridSpacing)

                        for portIndex = 1, 8 do
                            local portInfo = getPortInfo(self.renderer, portIndex)
                            if portInfo then
                                local localPX, localPY = portInfo[1], portInfo[2]
                                local localPos = Vector.new(cardLocalX + localPX, cardLocalY + localPY)
                                -- Rotate around network pivot at the center of the first grid cell
                                local halfW = self.renderer.CARD_WIDTH / 2
                                local halfH = self.renderer.CARD_HEIGHT / 2
                                local rotatedLocal = Vector.rotateAround(localPos, Vector.new(halfW, halfH), theta)
                                local worldPos = Vector.add(rotatedLocal, origin)
                                love.graphics.circle('line', worldPos.x, worldPos.y, clickRadius)
                            end
                        end
                    end
                end
            end
        end

        love.graphics.setColor(origR, origG, origB, origA)
        love.graphics.setLineWidth(origLineWidth)
        love.graphics.pop() -- Restore world space transform
    end
    -- [[[ END DEBUG ]]]

end

-- Helper function to check if point (px, py) is inside a rectangle {x, y, w, h}
local function isPointInRect(px, py, rect)
    return px >= rect.x and px < rect.x + rect.w and py >= rect.y and py < rect.y + rect.h
end

-- Helper: Find port under world coordinate for any player's network
function PlayState:_findPortAtWorld(wx, wy)
    local clickRadiusSq = 10 * 10
    local clickPoint = Vector.new(wx, wy)
    for pIdx, player in ipairs(self.players) do
        local origin = self.playerWorldOrigins[pIdx] or Vector.new(0, 0)
        local theta = player.orientation or 0
        for _, card in pairs(player.network.cards) do
            if card and card.position then
                local cellLocal = Vector.new(
                    card.position.x * (self.renderer.CARD_WIDTH + self.renderer.GRID_SPACING),
                    card.position.y * (self.renderer.CARD_HEIGHT + self.renderer.GRID_SPACING)
                )
                for portIndex = 1, 8 do
                    local info = getPortInfo(self.renderer, portIndex)
                    if info then
                        local portLocal = Vector.new(cellLocal.x + info[1], cellLocal.y + info[2])
                        local portWorld = Vector.localToWorld(portLocal, origin, theta)
                        if Vector.distanceSquared(clickPoint, portWorld) <= clickRadiusSq then
                            return pIdx, card.position.x, card.position.y, card, portIndex
                        end
                    end
                end
            end
        end
    end
    return nil, nil, nil, nil, nil
end

function PlayState:mousepressed(stateManager, x, y, button, istouch, presses)
    if self.sequencePicker then
        self.sequencePicker:handleMousePressed(x, y)
        return
    end
    
    -- NEW: Check if prompt is active FIRST
    if self.isDisplayingPrompt then
        if button == 1 then -- Only left click for prompt buttons
            if self.promptYesBounds and isPointInRect(x, y, self.promptYesBounds) then
                print("[PlayState] Clicked YES on prompt.")
                self.gameService:providePlayerYesNoAnswer(true)
                -- Resume our PlayState activation sequence if paused
                if self.activationSequence then
                    -- Move past the paused node and resume sequence
                    self.activationSequence.idx = self.activationSequence.idx + 1
                    self:_startActivationStep()
                end
                -- State is cleared in draw based on gameService.isWaitingForInput
                return -- Handled the click
            elseif self.promptNoBounds and isPointInRect(x, y, self.promptNoBounds) then
                print("[PlayState] Clicked NO on prompt.")
                self.gameService:providePlayerYesNoAnswer(false)
                -- Resume our PlayState activation sequence if paused
                if self.activationSequence then
                    -- Skip the paused node and resume sequence
                    self.activationSequence.idx = self.activationSequence.idx + 1
                    self:_startActivationStep()
                end
                -- State is cleared in draw based on gameService.isWaitingForInput
                return -- Handled the click
            end
            -- If clicked elsewhere while prompt is up, do nothing
            print("[PlayState] Clicked outside prompt buttons while prompt active.")
            return
        end
    end

    if self.isPaused then
        if button == 1 then -- Only handle left clicks for buttons
            for _, pbutton in ipairs(self.pauseMenuButtons) do
                if pbutton.handleMousePress and pbutton:handleMousePress(x, y) then
                    return -- Pause menu button handled the click
                end
            end
        end
        return -- Don't process game input if paused
    end
    
    -- Store last mouse position for panning (only if not paused)
    self.lastMouseX = x
    self.lastMouseY = y

    -- 1. Check UI Elements FIRST
    for _, element in ipairs(self.uiElements) do
        if element.handleMousePress and element:handleMousePress(x, y) then
            return -- UI element handled the click
        end
    end

    -- Check if the click should be ignored because we are waiting for input but didn't click the prompt
    -- This check might be redundant now due to the check at the start of the function, but safe to keep.
    if self.gameService.isWaitingForInput then
        print("[PlayState] Ignoring game click while waiting for prompt input.")
        return
    end

    local currentPlayerIndex = self.gameService.currentPlayerIndex
    local currentPlayer = self.players[currentPlayerIndex]
    local currentPhase = self.currentPhase

    if button == 1 then -- Left mouse button
        -- Check for Convergence Link UI click first (if in Converge phase)
        if currentPhase == TurnPhase.CONVERGE and self.convergenceSelectionState == nil then
            local worldX, worldY = self:_screenToWorld(x, y)
            local netLocal = self:_worldToNetworkLocal(worldX, worldY, currentPlayerIndex)
            local gx, gy, card, portIndex = self.renderer:getPortAtWorldPos(currentPlayer.network, netLocal.x, netLocal.y)
            if card and portIndex then
                local portInfo = getPortInfo(self.renderer, portIndex)
                if portInfo and portInfo[4] then -- found an output port
                    self.selectedConvergenceLinkType = portInfo[3]
                    self.initiatingConvergenceNodePos = { x = gx, y = gy }
                    self.initiatingConvergencePortIndex = portIndex
                    self.convergenceSelectionState = "selecting_opponent_input"
                    self:updateStatusMessage("Select an input port on an opponent's network.")
                    -- Disable phase/turn buttons during selection
                    self.buttonAdvancePhase:setEnabled(false)
                    self.buttonEndTurn:setEnabled(false)
                    return -- Handled click
                end
            end
        end

        -- 2. Check Hand Cards (Only if not selecting convergence)
        local handClickedIndex = nil
        for _, bounds in ipairs(self.handCardBounds) do
            if isPointInRect(x, y, bounds) then
                handClickedIndex = bounds.index
                break
            end
        end

        if handClickedIndex then
            -- Handle selection locally in PlayState
            if self.selectedHandIndex == handClickedIndex then
                self:resetSelectionAndStatus() -- This now disables both discard buttons
                self:updateStatusMessage("Card deselected.")
            else
                self.selectedHandIndex = handClickedIndex
                -- Enable both discard buttons if in Build phase
                local enableDiscard = (currentPhase == TurnPhase.BUILD)
                self.buttonDiscardMaterial:setEnabled(enableDiscard)
                self.buttonDiscardData:setEnabled(enableDiscard)
                local card = currentPlayer.hand[self.selectedHandIndex]
                self:updateStatusMessage(string.format("Selected card: %s (%s)", card.title, card.id))
            end
        else
            -- 3. Attempt Network Placement (Delegate to service) - Check Phase!
            if currentPhase == TurnPhase.BUILD and self.selectedHandIndex then
                -- Use helper to convert screen coordinates directly to grid coordinates
                local gridX, gridY = self:_screenToGrid(x, y, currentPlayerIndex)
             
                -- If grid coords found, proceed with placement logic
                if gridX ~= nil and gridY ~= nil then
                    -- Check if placement is valid BEFORE starting animation
                    local selectedCard = currentPlayer.hand[self.selectedHandIndex]
                    local isValid = self.gameService:isPlacementValid(currentPlayerIndex, selectedCard, gridX, gridY)
                    if isValid then
                        local canAfford = self.gameService:canAffordCard(currentPlayerIndex, selectedCard)
                        if canAfford then
                            -- Get start position (center of the hand card) - Calculation is correct
                            local handBounds = self.handCardBounds[self.selectedHandIndex]
                            local startScreenX = handBounds.x + handBounds.w / 2
                            local startScreenY = handBounds.y + handBounds.h / 2
                            local startWorldX, startWorldY = self:_screenToWorld(startScreenX, startScreenY)
                            
                            -- Calculate CORRECT endWorldPos for animation:
                            -- Start with target grid center relative to player origin (0,0) in unrotated space
                            local endLocalX = (gridX * (self.renderer.CARD_WIDTH + self.renderer.GRID_SPACING)) + self.renderer.CARD_WIDTH / 2
                            local endLocalY = (gridY * (self.renderer.CARD_HEIGHT + self.renderer.GRID_SPACING)) + self.renderer.CARD_HEIGHT / 2
                            
                            -- Apply player's local rotation to the local position vector using vector utility
                            local pivot = Vector.new(self.renderer.CARD_WIDTH / 2, self.renderer.CARD_HEIGHT / 2)
                            local rotatedPos = Vector.rotateAround(Vector.new(endLocalX, endLocalY), pivot, currentPlayer.orientation or 0)
                            local endRotX, endRotY = rotatedPos.x, rotatedPos.y
                            
                            -- Translate by player's world origin to get final world coordinates
                            local endWorldX = endRotX + self.playerWorldOrigins[currentPlayerIndex].x
                            local endWorldY = endRotY + self.playerWorldOrigins[currentPlayerIndex].y
                            
                            local cardToPlaceIndex = self.selectedHandIndex
                            local cardToPlace = selectedCard
                            
                            -- Get animation config from the Animations module
                            local animConfig = Animations.getCardPlayConfig(
                                self.renderer,
                                currentPlayer,
                                cardToPlace,
                                { x = startWorldX, y = startWorldY },
                                { x = endWorldX, y = endWorldY }
                            )
                            local animId = self.animationController:addAnimation(animConfig)
                            
                            self.animationController:registerCompletionCallback(animId, function()
                                local success, message = self.gameService:attemptPlacement(self, cardToPlaceIndex, gridX, gridY)
                                self:updateStatusMessage(message)
                            end)
                            
                            self.selectedHandIndex = nil
                            self.hoveredHandIndex = nil
                            self:updateStatusMessage("Placing card on the network...")
                        else
                            self:createShudderAnimation(self.selectedHandIndex, "cantAfford")
                            local _, message = self.gameService:attemptPlacement(self, self.selectedHandIndex, gridX, gridY)
                            self:updateStatusMessage(message)
                        end
                    else
                        local _, message = self.gameService:attemptPlacement(self, self.selectedHandIndex, gridX, gridY)
                        self:updateStatusMessage(message)
                        self:createShudderAnimation(self.selectedHandIndex, "invalidPlacement")
                    end
                else
                    -- Clicked outside any valid grid area for the current player
                    self:updateStatusMessage("Click on a valid grid location.")
                end
            elseif self.convergenceSelectionState == "selecting_own_output" then
                -- Handle selecting an OUTPUT port
                do
                    local worldX, worldY = self:_screenToWorld(x, y)
                    local pIdx = self.gameService.currentPlayerIndex
                    -- Convert world coords to network-local coords directly
                    local netLocal = self:_worldToNetworkLocal(worldX, worldY, pIdx)
                    local gx, gy, card, portIndex = self.renderer:getPortAtWorldPos(currentPlayer.network, netLocal.x, netLocal.y)
                     
                     if card and portIndex then -- Check if a port was found
                         local portInfo = getPortInfo(self.renderer, portIndex)
                         if portInfo and portInfo[4] and portInfo[3] == self.selectedConvergenceLinkType and card:isPortAvailable(portIndex) then
                             self.initiatingConvergenceNodePos = { x = gx, y = gy }
                             self.initiatingConvergencePortIndex = portIndex
                             self.convergenceSelectionState = "selecting_opponent_input"
                             self:updateStatusMessage(string.format("Select a %s INPUT port on an OPPONENT's network.",
                                 tostring(self.selectedConvergenceLinkType)))
                             print("Output port selected. Ready for input port selection.")
                         else
                             self:updateStatusMessage("Invalid output port selected.")
                         end
                     else
                         self:updateStatusMessage(string.format("Click a %s OUTPUT port on your network.",
                             tostring(self.selectedConvergenceLinkType)))
                     end
                end
                return

            elseif self.convergenceSelectionState == "selecting_opponent_input" then
                -- Handle selecting an INPUT port
                do
                    local worldX, worldY = self:_screenToWorld(x, y)
                    local targetPlayerIndex, targetGridX, targetGridY, targetCard, targetPortIndex = nil, nil, nil, nil, nil

                    -- Iterate through opponents to find the clicked port
                    for pIdx, player in ipairs(self.players) do
                        if pIdx ~= currentPlayerIndex then
                            -- Convert world to this opponent's local network coordinates using helper
                            local netLocal = self:_worldToNetworkLocal(worldX, worldY, pIdx)
                            local localX, localY = netLocal.x, netLocal.y
                            -- Check if click hits a port in this opponent's local coords
                            local gx, gy, card, portIndex = self.renderer:getPortAtWorldPos(player.network, localX, localY)
                            if card and portIndex then
                                -- Found a potential target
                                targetPlayerIndex, targetGridX, targetGridY, targetCard, targetPortIndex = pIdx, gx, gy, card, portIndex
                                break -- Stop checking other opponents
                            end
                        end
                    end

                    -- Validate the found target port (if any)
                    if targetCard and targetPortIndex then
                        local portInfo = getPortInfo(self.renderer, targetPortIndex)
                        local isCompatible = (COMPATIBLE_PORTS[self.initiatingConvergencePortIndex] == targetPortIndex)
                        if portInfo and not portInfo[4] and portInfo[3] == self.selectedConvergenceLinkType
                           and targetCard:isPortAvailable(targetPortIndex) and isCompatible then
                            self.targetConvergencePlayerIndex = targetPlayerIndex
                            self.targetConvergenceNodePos = { x = targetGridX, y = targetGridY }
                            self.targetConvergencePortIndex = targetPortIndex
                            local success, message, paradigmChanged = self.gameService:attemptConvergence(
                                self.gameService.currentPlayerIndex,
                                self.initiatingConvergenceNodePos,
                                self.initiatingConvergencePortIndex,
                                self.targetConvergencePlayerIndex,
                                self.targetConvergenceNodePos,
                                self.targetConvergencePortIndex,
                                self.selectedConvergenceLinkType)
                            self:updateStatusMessage(message)
                            if success then
                                print("Convergence successful!")
                                self.gameService.audioManager:playSound("link_create")
                                self:resetConvergenceSelection()
                                self.buttonAdvancePhase:setEnabled(true)
                                self.buttonEndTurn:setEnabled(true)
                            else
                                print("Convergence failed: " .. message)
                                self.targetConvergencePlayerIndex = nil
                                self.targetConvergenceNodePos = nil
                                self.targetConvergencePortIndex = nil
                                self:updateStatusMessage(message .. " Select a valid input port.")
                            end
                        else
                            self:updateStatusMessage("Invalid target port.")
                        end
                    else
                        self:updateStatusMessage("Click an input port on an opponent's network.")
                    end
                end
                return

            else
                -- Clicked network area with no card selected or wrong phase
                if self.selectedHandIndex then
                    self:updateStatusMessage("Placement only allowed in Build phase.")
                else
                    self:updateStatusMessage() -- Reset to default status
                end
                self.buttonAdvancePhase:setEnabled(true)
                self.buttonEndTurn:setEnabled(true)
            end
        end
    elseif button == 2 then -- Right mouse button: Activation / Convergence Abort / Deselect Card
        -- *** New Check: Deselect card if one is selected ***
        if self.selectedHandIndex then
            print("Card deselected via right-click.")
            self:resetSelectionAndStatus()
            self:updateStatusMessage("Card deselected.")
            -- Re-enable phase/turn buttons which might have been disabled by selection
            self.buttonAdvancePhase:setEnabled(true)
            self.buttonEndTurn:setEnabled(true)
            return -- Handled the click: deselected the card
        end
        -- *** End New Check ***

        -- Check for Convergence Abort first
        if self.convergenceSelectionState then
            print("Convergence selection aborted by user.")
            self:resetConvergenceSelection()
            self:updateStatusMessage("Convergence selection cancelled.")
            -- Re-enable buttons
            self.buttonAdvancePhase:setEnabled(true)
            self.buttonEndTurn:setEnabled(true)
            return -- Handled the click
        end

        -- Otherwise, handle Activation (if in Activate phase)
        if currentPhase == "Activate" then -- Activate phase logic updated for global targeting
            local activatingPlayerIndex = self.gameService.currentPlayerIndex
            -- Find which player's grid was clicked and the target card
            local targetPlayerIndex, targetGridX, targetGridY, targetCard = nil, nil, nil, nil
            for pIdx, player in ipairs(self.players) do
                -- Convert screen coordinates directly to grid coords for this player
                local gridX, gridY = self:_screenToGrid(x, y, pIdx)
                local card = player.network:getCardAt(gridX, gridY)
                if card and card.type ~= Card.Type.REACTOR then
                    targetPlayerIndex = pIdx
                    targetGridX = gridX
                    targetGridY = gridY
                    targetCard = card
                    print(string.format("Right-click targeted Player %d's card '%s' at grid (%d,%d)", pIdx, card.title, gridX, gridY))
                    break
                end
            end
            
            -- If a valid target was found, attempt global activation
            if targetCard then
                -- Retrieve all shortest paths
                local activatingPlayer = self.players[activatingPlayerIndex]
                local activatorReactor = activatingPlayer.network:findReactor()
                local foundAny, pathsData, reason = self.gameService.activationService:findGlobalActivationPaths(targetCard, activatorReactor, activatingPlayer)
                if foundAny then
                    if #pathsData > 1 then
                        -- Show sequence picker for player choice
                        self.sequencePicker = SequencePicker:new(self.renderer, pathsData, function(idx)
                            local chosen = pathsData[idx]
                            self.sequencePicker = nil
                            local status, msg = self:executeChosenActivation(chosen)
                            self:updateStatusMessage(msg)
                        end)
                    else
                        -- Only one path: execute it directly without re-running pathfinding
                        local status, msg = self:executeChosenActivation(pathsData[1])
                        self:updateStatusMessage(msg)
                    end
                else
                    self:updateStatusMessage("No valid global activation path: " .. reason)
                end
            else
                self:updateStatusMessage("Right-click a valid node (not a Reactor) to activate.")
            end
             
        else
             self:updateStatusMessage("Activation only allowed in Activate phase.")
        end
    elseif button == 3 then -- Middle mouse button: Start panning
        self.isPanning = true
        love.mouse.setRelativeMode(true)
    end
end

function PlayState:mousereleased(stateManager, x, y, button, istouch)
    -- Ignore if prompt is active, except for stopping panning
    if self.isDisplayingPrompt and button ~= 3 then
        return
    end

    if self.isPaused then
        -- Potentially handle pause button release if needed by Button class,
        -- but likely handled on press. Stop panning regardless.
        if button == 3 then
            self.isPanning = false
            love.mouse.setRelativeMode(false)
        end
        return
    end

    if button == 3 then -- Middle mouse button: Stop panning
        self.isPanning = false
        love.mouse.setRelativeMode(false) -- Show cursor again
    end
end

function PlayState:mousemoved(stateManager, x, y, dx, dy, istouch)
    -- Ignore if prompt is active, except for panning
    if self.isDisplayingPrompt and not self.isPanning then
        -- TODO: Could update hover state for Yes/No buttons here if desired
        return
    end

    if self.isPaused then
        -- Update pause button hover state if implemented in Button class
        -- For now, just prevent panning/game hover updates.
        return
    end

    -- Define UI Safe Area Top Edge
    local screenH = love.graphics.getHeight()
    local handCardH = self.renderer.HAND_CARD_HEIGHT or (140 * 0.6)
    local safeAreaTopY = screenH - self.BOTTOM_BUTTON_AREA_HEIGHT - handCardH - 20 -- <<< USE self.
    local isInSafeArea = (y >= safeAreaTopY)

    -- Reset hover grid coordinates
    self.hoverGridX, self.hoverGridY = nil, nil

    -- Only calculate grid hover if NOT in the safe area
    if not isInSafeArea then
        local currentPlayerIndex = self.gameService.currentPlayerIndex
        self.hoverGridX, self.hoverGridY = self:_screenToGrid(x, y, currentPlayerIndex)
    end

    -- Check for hand hover (do this regardless of safe area)
    local currentlyHovering = nil
    for _, bounds in ipairs(self.handCardBounds) do
        if isPointInRect(x, y, bounds) then
            currentlyHovering = bounds.index
            break
        end
    end
    self.hoveredHandIndex = currentlyHovering -- Update hovered index (nil if none)

    -- Check for convergence link UI hover (only in Converge phase)
    self.hoveredLinkType = nil -- Reset hover
    if self.currentPhase == "Converge" and self.convergenceSelectionState == nil then
        local player = self.players[self.gameService.currentPlayerIndex]
        local uiY_start = 30 -- Match drawUI
        local lineSpacing = 21 -- Match drawUI
        local resY = uiY_start + 2 * lineSpacing
        local linkY = resY + LINK_UI_Y_OFFSET
        local linkFont = self.renderer.fonts[self.renderer.styleGuide.UI_LABEL.fontName] -- Need the font
        local currentX = LINK_UI_START_X + (linkFont and linkFont:getWidth("Links:") or 50) + LINK_UI_GROUP_SPACING -- Approx start X

        local linkTypes = { Card.Type.TECHNOLOGY, Card.Type.CULTURE, Card.Type.RESOURCE, Card.Type.KNOWLEDGE }
        for _, linkType in ipairs(linkTypes) do
            local boxX = currentX
            local boxY = linkY - 2 -- Match drawUI vertical offset
            local linkRect = { x = boxX, y = boxY, w = LINK_UI_BOX_SIZE, h = LINK_UI_BOX_SIZE }

            if player:hasLinkSetAvailable(linkType) and isPointInRect(x, y, linkRect) then
                self.hoveredLinkType = linkType
                break -- Only hover one at a time
            end

            -- Advance X position for next icon
            currentX = currentX + LINK_UI_BOX_SIZE + LINK_UI_ICON_SPACING + LINK_UI_GROUP_SPACING
        end
    end

    if self.isPanning then
        self.cameraX = self.cameraX - (dx / self.cameraZoom)
        self.cameraY = self.cameraY - (dy / self.cameraZoom)
    end
    self.lastMouseX = x
    self.lastMouseY = y
end

function PlayState:wheelmoved(stateManager, x, y)
    if self.isDisplayingPrompt then return end -- Ignore zoom if prompt is up
    if self.isPaused then return end         -- Ignore zoom when paused

    -- Delegate zoom handling to CameraUtil
    local dyScroll = y
    if dyScroll ~= 0 then
        CameraUtil.zoom(self, dyScroll)
    end
end

function PlayState:keypressed(stateManager, key)
    if key == "escape" then
        -- If prompt is active, escape should perhaps cancel it?
        if self.isDisplayingPrompt then
            print("[PlayState] Escape pressed during prompt - Cancelling input.")
            self.gameService:providePlayerYesNoAnswer(false) -- Assume cancel = No
            -- State is cleared in draw based on gameService.isWaitingForInput
            return
        end
        self.isPaused = not self.isPaused -- Toggle pause state
    elseif key == "p" then -- Debug: Advance Phase
        if not self.isPaused and not self.isDisplayingPrompt then
            self:advancePhase()
        end
    end
    -- Ignore other keypresses if paused or prompt is active?
    if self.isPaused or self.isDisplayingPrompt then 
        if key == 'h' then -- Allow toggling debug even if paused/prompted
           self.debugDrawPortHitboxes = not self.debugDrawPortHitboxes
           print("Debug Port Hitboxes: " .. tostring(self.debugDrawPortHitboxes))
        end
        return 
    end

    -- Toggle debug drawing for port hitboxes
    if key == 'h' then
        self.debugDrawPortHitboxes = not self.debugDrawPortHitboxes
        print("Debug Port Hitboxes: " .. tostring(self.debugDrawPortHitboxes))
    end
end

function PlayState:resetConvergenceSelection()
    self.convergenceSelectionState = nil
    self.selectedConvergenceLinkType = nil
    self.hoveredLinkType = nil
    self.initiatingConvergenceNodePos = nil
    self.initiatingConvergencePortIndex = nil
    self.targetConvergencePlayerIndex = nil
    self.targetConvergenceNodePos = nil
    self.targetConvergencePortIndex = nil
    -- We might need to re-evaluate button states here too, but handled in abort logic for now
end

-- Helper function to create a shudder animation for a card in the player's hand
function PlayState:createShudderAnimation(cardIndex, errorType)
    local currentPlayer = self.players[self.gameService.currentPlayerIndex]
    local selectedCard = currentPlayer.hand[cardIndex]
    if not selectedCard or not self.handCardBounds or not self.handCardBounds[cardIndex] then
        print("Warning: Unable to create shudder animation - missing card or bounds")
        return
    end
    
    -- Calculate the card's expected position in the hand
    -- This ensures consistent positioning even if the original card isn't drawn
    local HAND_START_X = 50 -- Match Renderer's constant 
    local HAND_CARD_WIDTH = self.renderer.HAND_CARD_WIDTH or 60
    local HAND_SPACING = 10 -- Match Renderer's constant
    local handStartY = love.graphics.getHeight() - self.BOTTOM_BUTTON_AREA_HEIGHT - (self.renderer.HAND_CARD_HEIGHT or 84)
    
    -- Calculate screen position for this specific card index
    local centerX = HAND_START_X + (cardIndex-1) * (HAND_CARD_WIDTH + HAND_SPACING) + HAND_CARD_WIDTH/2
    local centerY = handStartY + (self.renderer.HAND_CARD_HEIGHT or 84)/2
    
    -- Create the animation with parameters based on error type
    -- Get animation config from the Animations module
    local animConfig = Animations.getHandShudderConfig(
        self.renderer, 
        currentPlayer, 
        selectedCard, 
        centerX, 
        centerY, 
        errorType
    )
    self.animationController:addAnimation(animConfig)
end

-- Helper to update UI element positions based on screen size
function PlayState:_recalculateLayout(w, h)
    print(string.format("Recalculating layout for %d x %d", w, h))

    -- Define button sizes and positions dynamically
    local buttonY = h - 50 -- Position relative to bottom
    local endTurnWidth = 80
    local discardWidth = 140
    local buttonHeight = 40
    local toggleHelpWidth = 100
    local toggleHelpHeight = 30
    local pauseButtonW = 150
    local pauseButtonH = 40
    local pauseButtonGap = 15

    -- Main Game Buttons
    local currentX = w - endTurnWidth - BUTTON_GAP
    if self.buttonEndTurn then
        self.buttonEndTurn:setPosition(currentX, buttonY)
        self.buttonEndTurn:setSize(endTurnWidth, buttonHeight)
    end

    currentX = currentX - endTurnWidth - BUTTON_GAP
    if self.buttonAdvancePhase then
        self.buttonAdvancePhase:setPosition(currentX, buttonY)
        self.buttonAdvancePhase:setSize(endTurnWidth, buttonHeight)
    end

    currentX = 10 -- Reset for left-aligned buttons
    if self.buttonDiscardMaterial then
        self.buttonDiscardMaterial:setPosition(currentX, buttonY)
        self.buttonDiscardMaterial:setSize(discardWidth, buttonHeight)
        self.buttonDiscardMaterial:setEnabled(self.selectedHandIndex and self.currentPhase == TurnPhase.BUILD) -- Update enabled state
    end

    currentX = currentX + discardWidth + BUTTON_GAP
    if self.buttonDiscardData then
        self.buttonDiscardData:setPosition(currentX, buttonY)
        self.buttonDiscardData:setSize(discardWidth, buttonHeight)
        self.buttonDiscardData:setEnabled(self.selectedHandIndex and self.currentPhase == TurnPhase.BUILD) -- Update enabled state
    end

    -- Help Toggle Button (Top Right)
    local toggleHelpX = w - toggleHelpWidth - BUTTON_GAP
    local toggleHelpY = 10
    if self.buttonToggleHelp then
        self.buttonToggleHelp:setPosition(toggleHelpX, toggleHelpY)
        self.buttonToggleHelp:setSize(toggleHelpWidth, toggleHelpHeight)
    end

    -- Pause Menu Buttons (Centered)
    local pauseTotalHeight = (pauseButtonH * 3) + (pauseButtonGap * 2)
    local pauseStartY = (h - pauseTotalHeight) / 2
    local pauseButtonX = (w - pauseButtonW) / 2
    if self.pauseMenuButtons and #self.pauseMenuButtons == 3 then
        self.pauseMenuButtons[1]:setPosition(pauseButtonX, pauseStartY)
        self.pauseMenuButtons[1]:setSize(pauseButtonW, pauseButtonH)
        self.pauseMenuButtons[2]:setPosition(pauseButtonX, pauseStartY + pauseButtonH + pauseButtonGap)
        self.pauseMenuButtons[2]:setSize(pauseButtonW, pauseButtonH)
        self.pauseMenuButtons[3]:setPosition(pauseButtonX, pauseStartY + 2 * (pauseButtonH + pauseButtonGap))
        self.pauseMenuButtons[3]:setSize(pauseButtonW, pauseButtonH)
    end

    -- TODO: Recalculate Help Box position/size if needed (depends on ToggleHelp button)
    -- TODO: Update status message position (e.g., top center)
    -- TODO: Update debug text position (e.g., bottom center)
end

-- LÖVE callback for window resize
function PlayState:resize(stateManager, w, h)
    -- Recalculate UI element positions
    self:_recalculateLayout(w, h)

    -- Optional: Adjust camera or other view elements if necessary
    -- For example, if the camera view should maintain aspect ratio or re-center
    -- print(string.format("PlayState received resize: %d x %d", w, h))
end

-- Execute a chosen activation path without pathfinding
function PlayState:executeChosenActivation(pathData)
    local idx = self.gameService.currentPlayerIndex
    local player = self.players[idx]
    local cost = #pathData.path - 1
    if player.resources.energy < cost then
        return false, string.format("Not enough energy. Cost: %d E (Have: %d E)", cost, player.resources.energy)
    end
    -- Deduct energy and play sound
    player:spendResource('energy', cost)
    self.gameService.audioManager:playSound('activation')
    -- Message for UI
    local initialMsg = string.format("Activated global path (Cost %d E):", cost)
    -- Initialize activation sequence with path and context
    self.activationSequence = {
        path = pathData.path,
        idx = 1,
        player = player,
        isConvergenceStart = pathData.isConvergenceStart
    }
    -- Update status and kick off first animation step
    self:updateStatusMessage(initialMsg)
    self:_startActivationStep()
    return true, initialMsg
end

-- Safe wrapper for screenToNetworkLocal: fallback to identity if missing
function PlayState:_screenToNetworkLocal(x, y, player, allPlayers, localPlayerIndex)
    if self.renderer and self.renderer.screenToNetworkLocal then
        return self.renderer:screenToNetworkLocal(x, y, player, allPlayers, localPlayerIndex)
    else
        print("Warning: screenToNetworkLocal not found on renderer, using identity.")
        return x, y
    end
end

-- Transform screen coordinates to world coordinates including camera rotation, zoom, and pan
function PlayState:_screenToWorld(sx, sy)
    return CameraUtil.screenToWorld(self, sx, sy)
end

-- Convert a world point (sx,sy) to network-local coordinates for a given player index
function PlayState:_worldToNetworkLocal(wx, wy, playerIndex)
    local origin = Vector.new(self.playerWorldOrigins[playerIndex].x, self.playerWorldOrigins[playerIndex].y)
    local pivot = Vector.add(origin, Vector.new(self.renderer.CARD_WIDTH/2, self.renderer.CARD_HEIGHT/2))
    local worldPt = Vector.new(wx, wy)
    -- Rotate around pivot by inverse orientation
    local localPivoted = Vector.worldToLocalAround(worldPt, pivot, self.players[playerIndex].orientation or 0)
    -- Subtract origin to get network-local coords
    return Vector.subtract(localPivoted, origin)
end

-- Insert new helper to convert screen coords to grid coords
function PlayState:_screenToGrid(sx, sy, playerIndex)
    local worldX, worldY = self:_screenToWorld(sx, sy)
    local localNet = self:_worldToNetworkLocal(worldX, worldY, playerIndex)
    if not self.renderer then return nil, nil end
    return self.renderer:worldToGridCoords(localNet.x, localNet.y, 0, 0)
end

-- After existing methods, add helper to start each activation step
function PlayState:_startActivationStep()
    local seq = self.activationSequence
    if not seq or seq.idx > #seq.path then
        -- Sequence complete
        self.activationSequence = nil
        return
    end
    -- Get next path element
    local elem = seq.path[seq.idx]
    local cardNode, owner = elem.card, elem.owner
    -- Compute card center in world coords
    local localX, localY = self.renderer:gridToWorldCoords(cardNode.position.x, cardNode.position.y, 0, 0)
    local halfW = self.renderer.CARD_WIDTH / 2
    local halfH = self.renderer.CARD_HEIGHT / 2
    local centerLocal = Vector.new(localX + halfW, localY + halfH)
    -- Rotate around card center pivot, then translate by world origin
    local pivot = Vector.new(halfW, halfH)
    local rotatedLocal = Vector.rotateAround(centerLocal, pivot, owner.orientation)
    local centerWorld = Vector.add(rotatedLocal, self.playerWorldOrigins[owner.id])
    -- Highlight this card with a rectangle
    self.highlightedActivationCard = {
        center = centerWorld,
        halfW = halfW,
        halfH = halfH,
        orientation = owner.orientation,
        elapsed = 0
    }
    -- Animate camera toward card and zoom in
    local targetZoom = 2.0
    local animKey = CameraUtil.animateToTarget(self, self.animationController,
        centerWorld.x, centerWorld.y,
        self.cameraRotation, targetZoom, 0.5)
    -- When camera animation finishes, trigger the card effect and next step
    self.animationController:registerCompletionCallback(animKey, function()
        -- Remove highlight
        self.highlightedActivationCard = nil
        -- Execute the card's activation effect (may pause for user input)
        local status = cardNode:activateEffect(self.gameService, seq.player, nil)
        -- Only continue if the action did not pause for input
        if status ~= "waiting" then
            -- Advance sequence index and start next step
            seq.idx = seq.idx + 1
            self:_startActivationStep()
        end
    end)
end

return PlayState 
