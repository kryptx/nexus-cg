-- src/game/states/play_state.lua
-- The main gameplay state

local Player = require('src.game.player')
local Card = require('src.game.card')
local Network = require('src.game.network')
local CardDefinitions = require('src.game.data.card_definitions')
local Renderer = require('src.rendering.renderer')
local Button = require('src.ui.button') -- Require the Button module
local ServiceModule = require('src.game.game_service') -- Require GameService module
local GameService = ServiceModule.GameService -- Extract the actual GameService table
local TurnPhase = ServiceModule.TurnPhase -- Extract TurnPhase constants
local StyleGuide = require('src.rendering.styles') -- Require the styles
local Text = require('src.ui.text') -- Need Text for wrapping

local PlayState = {}

-- Constants for Setup (adjust as needed)
local NUM_PLAYERS = 2
local STARTING_ENERGY = 5 -- Placeholder - GDD 4.1 value TBD
local STARTING_DATA = 5     -- Placeholder - GDD 4.1 value TBD
local STARTING_MATERIAL = 5 -- Placeholder - GDD 4.1 value TBD
local STARTING_HAND_CARD_IDS = { "NODE_TECH_001", "NODE_CULT_001" } -- Placeholder - GDD 4.1 Seed Cards TBD
local KEYBOARD_PAN_SPEED = 400 -- Base pixels per second at zoom 1.0
local PLAYER_GRID_OFFSET_X = 1300 -- Estimated world space to separate player grids horizontally
local PLAYER_GRID_OFFSET_Y = 0 -- Keep grids aligned vertically for now

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
    self.renderer = Renderer:new() -- Create renderer instance
    self.animationController = animationController -- Store the controller
    self.selectedHandIndex = nil -- Track selected card in hand
    self.hoveredHandIndex = nil -- Add this
    self.handCardBounds = {} -- Store bounding boxes returned by renderer
    self.statusMessage = "" -- For displaying feedback
    self.activeParadigm = nil -- Track the currently active Paradigm Shift card object
    self.currentPhase = nil -- Track the current turn phase locally
    self.playerOrigins = {}
    self.isPaused = false
    self.showHelpBox = true -- Enable help box by default
    self.BOTTOM_BUTTON_AREA_HEIGHT = 60 -- <<< STORE CONSTANT ON INSTANCE

    -- Camera State
    self.cameraX = -love.graphics.getWidth() / 2 -- Center initial view roughly
    self.cameraY = -love.graphics.getHeight() / 2
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
    self.hoverGridX = nil
    self.hoverGridY = nil

    -- State for Yes/No Prompt
    self.isDisplayingPrompt = false -- NEW: Flag if prompt is active
    self.promptQuestion = nil       -- NEW: Text of the question
    self.promptYesBounds = nil      -- NEW: Bounding box for Yes button (set by renderer)
    self.promptNoBounds = nil       -- NEW: Bounding box for No button (set by renderer)

    -- Initialize Game Service (using injected or create new)
    self.gameService = gameService or GameService:new() -- Use the injected gameService if provided

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

    -- Initial layout calculation using current window size
    self:_recalculateLayout(love.graphics.getWidth(), love.graphics.getHeight())
end

function PlayState:enter()
    print("Entering Play State - Initializing Game...")
    
    -- Initialize the game service first
    self.gameService:initializeGame(NUM_PLAYERS)
    
    -- Sync our state with GameService
    self.players = self.gameService:getPlayers()
    self.activeParadigm = self.gameService:getCurrentParadigm() -- Get the active paradigm
    self.currentPhase = self.gameService:getCurrentPhase() -- Get initial phase
    
    -- Calculate and store player origins
    self.playerOrigins = {}
    for i = 1, #self.players do
        -- Simple horizontal layout for now
        self.playerOrigins[i] = {
            x = (i - 1) * PLAYER_GRID_OFFSET_X,
            y = (i - 1) * PLAYER_GRID_OFFSET_Y
        }
        print(string.format("Player %d origin set to: (%d, %d)", i, self.playerOrigins[i].x, self.playerOrigins[i].y))
    end
    
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

        -- Center camera on the new active player's grid origin (with a slight offset)
        local newPlayerIndex = self.gameService.currentPlayerIndex
        local newOrigin = self.playerOrigins[newPlayerIndex] or {x=0, y=0}
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        -- Target a point slightly down-right from the origin for better initial view
        -- Use renderer constants here
        local cardW = self.renderer and self.renderer.CARD_WIDTH or 100 -- Fallback values
        local cardH = self.renderer and self.renderer.CARD_HEIGHT or 140
        local gridSpacing = self.renderer and self.renderer.GRID_SPACING or 10
        local centerOffsetX = 2 * (cardW + gridSpacing)
        local centerOffsetY = 2 * (cardH + gridSpacing)
        local targetWorldX = newOrigin.x + centerOffsetX
        local targetWorldY = newOrigin.y + centerOffsetY

        self.cameraX = targetWorldX - (screenW / (2 * self.cameraZoom))
        self.cameraY = targetWorldY - (screenH / (2 * self.cameraZoom))
        print(string.format("Centering view on Player %d grid area.", newPlayerIndex))

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
    local effectivePanSpeed = KEYBOARD_PAN_SPEED / self.cameraZoom
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        self.cameraY = self.cameraY - effectivePanSpeed * dt
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        self.cameraY = self.cameraY + effectivePanSpeed * dt
    end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        self.cameraX = self.cameraX - effectivePanSpeed * dt
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        self.cameraX = self.cameraX + effectivePanSpeed * dt
    end
