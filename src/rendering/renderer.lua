-- src/rendering/renderer.lua
-- Handles drawing the game state to the screen.

-- Safeguard love global to support tests outside LÖVE environment
if type(love) ~= 'table' then love = {} end
love.graphics = love.graphics or {}
love.graphics.getWidth = love.graphics.getWidth or function() return 0 end
love.graphics.getHeight = love.graphics.getHeight or function() return 0 end
love.graphics.getFont = love.graphics.getFont or function() return { setFilter = function() end, getHeight = function() return 16 end, getWidth = function() return 0 end } end
love.graphics.newFont = love.graphics.newFont or function(...) return love.graphics.getFont() end
love.filesystem = love.filesystem or {}
love.filesystem.getInfo = love.filesystem.getInfo or function() return false end

local Card = require('src.game.card') -- Needed for Card.Ports constants
local StyleGuide = require('src.rendering.styles') -- Load the styles
local PortRenderer = require('src.rendering.port_renderer') -- After loading StyleGuide, require the new PortRenderer
local CardRenderer = require('src.rendering.card_renderer') -- Extracted card drawing logic

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
    -- Expose card/hand constants for CardRenderer
    instance.HAND_CARD_SCALE = HAND_CARD_SCALE
    instance.HAND_SPACING = HAND_SPACING
    instance.HAND_START_X = HAND_START_X
    instance.BOTTOM_BUTTON_AREA_HEIGHT = BOTTOM_BUTTON_AREA_HEIGHT
    instance.SELECTED_CARD_RAISE = SELECTED_CARD_RAISE
    instance.CARD_COST_ICON_SIZE = CARD_COST_ICON_SIZE

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
    -- Use LÖVE's default font
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
    instance.cardRenderer = CardRenderer:new(instance)

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
            titleFont:setFilter('linear', 'linear')
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
            bmFont:setFilter('linear', 'linear')

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
                    bmFontWhite:setFilter('linear', 'linear')
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

-- NEW: Get player color based on ID
function Renderer:getPlayerColor(playerId)
    local colors = {
        {1, 0, 0, 1},    -- 1: Red
        {0, 0, 1, 1},    -- 2: Blue
        {1, 1, 0, 1},    -- 3: Yellow
        {0, 1, 0, 1},    -- 4: Green
        {0.5, 0, 0.5, 1} -- 5: Purple
    }
    return colors[playerId] or {0.7, 0.7, 0.7, 1} -- Default to Gray if ID out of range
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

-- Delegate to PortRenderer for port hit-testing
function Renderer:getPortAtWorldPos(network, localX, localY)
    return PortRenderer.getPortAtLocalPos(self, network, localX, localY)
end

-- Helper function to draw the 8 connection ports for a card
function Renderer:drawCardPorts(card, sx, sy, alphaOverride, activeLinks)
    PortRenderer.drawCardPorts(self, card, sx, sy, alphaOverride, activeLinks)
end

-- Draws the player's network grid
function Renderer:drawNetwork(network, originX, originY, activeLinks, animatingCardIds)
    if not network then
        print("Warning: drawNetwork called with nil network.")
        return
    end
    
    local playerColor = network.owner and self:getPlayerColor(network.owner.id) or {1, 1, 1, 1}

    -- Set base color for the network (slightly dimmed based on player color)
    love.graphics.setColor(playerColor[1] * 0.8, playerColor[2] * 0.8, playerColor[3] * 0.8, 0.6)
    
    -- Store original line width
    local originalLineWidth = love.graphics.getLineWidth()

    -- Apply the origin translation for this network
    love.graphics.push()
    love.graphics.translate(originX, originY)

    -- Draw cards within the network
    if network.cards then
        for _, card in pairs(network.cards) do
            local cardShouldRender = true
            if animatingCardIds and card.id and animatingCardIds[card.id] then
                -- Don't render cards that are part of a world-space animation (like card play)
                -- because they will be rendered separately by the animation system.
                cardShouldRender = false
            end
            
            if cardShouldRender then
                self.cardRenderer:drawCard(card, originX, originY, activeLinks)
            end
        end
    end

    -- Restore camera transform if it was applied locally
    -- [[ REMOVED
    -- love.graphics.pop() -- This was the original line causing the pop
    -- ]]
    
    -- Restore origin translation
    love.graphics.pop()

    -- Restore original line width and color
    love.graphics.setLineWidth(originalLineWidth)
    love.graphics.setColor(1,1,1,1) -- Reset color to white
