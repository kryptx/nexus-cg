-- tests/rendering/renderer_spec.lua
local Renderer = require 'src.rendering.renderer'

describe("Renderer coordinate transforms", function()
    local renderer, cx, cy

    before_each(function()
        -- Ensure love.graphics stubs are in place via test_helper.lua
        renderer = Renderer:new()
        cx = love.graphics.getWidth() / 2
        cy = love.graphics.getHeight() / 2
    end)

    it("gridToWorldCoords and worldToGridCoords are inverses with no rotation", function()
        local originX, originY = 100, 50
        for gridX = 0, 3 do
            for gridY = 0, 3 do
                local wx, wy = renderer:gridToWorldCoords(gridX, gridY, originX, originY)
                -- worldToGridCoords floors, so test direct inverse at cell origin
                local invGX, invGY = renderer:worldToGridCoords(wx, wy, originX, originY)
                assert.are.equal(gridX, invGX)
                assert.are.equal(gridY, invGY)
            end
        end
    end)

    it("screenToNetworkLocal inverts rotation correctly", function()
        local testPoints = {
            {10, 20},
            {100, -50},
            {-33.5, 47.2}
        }
        local angles = {0, math.pi/2, math.pi, 3*math.pi/2}
        for _, angle in ipairs(angles) do
            local player = { orientation = angle }
            for _, pt in ipairs(testPoints) do
                -- Original world point relative to center
                local w_x = cx + pt[1]
                local w_y = cy + pt[2]
                -- Simulate screen point by rotating world point around center
                local dx, dy = pt[1], pt[2]
                local s_x = dx * math.cos(angle) - dy * math.sin(angle) + cx
                local s_y = dx * math.sin(angle) + dy * math.cos(angle) + cy
                -- Invert rotation
                local inv_x, inv_y = renderer:screenToNetworkLocal(s_x, s_y, player)
                assert.is_true(math.abs(inv_x - w_x) < 1e-6)
                assert.is_true(math.abs(inv_y - w_y) < 1e-6)
            end
        end
    end)
end) 
