-- tests/rendering/port_renderer_spec.lua
-- Tests for the extracted PortRenderer module
local PortRenderer = require 'src.rendering.port_renderer'
local Card = require 'src.game.card'

describe('PortRenderer.getPortInfo', function()
    local fakeRenderer
    before_each(function()
        fakeRenderer = {
            CARD_WIDTH = 100,
            CARD_HEIGHT = 140
        }
    end)

    it('calculates TOP_LEFT correctly', function()
        local info = PortRenderer.getPortInfo(fakeRenderer, Card.Ports.TOP_LEFT)
        assert.is_table(info)
        assert.are.equal(fakeRenderer.CARD_WIDTH/4, info.x_offset)
        assert.are.equal(0, info.y_offset)
        assert.are.equal(Card.Type.CULTURE, info.type)
        assert.is_true(info.is_output)
    end)

    it('calculates BOTTOM_RIGHT correctly', function()
        local info = PortRenderer.getPortInfo(fakeRenderer, Card.Ports.BOTTOM_RIGHT)
        assert.are.equal( fakeRenderer.CARD_WIDTH/2 + fakeRenderer.CARD_WIDTH/4, info.x_offset )
        assert.are.equal( fakeRenderer.CARD_HEIGHT, info.y_offset )
    end)

    it('returns nil for invalid port index', function()
        assert.is_nil( PortRenderer.getPortInfo(fakeRenderer, 999) )
    end)
end)


describe('PortRenderer.getPortAtLocalPos', function()
    local fakeRenderer, fakeNetwork, fakeCard

    before_each(function()
        fakeRenderer = {
            CARD_WIDTH = 100,
            CARD_HEIGHT = 140,
            GRID_SPACING = 10,
            PORT_RADIUS = 5
        }
        -- Stub the coordinate transforms on the fake renderer
        function fakeRenderer:gridToWorldCoords(gridX, gridY, originX, originY)
            originX = originX or 0; originY = originY or 0
            return originX + gridX * (self.CARD_WIDTH + self.GRID_SPACING),
                   originY + gridY * (self.CARD_HEIGHT + self.GRID_SPACING)
        end
        function fakeRenderer:worldToGridCoords(wx, wy, originX, originY)
            originX = originX or 0; originY = originY or 0
            local cellW = self.CARD_WIDTH + self.GRID_SPACING
            local cellH = self.CARD_HEIGHT + self.GRID_SPACING
            return math.floor((wx - originX)/cellW), math.floor((wy - originY)/cellH)
        end

        fakeCard = {}
        fakeNetwork = {
            getCardAt = function(self, x, y)
                return (x == 0 and y == 0) and fakeCard or nil
            end
        }
    end)

    it('detects TOP_LEFT when clicking near that port', function()
        local offset = PortRenderer.getPortInfo(fakeRenderer, Card.Ports.TOP_LEFT)
        local clickX = offset.x_offset + 1
        local clickY = offset.y_offset + 1
        local gx, gy, card, port = PortRenderer.getPortAtLocalPos(fakeRenderer, fakeNetwork, clickX, clickY)
        assert.are.equal(0, gx)
        assert.are.equal(0, gy)
        assert.equals(fakeCard, card)
        assert.equals(Card.Ports.TOP_LEFT, port)
    end)

    it('returns nil when clicking far from any port', function()
        local clickX = fakeRenderer.CARD_WIDTH + fakeRenderer.GRID_SPACING * 2
        local clickY = fakeRenderer.CARD_HEIGHT + fakeRenderer.GRID_SPACING * 2
        local gx, gy, card, port = PortRenderer.getPortAtLocalPos(fakeRenderer, fakeNetwork, clickX, clickY)
        assert.is_nil(card)
        assert.is_nil(port)
    end)
end) 
