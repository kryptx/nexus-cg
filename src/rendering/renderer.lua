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

    -- NEW: Scale factor for pre-rendering card canvases
    instance.canvasRenderScaleFactor = 4

    -- Load Resource Icons
    instance.icons.energy = instance:_loadImage("assets/images/energy.png")
    instance.icons.data = instance:_loadImage("assets/images/data.png")
    instance.icons.material = instance:_loadImage("assets/images/materials.png")

    -- Load Card Type Icons
    instance.icons[Card.Type.TECHNOLOGY] = instance:_loadImage("assets/images/technology-black.png")
    instance.icons[Card.Type.CULTURE] = instance:_loadImage("assets/images/culture-black.png")
    instance.icons[Card.Type.RESOURCE] = instance:_loadImage("assets/images/resource-black.png")
    instance.icons[Card.Type.KNOWLEDGE] = instance:_loadImage("assets/images/knowledge-black.png")

    -- Prepare canvas cache for fully-rendered cards at world scale
    instance.cardCache = {}

    -- Attempt to load BMFont (image font) for in-card text rendering
    -- We load three different bitmap fonts:
    -- 1. titlefont.fnt - Used specifically for card titles
    -- 2. imagefont.fnt - Used for regular card text
    -- 3. imagefont-white.fnt - Used for convergence text (on dark background)
    local bmFontPath = "assets/fonts/imagefont.fnt"
    
    -- NEW: Load special title font for card titles
    local titleFontPath = "assets/fonts/titlefont.fnt"
    local titleFont = nil
    if love.filesystem.getInfo(titleFontPath) then
        local successTitle, titleFontOrErr = pcall(love.graphics.newFont, titleFontPath)
        if successTitle and titleFontOrErr then
            titleFont = titleFontOrErr
            -- Use nearest filtering for crisp pixel look
            titleFont:setFilter('nearest', 'nearest')
            print("Successfully loaded title BMFont: " .. titleFontPath)
            
            -- Assign to the worldTitleSemiBold slot specifically for card titles
            instance.fonts.worldTitleSemiBold = titleFont
        else
            print(string.format("Warning: Failed to load title BMFont '%s'. Error: %s. Falling back.", titleFontPath, tostring(titleFontOrErr)))
        end
    else
        print(string.format("Warning: Title BMFont file not found at '%s'. Falling back.", titleFontPath))
    end
    
    if love.filesystem.getInfo(bmFontPath) then
        local success, bmFontOrErr = pcall(love.graphics.newFont, bmFontPath)
        if success and bmFontOrErr then
            local bmFont = bmFontOrErr
            -- Use nearest filtering for crisp pixel look
            bmFont:setFilter('nearest', 'nearest')

            -- Replace world and preview font entries with the bitmap font
            instance.fonts.worldStandard = bmFont
            instance.fonts.worldSmall = bmFont
            -- Only replace worldTitleSemiBold if we didn't load a specific title font
            if not titleFont then
                instance.fonts.worldTitleSemiBold = bmFont
            end
            instance.fonts.previewTitleSemiBold = bmFont
            instance.fonts.previewStandard = bmFont
            instance.fonts.previewSmall = bmFont
            instance.fonts.previewMini = bmFont

            -- Re-compute world font multiplier so scaling math stays consistent
            instance.worldFontMultiplier = bmFont:getHeight() / baseStandardSize

            -- Attempt to load the WHITE BMFont for convergence text
            local bmFontWhitePath = "assets/fonts/imagefont-white.fnt"
            if love.filesystem.getInfo(bmFontWhitePath) then
                local successWhite, bmFontWhiteOrErr = pcall(love.graphics.newFont, bmFontWhitePath)
                if successWhite and bmFontWhiteOrErr then
                    local bmFontWhite = bmFontWhiteOrErr
                    bmFontWhite:setFilter('nearest', 'nearest')
                    instance.fonts.worldConvergence = bmFontWhite
                    print("Successfully loaded white BMFont: " .. bmFontWhitePath)
                else
                    print(string.format("Warning: Failed to load white BMFont '%s'. Error: %s. Falling back.", bmFontWhitePath, tostring(bmFontWhiteOrErr)))
                    instance.fonts.worldConvergence = bmFont -- Fallback to the main BMFont
                end
            else
                print(string.format("Warning: White BMFont file not found at '%s'. Falling back.", bmFontWhitePath))
                instance.fonts.worldConvergence = bmFont -- Fallback to the main BMFont
            end
            
            -- If we loaded a title font, calculate its multiplier for proper scaling
            if titleFont then
                instance.titleFontMultiplier = titleFont:getHeight() / baseTitleSize
                print("Title font multiplier: " .. instance.titleFontMultiplier)
            end

        else
            print(string.format("Warning: Failed to load BMFont '%s'. Error: %s", bmFontPath, tostring(bmFontOrErr)))
            -- Ensure fallback for convergence font if main BMFont fails
            instance.fonts.worldConvergence = instance.fonts.previewMini or defaultFont
        end
    else
        print(string.format("Warning: BMFont file not found at '%s'. Falling back to TTF fonts.", bmFontPath))
        -- Ensure fallback for convergence font if main BMFont isn't even found
        instance.fonts.worldConvergence = instance.fonts.previewMini or defaultFont
        
        -- Set up title font multiplier if title font was loaded but main font wasn't
        if titleFont then
            instance.titleFontMultiplier = titleFont:getHeight() / baseTitleSize
            print("Title font multiplier set on fallback: " .. instance.titleFontMultiplier)
        end
    end

    -- Final check/fallback for convergence font if it wasn't set above
    instance.fonts.worldConvergence = instance.fonts.worldConvergence or instance.fonts.worldSmall or defaultFont

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
    if style.fontName == "worldTitleSemiBold" and self.titleFontMultiplier then
        -- Use the specific multiplier for title font
        fontMultiplier = self.titleFontMultiplier
    elseif string.find(style.fontName, "world") then
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

    -- Determine color: Use white tint for BMFont styles, otherwise use style color
    local r, g, b
    local isBMFont = string.find(style.fontName, "world") or string.find(style.fontName, "preview")
    if isBMFont then
        r, g, b = 1, 1, 1 -- Use white tint for BMFont
    else
        local color = style.color or {0,0,0,1}
        r = color[1] or 0
        g = color[2] or 0
        b = color[3] or 0
    end
    local styleAlpha = (style.color and style.color[4]) or 1 -- Use alpha from style
    local finalAlpha = styleAlpha * alphaOverride

    love.graphics.setFont(font)
    love.graphics.setColor(r, g, b, finalAlpha)
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
    if isOutput then -- Draw trapezoid (wider outer edge)
        local outer_half_width = r * 1.5 -- Outer edge will be 3r wide/tall
        local inner_half_width = r       -- Inner edge remains 2r wide/tall

        if orientation == "top" then
            -- Outer edge points (y = portY)
            local x1_out = portX - inner_half_width
            local x2_out = portX + inner_half_width
            -- Inner edge points (y = portY)
            local x1_in = portX - outer_half_width
            local x2_in = portX + outer_half_width
            vertices = { x1_out, portY-r, x2_out, portY-r, x2_in, portY, x1_in, portY }
        elseif orientation == "bottom" then
             -- Outer edge points (y = portY+r)
            local x1_out = portX - inner_half_width
            local x2_out = portX + inner_half_width
            -- Inner edge points (y = portY)
            local x1_in = portX - outer_half_width
            local x2_in = portX + outer_half_width
            vertices = { x1_in, portY, x2_in, portY, x2_out, portY+r, x1_out, portY+r }
        elseif orientation == "left" then
            -- Outer edge points (x = portX-r)
            local y1_out = portY - inner_half_width
            local y2_out = portY + inner_half_width
            -- Inner edge points (x = portX)
            local y1_in = portY - outer_half_width
            local y2_in = portY + outer_half_width
            vertices = { portX-r, y1_out, portX, y1_in, portX, y2_in, portX-r, y2_out }
        elseif orientation == "right" then
             -- Outer edge points (x = portX+r)
            local y1_out = portY - inner_half_width
            local y2_out = portY + inner_half_width
            -- Inner edge points (x = portX)
            local y1_in = portY - outer_half_width
            local y2_in = portY + outer_half_width
            vertices = { portX, y1_in, portX+r, y1_out, portX+r, y2_out, portX, y2_in }
        end
    else -- Draw triangle (input)
        if orientation == "top" then vertices = { portX-r, portY-r, portX+r, portY-r, portX, portY+r } -- Points down
        elseif orientation == "bottom" then vertices = { portX-r, portY+r, portX+r, portY+r, portX, portY-r } -- Points up
        elseif orientation == "left" then vertices = { portX-r, portY-r, portX-r, portY+r, portX+r, portY } -- Points right
        elseif orientation == "right" then vertices = { portX+r, portY-r, portX+r, portY+r, portX-r, portY } -- Points left
        end
    end

    love.graphics.setLineWidth(0.5)
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

    -- Draw Outer Border FIRST
    local originalLineWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(self.PORT_RADIUS * 2)
    love.graphics.setColor(0.15, 0.15, 0.15, 1.0 * alphaOverride) -- Always black
    local cornerRadius = 2 -- Adjust as needed
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, cornerRadius, cornerRadius)
    love.graphics.setLineWidth(originalLineWidth) -- Restore line width before drawing content
    love.graphics.setColor(originalColor) -- Restore original color

    -- Base background (drawn over the border outline)
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

    -- Draws the actual type icon image (e.g., technology-black.png) over the background
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
    local titleX = x + margin + iconSize + margin - 3
    local titleY = y + margin - 2
    
    -- Adjust title position when using the special title font
    if self.titleFontMultiplier and self.fonts.worldTitleSemiBold then
        -- Add a bit more vertical space for the title font
        titleY = y + margin
    end
    
    local titleLimit = CARD_WIDTH - (2*margin + iconSize + costAreaW)
    local titleStyle = context.stylePrefix .. "_TITLE_NW"
    self:_drawTextScaled(card.title or "Untitled", titleX, titleY, titleLimit, "left", titleStyle, context.baseFontSizes.title, context.targetScales.title, alphaOverride)

    love.graphics.setColor(originalColor)
    local costYBase = y + margin - 2
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
        
        -- Draw flavor text box if the card has flavor text
        if card.flavorText and card.flavorText ~= "" then
            -- Semi-transparent black box covering bottom third of the artwork
            local flavorBoxHeight = areaH / 3
            local flavorBoxY = imageY + areaH - flavorBoxHeight
            love.graphics.setColor(0, 0, 0, 0.5 * alphaOverride) -- Semi-transparent black
            love.graphics.rectangle("fill", x + margin, flavorBoxY, areaW, flavorBoxHeight)
            
            -- Draw flavor text using the white font style similar to convergence text
            local flavorTextY = flavorBoxY + 1 -- Small padding from top of flavor box
            local flavorTextLimit = areaW - 2 -- Small padding on left and right
            love.graphics.setColor(originalColor) -- Restore original color for _drawTextScaled
            self:_drawTextScaled(card.flavorText, x + margin + 2, flavorTextY, flavorTextLimit, "left", 
                                 "CARD_EFFECT_CONVERGENCE", -- Use the white font style 
                                 context.baseFontSizes.effect, 
                                 context.targetScales.effect, 
                                 0.75 * alphaOverride)
        end
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
    local effectBaseFontSize = context.baseFontSizes.effect
    local targetScale_effect = context.targetScales.effect
    local effectStyleName = context.stylePrefix .. "_EFFECT"
    local effectFont = self.fonts[self.styleGuide[effectStyleName].fontName] or love.graphics.getFont()
    local fontMultiplier = 1
    if string.find(self.styleGuide[effectStyleName].fontName, "world") then
        fontMultiplier = self.worldFontMultiplier
    elseif string.find(self.styleGuide[effectStyleName].fontName, "preview") then
        fontMultiplier = self.uiFontMultiplier
    end
    local effectLineHeight = effectFont:getHeight() / fontMultiplier * targetScale_effect
    local effectPadding = 2
    local totalEffectAreaH = CARD_HEIGHT - headerH - imageH - (2 * margin)
    local convergenceBoxH = totalEffectAreaH * 0.5 -- Convergence gets 50% of the space
    local activationBoxH = totalEffectAreaH - convergenceBoxH -- Activation gets the rest
    local convergenceBoxY = effectsY + activationBoxH

    -- Activation Box (Light Background)
    love.graphics.setColor(0.9, 0.9, 0.9, 1.0 * alphaOverride)
    love.graphics.rectangle("fill", x + margin, effectsY, areaW, activationBoxH)
    love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride)
    love.graphics.rectangle("line", x + margin, effectsY, areaW, activationBoxH)

    -- Convergence Box (Dark Background)
    love.graphics.setColor(0.2, 0.2, 0.2, 1.0 * alphaOverride) -- Dark gray
    love.graphics.rectangle("fill", x + margin, convergenceBoxY, areaW, convergenceBoxH)
    love.graphics.setColor(0, 0, 0, 1.0 * alphaOverride) -- Black border
    love.graphics.rectangle("line", x + margin, convergenceBoxY, areaW, convergenceBoxH)

    -- Fetch Effect Texts (without labels)
    local activationText = card:getActivationDescription() or "No effect"
    local convergenceText = card:getConvergenceDescription() or "No effect"

    -- NEW: Helper to replace keywords with icons using frontier patterns
    local function replace_keywords_with_icons(text, map)
      if not text then return "" end
      local modified_text = text
      for keyword, icon in pairs(map) do
          -- Escape potential magic characters in the keyword
          local escaped_keyword = string.gsub(keyword, "[%%^$%(%)%%%%%%%[%]%*%+%-%?]", "%%%1")
          -- Use frontier patterns to match whole words only
          -- %f[%a] = frontier between non-alpha and alpha (start of word)
          -- %f[%A] = frontier between alpha and non-alpha (end of word)
          modified_text = string.gsub(modified_text, "%f[%a]" .. escaped_keyword .. "%f[%A]", icon)
      end
      return modified_text
    end

    -- NEW: Map keywords to icons
    local icon_map = {
        -- Card Types
        ["Culture"] = "%%",    ["culture"] = "%%",
        ["Technology"] = "}", ["technology"] = "}",
        ["Resource"] = "~",   ["resource"] = "~",
        ["Knowledge"] = "{",  ["knowledge"] = "{",
        -- Resources
        ["Materials"] = "@",  ["materials"] = "@",
        ["Material"] = "@",   ["material"] = "@",
        ["Data"] = "#",       ["data"] = "#",
        ["Energy"] = "\\",     ["energy"] = "\\"
    }

    -- NEW: Apply the substitutions
    activationText = replace_keywords_with_icons(activationText, icon_map)
    convergenceText = replace_keywords_with_icons(convergenceText, icon_map)

    local effectsLimit = areaW - (2 * effectPadding)

    -- Draw Activation Text (Light background -> use BMFont color handled in _drawTextScaled)
    love.graphics.setColor(originalColor) -- Restore original color before drawing (handled by _drawTextScaled)
    local activationTextY = effectsY + effectPadding
    self:_drawTextScaled(activationText, x + margin + effectPadding, activationTextY, effectsLimit, "left", effectStyleName, effectBaseFontSize, targetScale_effect, alphaOverride)

    -- Draw Convergence Text (Dark background -> use BMFont color handled in _drawTextScaled)
    -- No explicit setColor needed here, _drawTextScaled handles tint based on font type
    local convergenceStyleName = "CARD_EFFECT_CONVERGENCE" -- Use the new style for white font
    local convergenceTextY = convergenceBoxY + effectPadding
    self:_drawTextScaled(convergenceText, x + margin + effectPadding, convergenceTextY, effectsLimit, "left", convergenceStyleName, effectBaseFontSize, targetScale_effect, alphaOverride)

    love.graphics.setColor(originalColor) -- Restore original color after drawing text blocks
    -- Draw Connection Ports
    self:drawCardPorts(card, x, y, alphaOverride, context.activeLinks)
