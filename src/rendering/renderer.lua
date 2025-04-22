-- src/rendering/renderer.lua
-- Handles drawing the game state to the screen.

local Card = require('src.game.card') -- Needed for Card.Ports constants
local StyleGuide = require('src.rendering.styles') -- Load the styles

local Renderer = {}
Renderer.__index = Renderer

-- Constants for rendering (adjust as needed)
local CARD_WIDTH = 100
local CARD_HEIGHT = 140
local GRID_SPACING = 10 -- Space between cards
local NETWORK_OFFSET_X = 400 -- Initial screen X offset for the network drawing area
local NETWORK_OFFSET_Y = 100 -- Initial screen Y offset for the network drawing area
local PORT_RADIUS = 5 -- Size of the port indicator
local HAND_CARD_SCALE = 0.6
local HAND_CARD_WIDTH = CARD_WIDTH * HAND_CARD_SCALE
local HAND_CARD_HEIGHT = CARD_HEIGHT * HAND_CARD_SCALE
local HAND_SPACING = 10
local HAND_START_X = 50
local BOTTOM_BUTTON_AREA_HEIGHT = 60 -- Space reserved for buttons at the bottom
local SELECTED_CARD_RAISE = 15 -- How much to raise the selected card
local UI_ICON_SIZE = 18      -- Size for UI resource icons
local CARD_COST_ICON_SIZE = 9 -- Size for card cost icons

