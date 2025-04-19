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

    return instance
end

-- Helper function to load and cache images
function Renderer:_loadImage(path)
    if not path then return nil end

    -- Check cache first
    if self.images[path] then
        return self.images[path]
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
function Renderer:_drawTextScaled(text, x, y, limit, align, styleName, baseFontSize, targetScale)
    local style = self.styleGuide[styleName]
    if not style then
        print("Warning: Invalid style name provided to _drawTextScaled: " .. tostring(styleName))
        return
    end

    local font = self.fonts[style.fontName]
    if not font then
        print("Warning: Font not found for style '" .. styleName .. "': " .. style.fontName .. ". Using default.")
        font = love.graphics.getFont()
        -- Cannot determine multiplier or base size, so draw without scaling
        love.graphics.setFont(font)
        love.graphics.setColor(style.color or {0,0,0,1})
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

    -- Set font and color, then draw
    love.graphics.setFont(font)
    love.graphics.setColor(style.color)
    love.graphics.printf(text, x, y + yOffset, scaledLimit, align, 0, printfScale, printfScale)
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

-- Helper function to draw the 8 connection slots for a card
function Renderer:drawCardSlots(card, sx, sy)
    if not card then return end

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}

    for slotIndex = 1, 8 do
        local info = getSlotInfo(slotIndex)
        if info then
            local slotX = sx + info[1]
            local slotY = sy + info[2]
            local slotType = info[3]
            local isOutput = info[4]
            local isOpen = card:isSlotOpen(slotIndex)

            if isOpen then love.graphics.setColor(SLOT_COLORS[slotType] or {1,1,1,1}) else love.graphics.setColor(CLOSED_SLOT_COLOR) end
            love.graphics.circle("fill", slotX, slotY, SLOT_RADIUS)
            love.graphics.setColor(SLOT_BORDER_COLOR)
            love.graphics.circle("line", slotX, slotY, SLOT_RADIUS)

            if isOpen and not isOutput then
                love.graphics.circle("fill", slotX, slotY, SLOT_RADIUS * 0.3) -- Input marker
            end
        end
    end
    -- Restore font/color just in case slot drawing changes them
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

