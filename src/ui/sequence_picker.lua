-- src/ui/sequence_picker.lua
local SequencePicker = {}
SequencePicker.__index = SequencePicker

-- sequences: array of pathData { path={ {card=..., owner=..., traversedLinkType=...}, ... } }
-- onSelect: callback(index) when user picks a sequence
function SequencePicker:new(renderer, sequences, onSelect)
    local instance = setmetatable({}, SequencePicker)
    instance.renderer = renderer
    instance.sequences = sequences or {}
    instance.onSelect = onSelect
    instance.maxChoices = 5
    -- Take up to first maxChoices sequences
    instance.visibleSequences = {}
    for i = 1, math.min(#instance.sequences, instance.maxChoices) do
        instance.visibleSequences[i] = instance.sequences[i]
    end
    instance.cardBounds = {}    -- Bounds for each card in all sequences
    instance.buttonBounds = {}  -- Bounds for each Select button
    instance.hoveredCard = nil   -- { x, y, w, h, card }
    return instance
end

-- Update hovered card for preview
function SequencePicker:update()
    self.hoveredCard = nil
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(self.cardBounds) do
        if mx >= b.x and mx < b.x + b.w and my >= b.y and my < b.y + b.h then
            self.hoveredCard = b
            break
        end
    end
end

-- Handle mouse presses (return true if handled)
function SequencePicker:handleMousePressed(x, y)
    for idx, b in ipairs(self.buttonBounds) do
        if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then
            if self.onSelect then
                self.onSelect(idx)
            end
            return true
        end
    end
    return false
end

-- Draw the sequence picker overlay
function SequencePicker:draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, screenW, screenH)

    -- Layout parameters
    local padding = 10
    local buttonW, buttonH = 80, 30
    -- Increase small cards by 50%
    local cardScale = 0.9
    local invSf = 1 / (self.renderer.canvasRenderScaleFactor or 1)
    local drawScale = cardScale * invSf
    local cardW = self.renderer.CARD_WIDTH * cardScale
    local cardH = self.renderer.CARD_HEIGHT * cardScale

    -- Compute total height of all sequence items
    local num = #self.visibleSequences
    local itemHeight = cardH + padding * 2 + buttonH
    local totalHeight = num * itemHeight + (num - 1) * padding
    local startY = (screenH - totalHeight) / 2
    local startX = screenW * 0.1

    -- Clear bounds arrays
    self.cardBounds = {}
    self.buttonBounds = {}

    love.graphics.setColor(1, 1, 1, 1)
    -- Draw each sequence row
    for idx, seqData in ipairs(self.visibleSequences) do
        local y = startY + (idx - 1) * (itemHeight + padding)
        local x = startX
        -- Draw cards left-to-right
        for _, elem in ipairs(seqData.path) do
            local canvas = self.renderer:_generateCardCanvas(elem.card)
            love.graphics.draw(canvas, x, y + padding, 0, drawScale, drawScale)
            table.insert(self.cardBounds, { x = x, y = y + padding, w = cardW, h = cardH, card = elem.card })
            x = x + cardW + padding
        end
        -- Draw 'Select' button to the right
        local btnX = screenW - screenW * 0.1 - buttonW
        local btnY = y + padding + (cardH - buttonH) / 2
        love.graphics.setColor(0.3, 0.5, 0.8, 1)
        love.graphics.rectangle('fill', btnX, btnY, buttonW, buttonH, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        local font = love.graphics.getFont()
        love.graphics.printf("Select", btnX, btnY + (buttonH - font:getHeight()) / 2, buttonW, 'center')
        table.insert(self.buttonBounds, { x = btnX, y = btnY, w = buttonW, h = buttonH })
    end

    -- Draw hovered card preview (300% zoom), clamped and with activation area highlight
    if self.hoveredCard then
        local mx, my = love.mouse.getPosition()
        local canvas = self.renderer:_generateCardCanvas(self.hoveredCard.card)
        if canvas then
            local previewScale = 3.0 * invSf
            local w = canvas:getWidth() * previewScale
            local h = canvas:getHeight() * previewScale
            -- Initial position above cursor
            local px = mx - w / 2
            local py = my - h - 20
            -- Clamp preview to window bounds
            px = math.max(0, math.min(px, screenW - w))
            py = math.max(0, math.min(py, screenH - h))
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(canvas, px, py, 0, previewScale, previewScale)
            -- Highlight activation effect box in yellow (properly scaled)
            local R = self.renderer.PORT_RADIUS or 0
            local sf = self.renderer.canvasRenderScaleFactor or 1
            local finalScale = previewScale * sf
            local marginLocal = 5
            local headerH = 20
            local cw = self.renderer.CARD_WIDTH
            local ch = self.renderer.CARD_HEIGHT
            local areaW = cw - 2 * marginLocal
            local aspectRatio = 1024 / 720
            local imageH = areaW / aspectRatio
            local effectsY = headerH + marginLocal + imageH
            local totalEffectAreaH = ch - headerH - imageH - 2 * marginLocal
            local activationBoxH = totalEffectAreaH * 0.5
            -- Compute box coordinates in screen pixels
            local boxX = px + (R + marginLocal) * finalScale
            local boxY = py + (R + effectsY) * finalScale
            local boxW = areaW * finalScale
            local boxH = activationBoxH * finalScale
            love.graphics.setColor(1, 1, 0, 0.8)
            love.graphics.setLineWidth(4)
            love.graphics.rectangle('line', boxX, boxY, boxW, boxH)
            -- Restore color
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return SequencePicker 
