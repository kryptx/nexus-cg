-- tests/test_helper.lua

-- Get the absolute path to the project root
local current_dir = debug.getinfo(1).source:match("@?(.*/)") or ""
local project_root = current_dir:gsub("tests/$", "")

-- Add the project root to package path
package.path = project_root .. "?.lua;" .. package.path

-- You can add more test setup here if needed 

-- Stub LOVE2D graphics and filesystem for renderer tests
love = love or {}
love.graphics = love.graphics or {}
love.graphics.getWidth = love.graphics.getWidth or function() return 800 end
love.graphics.getHeight = love.graphics.getHeight or function() return 600 end
love.graphics.newFont = love.graphics.newFont or function(...) return {setFilter=function() end, getHeight=function() return 16 end} end
love.graphics.getFont = love.graphics.getFont or function()
    return { setFilter = function() end, getHeight = function() return 16 end, getWidth = function() return 0 end }
end
love.filesystem = love.filesystem or {}
love.filesystem.getInfo = love.filesystem.getInfo or function(_) return nil end
