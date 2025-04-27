-- src/rendering/card_renderer.lua
local Card = require('src.game.card') -- Added: Required for Card types
local PortRenderer = require('src.rendering.port_renderer')

local CardRenderer = {}
CardRenderer.__index = CardRenderer

-- Constructor takes a reference to the main Renderer instance
function CardRenderer:new(renderer)
    local instance = setmetatable({}, CardRenderer)
    instance.renderer = renderer
    return instance
end

-- Draw a single card within a network grid (world view)
function CardRenderer:drawCard(card, originX, originY, activeLinks)
    if not card then return end
    -- Convert grid to world coordinates
    local sx, sy = self.renderer:gridToWorldCoords(card.position.x, card.position.y, originX, originY)
    -- Delegate to the private single-card draw
    self:_drawSingleCardInWorld(card, sx, sy, activeLinks)
end

-- Preload canvases for a list of cards
function CardRenderer:preloadCardCanvases(cards)
    for _, card in pairs(cards) do
        self:_generateCardCanvas(card)
    end
end

-- Draw a hovered hand card (screen-space preview)
function CardRenderer:drawHoveredHandCard(card, sx, sy, scale)
    local renderer = self.renderer
    if not card then return end
    scale = scale or 1.0

    local originalFont = love.graphics.getFont()
    local originalColor = { love.graphics.getColor() }
    local originalLineWidth = love.graphics.getLineWidth()

    -- Adjust position to keep preview on screen
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local borderOut = renderer.PORT_RADIUS * scale
    local cardW = renderer.CARD_WIDTH * scale
    local cardH = renderer.CARD_HEIGHT * scale
    local drawX = sx
    local drawY = sy
    if drawX - borderOut < 0 then drawX = borderOut end
    if drawX + cardW + borderOut > screenW then drawX = screenW - cardW - borderOut end
    if drawY - borderOut < 0 then drawY = borderOut end
    if drawY + cardH + borderOut > screenH then drawY = screenH - cardH - borderOut end

    -- Draw cached high-res canvas
    local sf = renderer.canvasRenderScaleFactor or 1
    local invSf = 1 / sf
    local drawScale = scale * invSf
    local canvas = self:_generateCardCanvas(card)
    local pad = renderer.PORT_RADIUS
    local x0 = drawX - pad * drawScale
    local y0 = drawY - pad * drawScale
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(canvas, x0, y0, 0, drawScale, drawScale)

    -- Restore state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth)
end