end

-- Draw a single card within a network grid
function Renderer:drawCard(card, originX, originY, activeLinks, animatingCardIds)
    -- Delegate to CardRenderer
    return self.cardRenderer:drawCard(card, originX, originY, activeLinks, animatingCardIds)
end

-- Draw highlight / card preview over the hovered grid cell, or red outline if invalid
function Renderer:drawHoverHighlight(gridX, gridY, selectedCard, isPlacementValid, originX, originY, orientation)
    -- Delegate to CardRenderer
    return self.cardRenderer:drawHoverHighlight(gridX, gridY, selectedCard, isPlacementValid, originX, originY, orientation)
end

-- Function to draw a hand card preview
function Renderer:drawHoveredHandCard(card, sx, sy, scale)
    -- Delegate to CardRenderer
    return self.cardRenderer:drawHoveredHandCard(card, sx, sy, scale)
end

-- Draw a player's hand, visually indicating the selected card
-- Returns a table of bounding boxes for click detection: { { index=i, x=sx, y=sy, w=w, h=h }, ... }
-- cardsBeingAnimated is a table of cards that are in the process of being animated and should be hidden in the hand
function Renderer:drawHand(player, selectedIndex, animatingCardIds)
    -- Delegate to CardRenderer
    return self.cardRenderer:drawHand(player, selectedIndex, animatingCardIds)
end

-- Draw a single card that is currently animating
function Renderer:drawCardAnimation(animation)
    -- Delegate to CardRenderer
    return self.cardRenderer:drawCardAnimation(animation)
end

-- Draw a single card that is currently animating in screen space (for hand cards)
function Renderer:drawHandCardAnimation(animation)
    -- Delegate to CardRenderer
    return self.cardRenderer:drawHandCardAnimation(animation)
end

-- Preload canvases for all cards in a list
function Renderer:preloadCardCanvases(cards)
    -- Delegate to CardRenderer
    return self.cardRenderer:preloadCardCanvases(cards)
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
        local bgColor = self.styleGuide.PORT_COLORS[linkType] or {0.5, 0.5, 0.5, 1} -- Use PORT_COLORS from StyleGuide
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
function Renderer:drawYesNoPrompt(question, displayOptions)
    local screenW = love.graphics.getWidth()  -- Get current width
    local screenH = love.graphics.getHeight() -- Get current height
    
    displayOptions = displayOptions or {}
    local showCard = displayOptions.showCard
    local desiredCardScale = displayOptions.cardScale or 2.0 -- Keep the desired scale
    local highlightEffect = displayOptions.highlightEffect
    local sourceNode = displayOptions.sourceNode

    -- Box Appearance
    local boxWidth = screenW * 0.5  -- 50% of screen width
    local boxHeight = screenH * 0.4 -- 40% of screen height (might need adjustment)
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
    local questionTextHeight = questionFont:getHeight() -- Get height for layout

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
    
    -- 5. Draw the Card if requested and available
    if showCard and sourceNode and sourceNode.card then
        -- Calculate available space for the card
        local availableHeight = buttonStartY - (questionTextY + questionTextHeight) - (2 * padding)
        local availableWidth = boxWidth - (2 * padding)
        
        -- Calculate maximum scale based on available space
        local maxScaleHeight = availableHeight / self.CARD_HEIGHT
        local maxScaleWidth = availableWidth / self.CARD_WIDTH
        local maxScale = math.min(maxScaleHeight, maxScaleWidth)
        
        -- Use the smaller of desired scale and max possible scale
        local finalCardScale = math.min(desiredCardScale, maxScale)
        
        -- Recalculate card dimensions and position based on final scale
        local cardWidth = self.CARD_WIDTH * finalCardScale
        local cardHeight = self.CARD_HEIGHT * finalCardScale
        local cardX = boxX + (boxWidth - cardWidth) / 2
        local cardY = questionTextY + questionTextHeight + padding + (availableHeight - cardHeight) / 2 -- Center vertically in available space
        
        -- Get the pre-rendered canvas for the card
        local canvas = self.cardRenderer:_generateCardCanvas(sourceNode.card)
        if canvas then
            -- Save current state
            local originalFont = love.graphics.getFont()
            local originalColor = {love.graphics.getColor()}
            
            -- Draw the cached canvas at the desired scale and position
            local sf = self.canvasRenderScaleFactor or 1
            local invSf = 1 / sf
            local drawScale = finalCardScale * invSf -- Final scale to draw the high-res canvas
            local borderPadding = self.PORT_RADIUS -- Original units padding on canvas
            local canvasW = canvas:getWidth()
            local canvasH = canvas:getHeight()
            local drawW = canvasW * drawScale
            local drawH = canvasH * drawScale
            
            -- Calculate top-left draw position (relative to card content box, not canvas edge)
            local drawPosX = cardX
            local drawPosY = cardY
            
            love.graphics.setColor(1, 1, 1, 1) -- Ensure full alpha for the canvas
            love.graphics.draw(canvas, drawPosX - (borderPadding * drawScale), drawPosY - (borderPadding*drawScale), 0, drawScale, drawScale)
            
            -- Optionally draw a highlight border or effect
            if highlightEffect then
                 love.graphics.setLineWidth(2)
                 love.graphics.setColor(1, 1, 0, 0.8) -- Yellow highlight
                 love.graphics.rectangle("line", drawPosX - (borderPadding * drawScale), drawPosY- (borderPadding*drawScale), drawW, drawH)
                 love.graphics.setLineWidth(1)
            end
            
            -- Restore state
            love.graphics.setFont(originalFont)
            love.graphics.setColor(originalColor)
        else
            print(string.format("Warning: Could not get canvas for card '%s' in prompt.", sourceNode.card.id))
            -- Optionally draw a fallback placeholder if canvas fails
            love.graphics.setColor(1, 0, 0, 0.5) -- Red semi-transparent placeholder
            love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight)
        end
    end

    -- 6. Draw Buttons (Simple Rectangles for now, could use Button class later)
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