-- Port Type Colors (Approximate, adjust as needed)
local PORT_COLORS = {
    [Card.Type.TECHNOLOGY] = { 0.2, 1, 0.2, 1 }, -- Electric Green
    [Card.Type.CULTURE] = { 1, 0.8, 0, 1 }, -- Warm Yellow/Orange
    [Card.Type.RESOURCE] = { 0.6, 0.4, 0.2, 1 }, -- Earthy Brown/Bronze
    [Card.Type.KNOWLEDGE] = { 0.6, 0.2, 1, 1 }, -- Deep Purple/Indigo
}
local ABSENT_PORT_COLOR = { 0.3, 0.3, 0.3, 1 } -- Dim Gray (For ports that are not defined)
local PORT_BORDER_COLOR = { 0, 0, 0, 1 } -- Black

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
    instance.PORT_RADIUS = PORT_RADIUS -- Renamed constant
    instance.HAND_CARD_WIDTH = HAND_CARD_WIDTH
    instance.HAND_CARD_HEIGHT = HAND_CARD_HEIGHT
    instance.UI_ICON_SIZE = UI_ICON_SIZE

    -- Store default offsets
    instance.defaultOffsetX = NETWORK_OFFSET_X
    instance.defaultOffsetY = NETWORK_OFFSET_Y

    -- Font creation (unchanged from previous version)
    local baseStandardSize = 24
    local baseSmallSize = 16
    local baseMiniSize = 14
    local baseTitleSize = 16
    local uiBaseStandardSize = 7
    local uiBaseSmallSize = 6
    local uiBaseMiniSize = 5
    local worldFontMultiplier = 3
    local uiFontMultiplier = 2
    local fontPath = "assets/fonts/Roboto-Regular.ttf"
    local fontPathSemiBold = "assets/fonts/Roboto-SemiBold.ttf"
    local defaultFont = love.graphics.getFont()
    if love.filesystem.getInfo(fontPath) and love.filesystem.getInfo(fontPathSemiBold) then
        instance.fonts.worldStandard = love.graphics.newFont(fontPath, baseStandardSize * 3)
        instance.fonts.worldStandard:setFilter('linear', 'linear')
        instance.fonts.worldSmall = love.graphics.newFont(fontPath, baseSmallSize * 3)
        instance.fonts.worldSmall:setFilter('linear', 'linear')
        instance.fonts.worldTitleSemiBold = love.graphics.newFont(fontPathSemiBold, baseTitleSize * 3)
        instance.fonts.worldTitleSemiBold:setFilter('linear', 'linear')
        instance.fonts.uiStandard = love.graphics.newFont(fontPath, uiBaseStandardSize * uiFontMultiplier)
        instance.fonts.uiStandard:setFilter('linear', 'linear')
        instance.fonts.uiSmall = love.graphics.newFont(fontPath, uiBaseSmallSize * uiFontMultiplier)
        instance.fonts.uiSmall:setFilter('linear', 'linear')
        instance.fonts.uiMini = love.graphics.newFont(fontPath, uiBaseMiniSize * uiFontMultiplier)
        instance.fonts.uiMini:setFilter('linear', 'linear')
        instance.fonts.previewTitleSemiBold = love.graphics.newFont(fontPathSemiBold, uiBaseStandardSize * uiFontMultiplier)
        instance.fonts.previewTitleSemiBold:setFilter('linear', 'linear')
        instance.fonts.previewStandard = love.graphics.newFont(fontPath, uiBaseStandardSize * uiFontMultiplier)
        instance.fonts.previewStandard:setFilter('linear', 'linear')
        instance.fonts.previewSmall = love.graphics.newFont(fontPath, uiBaseSmallSize * uiFontMultiplier)
        instance.fonts.previewSmall:setFilter('linear', 'linear')
        instance.fonts.previewMini = love.graphics.newFont(fontPath, uiBaseMiniSize * uiFontMultiplier)
        instance.fonts.previewMini:setFilter('linear', 'linear')
    else
        print("Warning: One or more TTF fonts not found... Using default-sized fonts.")
        instance.fonts.worldStandard = love.graphics.newFont(baseStandardSize * 3)
        instance.fonts.worldStandard:setFilter('linear', 'linear')
        instance.fonts.worldSmall = love.graphics.newFont(baseSmallSize * 3)
        instance.fonts.worldSmall:setFilter('linear', 'linear')
        instance.fonts.worldTitleSemiBold = instance.fonts.worldSmall
        instance.fonts.uiStandard = love.graphics.newFont(uiBaseStandardSize * uiFontMultiplier)
        instance.fonts.uiStandard:setFilter('linear', 'linear')
        instance.fonts.uiSmall = love.graphics.newFont(uiBaseSmallSize * uiFontMultiplier)
        instance.fonts.uiSmall:setFilter('linear', 'linear')
        instance.fonts.uiMini = love.graphics.newFont(uiBaseMiniSize * uiFontMultiplier)
        instance.fonts.uiMini:setFilter('linear', 'linear')
        instance.fonts.previewTitleSemiBold = instance.fonts.uiStandard
        instance.fonts.previewStandard = instance.fonts.uiStandard
        instance.fonts.previewSmall = instance.fonts.uiSmall
        instance.fonts.previewMini = instance.fonts.uiMini
    end
    instance.fonts.worldStandard = instance.fonts.worldStandard or defaultFont
    instance.fonts.worldSmall = instance.fonts.worldSmall or defaultFont
    instance.fonts.uiStandard = instance.fonts.uiStandard or defaultFont
    instance.fonts.uiSmall = instance.fonts.uiSmall or defaultFont
    instance.fonts.worldTitleSemiBold = instance.fonts.worldTitleSemiBold or defaultFont
    instance.fonts.previewTitleSemiBold = instance.fonts.previewTitleSemiBold or instance.fonts.uiStandard or defaultFont
    instance.fonts.previewStandard = instance.fonts.previewStandard or instance.fonts.uiStandard or defaultFont
    instance.fonts.previewSmall = instance.fonts.previewSmall or instance.fonts.uiSmall or defaultFont
    instance.fonts.previewMini = instance.fonts.previewMini or instance.fonts.uiMini or defaultFont
    instance.baseMiniFontSize = baseMiniSize
    instance.baseSmallFontSize = baseSmallSize
    instance.baseTitleFontSize = baseTitleSize
    instance.baseStandardFontSize = baseStandardSize
    instance.uiBaseStandardSize = uiBaseStandardSize
    instance.uiBaseSmallSize = uiBaseSmallSize
    instance.uiBaseMiniSize = uiBaseMiniSize
    instance.worldFontMultiplier = worldFontMultiplier
    instance.uiFontMultiplier = uiFontMultiplier

    -- Load Resource Icons
    instance.icons.energy = instance:_loadImage("assets/images/energy.png")
    instance.icons.data = instance:_loadImage("assets/images/data.png")
    instance.icons.material = instance:_loadImage("assets/images/materials.png")

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
    if self.images[path] then
        return self.images[path] ~= false and self.images[path] or nil
    end
    local success, imageOrError = pcall(love.graphics.newImage, path)
    if success then
        print("Loaded image: " .. path)
        imageOrError:setFilter("linear", "linear")
        self.images[path] = imageOrError
        return imageOrError
    else
        print(string.format("Warning: Failed to load image '%s'. Error: %s", path, tostring(imageOrError)))
        self.images[path] = false
        return nil
    end
end

-- Internal helper for drawing text with scaling baked into printf
function Renderer:_drawTextScaled(text, x, y, limit, align, styleName, baseFontSize, targetScale, alphaOverride)
    alphaOverride = alphaOverride or 1.0
    local style = self.styleGuide[styleName]
    if not style then
        print("Warning: Invalid style name provided to _drawTextScaled: " .. tostring(styleName))
        return
    end
    local font = self.fonts[style.fontName]
    if not font then
        print("Warning: Font not found for style '" .. styleName .. "': " .. style.fontName .. ". Using default.")
        font = love.graphics.getFont()
        local color = style.color or {0,0,0,1}
        local r = (color[1] or 0)
        local g = (color[2] or 0)
        local b = (color[3] or 0)
        local a = (color[4] or 1)
        love.graphics.setColor(r, g, b, a * alphaOverride)
        love.graphics.setFont(font)
        love.graphics.printf(text, x, y, limit, align)
        return
    end
    local fontMultiplier
    if string.find(style.fontName, "world") then
        fontMultiplier = self.worldFontMultiplier
    elseif string.find(style.fontName, "ui") or string.find(style.fontName, "preview") then
        fontMultiplier = self.uiFontMultiplier
    else
        print("Warning: Unknown font category for ", style.fontName, ". Assuming multiplier 1.")
        fontMultiplier = 1
    end
    local printfScale = targetScale / fontMultiplier
    local scaledLimit = limit / printfScale
    local yOffset = baseFontSize * printfScale * 0.1
    if align == "center" then
        yOffset = -(baseFontSize * printfScale * 0.4)
    end
    local color = style.color or {0,0,0,1}
    local r = color[1] or 0
    local g = color[2] or 0
    local b = color[3] or 0
    local a = color[4] or 1
    love.graphics.setFont(font)
    love.graphics.setColor(r, g, b, (a * alphaOverride))
    love.graphics.printf(text, x, y + yOffset, scaledLimit, align, 0, printfScale, printfScale)
