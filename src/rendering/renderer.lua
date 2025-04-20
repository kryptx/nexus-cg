-- src/rendering/renderer.lua
-- Handles drawing the game state to the screen.

local Card = require('src.game.card') -- Needed for Card.Slots constants
local StyleGuide = require('src.rendering.styles') -- Load the styles

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
local UI_ICON_SIZE = 18      -- Size for UI resource icons
local CARD_COST_ICON_SIZE = 9 -- Size for card cost icons (Reduced from 12)

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
    instance.styleGuide = StyleGuide
    instance.fonts = {} -- Table to hold font objects
    instance.images = {} -- Table to cache loaded image objects
    instance.icons = {} -- Table to cache loaded icon image objects

    -- Store rendering constants on the instance
    instance.CARD_WIDTH = CARD_WIDTH
    instance.CARD_HEIGHT = CARD_HEIGHT
    instance.GRID_SPACING = GRID_SPACING
    instance.SLOT_RADIUS = SLOT_RADIUS
    instance.HAND_CARD_WIDTH = HAND_CARD_WIDTH
    instance.HAND_CARD_HEIGHT = HAND_CARD_HEIGHT
    instance.UI_ICON_SIZE = UI_ICON_SIZE
    -- ... potentially add others if needed ...

    -- Store default offsets
    instance.defaultOffsetX = NETWORK_OFFSET_X
    instance.defaultOffsetY = NETWORK_OFFSET_Y

    -- Define base sizes first
    -- Aim for world sizes * targetScale (1/3) to be reasonable (~7-10pt)
    local baseStandardSize = 24 -- Target world size ~8pt (24 * 1/3)
    local baseSmallSize = 16    -- Target world size ~6.7pt (20 * 1/3)
    local baseTitleSize = 16    -- Target world size ~8pt (24 * 1/3)
    local uiBaseStandardSize = 7 -- Base size for UI Standard (Target UI size 10pt)
    local uiBaseSmallSize = 6   -- Base size for UI Small (Target UI size 8pt)
    local worldFontMultiplier = 3 -- World fonts created at base * 3
    local uiFontMultiplier = 2 -- Create UI fonts at base * 2

    -- Create fonts once
    local fontPath = "assets/fonts/Roboto-Regular.ttf"
    local fontPathSemiBold = "assets/fonts/Roboto-SemiBold.ttf"
    local defaultFont = love.graphics.getFont()

    if love.filesystem.getInfo(fontPath) and love.filesystem.getInfo(fontPathSemiBold) then
        print("Loading TTF fonts...")
        -- World Fonts (3x)
        instance.fonts.worldStandard = love.graphics.newFont(fontPath, baseStandardSize * 3)
        instance.fonts.worldSmall = love.graphics.newFont(fontPath, baseSmallSize * 3)
        instance.fonts.worldTitleSemiBold = love.graphics.newFont(fontPathSemiBold, baseTitleSize * 3)
        -- UI Fonts (Sized by uiFontMultiplier)
        instance.fonts.uiStandard = love.graphics.newFont(fontPath, uiBaseStandardSize * uiFontMultiplier)
        instance.fonts.uiSmall = love.graphics.newFont(fontPath, uiBaseSmallSize * uiFontMultiplier)
        print("  Loaded UI Fonts (Sizes: " .. uiBaseStandardSize*uiFontMultiplier .. ", " .. uiBaseSmallSize*uiFontMultiplier .. ")")

        -- Preview Fonts (Using world font paths but UI sizes/multiplier)
        instance.fonts.previewTitleSemiBold = love.graphics.newFont(fontPathSemiBold, uiBaseStandardSize * uiFontMultiplier) -- 10*2=20pt
        instance.fonts.previewStandard = love.graphics.newFont(fontPath, uiBaseStandardSize * uiFontMultiplier)     -- 10*2=20pt
        instance.fonts.previewSmall = love.graphics.newFont(fontPath, uiBaseSmallSize * uiFontMultiplier)         -- 8*2=16pt

    else
        print("Warning: One or more TTF fonts not found... Using default-sized fonts.")
        -- Fallback
        instance.fonts.worldStandard = love.graphics.newFont(baseStandardSize * 3)
        instance.fonts.worldSmall = love.graphics.newFont(baseSmallSize * 3)
        instance.fonts.worldTitleSemiBold = instance.fonts.worldSmall
        instance.fonts.uiStandard = love.graphics.newFont(uiBaseStandardSize * uiFontMultiplier)
        instance.fonts.uiSmall = love.graphics.newFont(uiBaseSmallSize * uiFontMultiplier)
        -- Fallback for Preview Fonts
        instance.fonts.previewTitleSemiBold = instance.fonts.uiStandard -- Fallback to standard UI
        instance.fonts.previewStandard = instance.fonts.uiStandard
        instance.fonts.previewSmall = instance.fonts.uiSmall
    end

    -- Ensure all fonts have a valid fallback
    instance.fonts.worldStandard = instance.fonts.worldStandard or defaultFont
    instance.fonts.worldSmall = instance.fonts.worldSmall or defaultFont
    instance.fonts.uiStandard = instance.fonts.uiStandard or defaultFont
    instance.fonts.uiSmall = instance.fonts.uiSmall or defaultFont
    instance.fonts.worldTitleSemiBold = instance.fonts.worldTitleSemiBold or defaultFont
    -- Add fallbacks for preview fonts
    instance.fonts.previewTitleSemiBold = instance.fonts.previewTitleSemiBold or instance.fonts.uiStandard or defaultFont
    instance.fonts.previewStandard = instance.fonts.previewStandard or instance.fonts.uiStandard or defaultFont
    instance.fonts.previewSmall = instance.fonts.previewSmall or instance.fonts.uiSmall or defaultFont

    -- Store base sizes for scaling calculations
    instance.baseSmallFontSize = baseSmallSize
    instance.baseTitleFontSize = baseTitleSize
    instance.baseStandardFontSize = baseStandardSize -- Add missing assignment
    instance.uiBaseStandardSize = uiBaseStandardSize -- Store UI base size
    instance.uiBaseSmallSize = uiBaseSmallSize     -- Store UI base size
    -- Store multipliers used at creation time
    instance.worldFontMultiplier = worldFontMultiplier
    instance.uiFontMultiplier = uiFontMultiplier

    -- Load Resource Icons
    instance.icons.energy = instance:_loadImage("assets/images/energy.png")
    instance.icons.data = instance:_loadImage("assets/images/data.png")
    instance.icons.material = instance:_loadImage("assets/images/materials.png") -- Note: filename 'materials.png'

    -- Load Card Type Icons
    instance.icons[Card.Type.TECHNOLOGY] = instance:_loadImage("assets/images/technology-black.png")
    instance.icons[Card.Type.CULTURE] = instance:_loadImage("assets/images/culture-black.png")
    instance.icons[Card.Type.RESOURCE] = instance:_loadImage("assets/images/resource-black.png")
    instance.icons[Card.Type.KNOWLEDGE] = instance:_loadImage("assets/images/knowledge-black.png")

    return instance