end

-- Internal utility function to draw a single card in the world
function Renderer:_drawSingleCardInWorld(card, wx, wy, activeLinks, alphaOverride, useInvalidBorder)
    alphaOverride = alphaOverride or 1.0
    useInvalidBorder = useInvalidBorder or false

    -- Save original color state
    local originalColor = { love.graphics.getColor() }

    -- Draw the pre-rendered card base from cache
    local canvas = self:_generateCardCanvas(card)
    local sf = self.canvasRenderScaleFactor or 1 -- Use new scale factor
    local invSf = 1 / sf
    local borderPadding = self.PORT_RADIUS -- Original units
    -- draw the high-res canvas aligned so the inner content origin matches wx/wy
    local drawX = wx - borderPadding
    local drawY = wy - borderPadding
    love.graphics.setColor(1, 1, 1, alphaOverride)
    love.graphics.draw(canvas, drawX, drawY, 0, invSf, invSf)

    -- Draw invalid border highlight if needed
    if useInvalidBorder then
        local lineWidth = self.PORT_RADIUS * 2
        love.graphics.setLineWidth(lineWidth) -- Use base line width
        love.graphics.setColor(1, 0, 0, alphaOverride)
        -- Draw border relative to the card content box (wx, wy)
        love.graphics.rectangle("line", wx, wy, self.CARD_WIDTH, self.CARD_HEIGHT, 2, 2) -- Use base dimensions
    end

    -- Dynamic: Draw token count on card in world view if > 0
    if card.tokens and card.tokens > 0 then
        love.graphics.setColor(0, 0, 0, alphaOverride)
        -- Use a small UI font for token count
        local fontOld = love.graphics.getFont()
        local tokenFont = self.fonts.uiSmall or fontOld
        love.graphics.setFont(tokenFont)
        -- Position at bottom-left inside card
        love.graphics.print("Tokens: " .. card.tokens, wx + 5, wy + self.CARD_HEIGHT - 15)
        love.graphics.setFont(fontOld)
    end

    -- Draw convergence link tabs for world view
    self:_drawCardConvergenceTabs(card, wx, wy, alphaOverride, activeLinks)

    -- Restore original color state
    love.graphics.setColor(originalColor)
