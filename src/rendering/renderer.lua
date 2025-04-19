-- src/rendering/renderer.lua
-- Handles drawing the game state to the screen.

local Card = require('src.game.card') -- Needed for Card.Slots constants

local Renderer = {}
Renderer.__index = Renderer

-- Constants for rendering (adjust as needed)
local CARD_WIDTH = 100
local CARD_HEIGHT = 140
local GRID_SPACING = 10 -- Space between cards
local NETWORK_OFFSET_X = 400 -- Initial screen X offset for the network drawing area
local NETWORK_OFFSET_Y = 100 -- Initial screen Y offset for the network drawing area
local SLOT_RADIUS = 5 -- Size of the slot indicator
local HAND_CARD_SCALE = 0.6
local HAND_CARD_WIDTH = CARD_WIDTH * HAND_CARD_SCALE
local HAND_CARD_HEIGHT = CARD_HEIGHT * HAND_CARD_SCALE
local HAND_SPACING = 10
local HAND_START_X = 50
local BOTTOM_BUTTON_AREA_HEIGHT = 60 -- Space reserved for buttons at the bottom
local SELECTED_CARD_RAISE = 15 -- How much to raise the selected card

-- Slot Type Colors (Approximate, adjust as needed)
local SLOT_COLORS = {
    [Card.Type.TECHNOLOGY] = { 0.2, 1, 0.2, 1 }, -- Electric Green
    [Card.Type.CULTURE] = { 1, 0.8, 0, 1 }, -- Warm Yellow/Orange
    [Card.Type.RESOURCE] = { 0.6, 0.4, 0.2, 1 }, -- Earthy Brown/Bronze
    [Card.Type.KNOWLEDGE] = { 0.6, 0.2, 1, 1 }, -- Deep Purple/Indigo
}
local CLOSED_SLOT_COLOR = { 0.3, 0.3, 0.3, 1 } -- Dim Gray
local SLOT_BORDER_COLOR = { 0, 0, 0, 1 } -- Black

function Renderer:new()
    local instance = setmetatable({}, Renderer)
    print("Renderer initialized.")
    -- Store default offsets - these might become less relevant with camera
    instance.defaultOffsetX = NETWORK_OFFSET_X
    instance.defaultOffsetY = NETWORK_OFFSET_Y
    return instance
end

-- Convert network grid coordinates (x, y) to WORLD coordinates (wx, wy)
-- Note: World coordinates are independent of camera zoom/pan
function Renderer:gridToWorldCoords(gridX, gridY)
    -- Place grid (0,0) at world origin for simplicity with camera
    local wx = gridX * (CARD_WIDTH + GRID_SPACING)
    local wy = gridY * (CARD_HEIGHT + GRID_SPACING)
    return wx, wy
end

-- Convert screen coordinates (sx, sy) to WORLD coordinates (wx, wy)
function Renderer:screenToWorldCoords(sx, sy, cameraX, cameraY, cameraZoom)
    local wx = (sx / cameraZoom) + cameraX
    local wy = (sy / cameraZoom) + cameraY
    return wx, wy
end

-- Convert WORLD coordinates (wx, wy) to network grid coordinates (gridX, gridY)
function Renderer:worldToGridCoords(wx, wy)
    -- Corrected calculation
    local cellWidth = CARD_WIDTH + GRID_SPACING
    local cellHeight = CARD_HEIGHT + GRID_SPACING
    local gridX = math.floor(wx / cellWidth)
    local gridY = math.floor(wy / cellHeight)
    return gridX, gridY
end

