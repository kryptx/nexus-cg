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

function Button:new(x, y, text, onClick, width, height, fonts, styleGuide)
    local instance = setmetatable({}, Button)
    instance.x = x
    instance.y = y
    instance.text = text or "Button"
    instance.onClick = onClick or function() print("Button '" .. instance.text .. "' clicked, but no action defined.") end
    instance.width = width or 100
    instance.height = height or 30
    instance.fonts = fonts -- Store fonts table
    instance.styleGuide = styleGuide -- Store style guide
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
    -- Draw background and border based on state
    if not self.isEnabled then love.graphics.setColor(0.5, 0.5, 0.5, 0.8) -- Disabled BG
    elseif self.isPressed then love.graphics.setColor(0.7, 0.7, 0.7, 1) -- Pressed BG
    elseif self.isHovered then love.graphics.setColor(0.9, 0.9, 0.9, 1) -- Hover BG
    else love.graphics.setColor(0.8, 0.8, 0.8, 1) end -- Normal BG
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    love.graphics.setColor(0, 0, 0, 1) -- Border color
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)

    -- Set text style based on enabled status
    local style
    if not self.isEnabled then
        style = self.styleGuide.BUTTON_TEXT_DIS
    else
        style = self.styleGuide.BUTTON_TEXT
    end

    -- Get font object from stored fonts table
    local font = self.fonts[style.fontName]
    if not font then -- Fallback if font name is wrong in style guide
        print("Warning: Button font not found: " .. style.fontName .. ". Using default.")
        font = love.graphics.getFont()
    end

    -- Set font and color from style
    local originalFont = love.graphics.getFont()
    local originalColor = {love.graphics.getColor()}
    love.graphics.setFont(font)
    love.graphics.setColor(style.color)

    -- Calculate text position for centering
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    local textX = self.x + (self.width - textWidth) / 2
    local textY = self.y + (self.height - textHeight) / 2
    love.graphics.print(self.text, textX, textY)

    -- Restore original font and color
    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

function Button:setEnabled(enabled)
    self.isEnabled = enabled
    if not enabled then -- Reset visual state if disabled
        self.isHovered = false
        self.isPressed = false
    end
end

return Button