end

-- Extracted method to draw convergence link tabs for world view
function Renderer:_drawCardConvergenceTabs(card, sx, sy, alphaOverride, activeLinks)
    alphaOverride = alphaOverride or 1.0
    activeLinks = activeLinks or {}
    local linkMap = {}
    for _, link in ipairs(activeLinks) do linkMap[link.linkId] = link end
    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    -- use the card radius as offset inside canvas content
    local r = self.PORT_RADIUS
    for portIndex = 1, 8 do
        local info = getPortInfo(portIndex)
        if info then
            -- align to content origin on world canvas
            local portX = sx + info.x_offset
            local portY = sy + info.y_offset
            local isOutput = info.is_output
            local occupyingLinkId = card:getOccupyingLinkId(portIndex)
            if occupyingLinkId then
                -- Draw the base port shape dimmed
                self:_drawSinglePortShape(portIndex, portX, portY, r, alphaOverride * 0.4)
                -- Draw the convergence tab
                local linkDetails = linkMap[occupyingLinkId]
                local playerNumber = linkDetails and linkDetails.initiatingPlayerIndex or "?"
                local tabSize = r * 3.5
                local fixedOffset = r
                local orientation
                if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then orientation = "top"
                elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then orientation = "bottom"
                elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then orientation = "left"
                elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then orientation = "right"
                end
                local tabX, tabY
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
                    local centerX, centerY = portX, portY
                    if isOutput then
                        if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then centerY = portY - r / 2
                        elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then centerY = portY + r / 2
                        elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then centerX = portX - r / 2
                        elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then centerX = portX + r / 2 end
                    end
                    tabX = centerX - tabSize / 2
                    tabY = centerY - tabSize / 2
                end
                love.graphics.setColor(0.9, 0.9, 0.9, alphaOverride * 0.7)
                love.graphics.rectangle("fill", tabX, tabY, tabSize, tabSize)
                love.graphics.setColor(0, 0, 0, alphaOverride)
                love.graphics.rectangle("line", tabX, tabY, tabSize, tabSize)
                love.graphics.setFont(self.fonts.worldSmall or originalFont)
                love.graphics.setColor(0, 0, 0, alphaOverride)
                local text = tostring(playerNumber)
                local textScale = 0.45 / self.worldFontMultiplier
                local nativeW = love.graphics.getFont():getWidth(text)
                local nativeH = love.graphics.getFont():getHeight()
                love.graphics.push()
                love.graphics.translate(tabX + (tabSize - nativeW * textScale) / 2, tabY + (tabSize - nativeH * textScale) / 2)
                love.graphics.scale(textScale, textScale)
                love.graphics.print(text, 0, 0)
                love.graphics.pop()
            end
        end
    end
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