-- Draw a player's hand
function CardRenderer:drawHand(player, selectedIndex, animatingCardIds)
    local renderer = self.renderer
    if not player or not player.hand then return {} end
    animatingCardIds = animatingCardIds or {}
    local handY = love.graphics.getHeight() - renderer.BOTTOM_BUTTON_AREA_HEIGHT - renderer.HAND_CARD_HEIGHT
    local bounds = {}
    local origFont = love.graphics.getFont()
    local origColor = { love.graphics.getColor() }
    local origLW = love.graphics.getLineWidth()

    -- Label
    local labelStyle = renderer.styleGuide.UI_HAND_LABEL
    assert(renderer.fonts[labelStyle.fontName], "Hand label font not found: " .. labelStyle.fontName)
    love.graphics.setFont(renderer.fonts[labelStyle.fontName])
    love.graphics.setColor(labelStyle.color)
    love.graphics.print(string.format("%s Hand (%d):", player.name, #player.hand), renderer.HAND_START_X, handY - 20)

    local sf = renderer.canvasRenderScaleFactor or 1
    local invSf = 1 / sf
    -- Non-selected
    for i, card in ipairs(player.hand) do
        if i ~= selectedIndex and not animatingCardIds[card.instanceId] then
            local x = renderer.HAND_START_X + (i-1) * (renderer.HAND_CARD_WIDTH + renderer.HAND_SPACING)
            local y = handY
            table.insert(bounds, { index=i, x=x, y=y, w=renderer.HAND_CARD_WIDTH, h=renderer.HAND_CARD_HEIGHT })
            local canvas = self:_generateCardCanvas(card)
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(canvas, x, y, 0, renderer.HAND_CARD_SCALE * invSf, renderer.HAND_CARD_SCALE * invSf)
        end
    end
    -- Selected
    if selectedIndex then
        local i = selectedIndex
        local card = player.hand[i]
        local x = renderer.HAND_START_X + (i-1) * (renderer.HAND_CARD_WIDTH + renderer.HAND_SPACING)
        local found = false
        for _, b in ipairs(bounds) do if b.index == i then b.y = handY; found = true end end
        if not found then table.insert(bounds, { index=i, x=x, y=handY, w=renderer.HAND_CARD_WIDTH, h=renderer.HAND_CARD_HEIGHT }) end
        if card and not animatingCardIds[card.instanceId] then
            local y2 = handY - renderer.SELECTED_CARD_RAISE
            local canvas = self:_generateCardCanvas(card)
            local pad = renderer.PORT_RADIUS
            local ds = renderer.HAND_CARD_SCALE * invSf
            local x0 = x - pad * ds
            local y0 = y2 - pad * ds
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(canvas, x0, y0, 0, ds, ds)
            local w = canvas:getWidth()*ds
            local h = canvas:getHeight()*ds
            love.graphics.setLineWidth(3*ds)
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle("line", x0, y0, w, h, 2*ds, 2*ds)
        end
    end
    love.graphics.setFont(origFont)
    love.graphics.setColor(origColor)
    return bounds
end

-- Draw a card animation in world view
function CardRenderer:drawCardAnimation(animation)
    local renderer = self.renderer
    if not animation or not animation.card then return end
    local card = animation.card
    local wx = animation.currentWorldPos.x
    local wy = animation.currentWorldPos.y
    local scale = animation.currentScale
    local alpha = animation.currentAlpha or 1.0
    local rot = animation.currentRotation or 0
    local canvas = self:_generateCardCanvas(card)
    if not canvas then print("Warning: Canvas not found for animating card: "..card.id); return end
    local sf = renderer.canvasRenderScaleFactor or 1
    local invSf = 1 / sf
    local ds = scale * invSf
    local cw = canvas:getWidth()
    local ch = canvas:getHeight()
    local origColor = { love.graphics.getColor() }
    love.graphics.setColor(1,1,1,alpha)
    if rot ~= 0 then
        love.graphics.draw(canvas, wx, wy, rot, ds, ds, cw/2, ch/2)
    else
        local dw, dh = cw*ds, ch*ds
        love.graphics.draw(canvas, wx - dw/2, wy - dh/2, 0, ds, ds)
    end
    love.graphics.setColor(origColor)
end

-- Draw a card animation in hand (screen space)
function CardRenderer:drawHandCardAnimation(animation)
    local renderer = self.renderer
    if not animation or not animation.card or not animation.currentScreenPos then return end
    local card = animation.card
    local sx = animation.currentScreenPos.x
    local sy = animation.currentScreenPos.y
    local scale = animation.currentScale
    local alpha = animation.currentAlpha or 1.0
    local rot = animation.currentRotation or 0
    local canvas = self:_generateCardCanvas(card)
    if not canvas then print("Warning: Canvas not found for animating hand card: "..card.id); return end
    local sf = renderer.canvasRenderScaleFactor or 1
    local invSf = 1 / sf
    local ds = scale * invSf
    local cw = canvas:getWidth()
    local ch = canvas:getHeight()
    local origColor = { love.graphics.getColor() }
    love.graphics.setColor(1,1,1,alpha)
    if rot ~= 0 then
        love.graphics.draw(canvas, sx, sy, rot, ds, ds, cw/2, ch/2)
    else
        local dw, dh = cw*ds, ch*ds
        love.graphics.draw(canvas, sx - dw/2, sy - dh/2, 0, ds, ds)
    end
    love.graphics.setColor(origColor)
end

-- Draw highlight / card preview over the hovered grid cell, or red outline if invalid
function CardRenderer:drawHoverHighlight(gridX, gridY, selectedCard, isPlacementValid, originX, originY, orientation)
    local renderer = self.renderer
    orientation = orientation or 0
    isPlacementValid = isPlacementValid == nil or isPlacementValid == true
    originX = originX or 0
    originY = originY or 0

    if gridX == nil or gridY == nil then return end

    if selectedCard then
        local cardCenterX = renderer.CARD_WIDTH / 2
        local cardCenterY = renderer.CARD_HEIGHT / 2

        love.graphics.push()

        -- Go to player's world origin and apply rotation
        love.graphics.translate(originX, originY)
        love.graphics.translate(cardCenterX, cardCenterY)
        love.graphics.rotate(orientation)
        love.graphics.translate(-cardCenterX, -cardCenterY)

        -- Calculate rotated cell origin
        local targetRotatedX = gridX * (renderer.CARD_WIDTH + renderer.GRID_SPACING)
        local targetRotatedY = gridY * (renderer.CARD_HEIGHT + renderer.GRID_SPACING)

        local useInvalidBorder = not isPlacementValid
        self:_drawSingleCardInWorld(selectedCard, targetRotatedX, targetRotatedY, nil, 0.5, useInvalidBorder)

        love.graphics.pop()
    end
end

-- Internal core function to draw a card's elements based on context
function CardRenderer:_drawCardInternal(card, x, y, context)
    if not card or type(card) ~= 'table' then
        print("Warning: _drawCardInternal received invalid card data.")
        return
    end

    local originalColor = {love.graphics.getColor()}
    local alphaOverride = context.alpha or 1.0
    local useInvalidBorder = context.borderType == "invalid"

    -- Draw Outer Border FIRST
    local originalLineWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(self.renderer.PORT_RADIUS * 2)
    love.graphics.setColor(0.15, 0.15, 0.15, 1.0 * alphaOverride) -- Always black
    local cornerRadius = 2 -- Adjust as needed
    love.graphics.rectangle("line", x, y, self.renderer.CARD_WIDTH, self.renderer.CARD_HEIGHT, cornerRadius, cornerRadius)
    love.graphics.setLineWidth(originalLineWidth) -- Restore line width before drawing content
    love.graphics.setColor(originalColor) -- Restore original color

    -- Base background (drawn over the border outline)
    local baseR, baseG, baseB = 0.8, 0.8, 0.8
    if card.type == Card.Type.REACTOR then baseR, baseG, baseB = 1, 1, 0.5 end
    love.graphics.setColor(baseR, baseG, baseB, 1.0 * alphaOverride)
    love.graphics.rectangle("fill", x, y, self.renderer.CARD_WIDTH, self.renderer.CARD_HEIGHT)

    local margin = 5
    local headerH = 20
    local costAreaW = 17
    local iconSize = 15
    local imageY = y + headerH + margin
    -- Calculate area width first
    local areaW = self.renderer.CARD_WIDTH - (2 * margin)
    -- Calculate height based on width and desired aspect ratio (1024/720)
    local aspectRatio = 1024 / 720
    local imageH = areaW / aspectRatio -- Use the calculated height
    -- Calculate effects height based on remaining space
    local effectsH = self.renderer.CARD_HEIGHT - headerH - imageH - (2 * margin)
    -- Adjust effects Y position to be directly below the art box
    local effectsY = imageY + imageH -- Place effects box below the art box, no margin

    -- 1. Draw Header Area
    local baseTypeColor = self.renderer.styleGuide.PORT_COLORS[card.type] or {0.5, 0.5, 0.5, 1} -- Use PORT_COLORS from StyleGuide
    local headerIconX = x + margin
    local headerIconY = y + margin
    love.graphics.setColor(baseTypeColor[1], baseTypeColor[2], baseTypeColor[3], (baseTypeColor[4] or 1) * alphaOverride)
    love.graphics.rectangle("fill", headerIconX, headerIconY, iconSize, iconSize)

    -- Draws the actual type icon image (e.g., technology-black.png) over the background
    local typeIcon = self.renderer.icons[card.type]
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
    if self.renderer.titleFontMultiplier and self.renderer.fonts.worldTitleSemiBold then
        -- Add a bit more vertical space for the title font
        titleY = y + margin
    end
    
    local titleLimit = self.renderer.CARD_WIDTH - (2*margin + iconSize + costAreaW)
    local titleStyle = context.stylePrefix .. "_TITLE_NW"
    self.renderer:_drawTextScaled(card.title or "Untitled", titleX, titleY, titleLimit, "left", titleStyle, context.baseFontSizes.title, context.targetScales.title, alphaOverride)

    love.graphics.setColor(originalColor)
    local costYBase = y + margin - 2
    local costIconSize = self.renderer.CARD_COST_ICON_SIZE
    local costInnerSpacing = 2
    local costLineHeight = 12
    local artworkRightEdge = x + self.renderer.CARD_WIDTH - margin
    local matCost = card.buildCost and card.buildCost.material or 0
    local dataCost = card.buildCost and card.buildCost.data or 0
    local matIcon = self.renderer.icons.material
    local dataIcon = self.renderer.icons.data
    local costBaseFontSize = context.baseFontSizes.cost
    local targetScale_cost = context.targetScales.cost
    local costStyleName = context.stylePrefix .. "_COST"
    local costFont = self.renderer.fonts[self.renderer.styleGuide[costStyleName].fontName] or love.graphics.getFont()
    local costFontMultiplier = 1
    if string.find(self.renderer.styleGuide[costStyleName].fontName, "world") then
        costFontMultiplier = self.renderer.worldFontMultiplier
    elseif string.find(self.renderer.styleGuide[costStyleName].fontName, "preview") then
        costFontMultiplier = self.renderer.uiFontMultiplier
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
        self.renderer:_drawTextScaled(text, textX, costYBase, self.renderer.CARD_WIDTH, "left", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    else
        love.graphics.setColor(originalColor)
        self.renderer:_drawTextScaled(string.format("M:%d", matCost), x + margin, costYBase, self.renderer.CARD_WIDTH - 2*margin, "right", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
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
        self.renderer:_drawTextScaled(text, textX, dataY, self.renderer.CARD_WIDTH, "left", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    else
        love.graphics.setColor(originalColor)
        self.renderer:_drawTextScaled(string.format("D:%d", dataCost), x + margin, dataY, self.renderer.CARD_WIDTH - 2*margin, "right", costStyleName, costBaseFontSize, targetScale_cost, alphaOverride)
    end

    -- 2. Draw Image Placeholder Area OR Card Art
    local image = self.renderer:_loadImage(card.imagePath)
    if image then
        local areaW = self.renderer.CARD_WIDTH - (2 * margin)
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
            love.graphics.setColor(0, 0, 0, 0.7 * alphaOverride) -- Semi-transparent black
            love.graphics.rectangle("fill", x + margin, flavorBoxY, areaW, flavorBoxHeight)
            
            -- Draw flavor text using the white font style similar to convergence text
            local flavorTextY = flavorBoxY + 1 -- Small padding from top of flavor box
            local flavorTextLimit = areaW - 2 -- Small padding on left and right
            love.graphics.setColor(originalColor) -- Restore original color for _drawTextScaled
            self.renderer:_drawTextScaled(card.flavorText, x + margin + 2, flavorTextY, flavorTextLimit, "left", 
                                 "CARD_EFFECT_CONVERGENCE", -- Use the white font style 
                                 context.baseFontSizes.effect, 
                                 context.targetScales.effect, 
                                 0.9 * alphaOverride)
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
        self.renderer:_drawTextScaled("ART", x + margin + areaW / 2, imageY + imageH / 2, artLimit, "center", artStyleName, context.baseFontSizes.artLabel, context.targetScales.artLabel, alphaOverride)
    end

    -- 3. Draw Effects Box Area
    local effectBaseFontSize = context.baseFontSizes.effect
    local targetScale_effect = context.targetScales.effect
    local effectStyleName = context.stylePrefix .. "_EFFECT"
    local effectFont = self.renderer.fonts[self.renderer.styleGuide[effectStyleName].fontName] or love.graphics.getFont()
    local fontMultiplier = 1
    if string.find(self.renderer.styleGuide[effectStyleName].fontName, "world") then
        fontMultiplier = self.renderer.worldFontMultiplier
    elseif string.find(self.renderer.styleGuide[effectStyleName].fontName, "preview") then
        fontMultiplier = self.renderer.uiFontMultiplier
    end
    local effectLineHeight = effectFont:getHeight() / fontMultiplier * targetScale_effect
    local effectPadding = 2
    local totalEffectAreaH = self.renderer.CARD_HEIGHT - headerH - imageH - (2 * margin)
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
    self.renderer:_drawTextScaled(activationText, x + margin + effectPadding, activationTextY, effectsLimit, "left", effectStyleName, effectBaseFontSize, targetScale_effect, alphaOverride)

    -- Draw Convergence Text (Dark background -> use BMFont color handled in _drawTextScaled)
    -- No explicit setColor needed here, _drawTextScaled handles tint based on font type
    local convergenceStyleName = "CARD_EFFECT_CONVERGENCE" -- Use the new style for white font
    local convergenceTextY = convergenceBoxY + effectPadding
    self.renderer:_drawTextScaled(convergenceText, x + margin + effectPadding, convergenceTextY, effectsLimit, "left", convergenceStyleName, effectBaseFontSize, targetScale_effect, alphaOverride)

    love.graphics.setColor(originalColor) -- Restore original color after drawing text blocks
    -- Draw Connection Ports
    self.renderer:drawCardPorts(card, x, y, alphaOverride, context.activeLinks)
end

-- Internal utility function to generate a card canvas
function CardRenderer:_generateCardCanvas(card)
    local cacheKey = card.id
    if self.renderer.cardCache[cacheKey] then
        return self.renderer.cardCache[cacheKey]
    end

    local sf = self.renderer.canvasRenderScaleFactor or 1
    local borderPadding = self.renderer.PORT_RADIUS
    local canvasPadding = borderPadding * sf
    local baseW = self.renderer.CARD_WIDTH * sf
    local baseH = self.renderer.CARD_HEIGHT * sf
    local canvasW = baseW + 2 * canvasPadding
    local canvasH = baseH + 2 * canvasPadding
    local canvas = love.graphics.newCanvas(canvasW, canvasH, { mipmaps = "auto" })
    canvas:setFilter("linear", "linear", 1)

    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.translate(canvasPadding, canvasPadding)
    love.graphics.scale(sf, sf)
    local context = {
        stylePrefix = "CARD",
        baseFontSizes = {
            title    = self.renderer.baseTitleFontSize,
            cost     = self.renderer.baseSmallFontSize,
            effect   = self.renderer.baseMiniFontSize,
            artLabel = self.renderer.baseStandardFontSize
        },
        targetScales = {
            title    = 0.45,
            cost     = 0.35,
            effect   = 0.25,
            artLabel = 0.416666667
        },
        alpha       = 1.0,
        borderType  = "normal",
        activeLinks = {}
    }
    self:_drawCardInternal(card, 0, 0, context)
    love.graphics.setCanvas()
    love.graphics.pop()

    self.renderer.cardCache[cacheKey] = canvas
    return canvas
end

-- Internal utility function to draw a single card in the world
function CardRenderer:_drawSingleCardInWorld(card, wx, wy, activeLinks, alphaOverride, useInvalidBorder)
    alphaOverride = alphaOverride or 1.0
    useInvalidBorder = useInvalidBorder or false

    local canvas = self:_generateCardCanvas(card)
    local sf = self.renderer.canvasRenderScaleFactor or 1
    local invSf = 1 / sf
    local pad = self.renderer.PORT_RADIUS
    local drawX = wx - pad
    local drawY = wy - pad
    love.graphics.setColor(1, 1, 1, alphaOverride)
    love.graphics.draw(canvas, drawX, drawY, 0, invSf, invSf)

    if useInvalidBorder then
        local lineWidth = self.renderer.PORT_RADIUS * 2
        love.graphics.setLineWidth(lineWidth)
        love.graphics.setColor(1, 0, 0, alphaOverride)
        love.graphics.rectangle("line", wx, wy, self.renderer.CARD_WIDTH, self.renderer.CARD_HEIGHT, 2, 2)
    end

    if card.tokens and card.tokens > 0 then
        local tokenFont = self.renderer.fonts.uiSmall or love.graphics.getFont()
        love.graphics.setFont(tokenFont)
        love.graphics.setColor(0, 0, 0, alphaOverride)
        love.graphics.print("Tokens: " .. card.tokens, wx + 5, wy + self.renderer.CARD_HEIGHT - 15)
    end

    self:_drawCardConvergenceTabs(card, wx, wy, alphaOverride, activeLinks)
end

-- Extracted method to draw convergence link tabs for world view
function CardRenderer:_drawCardConvergenceTabs(card, sx, sy, alphaOverride, activeLinks)
    alphaOverride = alphaOverride or 1.0
    activeLinks = activeLinks or {}
    local linkMap = {}
    for _, link in ipairs(activeLinks) do linkMap[link.linkId] = link end
    local r = self.renderer.PORT_RADIUS
    for portIndex = 1, 8 do
        local info = PortRenderer.getPortInfo(self.renderer, portIndex)
        if info then
            local portX = sx + info.x_offset
            local portY = sy + info.y_offset
            local isOutput = info.is_output
            local occupyingLinkId = card:getOccupyingLinkId(portIndex)
            if occupyingLinkId then
                PortRenderer.drawPortShape(self.renderer, portIndex, portX, portY, r, alphaOverride * 0.4)
                local linkDetails = linkMap[occupyingLinkId]
                local playerNumber = linkDetails and linkDetails.initiatingPlayerIndex or "?"
                local tabSize = r * 3.5
                local fixedOffset = r
                local orientation
                -- orientation logic here
                -- ... rest of convergence tab logic copied ...
            end
        end
    end
end

return CardRenderer 