end

-- Helper function to load and cache images
function Renderer:_loadImage(path)
    if not path then return nil end

    -- Check cache first
    if self.images[path] then
        -- If cached value is 'false', it means loading failed before
        return self.images[path] ~= false and self.images[path] or nil
    end

    -- Attempt to load
    local success, imageOrError = pcall(love.graphics.newImage, path)
    if success then
        print("Loaded image: " .. path)
        -- Set filtering for potentially better scaling
        imageOrError:setFilter("linear", "linear")
        self.images[path] = imageOrError -- Cache the image object
        return imageOrError
    else
        print(string.format("Warning: Failed to load image '%s'. Error: %s", path, tostring(imageOrError)))
        self.images[path] = false -- Cache failure to avoid retrying
        return nil
    end
end

-- Internal helper for drawing text with scaling baked into printf
-- Assumes font was created at baseFontSize * fontMultiplier
function Renderer:_drawTextScaled(text, x, y, limit, align, styleName, baseFontSize, targetScale, alphaOverride)
    alphaOverride = alphaOverride or 1.0 -- Default to opaque

    local style = self.styleGuide[styleName]
    if not style then
        print("Warning: Invalid style name provided to _drawTextScaled: " .. tostring(styleName))
        return
    end

    local font = self.fonts[style.fontName]
    if not font then
        print("Warning: Font not found for style '" .. styleName .. "': " .. style.fontName .. ". Using default.")
        font = love.graphics.getFont()
        -- Apply alpha override to default color
        local color = style.color or {0,0,0,1}
        -- Ensure color components are in 0-1 range for setColor
        local r = (color[1] or 0) / 255
        local g = (color[2] or 0) / 255
        local b = (color[3] or 0) / 255
        local a = (color[4] or 255) / 255
        love.graphics.setColor(r, g, b, a * alphaOverride)
        love.graphics.setFont(font)
        love.graphics.printf(text, x, y, limit, align)
        return
    end

    -- Determine multiplier (e.g., 3 for world fonts)
    local fontMultiplier
    if string.find(style.fontName, "world") then
        fontMultiplier = self.worldFontMultiplier -- 3
    elseif string.find(style.fontName, "ui") or string.find(style.fontName, "preview") then -- Treat preview like UI
        fontMultiplier = self.uiFontMultiplier -- 2
    else
        print("Warning: Unknown font category for ", style.fontName, ". Assuming multiplier 1.")
        fontMultiplier = 1
    end

    -- Calculate the scale factor needed for printf
    local printfScale = targetScale / fontMultiplier

    -- Calculate adjusted limit and Y offset
    local scaledLimit = limit / printfScale
    -- Y offset calculation needs base font size
    local yOffset = baseFontSize * printfScale * 0.1 -- Heuristic adjustment, might need refinement per font/size
    if align == "center" then
        -- Approximation for vertical centering adjustment
        yOffset = -(baseFontSize * printfScale * 0.4)
    end

    -- Set font and color (applying alpha override), then draw
    local color = style.color or {0,0,0,1} -- Default to black if style missing color
    -- Correction: Style guide is already 0-1 range
    local r = color[1] or 0
    local g = color[2] or 0
    local b = color[3] or 0
    local a = color[4] or 1 -- Default alpha to opaque if missing
    love.graphics.setFont(font)
    love.graphics.setColor(r, g, b, (a * alphaOverride)) -- Apply alpha override correctly
    love.graphics.printf(text, x, y + yOffset, scaledLimit, align, 0, printfScale, printfScale)
end

-- Convert network grid coordinates (x, y) to WORLD coordinates (wx, wy)
-- Note: World coordinates are independent of camera zoom/pan
function Renderer:gridToWorldCoords(gridX, gridY, originX, originY)
    originX = originX or 0 -- Default to 0 if not provided
    originY = originY or 0
    -- Place grid (0,0) relative to the player's origin
    local wx = originX + gridX * (CARD_WIDTH + GRID_SPACING)
    local wy = originY + gridY * (CARD_HEIGHT + GRID_SPACING)
    return wx, wy
end

-- Convert screen coordinates (sx, sy) to WORLD coordinates (wx, wy)
function Renderer:screenToWorldCoords(sx, sy, cameraX, cameraY, cameraZoom)
    local wx = (sx / cameraZoom) + cameraX
    local wy = (sy / cameraZoom) + cameraY
    return wx, wy
end

-- Convert WORLD coordinates (wx, wy) to network grid coordinates (gridX, gridY)
function Renderer:worldToGridCoords(wx, wy, originX, originY)
    originX = originX or 0 -- Default to 0 if not provided
    originY = originY or 0
    -- Corrected calculation relative to origin
    local cellWidth = CARD_WIDTH + GRID_SPACING
    local cellHeight = CARD_HEIGHT + GRID_SPACING
    -- Check for division by zero, although unlikely with positive cell dimensions
    if cellWidth == 0 or cellHeight == 0 then return 0, 0 end
    local gridX = math.floor((wx - originX) / cellWidth)
    local gridY = math.floor((wy - originY) / cellHeight)
    return gridX, gridY
end

-- Helper function to get slot position and implicit type based on GDD 4.3 (Corrected)
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
    if slotIndex == Card.Slots.RIGHT_TOP then return { CARD_WIDTH, quartH, Card.Type.KNOWLEDGE, false } end
    if slotIndex == Card.Slots.RIGHT_BOTTOM then return { CARD_WIDTH, halfH + quartH, Card.Type.RESOURCE, true } end
    return nil
end