end

function PlayState:draw(stateManager)
    love.graphics.clear(0.3, 0.3, 0.3, 1)
    if not self.players or #self.players == 0 or not self.renderer then return end

    -- Get current player for UI/Hand drawing later
    local currentPlayer = self.players[self.gameService.currentPlayerIndex]
    local currentOrigin = self.playerOrigins[self.gameService.currentPlayerIndex] or {x=0, y=0} -- Fallback origin
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Get cards currently being animated
    local animatingCardIds = {}
    if self.animationController then
        animatingCardIds = self.animationController:getAnimatingCardIds()
    end

    -- Draw ALL player networks using their origins - pass animatingCardIds to skip cards being animated
    local activeLinks = self.gameService.activeConvergenceLinks -- Get active links
    for i, player in ipairs(self.players) do
        local origin = self.playerOrigins[i] or {x=0, y=0} -- Fallback origin
        self.renderer:drawNetwork(player.network, self.cameraX, self.cameraY, self.cameraZoom, origin.x, origin.y, activeLinks, animatingCardIds)
    end

    -- Draw any active card animations (after networks, before UI)
    if self.animationController then
        local activeAnimations = self.animationController:getActiveAnimations()
        for id, animation in pairs(activeAnimations) do
            if animation.type == 'cardPlay' then
                self.renderer:drawCardAnimation(animation, self.cameraX, self.cameraY, self.cameraZoom)
            end
        end
    end

    -- Draw highlight box around the active player's grid area
    local activePlayerIndex = self.gameService.currentPlayerIndex
    local activePlayer = self.players[activePlayerIndex]
    local activeOrigin = self.playerOrigins[activePlayerIndex] or {x=0, y=0}
    local highlightMargin = 30 -- Reduced margin slightly
    local highlightBoxX, highlightBoxY, highlightBoxWidth, highlightBoxHeight

    -- Calculate network bounds
    local minGridX, maxGridX, minGridY, maxGridY = nil, nil, nil, nil
    if activePlayer and activePlayer.network and activePlayer.network.cards then
        for _, card in pairs(activePlayer.network.cards) do
            if type(card) == "table" and card.position then
                if not minGridX or card.position.x < minGridX then minGridX = card.position.x end
                if not maxGridX or card.position.x > maxGridX then maxGridX = card.position.x end
                if not minGridY or card.position.y < minGridY then minGridY = card.position.y end
                if not maxGridY or card.position.y > maxGridY then maxGridY = card.position.y end
            end
        end
    end

    if minGridX then -- Check if any cards were found
        local minWorldX, minWorldY = self.renderer:gridToWorldCoords(minGridX, minGridY, activeOrigin.x, activeOrigin.y)
        local maxCellWorldX, maxCellWorldY = self.renderer:gridToWorldCoords(maxGridX, maxGridY, activeOrigin.x, activeOrigin.y)
        local maxWorldX = maxCellWorldX + self.renderer.CARD_WIDTH -- Use renderer instance
        local maxWorldY = maxCellWorldY + self.renderer.CARD_HEIGHT -- Use renderer instance

        highlightBoxX = minWorldX - highlightMargin
        highlightBoxY = minWorldY - highlightMargin
        highlightBoxWidth = (maxWorldX + highlightMargin) - highlightBoxX
        highlightBoxHeight = (maxWorldY + highlightMargin) - highlightBoxY
    else
        -- Default box around origin if no cards placed yet
        highlightBoxX = activeOrigin.x - highlightMargin
        highlightBoxY = activeOrigin.y - highlightMargin
        highlightBoxWidth = self.renderer.CARD_WIDTH + (2 * highlightMargin) -- Use renderer instance
        highlightBoxHeight = self.renderer.CARD_HEIGHT + (2 * highlightMargin) -- Use renderer instance
    end

    love.graphics.push()
    local originalLineWidth = love.graphics.getLineWidth() -- Store original width
    love.graphics.translate(-self.cameraX * self.cameraZoom, -self.cameraY * self.cameraZoom)
    love.graphics.scale(self.cameraZoom, self.cameraZoom)
    love.graphics.setLineWidth(4 / self.cameraZoom) -- Thicker line, adjusts with zoom
    love.graphics.setColor(1, 1, 0, 0.7) -- Yellow, slightly transparent
    love.graphics.rectangle("line", highlightBoxX, highlightBoxY, highlightBoxWidth, highlightBoxHeight)
    love.graphics.setLineWidth(originalLineWidth) -- Restore original width inside the push/pop
    love.graphics.pop()

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
            local currentOrigin = self.playerOrigins[self.gameService.currentPlayerIndex] or {x=0, y=0}
            local isValid = self.gameService:isPlacementValid(self.gameService.currentPlayerIndex, selectedCard, self.hoverGridX, self.hoverGridY)
            self.renderer:drawHoverHighlight(self.hoverGridX, self.hoverGridY, self.cameraX, self.cameraY, self.cameraZoom, selectedCard, isValid, currentOrigin.x, currentOrigin.y)
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
    love.graphics.print("MMB Drag / WASD: Pan | Wheel: Zoom | C: Test Converge | P: Next Phase", screenW / 2 - 200, screenH - 20)

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
            self.promptYesBounds, self.promptNoBounds = self.renderer:drawYesNoPrompt(self.promptQuestion)
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
end

