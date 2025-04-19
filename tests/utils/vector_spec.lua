-- tests/utils/vector_spec.lua
-- Unit tests for the Vector utility module

local Vector = require 'src.utils.vector'

describe("Vector Module", function()
    
    describe("Vector.new()", function()
        it("should create a new vector with the given coordinates", function()
            local v = Vector.new(3, 4)
            assert.are.equal(3, v.x)
            assert.are.equal(4, v.y)
        end)
        
        it("should default to (0, 0) when no coordinates are provided", function()
            local v = Vector.new()
            assert.are.equal(0, v.x)
            assert.are.equal(0, v.y)
        end)
        
        it("should accept partial coordinates and default the rest", function()
            local v = Vector.new(5)
            assert.are.equal(5, v.x)
            assert.are.equal(0, v.y)
        end)
    end)
    
    describe("Vector.add()", function()
        it("should add two vectors properly", function()
            local v1 = Vector.new(1, 2)
            local v2 = Vector.new(3, 4)
            local result = Vector.add(v1, v2)
            assert.are.equal(4, result.x)
            assert.are.equal(6, result.y)
        end)
    end)
    
    describe("Vector.subtract()", function()
        it("should subtract the second vector from the first", function()
            local v1 = Vector.new(5, 7)
            local v2 = Vector.new(2, 3)
            local result = Vector.subtract(v1, v2)
            assert.are.equal(3, result.x)
            assert.are.equal(4, result.y)
        end)
    end)
    
    describe("Vector.scale()", function()
        it("should multiply the vector by a scalar", function()
            local v = Vector.new(3, 4)
            local result = Vector.scale(v, 2)
            assert.are.equal(6, result.x)
            assert.are.equal(8, result.y)
        end)
    end)
    
    describe("Vector.length()", function()
        it("should calculate the correct length of a vector", function()
            local v = Vector.new(3, 4)
            assert.are.equal(5, Vector.length(v))
        end)
        
        it("should return 0 for a zero vector", function()
            local v = Vector.new(0, 0)
            assert.are.equal(0, Vector.length(v))
        end)
    end)
    
    describe("Vector.lengthSquared()", function()
        it("should calculate the correct squared length", function()
            local v = Vector.new(3, 4)
            assert.are.equal(25, Vector.lengthSquared(v))
        end)
    end)
    
    describe("Vector.normalize()", function()
        it("should return a unit vector with the same direction", function()
            local v = Vector.new(3, 4)
            local result = Vector.normalize(v)
            assert.is_near(0.6, result.x, 0.001)
            assert.is_near(0.8, result.y, 0.001)
            assert.is_near(1, Vector.length(result), 0.001)
        end)
        
        it("should return a zero vector when normalizing a zero vector", function()
            local v = Vector.new(0, 0)
            local result = Vector.normalize(v)
            assert.are.equal(0, result.x)
            assert.are.equal(0, result.y)
        end)
    end)
    
    describe("Vector.dot()", function()
        it("should calculate the dot product of two vectors", function()
            local v1 = Vector.new(2, 3)
            local v2 = Vector.new(4, 5)
            assert.are.equal(23, Vector.dot(v1, v2)) -- 2*4 + 3*5 = 8 + 15 = 23
        end)
    end)
    
    describe("Vector.distance()", function()
        it("should calculate the distance between two vectors", function()
            local v1 = Vector.new(1, 1)
            local v2 = Vector.new(4, 5)
            assert.is_near(5, Vector.distance(v1, v2), 0.001)
        end)
    end)
    
    describe("Vector.distanceSquared()", function()
        it("should calculate the squared distance between two vectors", function()
            local v1 = Vector.new(1, 1)
            local v2 = Vector.new(4, 5)
            assert.are.equal(25, Vector.distanceSquared(v1, v2))
        end)
    end)
    
    describe("Vector.equals()", function()
        it("should return true for equal vectors", function()
            local v1 = Vector.new(3, 4)
            local v2 = Vector.new(3, 4)
            assert.is_true(Vector.equals(v1, v2))
        end)
        
        it("should return false for different vectors", function()
            local v1 = Vector.new(3, 4)
            local v2 = Vector.new(3, 5)
            assert.is_false(Vector.equals(v1, v2))
            
            local v3 = Vector.new(4, 4)
            assert.is_false(Vector.equals(v1, v3))
        end)
    end)
    
    describe("Vector.gridNeighbor()", function()
        it("should return the correct grid neighbor in each direction", function()
            local pos = Vector.new(5, 5)
            
            local up = Vector.gridNeighbor(pos, "up")
            assert.are.equal(5, up.x)
            assert.are.equal(4, up.y)
            
            local down = Vector.gridNeighbor(pos, "down")
            assert.are.equal(5, down.x)
            assert.are.equal(6, down.y)
            
            local left = Vector.gridNeighbor(pos, "left")
            assert.are.equal(4, left.x)
            assert.are.equal(5, left.y)
            
            local right = Vector.gridNeighbor(pos, "right")
            assert.are.equal(6, right.x)
            assert.are.equal(5, right.y)
        end)
        
        it("should return the original position for invalid directions", function()
            local pos = Vector.new(5, 5)
            local result = Vector.gridNeighbor(pos, "invalid")
            assert.are.equal(5, result.x)
            assert.are.equal(5, result.y)
        end)
    end)
    
    describe("Vector.getAllGridNeighbors()", function()
        it("should return all four neighbors as a table", function()
            local pos = Vector.new(5, 5)
            local neighbors = Vector.getAllGridNeighbors(pos)
            
            assert.are.equal(4, #neighbors)
            
            -- Check that all 4 directions are represented
            local directions = {
                up = false,
                down = false,
                left = false,
                right = false
            }
            
            for _, v in ipairs(neighbors) do
                if v.x == 5 and v.y == 4 then directions.up = true end
                if v.x == 5 and v.y == 6 then directions.down = true end
                if v.x == 4 and v.y == 5 then directions.left = true end
                if v.x == 6 and v.y == 5 then directions.right = true end
            end
            
            assert.is_true(directions.up)
            assert.is_true(directions.down)
            assert.is_true(directions.left)
            assert.is_true(directions.right)
        end)
    end)
    
    describe("Vector.gridToScreen()", function()
        it("should convert grid coordinates to screen coordinates", function()
            local gridPos = Vector.new(3, 2)
            local cellSize = 64
            local screenPos = Vector.gridToScreen(gridPos, cellSize)
            
            assert.are.equal(3 * 64, screenPos.x)
            assert.are.equal(2 * 64, screenPos.y)
        end)
        
        it("should apply offset correctly when provided", function()
            local gridPos = Vector.new(3, 2)
            local cellSize = 64
            local offset = Vector.new(10, 20)
            local screenPos = Vector.gridToScreen(gridPos, cellSize, offset)
            
            assert.are.equal(10 + 3 * 64, screenPos.x)
            assert.are.equal(20 + 2 * 64, screenPos.y)
        end)
    end)
    
    describe("Vector.screenToGrid()", function()
        it("should convert screen coordinates to grid coordinates", function()
            local screenPos = Vector.new(160, 96)
            local cellSize = 32
            local gridPos = Vector.screenToGrid(screenPos, cellSize)
            
            assert.are.equal(5, gridPos.x) -- 160 / 32 = 5
            assert.are.equal(3, gridPos.y) -- 96 / 32 = 3
        end)
        
        it("should apply offset correctly when provided", function()
            local screenPos = Vector.new(180, 116)
            local cellSize = 32
            local offset = Vector.new(20, 20)
            local gridPos = Vector.screenToGrid(screenPos, cellSize, offset)
            
            assert.are.equal(5, gridPos.x) -- (180 - 20) / 32 = 5
            assert.are.equal(3, gridPos.y) -- (116 - 20) / 32 = 3
        end)
        
        it("should floor results correctly", function()
            local screenPos = Vector.new(159, 95)
            local cellSize = 32
            local gridPos = Vector.screenToGrid(screenPos, cellSize)
            
            assert.are.equal(4, gridPos.x) -- 159 / 32 = 4.96... -> 4
            assert.are.equal(2, gridPos.y) -- 95 / 32 = 2.96... -> 2
        end)
    end)
    
    describe("Vector.toString()", function()
        it("should format the vector as a string", function()
            local v = Vector.new(3, 4)
            assert.are.equal("(3, 4)", Vector.toString(v))
        end)
    end)
    
end) 
