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

-- Define Card module here for use in getSlotInfo, or require it
local Card = require('src.game.card')

-- Helper function to get slot position and implicit type based on GDD 4.3 (Corrected)
-- Note: This version uses renderer instance for dimensions
local function getSlotInfo(renderer, slotIndex)
    if not renderer then return nil end -- Need renderer for constants
    -- Returns { x_offset, y_offset, type, is_output }
    local cardW = renderer.CARD_WIDTH
    local cardH = renderer.CARD_HEIGHT
    local halfW = cardW / 2
    local halfH = cardH / 2
    local quartW = cardW / 4
    local quartH = cardH / 4

    if slotIndex == Card.Slots.TOP_LEFT then return { quartW, 0, Card.Type.CULTURE, true } end
    if slotIndex == Card.Slots.TOP_RIGHT then return { halfW + quartW, 0, Card.Type.TECHNOLOGY, false } end
    if slotIndex == Card.Slots.BOTTOM_LEFT then return { quartW, cardH, Card.Type.CULTURE, false } end
    if slotIndex == Card.Slots.BOTTOM_RIGHT then return { halfW + quartW, cardH, Card.Type.TECHNOLOGY, true } end
    if slotIndex == Card.Slots.LEFT_TOP then return { 0, quartH, Card.Type.KNOWLEDGE, true } end
    if slotIndex == Card.Slots.LEFT_BOTTOM then return { 0, halfH + quartH, Card.Type.RESOURCE, false } end
    if slotIndex == Card.Slots.RIGHT_TOP then return { cardW, quartH, Card.Type.KNOWLEDGE, false } end
    if slotIndex == Card.Slots.RIGHT_BOTTOM then return { cardW, halfH + quartH, Card.Type.RESOURCE, true } end
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
    self.initiatingConvergenceSlotIndex = nil -- 1-8
    self.targetConvergencePlayerIndex = nil
    self.targetConvergenceNodePos = nil -- {x, y} table
    self.targetConvergenceSlotIndex = nil -- 1-8

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
    local buttonGap = 10
    local uiFonts = self.renderer.fonts -- Get the fonts table
    local uiStyleGuide = self.renderer.styleGuide -- Get the style guide

    local currentX = screenW - buttonWidth - buttonGap
    self.buttonEndTurn = Button:new(currentX, buttonY, "End Turn", function() self:endTurn() end, buttonWidth, nil, uiFonts, uiStyleGuide) -- Pass fonts & styles
    
    currentX = currentX - buttonWidth - buttonGap
    self.buttonAdvancePhase = Button:new(currentX, buttonY, "Next Phase", function() self:advancePhase() end, buttonWidth, nil, uiFonts, uiStyleGuide)

    -- Create separate discard buttons
    currentX = 10
    self.buttonDiscardMaterial = Button:new(currentX, buttonY, "Discard for 1 M", function() self:discardSelected('material') end, buttonWidth, nil, uiFonts, uiStyleGuide)
    self.buttonDiscardMaterial:setEnabled(false)

    currentX = currentX + buttonWidth + buttonGap
    self.buttonDiscardData = Button:new(currentX, buttonY, "Discard for 1 D", function() self:discardSelected('data') end, buttonWidth, nil, uiFonts, uiStyleGuide)
    self.buttonDiscardData:setEnabled(false)

    -- Update uiElements list
    self.uiElements = { self.buttonEndTurn, self.buttonAdvancePhase, self.buttonDiscardMaterial, self.buttonDiscardData }
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

    -- Draw turn indicator & Quit message
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(string.format("Current Turn: Player %d (%s)", self.gameService.currentPlayerIndex, currentPlayer.name), 10, 10)
    love.graphics.print("MMB Drag / WASD: Pan | Wheel: Zoom | C: Test Converge | P: Next Phase", screenW / 2 - 200, screenH - 20)
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
            self:updateStatusMessage(string.format("Select a %s OUTPUT slot on your network.", tostring(self.selectedConvergenceLinkType)))
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
                -- Handle clicking on network to select output slot
                local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)
                local gridX, gridY, clickedCard, clickedSlotIndex = self.renderer:getSlotAtWorldPos(currentPlayer.network, worldX, worldY, currentOrigin.x, currentOrigin.y)

                if clickedCard and clickedSlotIndex then
                    print(string.format("Clicked on card '%s' at (%d,%d), slot %d", clickedCard.title, gridX, gridY, clickedSlotIndex))
                    -- Validate the selected slot
                    local slotInfo = getSlotInfo(self.renderer, clickedSlotIndex) -- Pass renderer
                    local isValid = true
                    local reason = ""

                    if not slotInfo then
                        isValid = false
                        reason = "Internal error: Invalid slot index."
                    elseif not clickedCard:isSlotDefinedOpen(clickedSlotIndex) then
                        isValid = false
                        reason = "Selected slot is closed."
                    -- TODO: Add check for slot availability (not occupied by another link) -> requires card/network state
                    -- elseif not clickedCard:isSlotAvailable(clickedSlotIndex) then
                    --    isValid = false
                    --    reason = "Selected slot is already occupied."
                    elseif not slotInfo[4] then -- Check if it IS an output slot (slotInfo[4] is is_output)
                        isValid = false
                        reason = "Selected slot must be an OUTPUT."
                    elseif slotInfo[3] ~= self.selectedConvergenceLinkType then -- Check if type matches
                        isValid = false
                        reason = string.format("Selected slot type (%s) does not match required link type (%s).", tostring(slotInfo[3]), tostring(self.selectedConvergenceLinkType))
                    end

                    if isValid then
                        -- Store selection and move to next state
                        self.initiatingConvergenceNodePos = {x=gridX, y=gridY}
                        self.initiatingConvergenceSlotIndex = clickedSlotIndex
                        self.convergenceSelectionState = "selecting_opponent_input"
                        self:updateStatusMessage(string.format("Now select an opponent's %s INPUT slot.", tostring(self.selectedConvergenceLinkType)))
                        print(string.format("Initiating slot selected: P%d (%d,%d) Slot %d. State -> selecting_opponent_input", currentPlayerIndex, gridX, gridY, clickedSlotIndex))
                        -- Buttons remain disabled
                        -- TODO: Play confirmation sound?
                    else
                        -- Invalid slot clicked, remain in selecting_own_output state
                        self:updateStatusMessage("Invalid slot: " .. reason)
                        print("Invalid initiating slot selected: " .. reason)
                        -- Buttons remain disabled
                    end
                else
                    -- Clicked on the grid but not near a specific slot
                    self:updateStatusMessage("Click closer to a valid output slot.")
                end
            elseif self.convergenceSelectionState == "selecting_opponent_input" then
                -- Handle clicking on network to select input slot
                local worldX, worldY = self.renderer:screenToWorldCoords(x, y, self.cameraX, self.cameraY, self.cameraZoom)

                -- Determine which opponent grid was clicked (iterate through players)
                local foundTargetPlayerIndex = nil
                local foundTargetGridX, foundTargetGridY = nil, nil
                local foundTargetCard, foundTargetSlotIndex = nil, nil

                for pIdx, player in ipairs(self.players) do
                    if pIdx ~= currentPlayerIndex then -- Only check opponents
                        local opponentOrigin = self.playerOrigins[pIdx] or {x=0, y=0}
                        local gridX, gridY, clickedCard, clickedSlotIndex = self.renderer:getSlotAtWorldPos(player.network, worldX, worldY, opponentOrigin.x, opponentOrigin.y)
                        
                        -- If a slot was found on this opponent's grid, store it and stop checking others
                        if clickedCard and clickedSlotIndex then
                            foundTargetPlayerIndex = pIdx
                            foundTargetGridX = gridX
                            foundTargetGridY = gridY
                            foundTargetCard = clickedCard
                            foundTargetSlotIndex = clickedSlotIndex
                            print(string.format("Potential target: Player %d Card '%s' at (%d,%d), slot %d", pIdx, clickedCard.title, gridX, gridY, clickedSlotIndex))
                            break -- Found a potential target, stop checking other players
                        end
                    end
                end

                if foundTargetCard and foundTargetSlotIndex then
                    -- Validate the selected slot
                    local slotInfo = getSlotInfo(self.renderer, foundTargetSlotIndex)
                    local isValid = true
                    local reason = ""

                    if not slotInfo then
                        isValid = false
                        reason = "Internal error: Invalid slot index."
                    elseif not foundTargetCard:isSlotDefinedOpen(foundTargetSlotIndex) then
                        isValid = false
                        reason = "Selected slot is closed."
                    -- TODO: Add check for slot availability (not occupied by another link) -> requires card/network state
                    -- elseif not foundTargetCard:isSlotAvailable(foundTargetSlotIndex) then
                    --    isValid = false
                    --    reason = "Selected slot is already occupied."
                    elseif slotInfo[4] then -- Check if it is NOT an output slot (i.e., it IS an input)
                        isValid = false
                        reason = "Selected slot must be an INPUT."
                    elseif slotInfo[3] ~= self.selectedConvergenceLinkType then -- Check if type matches
                        isValid = false
                        reason = string.format("Selected slot type (%s) does not match required link type (%s).", tostring(slotInfo[3]), tostring(self.selectedConvergenceLinkType))
                    end

                    if isValid then
                        -- All checks passed! Attempt the convergence via GameService
                        print("Target slot validated. Attempting convergence...")
                        self.targetConvergencePlayerIndex = foundTargetPlayerIndex
                        self.targetConvergenceNodePos = {x=foundTargetGridX, y=foundTargetGridY}
                        self.targetConvergenceSlotIndex = foundTargetSlotIndex

                        local success, message, shiftOccurred = self.gameService:attemptConvergence(
                            currentPlayerIndex, -- Initiating player
                            self.initiatingConvergenceNodePos,
                            self.initiatingConvergenceSlotIndex, -- Added Initiating Slot Index
                            self.targetConvergencePlayerIndex,
                            self.targetConvergenceNodePos,
                            self.targetConvergenceSlotIndex, -- Added Target Slot Index
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
                        -- Invalid target slot clicked
                        self:updateStatusMessage("Invalid target slot: " .. reason)
                        print("Invalid target slot selected: " .. reason)
                        -- Remain in selecting_opponent_input state
                    end
                else
                    -- Clicked, but not near a valid slot on any opponent grid
                    self:updateStatusMessage("Click closer to a valid opponent input slot.")
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
    if button == 3 then -- Middle mouse button: Stop panning
        self.isPanning = false
        love.mouse.setRelativeMode(false) -- Show cursor again
    end
end

function PlayState:mousemoved(stateManager, x, y, dx, dy, istouch)
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
    elseif key == "p" then -- Debug: Advance Phase
        self:advancePhase()
    end
end

function PlayState:resetConvergenceSelection()
    self.convergenceSelectionState = nil
    self.selectedConvergenceLinkType = nil
    self.hoveredLinkType = nil
    self.initiatingConvergenceNodePos = nil
    self.initiatingConvergenceSlotIndex = nil
    self.targetConvergencePlayerIndex = nil
    self.targetConvergenceNodePos = nil
    self.targetConvergenceSlotIndex = nil
    -- We might need to re-evaluate button states here too, but handled in abort logic for now
end

return PlayState 