-- Add a new wrapper to draw all player tables with rotation
function Renderer:drawTable(players, localPlayerIndex, activeLinks, animatingCardIds, highlightBox, cameraZoom, playerWorldOrigins)
    if not playerWorldOrigins then
        print("Error: playerWorldOrigins not provided to drawTable!")
        return
    end

    for i, player in ipairs(players) do
        local worldOrigin = playerWorldOrigins[i]
        if not worldOrigin then
            print(string.format("Warning: Missing world origin for player %d", i))
            goto continue_loop -- Skip drawing this player if origin is missing
        end

        love.graphics.push() -- Push for individual player transform

        -- 1. Translate to the player's fixed world origin
        love.graphics.translate(worldOrigin.x, worldOrigin.y)
        
        -- 2. Apply local rotation around the center of the (0,0) grid cell
        local cardCenterX = self.CARD_WIDTH / 2
        local cardCenterY = self.CARD_HEIGHT / 2
        love.graphics.translate(cardCenterX, cardCenterY) -- Move pivot to card center
        love.graphics.rotate(player.orientation or 0)      -- Rotate
        love.graphics.translate(-cardCenterX, -cardCenterY) -- Move pivot back

        -- 3. Draw the network relative to (0,0) in this translated/rotated frame
        self:drawNetwork(player.network,
                         0, 0, -- Network draws relative to (0,0) after transforms
                         activeLinks, animatingCardIds)

        -- 4. Draw Highlight Box if this is the local player
        if i == localPlayerIndex and highlightBox then
            -- Box coordinates are relative to the player's (0,0) origin before local rotation
            -- Draw them directly here, the transforms above place them correctly.
            local originalLineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(4 / (cameraZoom or 1.0)) -- Use passed cameraZoom
            love.graphics.setColor(1, 1, 0, 0.7) -- Yellow, slightly transparent
            love.graphics.rectangle("line", highlightBox.x, highlightBox.y, highlightBox.w, highlightBox.h)
            love.graphics.setLineWidth(originalLineWidth)
        end

        love.graphics.pop() -- Pop individual player transform
        
        ::continue_loop::
    end
end

-- Add inverse rotation helper for input mapping: convert screen coords to network-local screen coords
function Renderer:screenToNetworkLocal(sx, sy, player, allPlayers, localPlayerIndex)
    -- Invert the rotation applied in drawTable for the player's network
    if not player or not player.orientation or player.orientation == 0 then
        return sx, sy
    end
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cx, cy = screenW / 2, screenH / 2
    -- Translate to center
    local dx = sx - cx
    local dy = sy - cy
    -- Rotate by inverse of orientation
    local angle = -player.orientation
    local cosA, sinA = math.cos(angle), math.sin(angle)
    local rx = dx * cosA - dy * sinA
    local ry = dx * sinA + dy * cosA
    -- Translate back
    return rx + cx, ry + cy
end

return Renderer