-- Internal utility function to draw a single card (now a method)
function Renderer:_drawSingleCardInWorld(card, wx, wy)
    -- print(string.format("DEBUG: _drawSingleCardInWorld ENTRY - self type: %s, card type: %s", type(self), type(card)))
    if not card or type(card) ~= 'table' then -- Added type check just in case
        print("Warning: _drawSingleCardInWorld received invalid card data.")
        return
    end
    -- No need to check self validity as it's guaranteed by method call
    -- if not self or type(self) ~= 'table' then
    --      print("Warning: _drawSingleCardInWorld received invalid renderer instance.")
    --     return
    -- end

    -- Base background
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    if card.type == Card.Type.REACTOR then love.graphics.setColor(1, 1, 0.5, 1) end
    love.graphics.rectangle("fill", wx, wy, CARD_WIDTH, CARD_HEIGHT)

    -- Define Layout Areas
    local margin = 5
    local headerH = 20
    local costW = 20
    local iconSize = 15
    local effectsH = 45
    local imageY = wy + headerH + margin
    local imageH = CARD_HEIGHT - headerH - effectsH - (2 * margin)
    local effectsY = wy + CARD_HEIGHT - effectsH - margin
    local targetScale = 1/3

    -- 1. Draw Header Area
    local typeColor = SLOT_COLORS[card.type] or {0.5, 0.5, 0.5, 1}
    love.graphics.setColor(typeColor)
    love.graphics.rectangle("fill", wx + margin, wy + margin, iconSize, iconSize)
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("line", wx + margin, wy + margin, iconSize, iconSize)

    -- Card Title (Use Helper - passing renderer)
    local titleX = wx + margin + iconSize + margin - 2 -- Shift left by 2
    local titleY = wy + margin - 1 -- Reset Y position (consistent up 1)
    local titleLimit = CARD_WIDTH - (2*margin + iconSize + costW)
    -- Remove specific scaling, use a base world scale (to be calculated)
    local targetScale_title = 0.416666667 -- Target effective size 10pt
    self:_drawTextScaled(card.title or "Untitled", titleX, titleY, titleLimit, "left", "CARD_TITLE_NW", self.baseTitleFontSize, targetScale_title)

    -- Build Cost (Use Helper - passing renderer)
    local costX = wx + CARD_WIDTH - costW - margin
    local costYBase = wy + margin - 1
    local costLimit = costW
    local matCost = card.buildCost and card.buildCost.material or 0
    local dataCost = card.buildCost and card.buildCost.data or 0
    local matText = string.format("M: %d", matCost)
    local dataText = string.format("D: %d", dataCost)
    local costBaseFontSize = self.baseSmallFontSize
    local costFont = self.fonts["worldSmall"]
    local costY1 = costYBase
    -- Use fixed pixel offset for consistent spacing
    local costY2 = costY1 + 9
    local targetScale_cost = 0.4 -- Target effective size 8pt
    self:_drawTextScaled(matText, costX, costY1, costLimit, "right", "CARD_COST", costBaseFontSize, targetScale_cost)
    self:_drawTextScaled(dataText, costX, costY2, costLimit, "right", "CARD_COST", costBaseFontSize, targetScale_cost)

    -- 2. Draw Image Placeholder Area OR Card Art
    local image = self:_loadImage(card.imagePath)
    if image then
        -- Calculate scaling to fit image into the area (imageH, CARD_WIDTH - 2*margin)
        local areaW = CARD_WIDTH - (2 * margin)
        local areaH = imageH
        local imgW, imgH = image:getDimensions()
        local scaleX = areaW / imgW
        local scaleY = areaH / imgH
        local scale = math.min(scaleX, scaleY) -- Use 'contain' scaling
        local drawW = imgW * scale
        local drawH = imgH * scale
        -- Center the image within the area
        local drawX = wx + margin + (areaW - drawW) / 2
        local drawY = imageY + (areaH - drawH) / 2

        love.graphics.setColor(1, 1, 1, 1) -- Ensure white color for drawing image
        love.graphics.draw(image, drawX, drawY, 0, scale, scale)

        -- Draw border around the image area
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", wx + margin, imageY, areaW, areaH)
    else
        -- Fallback: Draw placeholder
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.rectangle("fill", wx + margin, imageY, CARD_WIDTH - (2 * margin), imageH)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", wx + margin, imageY, CARD_WIDTH - (2 * margin), imageH)
        -- ART Label (Use Helper - passing renderer)
        local artLimit = CARD_WIDTH - (2 * margin)
        local targetScale_art = 0.416666667 -- Target effective size 10pt
        self:_drawTextScaled("ART", wx + margin, imageY + imageH/2, artLimit, "center", "CARD_ART_LABEL", self.baseStandardFontSize, targetScale_art)
    end

    -- 3. Draw Effects Box Area
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.rectangle("fill", wx + margin, effectsY, CARD_WIDTH - (2 * margin), effectsH)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", wx + margin, effectsY, CARD_WIDTH - (2 * margin), effectsH)
    -- Effects Text (Use Helper - passing renderer)
    local effectBaseFontSize = self.baseSmallFontSize
    local actionText = "Action: " .. (type(card.actionEffect) == 'function' and "[Function]" or (card.actionEffect or "..."))
    local convergenceText = "Conv: " .. (type(card.convergenceEffect) == 'function' and "[Function]" or (card.convergenceEffect or "..."))
    local effectsLimit = (CARD_WIDTH - (2 * margin) - 4)
    local effectsTextYBase = effectsY + 2
    local effectFont = self.fonts["worldSmall"]
    local effectScaledLineHeight = effectFont:getHeight() / self.worldFontMultiplier
    local targetScale_effect = 0.4 -- Target effective size 8pt
    self:_drawTextScaled(actionText, wx + margin + 2, effectsTextYBase, effectsLimit, "left", "CARD_EFFECT", effectBaseFontSize, targetScale_effect)
    self:_drawTextScaled(convergenceText, wx + margin + 2, effectsTextYBase + effectScaledLineHeight * 0.9, effectsLimit, "left", "CARD_EFFECT", effectBaseFontSize, targetScale_effect)

    -- Draw Outer Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", wx, wy, CARD_WIDTH, CARD_HEIGHT)

    -- Draw Connection Slots (call as method on renderer)
    self:drawCardSlots(card, wx, wy)
end

-- Draw a player's network grid, applying camera transform
function Renderer:drawNetwork(network, cameraX, cameraY, cameraZoom)
    if not network then return end

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
        -- print(string.format("DEBUG: drawNetwork loop - Key: %s, Card Type: %s", tostring(cardId), type(card))) -- REMOVE DEBUG
        
        -- Process only if card is a valid table with a position
        if type(card) == "table" and card.position then
            local wx, wy = self:gridToWorldCoords(card.position.x, card.position.y)
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
        -- Call as method
        self:_drawSingleCardInWorld(item.card, item.wx, item.wy)
    end

    -- Restore original font/color after drawing all cards
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)

    love.graphics.pop() -- Restore previous transform state