end

-- Convert network grid coordinates (x, y) to WORLD coordinates (wx, wy)
function Renderer:gridToWorldCoords(gridX, gridY, originX, originY)
    originX = originX or 0
    originY = originY or 0
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
    originX = originX or 0
    originY = originY or 0
    local cellWidth = CARD_WIDTH + GRID_SPACING
    local cellHeight = CARD_HEIGHT + GRID_SPACING
    if cellWidth == 0 or cellHeight == 0 then return 0, 0 end
    local gridX = math.floor((wx - originX) / cellWidth)
    local gridY = math.floor((wy - originY) / cellHeight)
    return gridX, gridY
end

-- Helper function to get port position and implicit type based on GDD 4.3
local function getPortInfo(portIndex)
    local props = Card:getPortProperties(portIndex) -- Use Card helper
    if not props then return nil end

    local halfW = CARD_WIDTH / 2
    local halfH = CARD_HEIGHT / 2
    local quartW = CARD_WIDTH / 4
    local quartH = CARD_HEIGHT / 4

    local x_offset, y_offset
    if portIndex == Card.Ports.TOP_LEFT then x_offset, y_offset = quartW, 0 end
    if portIndex == Card.Ports.TOP_RIGHT then x_offset, y_offset = halfW + quartW, 0 end
    if portIndex == Card.Ports.BOTTOM_LEFT then x_offset, y_offset = quartW, CARD_HEIGHT end
    if portIndex == Card.Ports.BOTTOM_RIGHT then x_offset, y_offset = halfW + quartW, CARD_HEIGHT end
    if portIndex == Card.Ports.LEFT_TOP then x_offset, y_offset = 0, quartH end
    if portIndex == Card.Ports.LEFT_BOTTOM then x_offset, y_offset = 0, halfH + quartH end
    if portIndex == Card.Ports.RIGHT_TOP then x_offset, y_offset = CARD_WIDTH, quartH end
    if portIndex == Card.Ports.RIGHT_BOTTOM then x_offset, y_offset = CARD_WIDTH, halfH + quartH end

    if x_offset ~= nil then
        return { x_offset = x_offset, y_offset = y_offset, type = props.type, is_output = props.is_output }
    end
    return nil
end

-- Helper function to find the specific card port index closest to world coordinates
-- Returns: gridX, gridY, card, portIndex OR nil, nil, nil, nil
function Renderer:getPortAtWorldPos(network, wx, wy, originX, originY)
    originX = originX or 0
    originY = originY or 0
    local tolerance = self.PORT_RADIUS * 3.5 -- Use PORT_RADIUS
    local toleranceSq = tolerance * tolerance

    local clickGridX, clickGridY = self:worldToGridCoords(wx, wy, originX, originY)
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
        portIndex = nil
    }

    for _, cellCoords in ipairs(candidateCells) do
        local gridX, gridY = cellCoords[1], cellCoords[2]
        local card = network:getCardAt(gridX, gridY)

        if card then
            local cardWX, cardWY = self:gridToWorldCoords(gridX, gridY, originX, originY)

            for portIndex = 1, 8 do
                local portInfo = getPortInfo(portIndex)
                if portInfo then
                    local isOutput = portInfo.is_output
                    local r = self.PORT_RADIUS

                    local anchorWX = cardWX + portInfo.x_offset
                    local anchorWY = cardWY + portInfo.y_offset

                    local centerWX, centerWY = anchorWX, anchorWY
                    if isOutput then
                        if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then centerWY = anchorWY - r / 2
                        elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then centerWY = anchorWY + r / 2
                        elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then centerWX = anchorWX - r / 2
                        elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then centerWX = anchorWX + r / 2
                        end
                    end

                    local distSq = (wx - centerWX)^2 + (wy - centerWY)^2

                    if distSq < closestMatch.distanceSq then
                        closestMatch.distanceSq = distSq
                        closestMatch.card = card
                        closestMatch.gridX = gridX
                        closestMatch.gridY = gridY
                        closestMatch.portIndex = portIndex
                    end
                end
            end
        end
    end

    if closestMatch.card then
        return closestMatch.gridX, closestMatch.gridY, closestMatch.card, closestMatch.portIndex
    else
        return nil, nil, nil, nil
    end
end