-- Helper function to find the specific card slot index closest to world coordinates
-- Returns: gridX, gridY, card, slotIndex OR nil, nil, nil, nil
function Renderer:getSlotAtWorldPos(network, wx, wy, originX, originY)
    originX = originX or 0
    originY = originY or 0
    local tolerance = self.SLOT_RADIUS * 3.5
    local toleranceSq = tolerance * tolerance -- Use squared distance

    -- Find the primary grid cell under the click
    local clickGridX, clickGridY = self:worldToGridCoords(wx, wy, originX, originY)

    -- Define candidate grid cells to check (primary + orthogonal neighbors)
    local candidateCells = {
        {clickGridX, clickGridY},
        {clickGridX + 1, clickGridY},
        {clickGridX - 1, clickGridY},
        {clickGridX, clickGridY + 1},
        {clickGridX, clickGridY - 1}
    }

    local closestMatch = {
        distanceSq = toleranceSq,
        card = nil,
        gridX = nil,
        gridY = nil,
        slotIndex = nil
    }

    -- Check slots on cards in candidate cells
    for _, cellCoords in ipairs(candidateCells) do
        local gridX, gridY = cellCoords[1], cellCoords[2]
        local card = network:getCardAt(gridX, gridY)

        if card then
            local cardWX, cardWY = self:gridToWorldCoords(gridX, gridY, originX, originY)

            for slotIndex = 1, 8 do
                local slotInfo = getSlotInfo(slotIndex)
                if slotInfo then
                    local slotType = slotInfo[3]
                    local isOutput = slotInfo[4]
                    local r = self.SLOT_RADIUS

                    -- Calculate the anchor point on the card edge
                    local anchorWX = cardWX + slotInfo[1]
                    local anchorWY = cardWY + slotInfo[2]

                    -- Calculate the visual center of the slot graphic
                    local centerWX, centerWY = anchorWX, anchorWY
                    if isOutput then
                        if slotIndex == Card.Slots.TOP_LEFT or slotIndex == Card.Slots.TOP_RIGHT then centerWY = anchorWY - r / 2
                        elseif slotIndex == Card.Slots.BOTTOM_LEFT or slotIndex == Card.Slots.BOTTOM_RIGHT then centerWY = anchorWY + r / 2
                        elseif slotIndex == Card.Slots.LEFT_TOP or slotIndex == Card.Slots.LEFT_BOTTOM then centerWX = anchorWX - r / 2
                        elseif slotIndex == Card.Slots.RIGHT_TOP or slotIndex == Card.Slots.RIGHT_BOTTOM then centerWX = anchorWX + r / 2
                        end
                    end

                    -- Check distance from click to the calculated center
                    local distSq = (wx - centerWX)^2 + (wy - centerWY)^2

                    if distSq < closestMatch.distanceSq then
                        -- Update closest match found so far
                        closestMatch.distanceSq = distSq
                        closestMatch.card = card
                        closestMatch.gridX = gridX
                        closestMatch.gridY = gridY
                        closestMatch.slotIndex = slotIndex
                    end
                end
            end
        end
    end

    -- Return the details of the closest match if one was found within tolerance
    if closestMatch.card then
        return closestMatch.gridX, closestMatch.gridY, closestMatch.card, closestMatch.slotIndex
    else
        return nil, nil, nil, nil -- No slot found close enough in any candidate cell
    end
end

-- Helper function to draw the 8 connection slots for a card
function Renderer:drawCardSlots(card, sx, sy, alphaOverride, activeLinks)
    alphaOverride = alphaOverride or 1.0 -- Default to opaque
    activeLinks = activeLinks or {} -- Ensure it's a table
    if not card then return end

    -- Create a lookup map for faster link detail retrieval
    local linkMap = {}
    for _, link in ipairs(activeLinks) do
        linkMap[link.linkId] = link
    end

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    local r = self.SLOT_RADIUS -- Use instance variable

    for slotIndex = 1, 8 do
        local info = getSlotInfo(slotIndex)
        if info then
            local slotX = sx + info[1]
            local slotY = sy + info[2]
            local isOutput = info[4]
            local isDefinedOpen = card:isSlotDefinedOpen(slotIndex)
            local occupyingLinkId = card:getOccupyingLinkId(slotIndex)
            local isOccupied = occupyingLinkId ~= nil

            -- Calculate the visual center needed for positioning the tab
            local centerWX, centerWY = slotX, slotY
            local orientation
            if slotIndex == Card.Slots.TOP_LEFT or slotIndex == Card.Slots.TOP_RIGHT then orientation = "top"
            elseif slotIndex == Card.Slots.BOTTOM_LEFT or slotIndex == Card.Slots.BOTTOM_RIGHT then orientation = "bottom"
            elseif slotIndex == Card.Slots.LEFT_TOP or slotIndex == Card.Slots.LEFT_BOTTOM then orientation = "left"
            elseif slotIndex == Card.Slots.RIGHT_TOP or slotIndex == Card.Slots.RIGHT_BOTTOM then orientation = "right"
            end

            -- Draw original slot shape underneath first (slightly dimmed/transparent)
            self:_drawSingleSlotShape(slotIndex, slotX, slotY, r, alphaOverride * 0.4)

            if isOccupied then
                -- 1. Draw original shape underneath (dimmed)
                self:_drawSingleSlotShape(slotIndex, slotX, slotY, r, alphaOverride * 0.4)

                -- 2. Draw the larger tab centered on the visual center
                local linkDetails = linkMap[occupyingLinkId]
                local playerNumber = linkDetails and linkDetails.initiatingPlayerIndex or "?"

                -- Draw a square tab positioned next to the slot center
                local tabSize = r * 3.5 -- Size of the square tab
                local tabX, tabY
                local fixedOffset = r * 1.0 -- Moderate offset outwards

                -- Position tab based on slot ANCHOR (slotX, slotY) and orientation
                if orientation == "top" then
                    tabX = slotX - tabSize / 2
                    tabY = slotY - fixedOffset - tabSize
                elseif orientation == "bottom" then
                    tabX = slotX - tabSize / 2
                    tabY = slotY + fixedOffset
                elseif orientation == "left" then
                    tabX = slotX - fixedOffset - tabSize
                    tabY = slotY - tabSize / 2
                elseif orientation == "right" then
                    tabX = slotX + fixedOffset
                    tabY = slotY - tabSize / 2
                else -- Fallback
                    local centerWX, centerWY = slotX, slotY
                    if isOutput then
                       if slotIndex == Card.Slots.TOP_LEFT or slotIndex == Card.Slots.TOP_RIGHT then centerWY = slotY - r / 2
                       elseif slotIndex == Card.Slots.BOTTOM_LEFT or slotIndex == Card.Slots.BOTTOM_RIGHT then centerWY = slotY + r / 2
                       elseif slotIndex == Card.Slots.LEFT_TOP or slotIndex == Card.Slots.LEFT_BOTTOM then centerWX = slotX - r / 2
                       elseif slotIndex == Card.Slots.RIGHT_TOP or slotIndex == Card.Slots.RIGHT_BOTTOM then centerWX = slotX + r / 2
                       end
                    end
                    tabX = centerWX - tabSize / 2
                    tabY = centerWY - tabSize / 2
                end

                -- Draw tab square (Restore appearance)
                love.graphics.setColor(0.9, 0.9, 0.9, alphaOverride * 0.7) -- Light gray, transparent
                love.graphics.rectangle("fill", tabX, tabY, tabSize, tabSize)
                love.graphics.setColor(0, 0, 0, alphaOverride) -- Black border
                love.graphics.rectangle("line", tabX, tabY, tabSize, tabSize)

                -- Draw player number on tab (Use manually scaled print)
                local tabFont = self.fonts.worldSmall or originalFont
                love.graphics.setFont(tabFont)
                love.graphics.setColor(0, 0, 0, alphaOverride)
                local text = tostring(playerNumber)
                local textScale = 0.45 / self.worldFontMultiplier -- Use worldSmall multiplier

                -- Calculate text dimensions at font's native size
                local nativeTextW = tabFont:getWidth(text)
                local nativeTextH = tabFont:getHeight()

                -- Calculate position to center the text *after* scaling
                local scaledTextW = nativeTextW * textScale
                local scaledTextH = nativeTextH * textScale
                local textDrawX = tabX + (tabSize - scaledTextW) / 2
                local textDrawY = tabY + (tabSize - scaledTextH) / 2

                -- Apply scaling and print
                love.graphics.push()
                love.graphics.translate(textDrawX, textDrawY)
                love.graphics.scale(textScale, textScale)
                love.graphics.print(text, 0, 0)
                love.graphics.pop()

            elseif isDefinedOpen then
                -- Draw normal open slot using the helper
                 self:_drawSingleSlotShape(slotIndex, slotX, slotY, r, alphaOverride)

            else -- Closed slot
                -- Draw closed slot indicator (small gray circle)
                local closedColor = CLOSED_SLOT_COLOR
                love.graphics.setColor(closedColor[1], closedColor[2], closedColor[3], (closedColor[4] or 1) * alphaOverride)
                love.graphics.circle("fill", slotX, slotY, r * 0.8)
                local borderColor = SLOT_BORDER_COLOR
                love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], (borderColor[4] or 1) * alphaOverride)
                love.graphics.circle("line", slotX, slotY, r * 0.8)
            end
        end
    end
    -- Restore font/color
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