-- Draw a player's network grid, applying camera transform
function Renderer:drawNetwork(network, cameraX, cameraY, cameraZoom, originX, originY, activeLinks, animatingCardIds)
    if not network then return end
    originX = originX or 0
    originY = originY or 0
    animatingCardIds = animatingCardIds or {} -- Ensure it's a table
    local gridCardIds = animatingCardIds.gridCardIds or {} -- Extract grid card IDs

    love.graphics.push()
    love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
    love.graphics.scale(cameraZoom, cameraZoom)
    love.graphics.setLineWidth(1 / cameraZoom)

    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}

    local drawQueue = {}
    for cardId, card in pairs(network.cards) do
        -- Check if the card is currently animating
        if type(card) == "table" and card.position and not animatingCardIds[card.instanceId] then
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
    local originalColor = { love.graphics.getColor() }
    local originalLineWidth = love.graphics.getLineWidth()

    -- Calculate adjusted position to keep preview fully on screen
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local borderWidthOut = self.PORT_RADIUS * scale
    local cardDrawWidth = CARD_WIDTH * scale
    local cardDrawHeight = CARD_HEIGHT * scale
    local drawX = sx
    local drawY = sy
    if drawX - borderWidthOut < 0 then
        drawX = borderWidthOut
    elseif drawX + cardDrawWidth + borderWidthOut > screenWidth then
        drawX = screenWidth - cardDrawWidth - borderWidthOut
    end
    if drawY - borderWidthOut < 0 then
        drawY = borderWidthOut
    elseif drawY + cardDrawHeight + borderWidthOut > screenHeight then
        drawY = screenHeight - cardDrawHeight - borderWidthOut
    end

    -- Draw the cached card canvas scaled down
    local sf = self.canvasRenderScaleFactor or 1 -- Use new scale factor
    local invSf = 1 / sf
    local drawScale = scale * invSf
    local canvas = self:_generateCardCanvas(card)
    local borderPadding = self.PORT_RADIUS -- Original units
    local drawPosX = drawX - borderPadding * drawScale
    local drawPosY = drawY - borderPadding * drawScale
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, drawPosX, drawPosY, 0, drawScale, drawScale)

    -- Restore original state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth)
