-- src/rendering/port_renderer.lua
local Card = require('src.game.card')

local PortRenderer = {}

-- Add port rendering color constants and drawing functions
local PORT_COLORS = {
    [Card.Type.TECHNOLOGY] = { 0.2, 1,   0.2, 1 },
    [Card.Type.CULTURE]    = { 1,   0.8, 0,   1 },
    [Card.Type.RESOURCE]   = { 0.6, 0.4, 0.2, 1 },
    [Card.Type.KNOWLEDGE]  = { 0.6, 0.2, 1,   1 },
}
local ABSENT_PORT_COLOR = { 0.3, 0.3, 0.3, 1 }
local PORT_BORDER_COLOR  = { 0,   0,   0,   1 }

function PortRenderer.getPortInfo(renderer, portIndex)
    local props = Card:getPortProperties(portIndex)
    if not props then return nil end

    local halfW = renderer.CARD_WIDTH / 2
    local halfH = renderer.CARD_HEIGHT / 2
    local quartW = renderer.CARD_WIDTH / 4
    local quartH = renderer.CARD_HEIGHT / 4

    local x_offset, y_offset
    if portIndex == Card.Ports.TOP_LEFT then x_offset, y_offset = quartW, 0 end
    if portIndex == Card.Ports.TOP_RIGHT then x_offset, y_offset = halfW + quartW, 0 end
    if portIndex == Card.Ports.BOTTOM_LEFT then x_offset, y_offset = quartW, renderer.CARD_HEIGHT end
    if portIndex == Card.Ports.BOTTOM_RIGHT then x_offset, y_offset = halfW + quartW, renderer.CARD_HEIGHT end
    if portIndex == Card.Ports.LEFT_TOP then x_offset, y_offset = 0, quartH end
    if portIndex == Card.Ports.LEFT_BOTTOM then x_offset, y_offset = 0, halfH + quartH end
    if portIndex == Card.Ports.RIGHT_TOP then x_offset, y_offset = renderer.CARD_WIDTH, quartH end
    if portIndex == Card.Ports.RIGHT_BOTTOM then x_offset, y_offset = renderer.CARD_WIDTH, halfH + quartH end

    if x_offset ~= nil then
        return { x_offset = x_offset, y_offset = y_offset, type = props.type, is_output = props.is_output }
    end
    return nil
end

function PortRenderer.getPortAtLocalPos(renderer, network, localX, localY)
    local tolerance = renderer.PORT_RADIUS * 5.0
    local toleranceSq = tolerance * tolerance

    local clickGridX, clickGridY = renderer:worldToGridCoords(localX, localY, 0, 0)

    local candidateCells = {
        {clickGridX, clickGridY},
        {clickGridX + 1, clickGridY},
        {clickGridX - 1, clickGridY},
        {clickGridX, clickGridY + 1},
        {clickGridX, clickGridY - 1}
    }

    local closestMatch = { distanceSq = toleranceSq, card = nil, gridX = nil, gridY = nil, portIndex = nil }

    for _, cellCoords in ipairs(candidateCells) do
        local gridX, gridY = cellCoords[1], cellCoords[2]
        local card = network:getCardAt(gridX, gridY)

        if card then
            local cardLocalX, cardLocalY = renderer:gridToWorldCoords(gridX, gridY, 0, 0)
            for portIndex = 1, 8 do
                local portInfo = PortRenderer.getPortInfo(renderer, portIndex)
                if portInfo then
                    local dx = localX - (cardLocalX + portInfo.x_offset)
                    local dy = localY - (cardLocalY + portInfo.y_offset)
                    local distSq = dx * dx + dy * dy
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
    end
    return nil, nil, nil, nil
end