-- Internal helper to draw the shape for a single slot
function Renderer:_drawSingleSlotShape(slotIndex, slotX, slotY, radius, alpha)
    local info = getSlotInfo(slotIndex)
    if not info then return end

    local slotType = info[3]
    local isOutput = info[4]
    local r = radius -- Use passed radius

    -- Determine orientation
    local orientation
    if slotIndex == Card.Slots.TOP_LEFT or slotIndex == Card.Slots.TOP_RIGHT then orientation = "top"
    elseif slotIndex == Card.Slots.BOTTOM_LEFT or slotIndex == Card.Slots.BOTTOM_RIGHT then orientation = "bottom"
    elseif slotIndex == Card.Slots.LEFT_TOP or slotIndex == Card.Slots.LEFT_BOTTOM then orientation = "left"
    elseif slotIndex == Card.Slots.RIGHT_TOP or slotIndex == Card.Slots.RIGHT_BOTTOM then orientation = "right"
    end

    -- Apply alpha override to slot color
    local baseColor = SLOT_COLORS[slotType] or {1,1,1,1}
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], (baseColor[4] or 1) * alpha)

    local vertices
    if isOutput then -- Draw rectangle
        if orientation == "top" then vertices = { slotX-r, slotY-r, slotX+r, slotY-r, slotX+r, slotY, slotX-r, slotY }
        elseif orientation == "bottom" then vertices = { slotX-r, slotY, slotX+r, slotY, slotX+r, slotY+r, slotX-r, slotY+r }
        elseif orientation == "left" then vertices = { slotX-r, slotY-r, slotX, slotY-r, slotX, slotY+r, slotX-r, slotY+r }
        elseif orientation == "right" then vertices = { slotX, slotY-r, slotX+r, slotY-r, slotX+r, slotY+r, slotX, slotY+r }
        end
    else -- Draw triangle (input)
        if orientation == "top" then vertices = { slotX-r, slotY-r, slotX+r, slotY-r, slotX, slotY+r } -- Points down
        elseif orientation == "bottom" then vertices = { slotX-r, slotY+r, slotX+r, slotY+r, slotX, slotY-r } -- Points up
        elseif orientation == "left" then vertices = { slotX-r, slotY-r, slotX-r, slotY+r, slotX+r, slotY } -- Points right
        elseif orientation == "right" then vertices = { slotX+r, slotY-r, slotX+r, slotY+r, slotX-r, slotY } -- Points left
        end
    end

    if vertices then
        love.graphics.polygon("fill", vertices)
        -- Apply alpha override to border color
        local borderColor = SLOT_BORDER_COLOR
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], (borderColor[4] or 1) * alpha)
        love.graphics.polygon("line", vertices)
    else
        -- Fallback or error handling
        love.graphics.circle("fill", slotX, slotY, r)
        local borderColor = SLOT_BORDER_COLOR
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], (borderColor[4] or 1) * alpha)
        love.graphics.circle("line", slotX, slotY, r)
    end
end