end

-- Draw a player's hand, visually indicating the selected card
-- Returns a table of bounding boxes for click detection: { { index=i, x=sx, y=sy, w=w, h=h }, ... }
-- cardsBeingAnimated is a table of cards that are in the process of being animated and should be hidden in the hand
function Renderer:drawHand(player, selectedIndex, animatingCardIds)
    if not player or not player.hand then return {} end
    animatingCardIds = animatingCardIds or {} -- Ensure it's a table

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

    -- Adjust for cached canvas resolution (baked at canvasRenderScaleFactor)
    local sf = self.canvasRenderScaleFactor or 1 -- Use new scale factor
    local invSf = 1 / sf

    -- Draw non-selected cards by blitting cached canvas
    for i, card in ipairs(player.hand) do
        if i ~= selectedIndex then
            -- Check if this specific card instance is being animated
            if not animatingCardIds[card.instanceId] then
                local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
                local sy = handStartY
                table.insert(handBounds, { index = i, x = sx, y = sy, w = HAND_CARD_WIDTH, h = HAND_CARD_HEIGHT })

                local canvas = self:_generateCardCanvas(card)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(canvas, sx, sy, 0, HAND_CARD_SCALE * invSf, HAND_CARD_SCALE * invSf)
            end
        end
    end

    -- Draw selected card last (raised and highlighted)
    if selectedIndex then
        local i = selectedIndex
        local card = player.hand[i]
        local sx = HAND_START_X + (i-1) * (HAND_CARD_WIDTH + HAND_SPACING)
        -- Update or insert bounds for selected card at original position
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

        -- Only draw selected card if not currently animating
        if card and not animatingCardIds[card.instanceId] then
            local raisedY = handStartY - SELECTED_CARD_RAISE
            local canvas = self:_generateCardCanvas(card)
            local borderPadding = self.PORT_RADIUS
            local drawScale = HAND_CARD_SCALE * invSf
            local drawPosX = sx - borderPadding * drawScale
            local drawPosY = raisedY - borderPadding * drawScale
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(canvas, drawPosX, drawPosY, 0, drawScale, drawScale)

            -- Draw highlight border
            local canvasDrawW = canvas:getWidth() * drawScale
            local canvasDrawH = canvas:getHeight() * drawScale
            local cornerRadius = 2 * drawScale
            love.graphics.setLineWidth(3 * drawScale)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("line",
                drawPosX, drawPosY,
                canvasDrawW,
                canvasDrawH,
                cornerRadius, cornerRadius)
        end
    end

    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    -- No need to restore line width here, done inside/after loops

    return handBounds