-- Helper function to draw the 8 connection ports for a card
function Renderer:drawCardPorts(card, sx, sy, alphaOverride, activeLinks)
    alphaOverride = alphaOverride or 1.0
    activeLinks = activeLinks or {}
    if not card then return end

    local linkMap = {}
    for _, link in ipairs(activeLinks) do
        linkMap[link.linkId] = link
    end

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    local r = self.PORT_RADIUS -- Use instance variable

    for portIndex = 1, 8 do
        local info = getPortInfo(portIndex)
        if info then
            local portX = sx + info.x_offset
            local portY = sy + info.y_offset
            local isOutput = info.is_output
            local isDefined = card:isPortDefined(portIndex)
            local occupyingLinkId = card:getOccupyingLinkId(portIndex)
            local isOccupied = occupyingLinkId ~= nil

            local orientation
            if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then orientation = "top"
            elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then orientation = "bottom"
            elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then orientation = "left"
            elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then orientation = "right"
            end

            if isOccupied then
                -- 1. Draw original shape underneath (dimmed)
                self:_drawSinglePortShape(portIndex, portX, portY, r, alphaOverride * 0.4)

                -- 2. Draw the larger tab centered on the visual center
                local linkDetails = linkMap[occupyingLinkId]
                local playerNumber = linkDetails and linkDetails.initiatingPlayerIndex or "?"

                local tabSize = r * 3.5
                local tabX, tabY
                local fixedOffset = r * 1.0

                if orientation == "top" then
                    tabX = portX - tabSize / 2
                    tabY = portY - fixedOffset - tabSize
                elseif orientation == "bottom" then
                    tabX = portX - tabSize / 2
                    tabY = portY + fixedOffset
                elseif orientation == "left" then
                    tabX = portX - fixedOffset - tabSize
                    tabY = portY - tabSize / 2
                elseif orientation == "right" then
                    tabX = portX + fixedOffset
                    tabY = portY - tabSize / 2
                else 
                    local centerWX, centerWY = portX, portY
                    if isOutput then
                       if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then centerWY = portY - r / 2
                       elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then centerWY = portY + r / 2
                       elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then centerWX = portX - r / 2
                       elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then centerWX = portX + r / 2
                       end
                    end
                    tabX = centerWX - tabSize / 2
                    tabY = centerWY - tabSize / 2
                end

                love.graphics.setColor(0.9, 0.9, 0.9, alphaOverride * 0.7)
                love.graphics.rectangle("fill", tabX, tabY, tabSize, tabSize)
                love.graphics.setColor(0, 0, 0, alphaOverride)
                love.graphics.rectangle("line", tabX, tabY, tabSize, tabSize)

                local tabFont = self.fonts.worldSmall or originalFont
                love.graphics.setFont(tabFont)
                love.graphics.setColor(0, 0, 0, alphaOverride)
                local text = tostring(playerNumber)
                local textScale = 0.45 / self.worldFontMultiplier
                local nativeTextW = tabFont:getWidth(text)
                local nativeTextH = tabFont:getHeight()
                local scaledTextW = nativeTextW * textScale
                local scaledTextH = nativeTextH * textScale
                local textDrawX = tabX + (tabSize - scaledTextW) / 2
                local textDrawY = tabY + (tabSize - scaledTextH) / 2

                love.graphics.push()
                love.graphics.translate(textDrawX, textDrawY)
                love.graphics.scale(textScale, textScale)
                love.graphics.print(text, 0, 0)
                love.graphics.pop()

            elseif isDefined then
                -- Draw normal present port using the helper
                 self:_drawSinglePortShape(portIndex, portX, portY, r, alphaOverride)

            end
        end
    end
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

