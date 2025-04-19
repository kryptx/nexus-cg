-- main.lua: Main entry point for NEXUS: The Convergence

-- Require Core Systems
local StateManager = require 'src.core.state_manager'

-- Require Game States
local MenuState = require 'src.game.states.menu_state'
local PlayState = require 'src.game.states.play_state'

-- Global game state manager instance
-- Note: Making GameState global is convenient but consider dependency injection later
GameState = nil

function love.load()
    -- Called once at the start of the game
    print("NEXUS: The Convergence - Loading...")

    -- Create the State Manager instance
    GameState = StateManager:new()

    -- Register the states using the required modules
    GameState:register('menu', MenuState)
    GameState:register('play', PlayState)

    -- Set the initial state
    GameState:switchState('menu')

    print("Loading complete.")
end

function love.update(dt)
    -- Called repeatedly with the time delta (dt) since the last frame
    -- Delegate update to the current state
    GameState:update(dt)
end

function love.draw()
    -- Called repeatedly to draw everything to the screen
    -- Delegate draw to the current state
    GameState:draw()
end

function love.keypressed(key, scancode, isrepeat)
    -- Called when a key is pressed
    -- Delegate keypressed to the current state
    -- Note: Global escape handling removed here, should be handled by states if needed
    GameState:keypressed(key, scancode, isrepeat)
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Called when a mouse button is pressed
    -- Delegate mousepressed to the current state
    GameState:mousepressed(x, y, button, istouch, presses)
end

-- Add delegation for mouse release
function love.mousereleased(x, y, button, istouch)
    if GameState and GameState.currentState and GameState.currentState.mousereleased then
        GameState.currentState:mousereleased(x, y, button, istouch)
    end
end

-- Add delegation for mouse movement
function love.mousemoved(x, y, dx, dy, istouch)
    if GameState and GameState.currentState and GameState.currentState.mousemoved then
        GameState.currentState:mousemoved(x, y, dx, dy, istouch)
    end
end

-- Add delegation for mouse wheel
function love.wheelmoved(x, y)
    if GameState and GameState.currentState and GameState.currentState.wheelmoved then
        GameState.currentState:wheelmoved(x, y)
    end
end

-- Add other callbacks (love.resize, etc.) to delegate as needed