-- Helper to get slot position and implicit type based on GDD 4.3 (Corrected)
local function getSlotInfo(slotIndex)
    -- Returns { x_offset, y_offset, type, is_output }
    local halfW = CARD_WIDTH / 2
    local halfH = CARD_HEIGHT / 2
    local quartW = CARD_WIDTH / 4
    local quartH = CARD_HEIGHT / 4

    if slotIndex == Card.Slots.TOP_LEFT then return { quartW, 0, Card.Type.CULTURE, true } end
    if slotIndex == Card.Slots.TOP_RIGHT then return { halfW + quartW, 0, Card.Type.TECHNOLOGY, false } end
    if slotIndex == Card.Slots.BOTTOM_LEFT then return { quartW, CARD_HEIGHT, Card.Type.CULTURE, false } end
    if slotIndex == Card.Slots.BOTTOM_RIGHT then return { halfW + quartW, CARD_HEIGHT, Card.Type.TECHNOLOGY, true } end
    if slotIndex == Card.Slots.LEFT_TOP then return { 0, quartH, Card.Type.KNOWLEDGE, true } end
    if slotIndex == Card.Slots.LEFT_BOTTOM then return { 0, halfH + quartH, Card.Type.RESOURCE, false } end
    -- Corrected Right Edge based on user feedback and GDD v0.3
    if slotIndex == Card.Slots.RIGHT_TOP then return { CARD_WIDTH, quartH, Card.Type.KNOWLEDGE, false } end -- Was Resource Output
    if slotIndex == Card.Slots.RIGHT_BOTTOM then return { CARD_WIDTH, halfH + quartH, Card.Type.RESOURCE, true } end -- Was Knowledge Input
    return nil -- Should not happen
end

-- Helper function to draw the 8 connection slots for a card
function Renderer:drawCardSlots(card, sx, sy)
    if not card then return end

    for slotIndex = 1, 8 do
        local info = getSlotInfo(slotIndex)
        if info then
            local slotX = sx + info[1] -- x_offset
            local slotY = sy + info[2] -- y_offset
            local slotType = info[3]   -- type
            local isOutput = info[4]   -- is_output

            local isOpen = card:isSlotOpen(slotIndex)

            -- Set color based on open status and type
            if isOpen then
                love.graphics.setColor(SLOT_COLORS[slotType] or {1,1,1,1}) -- Default white if type unknown
            else
                love.graphics.setColor(CLOSED_SLOT_COLOR)
            end

            -- Draw the slot indicator (circle)
            love.graphics.circle("fill", slotX, slotY, SLOT_RADIUS)

            -- Draw border
            love.graphics.setColor(SLOT_BORDER_COLOR)
            love.graphics.circle("line", slotX, slotY, SLOT_RADIUS)

            -- Optional: Indicate Output/Input (e.g., small inner shape)
            if isOpen then
                 if isOutput then
                     -- Draw a small line/arrow pointing out?
                     -- love.graphics.line(slotX, slotY, slotX + directionX*SLOT_RADIUS*0.6, slotY + directionY*SLOT_RADIUS*0.6) -- Needs direction calc
                 else
                     -- Draw a small dot?
                     love.graphics.circle("fill", slotX, slotY, SLOT_RADIUS * 0.3)
                 end
            end
        end
    end
end

-- Draw a player's network grid, applying camera transform
function Renderer:drawNetwork(network, cameraX, cameraY, cameraZoom)
    if not network then return end

    love.graphics.push() -- Save current transform state
    love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom) -- Apply camera pan (adjusting for zoom)
    love.graphics.scale(cameraZoom, cameraZoom) -- Apply camera zoom

    love.graphics.setLineWidth(1 / cameraZoom) -- Adjust line width based on zoom

    for cardId, card in pairs(network.cards) do
        if card.position then
            -- Convert grid coords directly to world coords for drawing within the transformed space
            local wx, wy = self:gridToWorldCoords(card.position.x, card.position.y)

            -- Draw placeholder card rectangle
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            if card.type == Card.Type.REACTOR then
                love.graphics.setColor(1, 1, 0.5, 1)
            end
            love.graphics.rectangle("fill", wx, wy, CARD_WIDTH, CARD_HEIGHT)

            -- Draw border
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("line", wx, wy, CARD_WIDTH, CARD_HEIGHT)

            -- Draw basic info (adjust font size? for now, keep it simple)
            love.graphics.printf(card.title, wx + 5, wy + 5, CARD_WIDTH - 10, "left")
            love.graphics.printf(string.format("(%d,%d)", card.position.x, card.position.y), wx + 5, wy + CARD_HEIGHT - 20, CARD_WIDTH - 10, "left")

            -- Draw Connection Slots
            self:drawCardSlots(card, wx, wy) -- Pass world coords
        end
    end

    love.graphics.pop() -- Restore previous transform state