-- Draw the shape for a single port (input as triangle, output as trapezoid or default circle)
function PortRenderer.drawPortShape(renderer, portIndex, portX, portY, radius, alpha)
    local info = PortRenderer.getPortInfo(renderer, portIndex)
    if not info then return end

    local portType = info.type
    local isOutput = info.is_output
    local r = radius

    -- Determine orientation based on port index
    local orientation
    if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then orientation = "top"
    elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then orientation = "bottom"
    elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then orientation = "left"
    elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then orientation = "right"
    end

    -- Base color for port fill
    local color = PORT_COLORS[portType] or ABSENT_PORT_COLOR
    love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * alpha)

    -- Compute vertices for filled shape
    local vertices
    if isOutput then
        local outer = r * 1.5
        local inner = r
        if orientation == "top" then
            local x1_out = portX - inner; local x2_out = portX + inner
            local x1_in  = portX - outer; local x2_in  = portX + outer
            vertices = { x1_out, portY-r, x2_out, portY-r, x2_in, portY, x1_in, portY }
        elseif orientation == "bottom" then
            local x1_out = portX - inner; local x2_out = portX + inner
            local x1_in  = portX - outer; local x2_in  = portX + outer
            vertices = { x1_in, portY, x2_in, portY, x2_out, portY+r, x1_out, portY+r }
        elseif orientation == "left" then
            local y1_out = portY - inner; local y2_out = portY + inner
            local y1_in  = portY - outer; local y2_in  = portY + outer
            vertices = { portX-r, y1_out, portX, y1_in, portX, y2_in, portX-r, y2_out }
        elseif orientation == "right" then
            local y1_out = portY - inner; local y2_out = portY + inner
            local y1_in  = portY - outer; local y2_in  = portY + outer
            vertices = { portX, y1_in, portX+r, y1_out, portX+r, y2_out, portX, y2_in }
        end
    else
        if orientation == "top" then
            vertices = { portX-r, portY-r, portX+r, portY-r, portX, portY+r }
        elseif orientation == "bottom" then
            vertices = { portX-r, portY+r, portX+r, portY+r, portX, portY-r }
        elseif orientation == "left" then
            vertices = { portX-r, portY-r, portX-r, portY+r, portX+r, portY }
        elseif orientation == "right" then
            vertices = { portX+r, portY-r, portX+r, portY+r, portX-r, portY }
        end
    end

    love.graphics.setLineWidth(0.5)
    if vertices then
        love.graphics.polygon("fill", vertices)
        love.graphics.setColor(PORT_BORDER_COLOR[1], PORT_BORDER_COLOR[2], PORT_BORDER_COLOR[3], (PORT_BORDER_COLOR[4] or 1) * alpha)
        love.graphics.polygon("line", vertices)
    else
        love.graphics.circle("fill", portX, portY, r)
        love.graphics.setColor(PORT_BORDER_COLOR[1], PORT_BORDER_COLOR[2], PORT_BORDER_COLOR[3], (PORT_BORDER_COLOR[4] or 1) * alpha)
        love.graphics.circle("line", portX, portY, r)
    end
end

-- Draw the 8 connection ports for a card (including occupied tabs)
function PortRenderer.drawCardPorts(renderer, card, sx, sy, alphaOverride, activeLinks)
    alphaOverride = alphaOverride or 1.0
    activeLinks = activeLinks or {}
    if not card then return end

    local linkMap = {}
    for _, link in ipairs(activeLinks) do
        linkMap[link.linkId] = link
    end

    local originalFont = love.graphics.getFont()
    local originalColor = { love.graphics.getColor() }
    local r = renderer.PORT_RADIUS

    for portIndex = 1, 8 do
        local info = PortRenderer.getPortInfo(renderer, portIndex)
        if info then
            local portX = sx + info.x_offset
            local portY = sy + info.y_offset
            local isDefined = card:isPortDefined(portIndex)
            local occupyingLinkId = card:getOccupyingLinkId(portIndex)
            local isOccupied = occupyingLinkId ~= nil

            if isOccupied then
                -- Draw base port shape (dimmed)
                PortRenderer.drawPortShape(renderer, portIndex, portX, portY, r, alphaOverride * 0.4)

                -- Draw occupied tab
                local linkDetails = linkMap[occupyingLinkId]
                local playerNumber = linkDetails and linkDetails.initiatingPlayerIndex or "?"

                local tabSize = r * 3.5
                local fixedOffset = r
                local tabX, tabY

                -- Determine orientation for tab placement
                local orientation
                if portIndex == Card.Ports.TOP_LEFT or portIndex == Card.Ports.TOP_RIGHT then orientation = "top"
                elseif portIndex == Card.Ports.BOTTOM_LEFT or portIndex == Card.Ports.BOTTOM_RIGHT then orientation = "bottom"
                elseif portIndex == Card.Ports.LEFT_TOP or portIndex == Card.Ports.LEFT_BOTTOM then orientation = "left"
                elseif portIndex == Card.Ports.RIGHT_TOP or portIndex == Card.Ports.RIGHT_BOTTOM then orientation = "right"
                end

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
                    tabX = portX - tabSize / 2
                    tabY = portY - tabSize / 2
                end

                love.graphics.setColor(0.9, 0.9, 0.9, alphaOverride * 0.7)
                love.graphics.rectangle("fill", tabX, tabY, tabSize, tabSize)
                love.graphics.setColor(0, 0, 0, alphaOverride)
                love.graphics.rectangle("line", tabX, tabY, tabSize, tabSize)

                love.graphics.setFont(renderer.fonts.worldSmall or originalFont)
                love.graphics.setColor(0, 0, 0, alphaOverride)
                local text = tostring(playerNumber)
                local textScale = 0.45 / renderer.worldFontMultiplier
                local nativeW = (renderer.fonts.worldSmall or originalFont):getWidth(text)
                local nativeH = (renderer.fonts.worldSmall or originalFont):getHeight()
                love.graphics.push()
                love.graphics.translate(tabX + (tabSize - nativeW * textScale) / 2,
                                       tabY + (tabSize - nativeH * textScale) / 2)
                love.graphics.scale(textScale, textScale)
                love.graphics.print(text, 0, 0)
                love.graphics.pop()

            elseif isDefined then
                -- Draw normal port shape
                PortRenderer.drawPortShape(renderer, portIndex, portX, portY, r, alphaOverride)
            end
        end
    end

    love.graphics.setFont(originalFont)
    love.graphics.setColor(originalColor)
end

return PortRenderer
