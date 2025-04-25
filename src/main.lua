-- src/main.lua
-- Main application entry point for NEXUS: The Convergence

--[[ No longer needed when running from project root via bootstrap main.lua
-- Setup package path for requiring local modules easily
-- Assumes main.lua is in src/, adds parent dir (project root) to path
package.path = package.path .. ';../?.lua'
]]--

local StateManager = require 'src.core.state_manager'
local MenuState = require 'src.game.states.menu_state' -- Assuming this exists
local PlayState = require 'src.game.states.play_state'
local AnimationController = require('src.controllers.AnimationController') -- Require AnimationController
local ServiceModule = require('src.game.game_service') -- Require GameService module
local GameService = ServiceModule.GameService

-- Global variable to hold the state manager
local stateManager = nil -- Back to local
local animationController = nil -- Add animation controller instance
local gameService = nil -- Add game service instance

function love.load()
    print("love.load() - Initializing Game Manager")

    -- Improve font scaling sharpness
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    stateManager = StateManager:new() -- Assign to local
    animationController = AnimationController:new() -- Create instance
    gameService = GameService:new() -- Create GameService instance

    -- Register game states
    -- We need to create instances of the state tables
    local menuStateInstance = setmetatable({}, { __index = MenuState })
    local playStateInstance = PlayState:new(animationController, gameService) -- Pass BOTH instances

    stateManager:registerState('menu', menuStateInstance)
    stateManager:registerState('play', playStateInstance)

    -- Set the initial state
    stateManager:changeState('menu') -- Start with the menu (assuming)

    love.window.setTitle("NEXUS: The Convergence - Main Menu") -- Initial title
    print("State Manager initialized.")
end

function love.update(dt)
    if stateManager then
        stateManager:update(dt)
    end
    -- Update animations globally
    if animationController then
        animationController:update(dt)
    end
end

function love.draw()
    if stateManager then
        stateManager:draw()
    end
end

function love.keypressed(key, scancode, isrepeat)
    if stateManager then
        stateManager:keypressed(key, scancode, isrepeat)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if stateManager then
        stateManager:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased(x, y, button, istouch)
     if stateManager then
        stateManager:mousereleased(x, y, button, istouch)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
     if stateManager then
        stateManager:mousemoved(x, y, dx, dy, istouch)
    end
end

function love.wheelmoved(x, y)
     if stateManager then
        stateManager:wheelmoved(x, y)
    end
end

-- Handle window resizing if needed
function love.resize(w, h)
    if stateManager and stateManager:respondsTo("resize") then
        stateManager:resize(w, h)
    end
end

-- Handle game exit
function love.quit()
    print("Shutting down NEXUS...")
    if stateManager and stateManager:respondsTo("quit") then
        stateManager:quit()
    end
    -- Perform any other cleanup here if necessary
    print("Goodbye!")
end 
