-- src/game/states/play_state.lua
-- The main gameplay state

local Player = require('src.game.player')
local Card = require('src.game.card')
local Network = require('src.game.network')
local CardDefinitions = require('src.game.data.card_definitions')
local Renderer = require('src.rendering.renderer')
local Button = require('src.ui.button') -- Require the Button module
local GameService = require('src.game.game_service') -- Require GameService
local StyleGuide = require('src.rendering.styles') -- Require the styles

local PlayState = {}

-- Constants for Setup (adjust as needed)
local NUM_PLAYERS = 2
local STARTING_ENERGY = 5 -- Placeholder - GDD 4.1 value TBD
local STARTING_DATA = 5     -- Placeholder - GDD 4.1 value TBD
local STARTING_MATERIAL = 5 -- Placeholder - GDD 4.1 value TBD
local STARTING_HAND_CARD_IDS = { "NODE_TECH_001", "NODE_CULT_001" } -- Placeholder - GDD 4.1 Seed Cards TBD
local KEYBOARD_PAN_SPEED = 400 -- Base pixels per second at zoom 1.0

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

    -- Camera State
    self.cameraX = -love.graphics.getWidth() / 2 -- Center initial view roughly
    self.cameraY = -love.graphics.getHeight() / 2
    self.cameraZoom = 1.0
    self.minZoom = 0.2
    self.maxZoom = 3.0
    self.isPanning = false
    self.lastMouseX = 0
    self.lastMouseY = 0

    -- Hover State for Debugging
    self.hoverGridX = nil
    self.hoverGridY = nil

    -- Initialize Game Service (either use injected or create new)
    self.gameService = gameService or GameService:new()

    -- Create UI buttons (pass self for context in callbacks)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local buttonY = screenH - 50
    local buttonWidth = 150
    local uiFonts = self.renderer.fonts -- Get the fonts table
    local uiStyleGuide = self.renderer.styleGuide -- Get the style guide

    self.buttonEndTurn = Button:new(screenW - buttonWidth - 10, buttonY, "End Turn", function() self:endTurn() end, buttonWidth, nil, uiFonts, uiStyleGuide) -- Pass fonts & styles
    self.buttonDiscard = Button:new(10, buttonY, "Discard Selected", function() self:discardSelected() end, buttonWidth, nil, uiFonts, uiStyleGuide) -- Pass fonts & styles
    self.buttonDiscard:setEnabled(false)
    self.uiElements = { self.buttonEndTurn, self.buttonDiscard }
end

function PlayState:enter()
    print("Entering Play State - Initializing Game...")
    
    -- Initialize the game service first
    self.gameService:initializeGame(NUM_PLAYERS)
    
    -- Sync our state with GameService
    self.players = self.gameService:getPlayers()
    
    -- Set initial status message
    self.statusMessage = string.format("Player %d's turn.", self.gameService.currentPlayerIndex)
    print("Play State Initialization Complete.")
end

-- Action: End the current turn (Delegates to service)
function PlayState:endTurn()
    local success, message = self.gameService:endTurn(self)
    if success then
        -- Reset local state
        self:resetSelectionAndStatus(message)
    else
        -- Should not fail currently, but handle if it could
        self.statusMessage = message
    end
end

-- Action: Discard the selected card (Delegates to service)
function PlayState:discardSelected()
    if self.selectedHandIndex then
        local success, message = self.gameService:discardCard(self, self.selectedHandIndex)
        if success then
            -- Service removed card, reset local state
            self:resetSelectionAndStatus(message)
        else
            self.statusMessage = message
        end
    end
end

-- Helper to reset selection state and update status
function PlayState:resetSelectionAndStatus(newStatus)
    self.selectedHandIndex = nil
    self.hoveredHandIndex = nil -- Reset hover too
    self.handCardBounds = {} -- Clear bounds
    self.buttonDiscard:setEnabled(false) -- Disable discard button
    self.statusMessage = newStatus or ""
end