end

-- Draw a single card that is currently animating
function Renderer:drawCardAnimation(animation, cameraX, cameraY, cameraZoom)
    if not animation or not animation.card then return end

    local card = animation.card
    local worldX = animation.currentWorldPos.x
    local worldY = animation.currentWorldPos.y
    local scale = animation.currentScale
    local alpha = animation.currentAlpha or 1.0
    local rotation = animation.currentRotation or 0

    -- Get the pre-rendered canvas
    local canvas = self:_generateCardCanvas(card)
    if not canvas then
        print("Warning: Canvas not found for animating card: " .. card.id)
        return
    end

    -- Apply camera transform
    love.graphics.push()
    love.graphics.translate(-cameraX * cameraZoom, -cameraY * cameraZoom)
    love.graphics.scale(cameraZoom, cameraZoom)
    love.graphics.setLineWidth(1 / cameraZoom) -- Keep line width consistent if drawing borders

    -- Calculate draw parameters similar to drawHoveredHandCard/drawSingleCardInWorld
    local sf = self.canvasRenderScaleFactor or 1
    local invSf = 1 / sf
    local drawScale = scale * invSf -- The final scale to draw the high-res canvas
    local borderPadding = self.PORT_RADIUS -- Original units padding on canvas
    local canvasW = canvas:getWidth()
    local canvasH = canvas:getHeight()

    -- Calculate the top-left draw position based on the *center* world coordinates
    local drawW = canvasW * drawScale
    local drawH = canvasH * drawScale
    
    -- Draw the canvas centered at worldX, worldY with the interpolated scale and rotation
    local originalColor = {love.graphics.getColor()}
    love.graphics.setColor(1, 1, 1, alpha)
    
    -- For rotation, we need to use the origin point (center of the card)
    if rotation ~= 0 then
        -- When using rotation, we need to specify the rotation origin (center of the card)
        -- Draw with rotation around center
        love.graphics.draw(
            canvas,                -- The canvas to draw
            worldX,                -- X position (center)
            worldY,                -- Y position (center)
            rotation,              -- Rotation in radians
            drawScale,             -- X scale
            drawScale,             -- Y scale
            canvasW / 2,           -- Origin X (half canvas width - center point)
            canvasH / 2            -- Origin Y (half canvas height - center point)
        )
    else
        -- No rotation - calculate top-left corner for drawing
        local drawPosX = worldX - (drawW / 2)
        local drawPosY = worldY - (drawH / 2)
        -- Draw call uses top-left corner and scale
        love.graphics.draw(canvas, drawPosX, drawPosY, 0, drawScale, drawScale)
    end
    
    love.graphics.setColor(originalColor)
    love.graphics.pop() -- Restore camera transform
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

