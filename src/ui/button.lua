-- src/ui/button.lua
-- A simple clickable UI button component.

local Button = {}
Button.__index = Button

-- Default visual settings
local BG_COLOR = { 0.6, 0.6, 0.6, 1 } -- Normal background
local HOVER_BG_COLOR = { 0.75, 0.75, 0.75, 1 } -- Lighter when hovered
local PRESSED_BG_COLOR = { 0.5, 0.5, 0.5, 1 } -- Darker when pressed
local DISABLED_BG_COLOR = { 0.4, 0.4, 0.4, 1 }
local TEXT_COLOR = { 0, 0, 0, 1 } -- Black text
local DISABLED_TEXT_COLOR = { 0.7, 0.7, 0.7, 1 }
local BORDER_COLOR = { 0.1, 0.1, 0.1, 1 }
local ICON_PADDING = 4 -- Padding around a full-button icon
local INLINE_ICON_SPACING = 4 -- Space between text and inline icon
local INLINE_ICON_MAX_HEIGHT_RATIO = 0.8 -- Max height of inline icon relative to button height

-- Added inlineIcon parameter
function Button:new(x, y, text, onClick, width, height, fonts, styleGuide, icon, inlineIcon)
    local instance = setmetatable({}, Button)
    instance.x = x
    instance.y = y
    instance.text = text or "Button"
    instance.onClick = onClick or function() print("Button '" .. instance.text .. "' clicked, but no action defined.") end
    instance.width = width or 100
    instance.height = height or 30
    instance.fonts = fonts
    instance.styleGuide = styleGuide
    instance.icon = icon -- Full button icon
    instance.inlineIcon = inlineIcon -- Icon drawn after text
    instance.isHovered = false
    instance.isPressed = false
    instance.isEnabled = true
    return instance
end

function Button:containsPoint(px, py)
    return px >= self.x and px < self.x + self.width and py >= self.y and py < self.y + self.height
end

function Button:update(mouseX, mouseY, isMouseDown)
    if not self.isEnabled then
        self.isHovered = false
        self.isPressed = false
        return
    end
    self.isHovered = self:containsPoint(mouseX, mouseY)
    self.isPressed = self.isHovered and isMouseDown
end

function Button:handleMousePress(px, py)
    if self.isEnabled and self:containsPoint(px, py) then
        self:onClick()
        return true
    end
    return false
end

function Button:draw()
    local originalColor = {love.graphics.getColor()}
    local originalFont = love.graphics.getFont()

    -- Draw background
    local bgColor
    if not self.isEnabled then bgColor = DISABLED_BG_COLOR
    elseif self.isPressed then bgColor = PRESSED_BG_COLOR
    elseif self.isHovered then bgColor = HOVER_BG_COLOR
    else bgColor = BG_COLOR end
    love.graphics.setColor(bgColor)
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)

    -- Draw border
    love.graphics.setColor(BORDER_COLOR)
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)

    love.graphics.setColor(1, 1, 1, 1) -- Reset color before content

    -- Determine content type and draw
    if self.inlineIcon and self.text and self.text ~= "" then
        -- Draw Text + Inline Icon
        local style
        if not self.isEnabled then style = self.styleGuide.BUTTON_TEXT_DIS
        else style = self.styleGuide.BUTTON_TEXT end

        local font = self.fonts[style.fontName] or originalFont
        if not self.fonts[style.fontName] then print("Warning: Button font not found: " .. style.fontName .. ". Using default.") end

        love.graphics.setFont(font)

        local textWidth = font:getWidth(self.text)
        local textHeight = font:getHeight()

        -- Calculate inline icon dimensions
        local iconMaxH = self.height * INLINE_ICON_MAX_HEIGHT_RATIO
        local iconOrigW = self.inlineIcon:getWidth()
        local iconOrigH = self.inlineIcon:getHeight()
        local iconScale = 1
        if iconOrigH > iconMaxH then
             iconScale = iconMaxH / iconOrigH
        end
        local iconDrawW = iconOrigW * iconScale
        local iconDrawH = iconOrigH * iconScale

        local totalContentWidth = textWidth + INLINE_ICON_SPACING + iconDrawW

        -- Calculate centered starting positions
        local startX = self.x + (self.width - totalContentWidth) / 2
        local textY = self.y + (self.height - textHeight) / 2 -- Center text vertically
        local iconY = self.y + (self.height - iconDrawH) / 2 -- Center icon vertically

        -- Draw Text
        love.graphics.setColor(style.color)
        love.graphics.print(self.text, startX, textY)

        -- Draw Inline Icon
        local iconAlpha = self.isEnabled and 1 or 0.5
        love.graphics.setColor(1, 1, 1, iconAlpha) -- White, possibly dimmed
        love.graphics.draw(self.inlineIcon, startX + textWidth + INLINE_ICON_SPACING, iconY, 0, iconScale, iconScale)

    elseif self.icon then
        -- Draw Full Button Icon (Centered)
        local iconW = self.icon:getWidth()
        local iconH = self.icon:getHeight()
        local maxDrawW = self.width - (ICON_PADDING * 2)
        local maxDrawH = self.height - (ICON_PADDING * 2)
        local scale = 1
        if iconW > maxDrawW or iconH > maxDrawH then
            scale = math.min(maxDrawW / iconW, maxDrawH / iconH)
        end
        local drawW = iconW * scale
        local drawH = iconH * scale
        local drawX = self.x + (self.width - drawW) / 2
        local drawY = self.y + (self.height - drawH) / 2
        local iconAlpha = self.isEnabled and 1 or 0.5
        love.graphics.setColor(1, 1, 1, iconAlpha)
        love.graphics.draw(self.icon, drawX, drawY, 0, scale, scale)

    else
        -- Draw Text Only (Centered)
        local style
        if not self.isEnabled then style = self.styleGuide.BUTTON_TEXT_DIS
        else style = self.styleGuide.BUTTON_TEXT end

        local font = self.fonts[style.fontName] or originalFont
        if not self.fonts[style.fontName] then print("Warning: Button font not found: " .. style.fontName .. ". Using default.") end

        love.graphics.setFont(font)
        love.graphics.setColor(style.color)

        local textWidth = font:getWidth(self.text)
        local textHeight = font:getHeight()
        local textX = self.x + (self.width - textWidth) / 2
        local textY = self.y + (self.height - textHeight) / 2
        love.graphics.print(self.text, textX, textY)
    end

    -- Restore original font and color
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

function Button:setEnabled(enabled)
    self.isEnabled = enabled
    if not enabled then
        self.isHovered = false
        self.isPressed = false
    end
end

-- New method to set the position
function Button:setPosition(x, y)
    self.x = x
    self.y = y
end

-- New method to set the size
function Button:setSize(width, height)
    self.width = width
    self.height = height
end

return Button