-- Internal core function to draw a card's elements based on context
function Renderer:_drawCardInternal(card, x, y, context)
    if not card or type(card) ~= 'table' then
        print("Warning: _drawCardInternal received invalid card data.")
        return
    end

    local originalColor = {love.graphics.getColor()}
    local alphaOverride = context.alpha or 1.0
    local useInvalidBorder = context.borderType == "invalid"

    -- Base background (Apply Alpha)
    local baseR, baseG, baseB = 0.8, 0.8, 0.8
    if card.type == Card.Type.REACTOR then baseR, baseG, baseB = 1, 1, 0.5 end
    love.graphics.setColor(baseR, baseG, baseB, 1.0 * alphaOverride)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)

    -- Define Layout Areas (Constants are shared)
    local margin = 5
    local headerH = 20
    local costAreaW = 17 -- Keep the adjusted width
    local iconSize = 15  -- Header type icon size
    local effectsH = 45
    local imageY = y + headerH + margin
    local imageH = CARD_HEIGHT - headerH - effectsH - (2 * margin)
    local effectsY = y + CARD_HEIGHT - effectsH - margin

    -- 1. Draw Header Area
    local baseTypeColor = SLOT_COLORS[card.type] or {0.5, 0.5, 0.5, 1}
    local headerIconX = x + margin
    local headerIconY = y + margin
    love.graphics.setColor(baseTypeColor[1], baseTypeColor[2], baseTypeColor[3], (baseTypeColor[4] or 1) * alphaOverride)
    love.graphics.rectangle("fill", headerIconX, headerIconY, iconSize, iconSize)
    love.graphics.setColor(0,0,0, 1.0 * alphaOverride) -- Black border with alpha
    love.graphics.rectangle("line", headerIconX, headerIconY, iconSize, iconSize)

    -- Draw Card Type Icon on top
    local typeIcon = self.icons[card.type]
    if typeIcon then
        local typeIconScaleFactor = 0.8 -- Draw icon at 80% of the square size
        local targetDrawSize = iconSize * typeIconScaleFactor
        local iconDrawScale = targetDrawSize / typeIcon:getWidth() -- Scale needed for love.graphics.draw
        local offset = (iconSize - targetDrawSize) / 2 -- Offset to center the smaller icon
        local drawX = headerIconX + offset
        local drawY = headerIconY + offset

        love.graphics.setColor(1, 1, 1, alphaOverride) -- White with alpha (using black icon variants now)
        love.graphics.draw(typeIcon, drawX, drawY, 0, iconDrawScale, iconDrawScale)
    end

    -- Restore color before calling text helper (it handles alpha)
    love.graphics.setColor(originalColor)
    -- Card Title (Use Helper - passing alpha and context)
    local titleX = x + margin + iconSize + margin - 2
    local titleY = y + margin - 1
    local titleLimit = CARD_WIDTH - (2*margin + iconSize + costAreaW)
    local titleStyle = context.stylePrefix .. "_TITLE_NW"
    self:_drawTextScaled(card.title or "Untitled", titleX, titleY, titleLimit, "left", titleStyle, context.baseFontSizes.title, context.targetScales.title, alphaOverride)

    -- Restore color before drawing cost icons/text
    love.graphics.setColor(originalColor)
    -- Build Cost (Using Icons and context - Right Aligned)
    local costYBase = y + margin - 1 -- Include vertical adjustment
    local costIconSize = CARD_COST_ICON_SIZE -- Use the constant
    local costInnerSpacing = 2 -- Pixels between icon and text
    local costLineHeight = 12

    -- Define the target right edge for alignment
    local artworkRightEdge = x + CARD_WIDTH - margin

    local matCost = card.buildCost and card.buildCost.material or 0
    local dataCost = card.buildCost and card.buildCost.data or 0

    local matIcon = self.icons.material
    local dataIcon = self.icons.data

    local costBaseFontSize = context.baseFontSizes.cost
    local targetScale_cost = context.targetScales.cost
    local costStyleName = context.stylePrefix .. "_COST"
    local costFont = self.fonts[self.styleGuide[costStyleName].fontName] or love.graphics.getFont()
    -- Determine font multiplier for width calculation
    local costFontMultiplier = 1
    if string.find(self.styleGuide[costStyleName].fontName, "world") then
        costFontMultiplier = self.worldFontMultiplier
    elseif string.find(self.styleGuide[costStyleName].fontName, "preview") then
        costFontMultiplier = self.uiFontMultiplier
    end

    -- Draw Material Cost (Right-aligned)
    if matIcon then
        local text = tostring(matCost)
        local textWidth = costFont:getWidth(text) / costFontMultiplier * targetScale_cost
        local totalWidth = costIconSize + costInnerSpacing + textWidth
        local overallStartX = artworkRightEdge - totalWidth
        local iconX = overallStartX
        local textX = iconX + costIconSize + costInnerSpacing

        local iconScale = costIconSize / matIcon:getWidth()
        love.graphics.setColor(1, 1, 1, alphaOverride) -- White, with alpha
        love.graphics.draw(matIcon, iconX, costYBase, 0, iconScale, iconScale)
        love.graphics.setColor(originalColor) -- Restore before text
        self:_drawTextScaled(text, textX, costYBase, CARD_WIDTH, "left", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    else -- Fallback: Simple text near right margin
        love.graphics.setColor(originalColor)
        self:_drawTextScaled(string.format("M:%d", matCost), x + margin, costYBase, CARD_WIDTH - 2*margin, "right", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    end

    -- Draw Data Cost (Right-aligned)
    local dataY = costYBase + costLineHeight - 2 -- Include vertical adjustment
    if dataIcon then
        local text = tostring(dataCost)
        local textWidth = costFont:getWidth(text) / costFontMultiplier * targetScale_cost
        local totalWidth = costIconSize + costInnerSpacing + textWidth
        local overallStartX = artworkRightEdge - totalWidth
        local iconX = overallStartX
        local textX = iconX + costIconSize + costInnerSpacing

        local iconScale = costIconSize / dataIcon:getWidth()
        love.graphics.setColor(1, 1, 1, alphaOverride) -- White, with alpha
        love.graphics.draw(dataIcon, iconX, dataY, 0, iconScale, iconScale)
        love.graphics.setColor(originalColor) -- Restore before text
        self:_drawTextScaled(text, textX, dataY, CARD_WIDTH, "left", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    else -- Fallback: Simple text near right margin
        love.graphics.setColor(originalColor)
        self:_drawTextScaled(string.format("D:%d", dataCost), x + margin, dataY, CARD_WIDTH - 2*margin, "right", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    end

    -- 2. Draw Image Placeholder Area OR Card Art
    local image = self:_loadImage(card.imagePath)
    if image then
        local areaW = CARD_WIDTH - (2 * margin)
        local areaH = imageH
        local imgW, imgH = image:getDimensions()
        local scaleX = areaW / imgW
        local scaleY = areaH / imgH
        local scale = math.min(scaleX, scaleY)
        local drawW = imgW * scale
        local drawH = imgH * scale
        local drawX = x + margin + (areaW - drawW) / 2
        local drawY = imageY + (areaH - drawH) / 2
        love.graphics.setColor(1, 1, 1, 1.0 * alphaOverride)
        love.graphics.draw(image, drawX, drawY, 0, scale, scale)
        love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride)
        love.graphics.rectangle("line", x + margin, imageY, areaW, areaH)
    else
        love.graphics.setColor(0.6, 0.6, 0.6, 1.0 * alphaOverride)
        love.graphics.rectangle("fill", x + margin, imageY, CARD_WIDTH - (2 * margin), imageH)
        love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride)
        love.graphics.rectangle("line", x + margin, imageY, CARD_WIDTH - (2 * margin), imageH)
        local artLimit = CARD_WIDTH - (2 * margin)
        local artStyleName = context.stylePrefix .. "_ART_LABEL"
        love.graphics.setColor(originalColor)
        self:_drawTextScaled("ART", x + CARD_WIDTH/2, imageY + imageH/2, artLimit, "center", artStyleName, context.baseFontSizes.artLabel, context.targetScales.artLabel, alphaOverride)
    end

    -- 3. Draw Effects Box Area (Apply alpha)
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0 * alphaOverride)
    love.graphics.rectangle("fill", x + margin, effectsY, CARD_WIDTH - (2 * margin), effectsH)
    love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride) -- Border with alpha
    love.graphics.rectangle("line", x + margin, effectsY, CARD_WIDTH - (2 * margin), effectsH)
    -- Effects Text (Use Helper - passing alpha and context)
    local effectBaseFontSize = context.baseFontSizes.effect
    local activationText = "Activation: " .. (card:getActivationDescription() or "No effect")
    local convergenceText = "Convergence: " .. (card:getConvergenceDescription() or "No effect")
    -- Removed VP text from here, maybe draw elsewhere or add to context?
    local effectsLimit = (CARD_WIDTH - (2 * margin) - 4)
    local effectsTextYBase = effectsY + 2
    local effectStyleName = context.stylePrefix .. "_EFFECT"
    local targetScale_effect = context.targetScales.effect
    -- Calculate line height based on context (font style + target scale)
    local effectFont = self.fonts[self.styleGuide[effectStyleName].fontName] or love.graphics.getFont()
    local fontMultiplier = 1 -- Placeholder, need to determine based on fontName
    if string.find(self.styleGuide[effectStyleName].fontName, "world") then
        fontMultiplier = self.worldFontMultiplier
    elseif string.find(self.styleGuide[effectStyleName].fontName, "preview") then
        fontMultiplier = self.uiFontMultiplier
    end
    local effectLineHeight = effectFont:getHeight() / fontMultiplier * targetScale_effect

    -- Restore color before calling text helper
    love.graphics.setColor(originalColor)
    self:_drawTextScaled(activationText, x + margin + 2, effectsTextYBase, effectsLimit, "left", effectStyleName, effectBaseFontSize, targetScale_effect, alphaOverride)
    self:_drawTextScaled(convergenceText, x + margin + 2, effectsTextYBase + effectLineHeight * 3, effectsLimit, "left", effectStyleName, effectBaseFontSize, targetScale_effect, alphaOverride) -- Increased multiplier from 1.1

    -- Draw Outer Border (Apply alpha and conditional color)
    if useInvalidBorder then
        love.graphics.setColor(1, 0, 0, 1.0 * alphaOverride) -- Red border for invalid placement
    else
        love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride) -- Default black border
    end
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)

    -- Restore color before drawing slots (they handle alpha internally)
    love.graphics.setColor(originalColor)
    -- Draw Connection Slots (call as method on renderer, passing coordinates, alpha, and activeLinks)
    self:drawCardSlots(card, x, y, alphaOverride, context.activeLinks)