end

-- Draw highlight / card preview over the hovered grid cell
function Renderer:drawHoverHighlight(gridX, gridY, cameraX, cameraY, cameraZoom, selectedCard)
    if gridX == nil or gridY == nil then return end

    -- If a card is selected, draw it transparently
    if selectedCard then
        local wx, wy = self:gridToWorldCoords(gridX, gridY)
        love.graphics.push()
        love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
        love.graphics.scale(cameraZoom, cameraZoom)
        love.graphics.setLineWidth(1 / cameraZoom)

        local originalFont = love.graphics.getFont()
        local originalColor = {love.graphics.getColor()}

        love.graphics.setColor(1, 1, 1, 0.5) -- Transparency
        -- Call as utility function, passing self
        -- _drawSingleCardInWorld(self, selectedCard, wx, wy)
        -- Call as method
        self:_drawSingleCardInWorld(selectedCard, wx, wy)

        love.graphics.setColor(originalColor)
        love.graphics.setFont(originalFont)
        love.graphics.pop()
    end
    -- No else needed: Do nothing if no card is selected
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

    local cardX, cardY = 0, 0

    -- Base background - Match world card background
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    -- Add reactor check - Match world card reactor check
    if card.type == Card.Type.REACTOR then love.graphics.setColor(1, 1, 0.5, 1) end
    love.graphics.rectangle("fill", cardX, cardY, CARD_WIDTH, CARD_HEIGHT)

    -- Define Layout Areas
    local margin = 5
    local headerH = 20
    local costW = 20
    local iconSize = 15
    local effectsH = 45
    local imageY = cardY + headerH + margin
    local imageH = CARD_HEIGHT - headerH - effectsH - (2 * margin)
    local effectsY = cardY + CARD_HEIGHT - effectsH - margin

    -- 1. Draw Header Area
    local typeColor = SLOT_COLORS[card.type] or {0.5, 0.5, 0.5, 1}
    love.graphics.setColor(typeColor)
    love.graphics.rectangle("fill", cardX + margin, cardY + margin, iconSize, iconSize)
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("line", cardX + margin, cardY + margin, iconSize, iconSize)

    -- Card Title (Use Helper)
    local titleX = cardX + margin + iconSize + margin - 2 -- Shift left by 2
    local titleY = cardY + margin - 2 -- Adjusted Y position (up 2)
    local titleLimit = CARD_WIDTH - (2*margin + iconSize + costW)
    -- Remove specific scaling, use base preview scale (1.0)
    local targetScale_preview_title = 1.0
    self:_drawTextScaled(card.title or "Untitled", titleX, titleY, titleLimit, "left", "PREVIEW_TITLE_NW", self.uiBaseStandardSize, targetScale_preview_title)

    -- Build Cost (Use Helper)
    local costX = cardX + CARD_WIDTH - costW - margin
    local costYBase = cardY + margin - 1 -- Adjusted Y pos like world cost
    local costLimit = costW
    local matCost = card.buildCost and card.buildCost.material or 0
    local dataCost = card.buildCost and card.buildCost.data or 0
    local matText = string.format("M: %d", matCost)
    local dataText = string.format("D: %d", dataCost)
    -- Get base size for line height calculation - Use UI base size and PREVIEW font
    local costBaseFontSize = self.uiBaseSmallSize
    local costFont = self.fonts["previewSmall"] -- Use preview font for correct height calc
    -- local scaledLineHeight = costFont:getHeight() / self.uiFontMultiplier -- Use UI multiplier
    local costY1 = costYBase
    -- Use fixed pixel offset for consistent spacing
    local costY2 = costY1 + 9
    -- Use PREVIEW_COST style and costBaseFontSize (uiBaseSmallSize)
    local targetScale_preview_cost = 1.0 -- Use base UI scale
    self:_drawTextScaled(matText, costX, costY1, costLimit, "right", "PREVIEW_COST", costBaseFontSize, targetScale_preview_cost)
    self:_drawTextScaled(dataText, costX, costY2, costLimit, "right", "PREVIEW_COST", costBaseFontSize, targetScale_preview_cost)

    -- 2. Draw Image Placeholder Area OR Card Art
    local image_preview = self:_loadImage(card.imagePath)
    if image_preview then
         -- Calculate scaling to fit image into the area (imageH, CARD_WIDTH - 2*margin)
        local areaW = CARD_WIDTH - (2 * margin)
        local areaH = imageH
        local imgW, imgH = image_preview:getDimensions()
        local scaleX = areaW / imgW
        local scaleY = areaH / imgH
        local scale = math.min(scaleX, scaleY) -- Use 'contain' scaling
        local drawW = imgW * scale
        local drawH = imgH * scale
        -- Center the image within the area
        local drawX = cardX + margin + (areaW - drawW) / 2
        local drawY = imageY + (areaH - drawH) / 2

        love.graphics.setColor(1, 1, 1, 1) -- Ensure white color for drawing image
        love.graphics.draw(image_preview, drawX, drawY, 0, scale, scale)

        -- Draw border around the image area
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", cardX + margin, imageY, areaW, areaH)
    else
        -- Fallback: Draw placeholder
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.rectangle("fill", cardX + margin, imageY, CARD_WIDTH - (2 * margin), imageH)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", cardX + margin, imageY, CARD_WIDTH - (2 * margin), imageH)
        -- ART Label (Use Helper)
        local artLimit = CARD_WIDTH - (2 * margin)
        local targetScale_art_preview = 1.0 -- Base UI scale
        self:_drawTextScaled("ART", cardX + margin, imageY + imageH/2, artLimit, "center", "PREVIEW_ART_LABEL", self.uiBaseStandardSize, targetScale_art_preview)
    end

    -- 3. Draw Effects Box Area
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.rectangle("fill", cardX + margin, effectsY, CARD_WIDTH - (2 * margin), effectsH)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", cardX + margin, effectsY, CARD_WIDTH - (2 * margin), effectsH)
    -- Effects Text (Use Helper)
    local effectBaseFontSize = self.uiBaseSmallSize
    local actionText = "Action: " .. (type(card.actionEffect) == 'function' and "[Function]" or (card.actionEffect or "..."))
    local convergenceText = "Conv: " .. (type(card.convergenceEffect) == 'function' and "[Function]" or (card.convergenceEffect or "..."))
    local effectsLimit = CARD_WIDTH - (2 * margin) - 4
    local effectsTextYBase = effectsY + 2 -- Start 2px below top of effects box
    -- Use UI base size and PREVIEW font for line height
    local effectFont = self.fonts["previewSmall"]
    -- local effectScaledLineHeight = effectFont:getHeight() / self.uiFontMultiplier
    -- Use PREVIEW_EFFECT style and effectBaseFontSize (uiBaseSmallSize)
    local actionY = effectsTextYBase
    local convY = effectsY + effectsH * 0.5 -- Position near vertical middle
    self:_drawTextScaled(actionText, cardX + margin + 2, actionY, effectsLimit, "left", "PREVIEW_EFFECT", effectBaseFontSize, 1.0)
    self:_drawTextScaled(convergenceText, cardX + margin + 2, convY, effectsLimit, "left", "PREVIEW_EFFECT", effectBaseFontSize, 1.0)

    -- Draw Outer Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", cardX, cardY, CARD_WIDTH, CARD_HEIGHT)

    -- Draw Connection Slots relative to (0,0)
    self:drawCardSlots(card, cardX, cardY)

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

    -- Store the font that was active before this function
    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}

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
            love.graphics.setLineWidth(1) -- Reset line width
            -- Set color for title text
            love.graphics.setColor(cardTitleStyle.color)
            love.graphics.printf(card.title, sx + 3, sy + 3, HAND_CARD_WIDTH - 6, "left")
        end
    end

    -- Restore original font/color
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)

    return handBounds
end

-- Drawing UI elements (resources, VP, turn info)
function Renderer:drawUI(player)
    if not player then return end

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}

    -- Use UI Label Style
    local style = self.styleGuide.UI_LABEL
    assert(self.fonts[style.fontName], "UI Label font not found: " .. style.fontName)
    love.graphics.setFont(self.fonts[style.fontName])
    love.graphics.setColor(style.color)

    -- Print UI text
    love.graphics.print(string.format("--- %s UI ---", player.name), 10, 30)
    love.graphics.print(string.format("VP: %d", player.vp), 10, 50)
    love.graphics.print(string.format("Res: E:%d D:%d M:%d", player.resources.energy, player.resources.data, player.resources.material), 10, 70)

    -- Restore
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

return Renderer