function PlayState:update(stateManager, dt)
    -- Update UI elements (buttons)
    local mx, my = love.mouse.getPosition()
    local mouseDown = love.mouse.isDown(1)
    for _, element in ipairs(self.uiElements) do
        if element.update then
            element:update(mx, my, mouseDown)
        end
    end

    -- Keyboard Panning Logic
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

    local currentPlayer = self.players[self.gameService.currentPlayerIndex]
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Draw game elements
    self.renderer:drawNetwork(currentPlayer.network, self.cameraX, self.cameraY, self.cameraZoom)

    -- Draw grid hover highlight (conditionally, pass selected card) - BEFORE HAND & UI
    local selectedCard = self.selectedHandIndex and currentPlayer.hand[self.selectedHandIndex] or nil
    if selectedCard then
        self.renderer:drawHoverHighlight(self.hoverGridX, self.hoverGridY, self.cameraX, self.cameraY, self.cameraZoom, selectedCard)
    end

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

    self.renderer:drawUI(currentPlayer)

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

    -- Draw turn indicator & Quit message
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(string.format("Current Turn: Player %d (%s)", self.gameService.currentPlayerIndex, currentPlayer.name), 10, 10)
    love.graphics.print("MMB Drag / WASD: Pan | Wheel: Zoom", screenW / 2 - 100, screenH - 20)
    love.graphics.print("Press Esc to Quit", 10, screenH - 20)

    -- Restore original font
    love.graphics.setFont(originalFont)
end

-- Helper function to check if point (px, py) is inside a rectangle {x, y, w, h}
local function isPointInRect(px, py, rect)
    return px >= rect.x and px < rect.x + rect.w and py >= rect.y and py < rect.y + rect.h
end

function PlayState:mousepressed(stateManager, x, y, button, istouch, presses)
    -- Store last mouse position for panning
    self.lastMouseX = x
    self.lastMouseY = y

    -- 1. Check UI Elements FIRST
    for _, element in ipairs(self.uiElements) do
        if element.handleMousePress and element:handleMousePress(x, y) then
            return -- UI element handled the click
        end
    end

    local currentPlayer = self.players[self.gameService.currentPlayerIndex]

    if button == 1 then -- Left mouse button
        -- 2. Check Hand Cards
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
                self:resetSelectionAndStatus("Card deselected.")
                print("Deselected hand card: " .. handClickedIndex)
            else
                self.selectedHandIndex = handClickedIndex
                self.buttonDiscard:setEnabled(true)
                local card = currentPlayer.hand[self.selectedHandIndex]
                self.statusMessage = string.format("Selected card: %s (%s)", card.title, card.id)
                print("Selected hand card: " .. handClickedIndex, card.title)
            end
        else
            -- 3. Attempt Network Placement (Delegate to service)
            if self.selectedHandIndex then
                local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
                local gridX, gridY = self.renderer:worldToGridCoords(worldX, worldY)

                local success, message = self.gameService:attemptPlacement(self, self.selectedHandIndex, gridX, gridY)
                self.statusMessage = message
                if success then
                    -- Placement successful, reset selection state
                    self:resetSelectionAndStatus(message)
                end
                -- If placement failed, message is already set, keep card selected
            else
                 self.statusMessage = ""
                 print("Clicked network area with no card selected.")
            end
        end
    elseif button == 2 then -- Right mouse button: Activation (Delegate to service)
        local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
        local gridX, gridY = self.renderer:worldToGridCoords(worldX, worldY)
        print(string.format("Right-click screen(%d,%d) -> world(%.1f,%.1f) -> grid(%d,%d)", x, y, worldX, worldY, gridX, gridY))

        local success, message = self.gameService:attemptActivation(self, gridX, gridY)
        self.statusMessage = message
        -- No selection state change on activation attempt (success or fail)
    elseif button == 3 then -- Middle mouse button: Start panning
        self.isPanning = true
        love.mouse.setRelativeMode(true)
    end
end

function PlayState:mousereleased(stateManager, x, y, button, istouch)
    if button == 3 then -- Middle mouse button: Stop panning
        self.isPanning = false
        love.mouse.setRelativeMode(false) -- Show cursor again
    end
end

function PlayState:mousemoved(stateManager, x, y, dx, dy, istouch)
    -- Update hover grid coordinates
    local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
    self.hoverGridX, self.hoverGridY = self.renderer:worldToGridCoords(worldX, worldY)

    -- Check for hand hover
    local currentlyHovering = nil
    for _, bounds in ipairs(self.handCardBounds) do
        if isPointInRect(x, y, bounds) then
            currentlyHovering = bounds.index
            break
        end
    end
    self.hoveredHandIndex = currentlyHovering -- Update hovered index (nil if none)

    if self.isPanning then
        self.cameraX = self.cameraX - (dx / self.cameraZoom)
        self.cameraY = self.cameraY - (dy / self.cameraZoom)
    end
    self.lastMouseX = x
    self.lastMouseY = y
end

function PlayState:wheelmoved(stateManager, x, y)
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
        love.event.quit()
    end
end

return PlayState 