-- Internal helper to draw the shape for a single port
function Renderer:_drawSinglePortShape(portIndex, portX, portY, radius, alpha)
    local info = getPortInfo(portIndex)
    if not info then return end

    local portType = info.type
    local isOutput = info.is_output
    local r = radius

    local orientation
    if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then orientation = "top"
    elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then orientation = "bottom"
    elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then orientation = "left"
    elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then orientation = "right"
    end

    local baseColor = PORT_COLORS[portType] or {1,1,1,1}
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], (baseColor[4] or 1) * alpha)

    local vertices
    if isOutput then -- Draw rectangle
        if orientation == "top" then vertices = { portX-r, portY-r, portX+r, portY-r, portX+r, portY, portX-r, portY }
        elseif orientation == "bottom" then vertices = { portX-r, portY, portX+r, portY, portX+r, portY+r, portX-r, portY+r }
        elseif orientation == "left" then vertices = { portX-r, portY-r, portX, portY-r, portX, portY+r, portX-r, portY+r }
        elseif orientation == "right" then vertices = { portX, portY-r, portX+r, portY-r, portX+r, portY+r, portX, portY+r }
        end
    else -- Draw triangle (input)
        if orientation == "top" then vertices = { portX-r, portY-r, portX+r, portY-r, portX, portY+r } -- Points down
        elseif orientation == "bottom" then vertices = { portX-r, portY+r, portX+r, portY+r, portX, portY-r } -- Points up
        elseif orientation == "left" then vertices = { portX-r, portY-r, portX-r, portY+r, portX+r, portY } -- Points right
        elseif orientation == "right" then vertices = { portX+r, portY-r, portX+r, portY+r, portX-r, portY } -- Points left
        end
    end

    if vertices then
        love.graphics.polygon("fill", vertices)
        local borderColor = PORT_BORDER_COLOR
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], (borderColor[4] or 1) * alpha)
        love.graphics.polygon("line", vertices)
    else
        love.graphics.circle("fill", portX, portY, r)
        local borderColor = PORT_BORDER_COLOR
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], (borderColor[4] or 1) * alpha)
        love.graphics.circle("line", portX, portY, r)
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

    -- Base background
    local baseR, baseG, baseB = 0.8, 0.8, 0.8
    if card.type == Card.Type.REACTOR then baseR, baseG, baseB = 1, 1, 0.5 end
    love.graphics.setColor(baseR, baseG, baseB, 1.0 * alphaOverride)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)

    local margin = 5
    local headerH = 20
    local costAreaW = 17
    local iconSize = 15
    local imageY = y + headerH + margin
    -- Calculate area width first
    local areaW = CARD_WIDTH - (2 * margin)
    -- Calculate height based on width and desired aspect ratio (1024/720)
    local aspectRatio = 1024 / 720
    local imageH = areaW / aspectRatio -- Use the calculated height
    -- Calculate effects height based on remaining space
    local effectsH = CARD_HEIGHT - headerH - imageH - (2 * margin)
    -- Adjust effects Y position to be directly below the art box
    local effectsY = imageY + imageH -- Place effects box below the art box, no margin

    -- 1. Draw Header Area
    local baseTypeColor = PORT_COLORS[card.type] or {0.5, 0.5, 0.5, 1} -- Use PORT_COLORS
    local headerIconX = x + margin
    local headerIconY = y + margin
    love.graphics.setColor(baseTypeColor[1], baseTypeColor[2], baseTypeColor[3], (baseTypeColor[4] or 1) * alphaOverride)
    love.graphics.rectangle("fill", headerIconX, headerIconY, iconSize, iconSize)
    love.graphics.setColor(0,0,0, 1.0 * alphaOverride)
    love.graphics.rectangle("line", headerIconX, headerIconY, iconSize, iconSize)

    local typeIcon = self.icons[card.type]
    if typeIcon then
        local typeIconScaleFactor = 0.8
        local targetDrawSize = iconSize * typeIconScaleFactor
        local iconDrawScale = targetDrawSize / typeIcon:getWidth()
        local offset = (iconSize - targetDrawSize) / 2
        local drawX = headerIconX + offset
        local drawY = headerIconY + offset
        love.graphics.setColor(1, 1, 1, alphaOverride)
        love.graphics.draw(typeIcon, drawX, drawY, 0, iconDrawScale, iconDrawScale)
    end

    love.graphics.setColor(originalColor)
    local titleX = x + margin + iconSize + margin - 2
    local titleY = y + margin - 1
    local titleLimit = CARD_WIDTH - (2*margin + iconSize + costAreaW)
    local titleStyle = context.stylePrefix .. "_TITLE_NW"
    self:_drawTextScaled(card.title or "Untitled", titleX, titleY, titleLimit, "left", titleStyle, context.baseFontSizes.title, context.targetScales.title, alphaOverride)

    love.graphics.setColor(originalColor)
    local costYBase = y + margin - 1
    local costIconSize = CARD_COST_ICON_SIZE
    local costInnerSpacing = 2
    local costLineHeight = 12
    local artworkRightEdge = x + CARD_WIDTH - margin
    local matCost = card.buildCost and card.buildCost.material or 0
    local dataCost = card.buildCost and card.buildCost.data or 0
    local matIcon = self.icons.material
    local dataIcon = self.icons.data
    local costBaseFontSize = context.baseFontSizes.cost
    local targetScale_cost = context.targetScales.cost
    local costStyleName = context.stylePrefix .. "_COST"
    local costFont = self.fonts[self.styleGuide[costStyleName].fontName] or love.graphics.getFont()
    local costFontMultiplier = 1
    if string.find(self.styleGuide[costStyleName].fontName, "world") then
        costFontMultiplier = self.worldFontMultiplier
    elseif string.find(self.styleGuide[costStyleName].fontName, "preview") then
        costFontMultiplier = self.uiFontMultiplier
    end

    if matIcon then
        local text = tostring(matCost)
        local textWidth = costFont:getWidth(text) / costFontMultiplier * targetScale_cost
        local totalWidth = costIconSize + costInnerSpacing + textWidth
        local overallStartX = artworkRightEdge - totalWidth
        local iconX = overallStartX
        local textX = iconX + costIconSize + costInnerSpacing
        local iconScale = costIconSize / matIcon:getWidth()
        love.graphics.setColor(1, 1, 1, alphaOverride)
        love.graphics.draw(matIcon, iconX, costYBase, 0, iconScale, iconScale)
        love.graphics.setColor(originalColor)
        self:_drawTextScaled(text, textX, costYBase, CARD_WIDTH, "left", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    else
        love.graphics.setColor(originalColor)
        self:_drawTextScaled(string.format("M:%d", matCost), x + margin, costYBase, CARD_WIDTH - 2*margin, "right", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    end

    local dataY = costYBase + costLineHeight - 2
    if dataIcon then
        local text = tostring(dataCost)
        local textWidth = costFont:getWidth(text) / costFontMultiplier * targetScale_cost
        local totalWidth = costIconSize + costInnerSpacing + textWidth
        local overallStartX = artworkRightEdge - totalWidth
        local iconX = overallStartX
        local textX = iconX + costIconSize + costInnerSpacing
        local iconScale = costIconSize / dataIcon:getWidth()
        love.graphics.setColor(1, 1, 1, alphaOverride)
        love.graphics.draw(dataIcon, iconX, dataY, 0, iconScale, iconScale)
        love.graphics.setColor(originalColor)
        self:_drawTextScaled(text, textX, dataY, CARD_WIDTH, "left", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    else
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
        -- Use areaW and imageH for the placeholder rectangle
        love.graphics.rectangle("fill", x + margin, imageY, areaW, imageH)
        love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride)
        love.graphics.rectangle("line", x + margin, imageY, areaW, imageH)
        local artLimit = areaW -- Use areaW for limit
        local artStyleName = context.stylePrefix .. "_ART_LABEL"
        love.graphics.setColor(originalColor)
        -- Center text within the new area dimensions
        self:_drawTextScaled("ART", x + margin + areaW / 2, imageY + imageH / 2, artLimit, "center", artStyleName, context.baseFontSizes.artLabel, context.targetScales.artLabel, alphaOverride)
    end

    -- 3. Draw Effects Box Area
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0 * alphaOverride)
    -- Use areaW for effects box width
    love.graphics.rectangle("fill", x + margin, effectsY, areaW, effectsH)
    love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride)
    -- Use areaW for effects box width
    love.graphics.rectangle("line", x + margin, effectsY, areaW, effectsH)
    local effectBaseFontSize = context.baseFontSizes.effect
    local activationText = "Activation: " .. (card:getActivationDescription() or "No effect")
    local convergenceText = "Convergence: " .. (card:getConvergenceDescription() or "No effect")
    local effectsLimit = (CARD_WIDTH - (2 * margin) - 4)
    local effectsTextYBase = effectsY + 2
    local effectStyleName = context.stylePrefix .. "_EFFECT"
    local targetScale_effect = context.targetScales.effect
    local effectFont = self.fonts[self.styleGuide[effectStyleName].fontName] or love.graphics.getFont()
    local fontMultiplier = 1
    if string.find(self.styleGuide[effectStyleName].fontName, "world") then
        fontMultiplier = self.worldFontMultiplier
    elseif string.find(self.styleGuide[effectStyleName].fontName, "preview") then
        fontMultiplier = self.uiFontMultiplier
    end
    local effectLineHeight = effectFont:getHeight() / fontMultiplier * targetScale_effect

    love.graphics.setColor(originalColor)
    self:_drawTextScaled(activationText, x + margin + 2, effectsTextYBase, effectsLimit, "left", effectStyleName, effectBaseFontSize, targetScale_effect, alphaOverride)
    self:_drawTextScaled(convergenceText, x + margin + 2, effectsTextYBase + effectLineHeight * 3, effectsLimit, "left", effectStyleName, effectBaseFontSize, targetScale_effect, alphaOverride)

    -- Draw Outer Border
    if useInvalidBorder then
        love.graphics.setColor(1, 0, 0, 1.0 * alphaOverride)
    else
        love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride)
    end
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)

    love.graphics.setColor(originalColor)
    -- Draw Connection Ports
    self:drawCardPorts(card, x, y, alphaOverride, context.activeLinks)
