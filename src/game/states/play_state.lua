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

function PlayState:new(gameService)
    local instance = setmetatable({}, { __index = PlayState })
    instance:init(gameService)
    return instance
end

function PlayState:init(gameService)
    -- Initialize state variables
    self.players = {}
    self.renderer = Renderer:new() -- Create renderer instance
    self.selectedHandIndex = nil -- Track selected card in hand
    self.hoveredHandIndex = nil -- Add this
    self.handCardBounds = {} -- Store bounding boxes returned by renderer
    self.statusMessage = "" -- For displaying feedback
    self.activeParadigm = nil -- Track the currently active Paradigm Shift card object
    self.currentPhase = nil -- Track the current turn phase locally
    self.playerOrigins = {}
    self.isPaused = false
    self.showHelpBox = true -- Enable help box by default

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

    -- Initialize Game Service (either use injected or create new)
    self.gameService = gameService or GameService:new()

    -- Create UI buttons (pass self for context in callbacks)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local buttonY = screenH - 50
    local endTurnWidth = 80 -- Width for End Turn/Next Phase
    local discardWidth = 140 -- Increased width for discard buttons
    local buttonHeight = 40 -- Explicit height
    local uiFonts = self.renderer.fonts -- Get the fonts table
    local uiStyleGuide = self.renderer.styleGuide -- Get the style guide

    -- End Turn / Next Phase buttons
    local currentX = screenW - endTurnWidth - BUTTON_GAP
    self.buttonEndTurn = Button:new(currentX, buttonY, "End Turn", function() self:endTurn() end, endTurnWidth, buttonHeight, uiFonts, uiStyleGuide)

    currentX = currentX - endTurnWidth - BUTTON_GAP
    self.buttonAdvancePhase = Button:new(currentX, buttonY, "Next Phase", function() self:advancePhase() end, endTurnWidth, buttonHeight, uiFonts, uiStyleGuide)

    -- Create discard buttons with text and inline icons
    currentX = 10
    local discardText = "Discard for 1 "
    -- Use nil for the 'icon' parameter (5th to last), pass icon to 'inlineIcon' (last)
    self.buttonDiscardMaterial = Button:new(currentX, buttonY, discardText, function() self:discardSelected('material') end, discardWidth, buttonHeight, uiFonts, uiStyleGuide, nil, self.renderer.icons.material)
    self.buttonDiscardMaterial:setEnabled(false)

    currentX = currentX + discardWidth + BUTTON_GAP
    self.buttonDiscardData = Button:new(currentX, buttonY, discardText, function() self:discardSelected('data') end, discardWidth, buttonHeight, uiFonts, uiStyleGuide, nil, self.renderer.icons.data)
    self.buttonDiscardData:setEnabled(false)

    -- Calculate position for Help Toggle button (e.g., near top right)
    local toggleHelpWidth = 100
    local toggleHelpHeight = 30
    local toggleHelpX = screenW - toggleHelpWidth - BUTTON_GAP
    local toggleHelpY = 10 -- Place it near the top status message

    self.buttonToggleHelp = Button:new(toggleHelpX, toggleHelpY, "Toggle Help", function()
        self.showHelpBox = not self.showHelpBox
        print("Help Box Toggled: ", self.showHelpBox)
    end, toggleHelpWidth, toggleHelpHeight, uiFonts, uiStyleGuide)

    -- Update uiElements list
    self.uiElements = { self.buttonEndTurn, self.buttonAdvancePhase, self.buttonDiscardMaterial, self.buttonDiscardData, self.buttonToggleHelp }

    local pauseButtonW = 150
    local pauseButtonH = 40
    local pauseButtonGap = 15
    local pauseTotalHeight = (pauseButtonH * 3) + (pauseButtonGap * 2)
    local pauseStartY = (screenH - pauseTotalHeight) / 2
    local pauseButtonX = (screenW - pauseButtonW) / 2

    self.pauseMenuButtons = {
        Button:new(pauseButtonX, pauseStartY, "Resume Game", function() self.isPaused = false end, pauseButtonW, pauseButtonH, uiFonts, uiStyleGuide),
        Button:new(pauseButtonX, pauseStartY + pauseButtonH + pauseButtonGap, "Main Menu", function() print("TODO: Transition to Main Menu state") end, pauseButtonW, pauseButtonH, uiFonts, uiStyleGuide),
        Button:new(pauseButtonX, pauseStartY + 2 * (pauseButtonH + pauseButtonGap), "Quit Game", function() love.event.quit() end, pauseButtonW, pauseButtonH, uiFonts, uiStyleGuide)
    }
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

    -- Keyboard Panning Logic (only if not paused)
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

    -- Draw ALL player networks using their origins
    local activeLinks = self.gameService.activeConvergenceLinks -- Get active links
    for i, player in ipairs(self.players) do
        local origin = self.playerOrigins[i] or {x=0, y=0} -- Fallback origin
        self.renderer:drawNetwork(player.network, self.cameraX, self.cameraY, self.cameraZoom, origin.x, origin.y, activeLinks)
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
    local selectedCard = self.selectedHandIndex and currentPlayer.hand[self.selectedHandIndex] or nil
    -- Only draw highlight if a card is selected AND we are hovering over the grid
    if selectedCard and self.hoverGridX ~= nil and self.hoverGridY ~= nil and self.currentPhase == TurnPhase.BUILD then
        -- Check placement validity using the game service (ensure this function exists!)
        -- We use the hoverGridX/Y calculated relative to the current player's origin
        local isValid = self.gameService:isPlacementValid(self.gameService.currentPlayerIndex, selectedCard, self.hoverGridX, self.hoverGridY)
        self.renderer:drawHoverHighlight(self.hoverGridX, self.hoverGridY, self.cameraX, self.cameraY, self.cameraZoom, selectedCard, isValid, currentOrigin.x, currentOrigin.y)
    end

    -- Ensure default line width for screen-space UI (Hand)
    love.graphics.setLineWidth(1)
    -- Now draw the actual hand (will draw over the grid highlight and preview)
    self.handCardBounds = self.renderer:drawHand(currentPlayer, self.selectedHandIndex)
    
    -- Draw hovered hand card preview near the mouse
    if self.hoveredHandIndex then
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

            -- Clamp position to stay within screen bounds using scaled dimensions
            if previewX + previewCardW > screenW then
                previewX = screenW - previewCardW
            end
            if previewY + previewCardH > screenH then
                previewY = screenH - previewCardH
            end
            previewX = math.max(0, previewX)
            previewY = math.max(0, previewY)

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
    if self.showHelpBox and self.currentPhase then
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

                local success, message = self.gameService:attemptPlacement(self, self.selectedHandIndex, gridX, gridY)
                if success then
                    self:resetSelectionAndStatus()
                end
                self:updateStatusMessage(message)
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
    elseif button == 2 then -- Right mouse button: Activation / Convergence Abort
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
    if self.isPaused then
        -- Update pause button hover state if implemented in Button class
        -- For now, just prevent panning/game hover updates.
        return
    end

    -- Update world mouse coordinates
    local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)

    -- Convert world coordinates to grid coordinates relative to the CURRENT player's origin for hover effects
    local currentOrigin = self.playerOrigins[self.gameService.currentPlayerIndex] or {x=0, y=0}
    self.hoverGridX, self.hoverGridY = self.renderer:worldToGridCoords(worldX, worldY, currentOrigin.x, currentOrigin.y)

    -- Check for hand hover
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
    if self.isPaused then
        return
    end

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
        self.isPaused = not self.isPaused -- Toggle pause state
    elseif key == "p" then -- Debug: Advance Phase
        if not self.isPaused then
            self:advancePhase()
        end
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

return PlayState 