-- Helper function to check if point (px, py) is inside a rectangle {x, y, w, h}
local function isPointInRect(px, py, rect)
    return px >= rect.x and px < rect.x + rect.w and py >= rect.y and py < rect.y + rect.h
end

function PlayState:mousepressed(stateManager, x, y, button, istouch, presses)
    -- NEW: Check if prompt is active FIRST
    if self.isDisplayingPrompt then
        if button == 1 then -- Only left click for prompt buttons
            if self.promptYesBounds and isPointInRect(x, y, self.promptYesBounds) then
                print("[PlayState] Clicked YES on prompt.")
                self.gameService:providePlayerYesNoAnswer(true)
                -- State is cleared in draw based on gameService.isWaitingForInput
                return -- Handled the click
            elseif self.promptNoBounds and isPointInRect(x, y, self.promptNoBounds) then
                print("[PlayState] Clicked NO on prompt.")
                self.gameService:providePlayerYesNoAnswer(false)
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
    local currentOrigin = self.playerOrigins[currentPlayerIndex] or {x=0, y=0} -- Get current player's origin

    if button == 1 then -- Left mouse button
        -- Check for Convergence Link UI click first (if in Converge phase)
        if currentPhase == "Converge" and self.convergenceSelectionState == nil and self.hoveredLinkType then
            -- Initiate convergence selection
            self.selectedConvergenceLinkType = self.hoveredLinkType
            self.convergenceSelectionState = "selecting_own_output"
            self:updateStatusMessage(string.format("Select a %s OUTPUT port on your network.", tostring(self.selectedConvergenceLinkType)))
            print(string.format("Starting convergence selection for type: %s", tostring(self.selectedConvergenceLinkType)))
            self.hoveredLinkType = nil -- Clear hover after selection
            -- Disable phase/turn buttons
            self.buttonAdvancePhase:setEnabled(false)
            self.buttonEndTurn:setEnabled(false)
            return -- Handled the click
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
                local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
                -- Convert to grid coordinates relative to the CURRENT player's origin
                local gridX, gridY = self.renderer:worldToGridCoords(worldX, worldY, currentOrigin.x, currentOrigin.y)

                -- Check if placement is valid BEFORE starting animation
                local selectedCard = currentPlayer.hand[self.selectedHandIndex]
                local isValid = self.gameService:isPlacementValid(currentPlayerIndex, selectedCard, gridX, gridY)
                if isValid then
                    -- Get start position (center of the hand card)
                    local handBounds = self.handCardBounds[self.selectedHandIndex]
                    local startScreenX = handBounds.x + handBounds.w / 2
                    local startScreenY = handBounds.y + handBounds.h / 2
                    local startWorldX, startWorldY = self.renderer:screenToWorldCoords(startScreenX, startScreenY, self.cameraX, self.cameraY, self.cameraZoom)
                    -- Get end position (center of the grid cell)
                    local endWorldXBase, endWorldYBase = self.renderer:gridToWorldCoords(gridX, gridY, currentOrigin.x, currentOrigin.y)
                    local endWorldX = endWorldXBase + self.renderer.CARD_WIDTH / 2
                    local endWorldY = endWorldYBase + self.renderer.CARD_HEIGHT / 2
                    -- Start Animation!
                    self.animationController:addAnimation({
                        type = 'cardPlay',
                        duration = 0.5, -- Slightly longer to appreciate the effects
                        card = selectedCard,
                        startWorldPos = { x = startWorldX, y = startWorldY },
                        endWorldPos = { x = endWorldX, y = endWorldY },
                        startScale = self.renderer.HAND_CARD_SCALE or 0.6,
                        endScale = 1.0,
                        startRotation = math.pi * 0.1, -- Slight tilt at start
                        endRotation = 0, -- End with no rotation
                        easingType = "outBack", -- Use the outBack easing for a slight overshoot
                        startAlpha = 0.9,
                        endAlpha = 1.0
                    })
                    -- Clear selection immediately so the card disappears from hand
                    local cardToRemove = self.selectedHandIndex -- Store index before clearing
                    self:resetSelectionAndStatus() -- Clear selection
                    -- Actually play the card in the game state (happens after animation)
                    -- The animation system doesn't handle game logic
                    local success, message = self.gameService:attemptPlacement(self, cardToRemove, gridX, gridY)
                    self:updateStatusMessage(message)
                    -- Note: success check is somewhat redundant as we checked isValid, but good practice
                else
                    -- Placement not valid, update status from gameService
                    local _, message = self.gameService:attemptPlacement(self, self.selectedHandIndex, gridX, gridY)
                    self:updateStatusMessage(message)
                    -- Don't reset selection, allow player to try again
                end
            elseif self.convergenceSelectionState == "selecting_own_output" then
                -- Handle clicking on network to select output port
                local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
                local gridX, gridY, clickedCard, clickedPortIndex = self.renderer:getPortAtWorldPos(currentPlayer.network, worldX, worldY, currentOrigin.x, currentOrigin.y)

                if clickedCard and clickedPortIndex then
                    print(string.format("Clicked on card '%s' at (%d,%d), port %d", clickedCard.title, gridX, gridY, clickedPortIndex))
                    -- Validate the selected port
                    local portInfo = getPortInfo(self.renderer, clickedPortIndex) -- Pass renderer
                    local isValid = true
                    local reason = ""

                    if not portInfo then
                        isValid = false
                        reason = "Internal error: Invalid port index."
                    elseif not clickedCard:isPortDefined(clickedPortIndex) then
                        isValid = false
                        reason = "Selected port is closed."
                    -- TODO: Add check for port availability (not occupied by another link) -> requires card/network state
                    -- elseif not clickedCard:isPortAvailable(clickedPortIndex) then
                    --    isValid = false
                    --    reason = "Selected port is already occupied."
                    elseif not portInfo[4] then -- Check if it IS an output port (portInfo[4] is is_output)
                        isValid = false
                        reason = "Selected port must be an OUTPUT."
                    elseif portInfo[3] ~= self.selectedConvergenceLinkType then -- Check if type matches
                        isValid = false
                        reason = string.format("Selected port type (%s) does not match required link type (%s).", tostring(portInfo[3]), tostring(self.selectedConvergenceLinkType))
                    
                    -- NEW: Check if initiating node is the Reactor
                    elseif clickedCard == currentPlayer.reactorCard then
                        isValid = false
                        reason = "Cannot initiate convergence from the Reactor."
                        
                    -- NEW: Check if port is blocked by adjacent card in own network
                    else
                        local initiatingAdjCoord = currentPlayer.network:getAdjacentCoordForPort({x=gridX, y=gridY}, clickedPortIndex) -- Use the clicked grid coords
                        if initiatingAdjCoord and currentPlayer.network:getCardAt(initiatingAdjCoord.x, initiatingAdjCoord.y) then
                            isValid = false
                            reason = "Port blocked by adjacent card in network."
                        end
                    end

                    if isValid then
                        -- Store selection and move to next state
                        self.initiatingConvergenceNodePos = {x=gridX, y=gridY}
                        self.initiatingConvergencePortIndex = clickedPortIndex
                        self.convergenceSelectionState = "selecting_opponent_input"
                        self:updateStatusMessage(string.format("Now select an opponent's %s INPUT port.", tostring(self.selectedConvergenceLinkType)))
                        print(string.format("Initiating port selected: P%d (%d,%d) Port %d. State -> selecting_opponent_input", currentPlayerIndex, gridX, gridY, clickedPortIndex))
                        -- Buttons remain disabled
                        -- TODO: Play confirmation sound?
                    else
                        -- Invalid port clicked, remain in selecting_own_output state
                        self:updateStatusMessage("Invalid port: " .. reason)
                        print("Invalid initiating port selected: " .. reason)
                        -- Buttons remain disabled
                    end
                else
                    -- Clicked on the grid but not near a specific port
                    self:updateStatusMessage("Click closer to a valid output port.")
                end
            elseif self.convergenceSelectionState == "selecting_opponent_input" then
                -- Handle clicking on network to select input port
                local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)

                -- Determine which opponent grid was clicked (iterate through players)
                local foundTargetPlayerIndex = nil
                local foundTargetGridX, foundTargetGridY = nil, nil
                local foundTargetCard, foundTargetPortIndex = nil, nil

                for pIdx, player in ipairs(self.players) do
                    if pIdx ~= currentPlayerIndex then -- Only check opponents
                        local opponentOrigin = self.playerOrigins[pIdx] or {x=0, y=0}
                        local gridX, gridY, clickedCard, clickedPortIndex = self.renderer:getPortAtWorldPos(player.network, worldX, worldY, opponentOrigin.x, opponentOrigin.y)
                        
                        -- If a port was found on this opponent's grid, store it and stop checking others
                        if clickedCard and clickedPortIndex then
                            foundTargetPlayerIndex = pIdx
                            foundTargetGridX = gridX
                            foundTargetGridY = gridY
                            foundTargetCard = clickedCard
                            foundTargetPortIndex = clickedPortIndex
                            print(string.format("Potential target: Player %d Card '%s' at (%d,%d), port %d", pIdx, clickedCard.title, gridX, gridY, clickedPortIndex))
                            break -- Found a potential target, stop checking other players
                        end
                    end
                end

                if foundTargetCard and foundTargetPortIndex then
                    -- Validate the selected port
                    local portInfo = getPortInfo(self.renderer, foundTargetPortIndex)
                    local isValid = true
                    local reason = ""

                    if not portInfo then
                        isValid = false
                        reason = "Internal error: Invalid port index."
                    elseif not foundTargetCard:isPortDefined(foundTargetPortIndex) then
                        isValid = false
                        reason = "Selected port is closed."
                    -- TODO: Add check for port availability (not occupied by another link) -> requires card/network state
                    -- elseif not foundTargetCard:isPortAvailable(foundTargetPortIndex) then
                    --    isValid = false
                    --    reason = "Selected port is already occupied."
                    elseif portInfo[4] then -- Check if it is NOT an output port (i.e., it IS an input)
                        isValid = false
                        reason = "Selected port must be an INPUT."
                    elseif portInfo[3] ~= self.selectedConvergenceLinkType then -- Check if type matches
                        isValid = false
                        reason = string.format("Selected port type (%s) does not match required link type (%s).", tostring(portInfo[3]), tostring(self.selectedConvergenceLinkType))
                    end

                    if isValid then
                        -- All checks passed! Attempt the convergence via GameService
                        print("Target port validated. Attempting convergence...")
                        self.targetConvergencePlayerIndex = foundTargetPlayerIndex
                        self.targetConvergenceNodePos = {x=foundTargetGridX, y=foundTargetGridY}
                        self.targetConvergencePortIndex = foundTargetPortIndex

                        local success, message, shiftOccurred = self.gameService:attemptConvergence(
                            currentPlayerIndex, -- Initiating player
                            self.initiatingConvergenceNodePos,
                            self.initiatingConvergencePortIndex, -- Added Initiating Port Index
                            self.targetConvergencePlayerIndex,
                            self.targetConvergenceNodePos,
                            self.targetConvergencePortIndex, -- Added Target Port Index
                            self.selectedConvergenceLinkType
                        )

                        self:updateStatusMessage(message) -- Display result
                        -- Check if paradigm shifted (GameService now returns this)
                        if success and shiftOccurred then
                            self.activeParadigm = self.gameService:getCurrentParadigm() -- Re-sync
                            -- Status message already updated by attemptConvergence, but we could add more detail
                            print("PlayState detected Paradigm Shift!")
                            self:updateStatusMessage() -- Update status to include new paradigm name
                        end
                        self:resetConvergenceSelection() -- Clear selection state
                        self.buttonAdvancePhase:setEnabled(true) -- Re-enable buttons
                        self.buttonEndTurn:setEnabled(true)

                    else
                        -- Invalid target port clicked
                        self:updateStatusMessage("Invalid target port: " .. reason)
                        print("Invalid target port selected: " .. reason)
                        -- Remain in selecting_opponent_input state
                    end
                else
                    -- Clicked, but not near a valid port on any opponent grid
                    self:updateStatusMessage("Click closer to a valid opponent input port.")
                end
            else
                -- Clicked network area with no card selected or wrong phase
                if self.selectedHandIndex then
                    self:updateStatusMessage("Placement only allowed in Build phase.")
                else
                    self:updateStatusMessage() -- Reset to default status
                end
                -- Re-enable buttons if we clicked off everything and aren't selecting convergence
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
             local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
             
             -- Find which player's grid was clicked and the target card
             local targetPlayerIndex = nil
             local targetGridX = nil
             local targetGridY = nil
             local targetCard = nil
 
             for pIdx, player in ipairs(self.players) do
                 local playerOrigin = self.playerOrigins[pIdx] or {x=0, y=0}
                 local gridX, gridY = self.renderer:worldToGridCoords(worldX, worldY, playerOrigin.x, playerOrigin.y)
                 local card = player.network:getCardAt(gridX, gridY)
                 -- Check if a valid, non-reactor card exists at this grid position for this player
                 if card and card.type ~= Card.Type.REACTOR then 
                     targetPlayerIndex = pIdx
                     targetGridX = gridX
                     targetGridY = gridY
                     targetCard = card
                     print(string.format("Right-click targeted Player %d's card '%s' at grid (%d,%d)", pIdx, card.title, gridX, gridY))
                     break -- Found a valid target
                 end
             end
 
             -- If a valid target was found, attempt global activation
             if targetCard then
                 local success, message = self.gameService:attemptActivationGlobal(activatingPlayerIndex, targetPlayerIndex, targetGridX, targetGridY)
                 self:updateStatusMessage(message)
             else
                 -- No valid target card clicked
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

    -- Update world mouse coordinates (needed for panning regardless)
    local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)

    -- Reset hover grid coords
    self.hoverGridX, self.hoverGridY = nil, nil

    -- Only calculate grid hover if NOT in the safe area
    if not isInSafeArea then
        local currentOrigin = self.playerOrigins[self.gameService.currentPlayerIndex] or {x=0, y=0}
        self.hoverGridX, self.hoverGridY = self.renderer:worldToGridCoords(worldX, worldY, currentOrigin.x, currentOrigin.y)
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
    if self.isPaused then return end

    -- Zoom in/out based on scroll direction (y > 0 is scroll up/zoom in)
    local zoomFactor = 1.1
    local oldZoom = self.cameraZoom
    local newZoom

    if y > 0 then
        newZoom = math.min(self.maxZoom, self.cameraZoom * zoomFactor)
    elseif y < 0 then
        newZoom = math.max(self.minZoom, self.cameraZoom / zoomFactor)
    else
        return -- No change
    end

    self.cameraZoom = newZoom

    -- Adjust camera position to zoom towards the mouse cursor
    -- Get world coordinates under cursor before zoom
    local worldMouseX, worldMouseY = self.renderer:screenToWorldCoords(self.lastMouseX, self.lastMouseY, self.cameraX, self.cameraY, oldZoom)
    -- Calculate new camera position to keep world coords under cursor
    self.cameraX = worldMouseX - (self.lastMouseX / self.cameraZoom)
    self.cameraY = worldMouseY - (self.lastMouseY / self.cameraZoom)

    print(string.format("Zoom changed to: %.2f", self.cameraZoom))
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
    if self.isPaused or self.isDisplayingPrompt then return end
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

return PlayState 
