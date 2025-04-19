-- src/game/states/play_state.lua
-- The main gameplay state

local Player = require('src.game.player')
local Card = require('src.game.card')
local Network = require('src.game.network')
local CardDefinitions = require('src.game.data.card_definitions')
local Renderer = require('src.rendering.renderer')
local Button = require('src.ui.button') -- Require the Button module
local GameService = require('src.game.game_service') -- Require GameService

local PlayState = {}

-- Constants for Setup (adjust as needed)
local NUM_PLAYERS = 2
local STARTING_ENERGY = 5 -- Placeholder - GDD 4.1 value TBD
local STARTING_DATA = 5     -- Placeholder - GDD 4.1 value TBD
local STARTING_MATERIAL = 5 -- Placeholder - GDD 4.1 value TBD
local STARTING_HAND_CARD_IDS = { "NODE_TECH_001", "NODE_CULT_001" } -- Placeholder - GDD 4.1 Seed Cards TBD
local KEYBOARD_PAN_SPEED = 400 -- Base pixels per second at zoom 1.0

function PlayState:new()
    local instance = setmetatable({}, { __index = PlayState })
    instance:init()
    return instance
end

function PlayState:init()
    -- Initialize state variables
    self.players = {}
    self.currentPlayerIndex = 1 -- Start with player 1
    self.renderer = Renderer:new() -- Create renderer instance
    self.selectedHandIndex = nil -- Track selected card in hand
    self.handCardBounds = {} -- Store bounding boxes returned by renderer
    self.statusMessage = "" -- For displaying feedback
    -- Potentially store loaded definitions if needed elsewhere
    -- self.cardDefs = CardDefinitions

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

    -- Initialize Game Service (passing self)
    self.gameService = GameService:new()

    -- Create UI buttons (pass self for context in callbacks)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local buttonY = screenH - 50
    local buttonWidth = 150

    self.buttonEndTurn = Button:new(screenW - buttonWidth - 10, buttonY, "End Turn", function() self:endTurn() end, buttonWidth)
    self.buttonDiscard = Button:new(10, buttonY, "Discard Selected", function() self:discardSelected() end, buttonWidth)
    self.buttonDiscard:setEnabled(false)
    self.uiElements = { self.buttonEndTurn, self.buttonDiscard }
end

function PlayState:enter()
    print("Entering Play State - Initializing Game...")
    self:init() -- Reset state variables and create renderer

    -- 1. Create Players
    for i = 1, NUM_PLAYERS do
        local player = Player:new(i, "Player " .. i)
        table.insert(self.players, player)

        -- 2. Set Starting Resources
        player:addResource('energy', STARTING_ENERGY)
        player:addResource('data', STARTING_DATA)
        player:addResource('material', STARTING_MATERIAL)

        -- 3. Create Reactor Card (before creating network)
        local reactorData = CardDefinitions["REACTOR_BASE"]
        if reactorData then
            player.reactorCard = Card:new(reactorData)
            player.reactorCard.owner = player -- Assign ownership early
        else
            error("REACTOR_BASE definition not found!")
        end

        -- 4. Create Network (which automatically places the reactor)
        player.network = Network:new(player) -- Create network, passing the player
        if not player.network then
            error("Failed to create network for player " .. player.name)
        end

        -- 5. Create and Add Starting Hand Cards (Seed Cards)
        print(string.format("Adding starting hand for %s:", player.name))
        for _, cardId in ipairs(STARTING_HAND_CARD_IDS) do
            local cardData = CardDefinitions[cardId]
            if cardData then
                local cardInstance = Card:new(cardData)
                player:addCardToHand(cardInstance)
            else
                print(string.format("Warning: Seed card definition not found for ID: %s", cardId))
            end
        end
        print("---")

    end

    -- Set initial status message
    self.statusMessage = string.format("Player %d's turn.", self.currentPlayerIndex)
    print("Play State Initialization Complete.")
end

-- Action: End the current turn (Delegates to service)
function PlayState:endTurn()
    local success, message = self.gameService:endTurn(self)
    if success then
        -- Service already advanced player index, reset local state
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
    self.handCardBounds = {} -- Clear bounds
    self.buttonDiscard:setEnabled(false) -- Disable discard button
    self.statusMessage = newStatus or ""
end

function PlayState:update(dt)
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

function PlayState:draw()
    love.graphics.clear(0.3, 0.3, 0.3, 1)
    if not self.players or #self.players == 0 or not self.renderer then return end

    local currentPlayer = self.players[self.currentPlayerIndex]
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Draw game elements, passing camera state
    self.renderer:drawNetwork(currentPlayer.network, self.cameraX, self.cameraY, self.cameraZoom)
    self.handCardBounds = self.renderer:drawHand(currentPlayer, self.selectedHandIndex)
    self.renderer:drawUI(currentPlayer)

    -- Draw hover highlight (after network, before UI/buttons)
    self.renderer:drawHoverHighlight(self.hoverGridX, self.hoverGridY, self.cameraX, self.cameraY, self.cameraZoom)

    -- Draw UI elements (buttons)
    for _, element in ipairs(self.uiElements) do
        element:draw()
    end

    -- Draw status message (Top Center)
    love.graphics.setColor(1, 1, 0, 1)
    -- Calculate position for top-center display
    local statusText = self.statusMessage or ""
    local statusWidth = love.graphics.getFont():getWidth(statusText)
    local statusX = (screenW - statusWidth) / 2
    local statusY = 10 -- Position near the top
    love.graphics.print(statusText, statusX, statusY)

    -- Draw turn indicator & Quit message
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(string.format("Current Turn: Player %d (%s)", self.currentPlayerIndex, currentPlayer.name), 10, 10)
    love.graphics.print("MMB Drag / WASD: Pan | Wheel: Zoom", screenW / 2 - 100, screenH - 20)
    love.graphics.print("Press Esc to Quit", 10, screenH - 20)
end

-- Helper function to check if point (px, py) is inside a rectangle {x, y, w, h}
local function isPointInRect(px, py, rect)
    return px >= rect.x and px < rect.x + rect.w and py >= rect.y and py < rect.y + rect.h
end

function PlayState:mousepressed(x, y, button, istouch, presses)
    -- Store last mouse position for panning
    self.lastMouseX = x
    self.lastMouseY = y

    -- 1. Check UI Elements FIRST
    for _, element in ipairs(self.uiElements) do
        if element.handleMousePress and element:handleMousePress(x, y) then
            return -- UI element handled the click
        end
    end

    local currentPlayer = self.players[self.currentPlayerIndex]

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

function PlayState:mousereleased(x, y, button, istouch)
    if button == 3 then -- Middle mouse button: Stop panning
        self.isPanning = false
        love.mouse.setRelativeMode(false) -- Show cursor again
    end
end

function PlayState:mousemoved(x, y, dx, dy, istouch)
    -- Update hover grid coordinates
    local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
    self.hoverGridX, self.hoverGridY = self.renderer:worldToGridCoords(worldX, worldY)

    if self.isPanning then
        self.cameraX = self.cameraX - (dx / self.cameraZoom)
        self.cameraY = self.cameraY - (dy / self.cameraZoom)
    end
    self.lastMouseX = x
    self.lastMouseY = y
end

function PlayState:wheelmoved(x, y)
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

function PlayState:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return PlayState 