end

-- Internal utility function to draw a single card in the world
function Renderer:_drawSingleCardInWorld(card, wx, wy, activeLinks, alphaOverride, useInvalidBorder)
    alphaOverride = alphaOverride or 1.0
    useInvalidBorder = useInvalidBorder or false

    local context = {
        stylePrefix = "CARD",
        baseFontSizes = {
            title = self.baseTitleFontSize,
            cost = self.baseSmallFontSize,
            effect = self.baseMiniFontSize,
            artLabel = self.baseStandardFontSize
        },
        targetScales = {
            title = 0.4375,
            cost = 0.4,
            effect = 0.36,
            artLabel = 0.416666667
        },
        alpha = alphaOverride,
        borderType = useInvalidBorder and "invalid" or "normal",
        activeLinks = activeLinks
    }

    self:_drawCardInternal(card, wx, wy, context)
end

-- Draw a player's network grid, applying camera transform
function Renderer:drawNetwork(network, cameraX, cameraY, cameraZoom, originX, originY, activeLinks)
    if not network then return end
    originX = originX or 0
    originY = originY or 0

    love.graphics.push()
    love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
    love.graphics.scale(cameraZoom, cameraZoom)
    love.graphics.setLineWidth(1 / cameraZoom)

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}

    local drawQueue = {}
    for cardId, card in pairs(network.cards) do
        if type(card) == "table" and card.position then
            local wx, wy = self:gridToWorldCoords(card.position.x, card.position.y, originX, originY)
            table.insert(drawQueue, { card = card, wx = wx, wy = wy })
        else
            if type(card) ~= "table" then
                -- print(string.format("Warning in drawNetwork: Skipping non-table value..."))
            end
        end
    end

    for _, item in ipairs(drawQueue) do
        self:_drawSingleCardInWorld(item.card, item.wx, item.wy, activeLinks)
    end

    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)

    love.graphics.pop()