end

-- Draw highlight over the hovered grid cell
function Renderer:drawHoverHighlight(gridX, gridY, cameraX, cameraY, cameraZoom)
    if gridX == nil or gridY == nil then return end

    -- Convert grid coords to world coords for drawing within transformed space
    local wx, wy = self:gridToWorldCoords(gridX, gridY)

    love.graphics.push() -- Apply camera transform just for this highlight
    love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
    love.graphics.scale(cameraZoom, cameraZoom)

    love.graphics.setColor(1, 1, 1, 0.3) -- Semi-transparent white
    love.graphics.rectangle("fill", wx, wy, CARD_WIDTH, CARD_HEIGHT)

    love.graphics.pop()
end

-- Draw a player's hand, visually indicating the selected card
-- Returns a table of bounding boxes for click detection: { { index=i, x=sx, y=sy, w=w, h=h }, ... }
function Renderer:drawHand(player, selectedIndex)
    if not player or not player.hand then return {} end

    -- Calculate Y position to be above the bottom button area
    local handStartY = love.graphics.getHeight() - BOTTOM_BUTTON_AREA_HEIGHT - HAND_CARD_HEIGHT
    local handBounds = {}

    love.graphics.setColor(0,0,0,1)
    love.graphics.print(string.format("%s Hand (%d):", player.name, #player.hand), HAND_START_X, handStartY - 20)

    -- Draw non-selected cards first
    for i, card in ipairs(player.hand) do
        if i ~= selectedIndex then
            local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
            local sy = handStartY
            -- Store bounds for click detection
            table.insert(handBounds, { index = i, x = sx, y = sy, w = HAND_CARD_WIDTH, h = HAND_CARD_HEIGHT })
            -- Draw placeholder card rectangle
            love.graphics.setColor(0.8, 0.8, 1, 1) -- Bluish tint
            love.graphics.rectangle("fill", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("line", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.printf(card.title, sx + 3, sy + 3, HAND_CARD_WIDTH - 6, "left")
        end
    end

    -- Draw selected card last (so it's on top and raised)
    if selectedIndex then
        local card = player.hand[selectedIndex]
        if card then
            local i = selectedIndex
            local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
            local sy = handStartY - SELECTED_CARD_RAISE -- Raise selected card
            -- Store bounds for click detection (use original y for hit detection)
            table.insert(handBounds, { index = i, x = sx, y = handStartY, w = HAND_CARD_WIDTH, h = HAND_CARD_HEIGHT })
            -- Draw placeholder card rectangle (highlighted)
            love.graphics.setColor(1, 1, 0.8, 1)
            love.graphics.rectangle("fill", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setLineWidth(3) -- Thicker border
            love.graphics.rectangle("line", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setLineWidth(1) -- Reset line width
            love.graphics.printf(card.title, sx + 3, sy + 3, HAND_CARD_WIDTH - 6, "left")
        end
    end

    return handBounds
end

-- Placeholder for drawing UI elements (resources, VP, turn info)
function Renderer:drawUI(player)
    if not player then return end
    -- TODO: Implement UI drawing logic
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(string.format("--- %s UI ---", player.name), 10, 30)
    love.graphics.print(string.format("VP: %d", player.vp), 10, 50)
    love.graphics.print(string.format("Res: E:%d D:%d M:%d", player.resources.energy, player.resources.data, player.resources.material), 10, 70)
end

return Renderer