-- NEW: Draw Yes/No Prompt Box
-- Draws a modal box with the question and returns bounds for Yes/No buttons
-- Returns: yesBounds {x, y, w, h}, noBounds {x, y, w, h}
function Renderer:drawYesNoPrompt(question)
    local screenW = love.graphics.getWidth()  -- Get current width
    local screenH = love.graphics.getHeight() -- Get current height

    -- Box Appearance
    local boxWidth = screenW * 0.5  -- 50% of screen width
    local boxHeight = screenH * 0.3 -- 30% of screen height
    local boxX = (screenW - boxWidth) / 2
    local boxY = (screenH - boxHeight) / 2
    local padding = 20
    local cornerRadius = 5

    -- Button Appearance
    local buttonWidth = 100
    local buttonHeight = 40
    local buttonGap = 30
    local buttonsTotalWidth = (buttonWidth * 2) + buttonGap
    local buttonStartY = boxY + boxHeight - padding - buttonHeight
    local buttonStartX = boxX + (boxWidth - buttonsTotalWidth) / 2
    local yesButtonX = buttonStartX
    local noButtonX = buttonStartX + buttonWidth + buttonGap

    -- Text Appearance
    local questionFont = self.fonts.uiStandard or love.graphics.getFont()
    local buttonFont = self.fonts.uiStandard or love.graphics.getFont()
    local questionMaxWidth = boxWidth - (2 * padding)
    local questionTextY = boxY + padding

    -- 1. Draw Background Overlay (dim the background)
    local originalColor = {love.graphics.getColor()}
    love.graphics.setColor(0, 0, 0, 0.7) -- Dark semi-transparent overlay
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- 2. Draw Prompt Box Background
    love.graphics.setColor(StyleGuide.PROMPT_BOX_BACKGROUND_COLOR or {0.2, 0.2, 0.25, 1}) -- Use style or fallback
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, cornerRadius, cornerRadius)

    -- 3. Draw Prompt Box Border
    local originalLineWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(2)
    love.graphics.setColor(StyleGuide.PROMPT_BOX_BORDER_COLOR or {0.9, 0.9, 0.9, 1}) -- Use style or fallback
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, cornerRadius, cornerRadius)
    love.graphics.setLineWidth(originalLineWidth)

    -- 4. Draw Question Text
    love.graphics.setFont(questionFont)
    love.graphics.setColor(StyleGuide.PROMPT_BOX_TEXT_COLOR or {1, 1, 1, 1}) -- Use style or fallback
    love.graphics.printf(question or "Confirm?", boxX + padding, questionTextY, questionMaxWidth, "center")

    -- 5. Draw Buttons (Simple Rectangles for now, could use Button class later)
    -- Yes Button
    local yesBounds = { x = yesButtonX, y = buttonStartY, w = buttonWidth, h = buttonHeight }
    love.graphics.setColor(0.3, 0.7, 0.3, 1) -- Greenish
    love.graphics.rectangle("fill", yesBounds.x, yesBounds.y, yesBounds.w, yesBounds.h, cornerRadius, cornerRadius)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", yesBounds.x, yesBounds.y, yesBounds.w, yesBounds.h, cornerRadius, cornerRadius)
    love.graphics.setFont(buttonFont)
    love.graphics.printf("Yes", yesBounds.x, yesBounds.y + (buttonHeight - buttonFont:getHeight()) / 2, buttonWidth, "center")

    -- No Button
    local noBounds = { x = noButtonX, y = buttonStartY, w = buttonWidth, h = buttonHeight }
    love.graphics.setColor(0.7, 0.3, 0.3, 1) -- Reddish
    love.graphics.rectangle("fill", noBounds.x, noBounds.y, noBounds.w, noBounds.h, cornerRadius, cornerRadius)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", noBounds.x, noBounds.y, noBounds.w, noBounds.h, cornerRadius, cornerRadius)
    love.graphics.setFont(buttonFont)
    love.graphics.printf("No", noBounds.x, noBounds.y + (buttonHeight - buttonFont:getHeight()) / 2, buttonWidth, "center")

    -- Restore original color
    love.graphics.setColor(originalColor)

    -- Return the calculated bounds for click detection
    return yesBounds, noBounds