end

-- Draw highlight / card preview over the hovered grid cell, or red outline if invalid
function Renderer:drawHoverHighlight(gridX, gridY, cameraX, cameraY, cameraZoom, selectedCard, isPlacementValid, originX, originY)
    isPlacementValid = isPlacementValid == nil or isPlacementValid == true
    originX = originX or 0
    originY = originY or 0

    if gridX == nil or gridY == nil then return end

    if selectedCard then
        local wx, wy = self:gridToWorldCoords(gridX, gridY, originX, originY)
        love.graphics.push()
        love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
        love.graphics.scale(cameraZoom, cameraZoom)
        love.graphics.setLineWidth(1 / cameraZoom)

        local useInvalidBorder = not isPlacementValid
        self:_drawSingleCardInWorld(selectedCard, wx, wy, nil, 0.5, useInvalidBorder)

        love.graphics.pop()
    end
end

-- Function to draw a hand card preview
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

    local context = {
        stylePrefix = "PREVIEW",
        baseFontSizes = {
            title = self.uiBaseStandardSize,
            cost = self.uiBaseSmallSize,
            effect = self.uiBaseMiniSize,
            artLabel = self.uiBaseStandardSize
        },
        targetScales = {
            title = 1.0,
            cost = 1.0,
            effect = 0.9,
            artLabel = 1.0
        },
        alpha = 1.0,
        borderType = "normal"
    }

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

    local handStartY = love.graphics.getHeight() - BOTTOM_BUTTON_AREA_HEIGHT - HAND_CARD_HEIGHT
    local handBounds = {}

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    local originalLineWidth = love.graphics.getLineWidth()

    local labelStyle = self.styleGuide.UI_HAND_LABEL
    assert(self.fonts[labelStyle.fontName], "Hand label font not found: " .. labelStyle.fontName)
    love.graphics.setFont(self.fonts[labelStyle.fontName])
    love.graphics.setColor(labelStyle.color)
    love.graphics.print(string.format("%s Hand (%d):", player.name, #player.hand), HAND_START_X, handStartY - 20)

    local cardTitleStyle = self.styleGuide.UI_HAND_LABEL
    love.graphics.setFont(self.fonts[cardTitleStyle.fontName])

    for i, card in ipairs(player.hand) do
        if i ~= selectedIndex then
            local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
            local sy = handStartY
            table.insert(handBounds, { index = i, x = sx, y = sy, w = HAND_CARD_WIDTH, h = HAND_CARD_HEIGHT })
            love.graphics.setColor(0.8, 0.8, 1, 1)
            love.graphics.rectangle("fill", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("line", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(cardTitleStyle.color)
            love.graphics.printf(card.title, sx + 3, sy + 3, HAND_CARD_WIDTH - 6, "left")
        end
    end

    if selectedIndex then
        local card = player.hand[selectedIndex]
        if card then
            local i = selectedIndex
            local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
            local sy = handStartY - SELECTED_CARD_RAISE
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

            love.graphics.setColor(1, 1, 0.8, 1)
            love.graphics.rectangle("fill", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", sx, sy, HAND_CARD_WIDTH, HAND_CARD_HEIGHT)
            love.graphics.setColor(cardTitleStyle.color)
            love.graphics.printf(card.title, sx + 3, sy + 3, HAND_CARD_WIDTH - 6, "left")
        end
    end

    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth)

    return handBounds
end

-- Drawing UI elements (resources, VP, turn info)
function Renderer:drawUI(player, hoveredLinkType, currentPhase, convergenceSelectionState)
    if not player then return end

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    local originalLineWidth = love.graphics.getLineWidth()

    local style = self.styleGuide.UI_LABEL
    local font = self.fonts[style.fontName]
    if not font then
        print("Warning: UI Label font not found: " .. style.fontName .. ". Using default.")
        font = love.graphics.getFont()
    end
    local r = style.color[1] or 0
    local g = style.color[2] or 0
    local b = style.color[3] or 0
    local a = style.color[4] or 1

    love.graphics.setFont(font)
    love.graphics.setColor(r, g, b, a)

    local uiX = 10
    local uiY_start = 30
    local lineSpacing = 21
    love.graphics.print(string.format("--- %s UI ---", player.name), uiX, uiY_start)
    love.graphics.print(string.format("VP: %d", player.vp), uiX, uiY_start + lineSpacing)

    local resY = uiY_start + 2 * lineSpacing
    local iconSize = UI_ICON_SIZE
    local iconSpacing = 5
    local resGroupSpacing = 25

    local currentX = uiX

    local energyIcon = self.icons.energy
    if energyIcon then
        local scale = iconSize / energyIcon:getWidth()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(energyIcon, currentX, resY, 0, scale, scale)
        love.graphics.setColor(r, g, b, a)
        local energyText = tostring(player.resources.energy)
        love.graphics.print(energyText, currentX + iconSize + iconSpacing, resY)
        currentX = currentX + iconSize + iconSpacing + font:getWidth(energyText) + resGroupSpacing
    else
        local energyText = string.format("E:%d", player.resources.energy)
        love.graphics.print(energyText, currentX, resY)
        currentX = currentX + font:getWidth(energyText) + resGroupSpacing
    end

    local dataIcon = self.icons.data
    if dataIcon then
        local scale = iconSize / dataIcon:getWidth()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(dataIcon, currentX, resY, 0, scale, scale)
        love.graphics.setColor(r, g, b, a)
        local dataText = tostring(player.resources.data)
        love.graphics.print(dataText, currentX + iconSize + iconSpacing, resY)
        currentX = currentX + iconSize + iconSpacing + font:getWidth(dataText) + resGroupSpacing
    else
        local dataText = string.format("D:%d", player.resources.data)
        love.graphics.print(dataText, currentX, resY)
        currentX = currentX + font:getWidth(dataText) + resGroupSpacing
    end

    local materialIcon = self.icons.material
    if materialIcon then
        local scale = iconSize / materialIcon:getWidth()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(materialIcon, currentX, resY, 0, scale, scale)
        love.graphics.setColor(r, g, b, a)
        local materialText = tostring(player.resources.material)
        love.graphics.print(materialText, currentX + iconSize + iconSpacing, resY)
        currentX = currentX + iconSize + iconSpacing + font:getWidth(materialText) + resGroupSpacing
    else
        local materialText = string.format("M:%d", player.resources.material)
        love.graphics.print(materialText, currentX, resY)
        currentX = currentX + font:getWidth(materialText) + resGroupSpacing
    end

    -- Draw Available Convergence Link Sets
    local linkY = resY + lineSpacing
    local linkStartX = uiX
    local linkIconSize = UI_ICON_SIZE * 0.8
    local linkIconSpacing = 3
    local linkGroupSpacing = 5
    local linkTextStyle = self.styleGuide.UI_LABEL
    local linkFont = self.fonts[linkTextStyle.fontName] or font
    love.graphics.setFont(linkFont)
    love.graphics.setColor(linkTextStyle.color)
    love.graphics.print("Links:", linkStartX, linkY)
    currentX = linkStartX + linkFont:getWidth("Links:") + linkGroupSpacing

    local linkTypes = { Card.Type.TECHNOLOGY, Card.Type.CULTURE, Card.Type.RESOURCE, Card.Type.KNOWLEDGE }
    for _, linkType in ipairs(linkTypes) do
        local isAvailable = player:hasLinkSetAvailable(linkType)
        local isHovered = (hoveredLinkType == linkType)
        local icon = self.icons[linkType]
        local bgColor = PORT_COLORS[linkType] or {0.5, 0.5, 0.5, 1} -- Use PORT_COLORS
        local boxSize = linkIconSize + 4
        local boxX = currentX
        local boxY = linkY - 2

        if isAvailable then
            love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
        else
            love.graphics.setColor(bgColor[1] * 0.5, bgColor[2] * 0.5, bgColor[3] * 0.5, (bgColor[4] or 1) * 0.7)
        end
        love.graphics.rectangle("fill", boxX, boxY, boxSize, boxSize)

        if isHovered and isAvailable and currentPhase == "Converge" and convergenceSelectionState == nil then
            local currentLineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(2)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", boxX, boxY, boxSize, boxSize)
            love.graphics.setLineWidth(currentLineWidth)
        end

        if icon then
            local iconDrawX = boxX + (boxSize - linkIconSize) / 2
            local iconDrawY = boxY + (boxSize - linkIconSize) / 2
            local scale = linkIconSize / icon:getWidth()
            if isAvailable then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            end
            love.graphics.draw(icon, iconDrawX, iconDrawY, 0, scale, scale)
            currentX = currentX + boxSize + linkIconSpacing
        else
            local typeStr = "UNK"
            if linkType == Card.Type.TECHNOLOGY then typeStr = "T" end
            if linkType == Card.Type.CULTURE then typeStr = "C" end
            if linkType == Card.Type.RESOURCE then typeStr = "R" end
            if linkType == Card.Type.KNOWLEDGE then typeStr = "K" end
            local txtColor = linkTextStyle.color
            if isAvailable then
                love.graphics.setColor(txtColor[1], txtColor[2], txtColor[3], txtColor[4] or 1)
            else
                love.graphics.setColor(txtColor[1]*0.5, txtColor[2]*0.5, txtColor[3]*0.5, (txtColor[4] or 1)*0.7)
            end
            local textWidth = linkFont:getWidth(typeStr)
            local textHeight = linkFont:getHeight()
            local textDrawX = boxX + (boxSize - textWidth) / 2
            local textDrawY = boxY + (boxSize - textHeight) / 2
            love.graphics.print(typeStr, textDrawX, textDrawY)
            currentX = currentX + boxSize + linkIconSpacing
        end
         currentX = currentX + linkGroupSpacing
    end

    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth)
end

return Renderer
