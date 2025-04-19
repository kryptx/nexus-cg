-- src/utils/vector.lua
-- Provides utility functions for 2D vector operations

local Vector = {}

-- Create a new vector
function Vector.new(x, y)
    return {x = x or 0, y = y or 0}
end

-- Add two vectors
function Vector.add(v1, v2)
    return Vector.new(v1.x + v2.x, v1.y + v2.y)
end

-- Subtract v2 from v1
function Vector.subtract(v1, v2)
    return Vector.new(v1.x - v2.x, v1.y - v2.y)
end

-- Multiply vector by scalar
function Vector.scale(v, scalar)
    return Vector.new(v.x * scalar, v.y * scalar)
end

-- Calculate vector length/magnitude
function Vector.length(v)
    return math.sqrt(v.x * v.x + v.y * v.y)
end

-- Calculate squared length (often more efficient for comparisons)
function Vector.lengthSquared(v)
    return v.x * v.x + v.y * v.y
end

-- Normalize vector (make it unit length)
function Vector.normalize(v)
    local len = Vector.length(v)
    if len > 0 then
        return Vector.new(v.x / len, v.y / len)
    else
        return Vector.new(0, 0)
    end
end

-- Calculate dot product of two vectors
function Vector.dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end

-- Calculate distance between two points/vectors
function Vector.distance(v1, v2)
    return Vector.length(Vector.subtract(v1, v2))
end

-- Calculate squared distance (more efficient for comparisons)
function Vector.distanceSquared(v1, v2)
    local dx, dy = v1.x - v2.x, v1.y - v2.y
    return dx * dx + dy * dy
end

-- Check if two vectors are equal
function Vector.equals(v1, v2)
    return v1.x == v2.x and v1.y == v2.y
end

-- Create a grid neighbor vector in the given direction (integer indices)
-- dir: "up", "down", "left", "right"
function Vector.gridNeighbor(position, dir)
    if dir == "up" then
        return Vector.new(position.x, position.y - 1)
    elseif dir == "down" then
        return Vector.new(position.x, position.y + 1)
    elseif dir == "left" then
        return Vector.new(position.x - 1, position.y)
    elseif dir == "right" then
        return Vector.new(position.x + 1, position.y)
    else
        return Vector.new(position.x, position.y)
    end
end

-- Get all four grid neighbors (up, down, left, right)
function Vector.getAllGridNeighbors(position)
    return {
        Vector.gridNeighbor(position, "up"),
        Vector.gridNeighbor(position, "down"),
        Vector.gridNeighbor(position, "left"),
        Vector.gridNeighbor(position, "right")
    }
end

-- Convert a grid position to screen coordinates
-- cellSize: width/height of each grid cell
-- offset: optional offset vector from the grid origin
function Vector.gridToScreen(gridPos, cellSize, offset)
    offset = offset or Vector.new(0, 0)
    return Vector.new(
        offset.x + gridPos.x * cellSize,
        offset.y + gridPos.y * cellSize
    )
end

-- Convert screen coordinates to grid position
-- cellSize: width/height of each grid cell
-- offset: optional offset vector from the grid origin
function Vector.screenToGrid(screenPos, cellSize, offset)
    offset = offset or Vector.new(0, 0)
    return Vector.new(
        math.floor((screenPos.x - offset.x) / cellSize),
        math.floor((screenPos.y - offset.y) / cellSize)
    )
end

-- Get vector representation as string for debugging
function Vector.toString(v)
    return "(" .. v.x .. ", " .. v.y .. ")"
end

return Vector