end

-- Internal utility function to draw a single card in the world
function Renderer:_drawSingleCardInWorld(card, wx, wy, activeLinks, alphaOverride, useInvalidBorder)
    -- Default alpha and border type
    alphaOverride = alphaOverride or 1.0
    useInvalidBorder = useInvalidBorder or false

    -- Prepare context for world rendering
    local context = {
        stylePrefix = "CARD",
        baseFontSizes = {
            title = self.baseTitleFontSize,
            cost = self.baseSmallFontSize,
            effect = self.baseSmallFontSize,
            artLabel = self.baseStandardFontSize
        },
        targetScales = {
            title = 0.4375, -- 7px effective size (7/16)
            cost = 0.4,     -- 8pt effective size (~12 * 1/3 -> base 16 * 0.4 = 6.4px)
            effect = 0.4,   -- 8pt effective size
            artLabel = 0.416666667 -- 10pt effective size
        },
        alpha = alphaOverride,
        borderType = useInvalidBorder and "invalid" or "normal",
        activeLinks = activeLinks -- Pass links through
    }

    -- Call the core drawing function
    self:_drawCardInternal(card, wx, wy, context)
end

-- Draw a player's network grid, applying camera transform
function Renderer:drawNetwork(network, cameraX, cameraY, cameraZoom, originX, originY, activeLinks)
    if not network then return end
    originX = originX or 0 -- Default origin if not provided
    originY = originY or 0

    love.graphics.push() -- Save current transform state
    love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
    love.graphics.scale(cameraZoom, cameraZoom)
    love.graphics.setLineWidth(1 / cameraZoom)

    -- Store original font/color to restore later if needed
    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}

    -- Build a queue of items to draw
    local drawQueue = {}
    for cardId, card in pairs(network.cards) do
        -- Process only if card is a valid table with a position
        if type(card) == "table" and card.position then
            local wx, wy = self:gridToWorldCoords(card.position.x, card.position.y, originX, originY) -- Pass origin
            -- Add to queue instead of drawing immediately
            table.insert(drawQueue, { card = card, wx = wx, wy = wy })
        else
            -- Skip non-tables or cards without position
            if type(card) ~= "table" then
                -- print(string.format("Warning in drawNetwork: Skipping non-table value...")) -- REMOVE DEBUG
            end
        end
        -- No goto needed now
    end

    -- Process the draw queue
    for _, item in ipairs(drawQueue) do
        -- Call as utility function, passing self
        -- _drawSingleCardInWorld(self, item.card, item.wx, item.wy)
        -- Call as method, passing activeLinks
        self:_drawSingleCardInWorld(item.card, item.wx, item.wy, activeLinks)
    end

    -- Restore original font/color after drawing all cards
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)

    love.graphics.pop() -- Restore previous transform state
end

-- Draw highlight / card preview over the hovered grid cell, or red outline if invalid
function Renderer:drawHoverHighlight(gridX, gridY, cameraX, cameraY, cameraZoom, selectedCard, isPlacementValid, originX, originY)
    -- Default to valid if not provided
    isPlacementValid = isPlacementValid == nil or isPlacementValid == true
    originX = originX or 0 -- Default origin
    originY = originY or 0

    if gridX == nil or gridY == nil then return end

    -- If a card is selected, draw highlight or preview
    if selectedCard then
        local wx, wy = self:gridToWorldCoords(gridX, gridY, originX, originY) -- Use origin
        love.graphics.push()
        love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
        love.graphics.scale(cameraZoom, cameraZoom)
        love.graphics.setLineWidth(1 / cameraZoom) -- Adjust line width based on zoom

        -- Use _drawSingleCardInWorld, passing alpha and validity flag
        local useInvalidBorder = not isPlacementValid
        -- Corrected arguments: Pass nil for activeLinks, then alpha, then border flag
        self:_drawSingleCardInWorld(selectedCard, wx, wy, nil, 0.5, useInvalidBorder)

        -- Restore state (pop restores color, font, line width, transforms)
        love.graphics.pop()
    end