end

function Renderer:_generateCardCanvas(card)
    -- Create a cache key that combines the card definition ID and the instance ID
    local cacheKey = card.id
    
    -- Check if we already have this card in the cache
    if self.cardCache[cacheKey] then 
        return self.cardCache[cacheKey]
    end
    
    -- Render at higher resolution (canvasRenderScaleFactor)
    local sf = self.canvasRenderScaleFactor or 1 -- Use new scale factor
    -- Calculate canvas size including padding for half the border width
    local borderPadding = self.PORT_RADIUS -- Padding needed in sf=1 units
    local canvasPadding = borderPadding * sf
    local baseW, baseH = self.CARD_WIDTH * sf, self.CARD_HEIGHT * sf
    local canvasW, canvasH = baseW + 2 * canvasPadding, baseH + 2 * canvasPadding
    local canvas = love.graphics.newCanvas(canvasW, canvasH, { mipmaps = "auto" })
    canvas:setFilter("linear", "linear", 1) -- Use mipmapping

    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Translate to account for padding before scaling
    love.graphics.translate(canvasPadding, canvasPadding)
    -- Scale drawing so 1:1 coordinates map to sf× size on canvas
    love.graphics.scale(sf, sf) -- Use new scale factor
    local context = {
        stylePrefix = "CARD",
        baseFontSizes = {
            title = self.baseTitleFontSize,
            cost = self.baseSmallFontSize,
            effect = self.baseMiniFontSize,
            artLabel = self.baseStandardFontSize
        },
        targetScales = {
            title = 0.5,
            cost = 0.35,
            effect = 0.25,
            artLabel = 0.416666667
        },
        alpha = 1.0,
        borderType = "normal",
        activeLinks = {}
    }
    self:_drawCardInternal(card, 0, 0, context)
    love.graphics.setCanvas()
    love.graphics.pop()
    self.cardCache[cacheKey] = canvas
    return canvas
end

-- Preload canvases for all cards in a list
function Renderer:preloadCardCanvases(cards)
    for _, card in pairs(cards) do
        self:_generateCardCanvas(card)
    end
end

-- Draw a single card that is currently animating in screen space (for hand cards)
function Renderer:drawHandCardAnimation(animation)
    if not animation or not animation.card or not animation.currentScreenPos then return end

    local card = animation.card
    local screenX = animation.currentScreenPos.x
    local screenY = animation.currentScreenPos.y
    local scale = animation.currentScale
    local alpha = animation.currentAlpha or 1.0
    local rotation = animation.currentRotation or 0

    -- Get the pre-rendered canvas
    local canvas = self:_generateCardCanvas(card)
    if not canvas then
        print("Warning: Canvas not found for animating hand card: " .. card.id)
        return
    end

    -- Calculate draw parameters similar to drawHoveredHandCard
    local sf = self.canvasRenderScaleFactor or 1
    local invSf = 1 / sf
    local drawScale = scale * invSf -- The final scale to draw the high-res canvas
    local borderPadding = self.PORT_RADIUS -- Original units padding on canvas
    local canvasW = canvas:getWidth()
    local canvasH = canvas:getHeight()

    -- For rotation, we need to work with the center of the card
    local drawW = canvasW * drawScale
    local drawH = canvasH * drawScale
    
    -- Draw the canvas centered at screenX, screenY with the interpolated scale and rotation
    local originalColor = {love.graphics.getColor()}
    love.graphics.setColor(1, 1, 1, alpha)
    
    if rotation ~= 0 then
        -- When using rotation, we need to specify the rotation origin (center of the card)
        love.graphics.draw(
            canvas,                -- The canvas to draw
            screenX,               -- X position (center)
            screenY,               -- Y position (center)
            rotation,              -- Rotation in radians
            drawScale,             -- X scale
            drawScale,             -- Y scale
            canvasW / 2,           -- Origin X (half canvas width - center point)
            canvasH / 2            -- Origin Y (half canvas height - center point)
        )
    else
        -- No rotation - calculate top-left corner for drawing
        local drawPosX = screenX - (drawW / 2)
        local drawPosY = screenY - (drawH / 2)
        -- Draw call uses top-left corner and scale
        love.graphics.draw(canvas, drawPosX, drawPosY, 0, drawScale, drawScale)
    end
    
    love.graphics.setColor(originalColor)
end

return Renderer
