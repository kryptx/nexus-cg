-- src/ui/button.lua
-- A simple clickable UI button component.

local Button = {}
Button.__index = Button

-- Default visual settings
local PADDING_X = 10
local PADDING_Y = 5
local BG_COLOR = { 0.6, 0.6, 0.6, 1 } -- Normal background
local HOVER_BG_COLOR = { 0.75, 0.75, 0.75, 1 } -- Lighter when hovered
local PRESSED_BG_COLOR = { 0.5, 0.5, 0.5, 1 } -- Darker when pressed
local DISABLED_BG_COLOR = { 0.4, 0.4, 0.4, 1 }
local TEXT_COLOR = { 0, 0, 0, 1 } -- Black text
local DISABLED_TEXT_COLOR = { 0.7, 0.7, 0.7, 1 }
local BORDER_COLOR = { 0.1, 0.1, 0.1, 1 }

function Button:new(x, y, text, onClick, width, height)
    local instance = setmetatable({}, Button)
    instance.x = x
    instance.y = y
    instance.text = text or "Button"
    instance.onClick = onClick or function() print("Button '" .. instance.text .. "' clicked, but no action defined.") end

    -- Calculate dimensions based on text if not provided
    local font = love.graphics.getFont()
    instance.width = width or (font:getWidth(instance.text) + PADDING_X * 2)
    instance.height = height or (font:getHeight() + PADDING_Y * 2)

    instance.isHovered = false
    instance.isPressed = false
    instance.isEnabled = true

    return instance
end

-- Check if screen coordinates are within the button's bounds
function Button:containsPoint(px, py)
    return px >= self.x and px < self.x + self.width and py >= self.y and py < self.y + self.height
end

-- Update button state based on mouse position and press state
-- (Call this in love.update or before checking clicks)
function Button:update(mouseX, mouseY, isMouseDown)
    if not self.isEnabled then
        self.isHovered = false
        self.isPressed = false
        return
    end

    self.isHovered = self:containsPoint(mouseX, mouseY)
    self.isPressed = self.isHovered and isMouseDown
end

-- Handle mouse press event. Returns true if the click was handled (and action triggered).
function Button:handleMousePress(px, py)
    if self.isEnabled and self:containsPoint(px, py) then
        self:onClick()
        return true -- Click was handled by this button
    end
    return false
end

-- Draw the button
function Button:draw()
    local bgColor = BG_COLOR
    local textColor = TEXT_COLOR

    if not self.isEnabled then
        bgColor = DISABLED_BG_COLOR
        textColor = DISABLED_TEXT_COLOR
    elseif self.isPressed then
        bgColor = PRESSED_BG_COLOR
    elseif self.isHovered then
        bgColor = HOVER_BG_COLOR
    end

    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- Draw border
    love.graphics.setColor(BORDER_COLOR)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- Draw text centered
    love.graphics.setColor(textColor)
    love.graphics.printf(self.text, self.x + PADDING_X, self.y + PADDING_Y, self.width - PADDING_X * 2, "center")
end

function Button:setEnabled(enabled)
    self.isEnabled = enabled
    if not enabled then -- Reset visual state if disabled
        self.isHovered = false
        self.isPressed = false
    end
end

return Button