end

-- Function to draw a hand card preview (uses UI scale fonts and applies preview scale)
function Renderer:drawHoveredHandCard(card, sx, sy, scale)
    if not card then return end
    scale = scale or 1.0

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    local originalLineWidth = love.graphics.getLineWidth()

    love.graphics.push()
    love.graphics.translate(sx, sy)
    love.graphics.scale(scale, scale)
    love.graphics.setLineWidth(originalLineWidth / scale)

    -- Prepare context for preview rendering
    local context = {
        stylePrefix = "PREVIEW",
        baseFontSizes = {
            title = self.uiBaseStandardSize, -- 7pt base
            cost = self.uiBaseSmallSize,     -- 6pt base
            effect = self.uiBaseSmallSize,   -- 6pt base
            artLabel = self.uiBaseStandardSize -- 7pt base
        },
        targetScales = {
            title = 1.0,    -- Effective 7pt * 1.0 = 7px
            cost = 1.0,     -- Effective 6pt * 1.0 = 6px
            effect = 1.0,   -- Effective 6pt * 1.0 = 6px
            artLabel = 1.0  -- Effective 7pt * 1.0 = 7px
        },
        alpha = 1.0, -- Preview is always opaque unless scaled externally
        borderType = "normal"
    }

    -- Call the core drawing function with relative coordinates (0,0)
    self:_drawCardInternal(card, 0, 0, context)

    love.graphics.pop()

    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth)
end

-- Draw a player's hand, visually indicating the selected card
-- Returns a table of bounding boxes for click detection: { { index=i, x=sx, y=sy, w=w, h=h }, ... }
function Renderer:drawHand(player, selectedIndex)
    if not player or not player.hand then return {} end

    -- Calculate Y position to be above the bottom button area
    local handStartY = love.graphics.getHeight() - BOTTOM_BUTTON_AREA_HEIGHT - HAND_CARD_HEIGHT
    local handBounds = {}

    -- Store the font/color/line width that was active before this function
    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    local originalLineWidth = love.graphics.getLineWidth()

    -- Hand Label (Use StyleGuide)
    local labelStyle = self.styleGuide.UI_HAND_LABEL
    assert(self.fonts[labelStyle.fontName], "Hand label font not found: " .. labelStyle.fontName)
    love.graphics.setFont(self.fonts[labelStyle.fontName])
    love.graphics.setColor(labelStyle.color)
    love.graphics.print(string.format("%s Hand (%d):", player.name, #player.hand), HAND_START_X, handStartY - 20)

    -- Draw cards (Assume button-like style for now? Or needs CARD_HAND style?)
    -- Let's reuse UI_HAND_LABEL style for the title text on hand cards
    local cardTitleStyle = self.styleGuide.UI_HAND_LABEL
    love.graphics.setFont(self.fonts[cardTitleStyle.fontName]) -- Font is likely already set, but be explicit

    -- Draw non-selected cards
    for i, card in ipairs(player.hand) do
        if i ~= selectedIndex then
            local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
            local sy = handStartY
            -- Store bounds for click detection
            table.insert(handBounds, { index = i, x = sx, y = sy, w = HAND_CARD_WIDTH, h = HAND_CARD_HEIGHT })
            love.graphics.setColor(0.8, 0.8, 1, 1)
            love.graphics.rectangle("fill", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("line", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            -- Set color for title text
            love.graphics.setColor(cardTitleStyle.color)
            love.graphics.printf(card.title, sx + 3, sy + 3, HAND_CARD_WIDTH - 6, "left")
        end
    end

    -- Draw selected card
    if selectedIndex then
        local card = player.hand[selectedIndex]
        if card then
            local i = selectedIndex
            local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
            local sy = handStartY - SELECTED_CARD_RAISE -- Raise selected card
            -- Update bounds y pos
            local boundsFound = false
            for k, b in ipairs(handBounds) do
                if b.index == i then
                    b.y = handStartY
                    boundsFound = true
                    break
                end
            end
            if not boundsFound then
                table.insert(handBounds, { index = i, x = sx, y = handStartY, w = HAND_CARD_WIDTH, h = HAND_CARD_HEIGHT })
            end

            -- Draw placeholder card rectangle (highlighted)
            love.graphics.setColor(1, 1, 0.8, 1)
            love.graphics.rectangle("fill", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setLineWidth(3) -- Thicker border
            love.graphics.rectangle("line", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            -- Set color for title text
            love.graphics.setColor(cardTitleStyle.color)
            love.graphics.printf(card.title, sx + 3, sy + 3, HAND_CARD_WIDTH - 6, "left")
        end
    end

    -- Restore original state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth) -- Restore original line width

    return handBounds
end

-- Drawing UI elements (resources, VP, turn info)
function Renderer:drawUI(player, hoveredLinkType, currentPhase, convergenceSelectionState)
    if not player then return end

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    local originalLineWidth = love.graphics.getLineWidth() -- Store original line width

    -- Use UI Label Style
    local style = self.styleGuide.UI_LABEL
    local font = self.fonts[style.fontName]
    if not font then
        print("Warning: UI Label font not found: " .. style.fontName .. ". Using default.")
        font = love.graphics.getFont()
    end
    -- Convert style color from bytes (0-255) to 0-1 range
    local r = style.color[1] or 0 -- Use value directly
    local g = style.color[2] or 0 -- Use value directly
    local b = style.color[3] or 0 -- Use value directly
    local a = style.color[4] or 1 -- Use value directly, default alpha to 1 (opaque)

    love.graphics.setFont(font)
    love.graphics.setColor(r, g, b, a)

    -- Print UI text
    local uiX = 10
    local uiY_start = 30
    local lineSpacing = 21
    love.graphics.print(string.format("--- %s UI ---", player.name), uiX, uiY_start)
    love.graphics.print(string.format("VP: %d", player.vp), uiX, uiY_start + lineSpacing)

    -- Draw Resources with Icons
    local resY = uiY_start + 2 * lineSpacing
    local iconSize = UI_ICON_SIZE
    local iconSpacing = 5 -- Space between icon and number
    local resGroupSpacing = 25 -- Space between resource groups (icon + number)

    local currentX = uiX

    -- Energy
    local energyIcon = self.icons.energy
    if energyIcon then
        local scale = iconSize / energyIcon:getWidth() -- Assume square icon for simplicity
        love.graphics.setColor(1, 1, 1, 1) -- Set color to white for icon drawing
        love.graphics.draw(energyIcon, currentX, resY, 0, scale, scale)
        love.graphics.setColor(r, g, b, a) -- Restore text color
        local energyText = tostring(player.resources.energy)
        love.graphics.print(energyText, currentX + iconSize + iconSpacing, resY)
        currentX = currentX + iconSize + iconSpacing + font:getWidth(energyText) + resGroupSpacing
    else -- Fallback
        local energyText = string.format("E:%d", player.resources.energy)
        love.graphics.print(energyText, currentX, resY)
        currentX = currentX + font:getWidth(energyText) + resGroupSpacing
    end

    -- Data
    local dataIcon = self.icons.data
    if dataIcon then
        local scale = iconSize / dataIcon:getWidth()
        love.graphics.setColor(1, 1, 1, 1) -- White for icon
        love.graphics.draw(dataIcon, currentX, resY, 0, scale, scale)
        love.graphics.setColor(r, g, b, a) -- Restore text color
        local dataText = tostring(player.resources.data)
        love.graphics.print(dataText, currentX + iconSize + iconSpacing, resY)
        currentX = currentX + iconSize + iconSpacing + font:getWidth(dataText) + resGroupSpacing
    else -- Fallback
        local dataText = string.format("D:%d", player.resources.data)
        love.graphics.print(dataText, currentX, resY)
        currentX = currentX + font:getWidth(dataText) + resGroupSpacing
    end

    -- Material
    local materialIcon = self.icons.material
    if materialIcon then
        local scale = iconSize / materialIcon:getWidth()
        love.graphics.setColor(1, 1, 1, 1) -- White for icon
        love.graphics.draw(materialIcon, currentX, resY, 0, scale, scale)
        love.graphics.setColor(r, g, b, a) -- Restore text color
        local materialText = tostring(player.resources.material)
        love.graphics.print(materialText, currentX + iconSize + iconSpacing, resY)
        currentX = currentX + font:getWidth(materialText) + resGroupSpacing
    else -- Fallback
        local materialText = string.format("M:%d", player.resources.material)
        love.graphics.print(materialText, currentX, resY)
        currentX = currentX + font:getWidth(materialText) + resGroupSpacing
    end

    -- Draw Available Convergence Link Sets
    local linkY = resY + lineSpacing -- Draw below resources
    local linkStartX = uiX
    local linkIconSize = UI_ICON_SIZE * 0.8 -- Slightly smaller than resource icons
    local linkIconSpacing = 3
    local linkGroupSpacing = 5
    local linkTextStyle = self.styleGuide.UI_LABEL -- Use standard UI label style
    local linkFont = self.fonts[linkTextStyle.fontName] or font -- Fallback to standard UI font
    love.graphics.setFont(linkFont)
    love.graphics.setColor(linkTextStyle.color)
    love.graphics.print("Links:", linkStartX, linkY)
    currentX = linkStartX + linkFont:getWidth("Links:") + linkGroupSpacing

    local linkTypes = { Card.Type.TECHNOLOGY, Card.Type.CULTURE, Card.Type.RESOURCE, Card.Type.KNOWLEDGE }
    for _, linkType in ipairs(linkTypes) do
        local isAvailable = player:hasLinkSetAvailable(linkType)
        local isHovered = (hoveredLinkType == linkType)
        local icon = self.icons[linkType] -- Get the icon for the link type
        local bgColor = SLOT_COLORS[linkType] or {0.5, 0.5, 0.5, 1} -- Fallback gray
        local boxSize = linkIconSize + 4 -- Background box slightly larger than icon
        local boxX = currentX
        local boxY = linkY - 2 -- Adjust vertical position slightly for centering

        -- Draw background square, dimmed if not available
        if isAvailable then
            love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
        else
            love.graphics.setColor(bgColor[1] * 0.5, bgColor[2] * 0.5, bgColor[3] * 0.5, (bgColor[4] or 1) * 0.7)
        end
        love.graphics.rectangle("fill", boxX, boxY, boxSize, boxSize)

        -- Draw white border if hovered, available, and in Converge phase and not already selecting
        if isHovered and isAvailable and currentPhase == "Converge" and convergenceSelectionState == nil then
            local currentLineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(2) -- Make border noticeable
            love.graphics.setColor(1, 1, 1, 1) -- White
            love.graphics.rectangle("line", boxX, boxY, boxSize, boxSize)
            love.graphics.setLineWidth(currentLineWidth) -- Reset line width
        end

        -- Draw icon or text on top
        if icon then
            local iconDrawX = boxX + (boxSize - linkIconSize) / 2 -- Center icon in box
            local iconDrawY = boxY + (boxSize - linkIconSize) / 2
            local scale = linkIconSize / icon:getWidth()
            -- Set icon color (white, potentially dimmed if needed, though background dimming is primary)
            if isAvailable then
                love.graphics.setColor(1, 1, 1, 1) -- Full white for icon itself
            else
                love.graphics.setColor(0.8, 0.8, 0.8, 0.8) -- Slightly dimmed white
            end
            love.graphics.draw(icon, iconDrawX, iconDrawY, 0, scale, scale)
            currentX = currentX + boxSize + linkIconSpacing -- Advance by box size + spacing
        else
            -- Fallback: Draw text abbreviation centered in box
            local typeStr = "UNK"
            if linkType == Card.Type.TECHNOLOGY then typeStr = "T" end
            if linkType == Card.Type.CULTURE then typeStr = "C" end
            if linkType == Card.Type.RESOURCE then typeStr = "R" end
            if linkType == Card.Type.KNOWLEDGE then typeStr = "K" end
            -- Set text color (using style, dimmed if needed)
            local txtColor = linkTextStyle.color
            if isAvailable then
                love.graphics.setColor(txtColor[1], txtColor[2], txtColor[3], txtColor[4] or 1)
            else
                love.graphics.setColor(txtColor[1]*0.5, txtColor[2]*0.5, txtColor[3]*0.5, (txtColor[4] or 1)*0.7)
            end
            -- Calculate text position for centering
            local textWidth = linkFont:getWidth(typeStr)
            local textHeight = linkFont:getHeight()
            local textDrawX = boxX + (boxSize - textWidth) / 2
            local textDrawY = boxY + (boxSize - textHeight) / 2
            love.graphics.print(typeStr, textDrawX, textDrawY)
            currentX = currentX + boxSize + linkIconSpacing -- Advance by box size + spacing
        end
         -- Add spacing before next link type
         currentX = currentX + linkGroupSpacing
    end

    -- Restore
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth) -- Restore original line width at the end
end

return Renderer
