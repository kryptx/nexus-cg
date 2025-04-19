-- src/core/state_manager.lua
-- Manages game states (e.g., menu, playing, game over)

local StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local instance = setmetatable({}, StateManager)
    instance.states = {} -- Stores all registered states {name = state_object}
    instance.currentState = nil
    instance.currentStateName = nil
    return instance
end

-- Register a state object with a given name
function StateManager:register(name, state)
    if not name or not state then
        error("Attempted to register state without a valid name or state object.")
        return
    end
    if self.states[name] then
        print("Warning: Overwriting existing state: " .. name)
    end
    self.states[name] = state
    print("Registered state: " .. name)
end

-- Switch to a new state by name
function StateManager:switchState(name, ...)
    local newState = self.states[name]
    if not newState then
        error("Attempted to switch to unregistered state: " .. name)
        return
    end

    print("Switching state from " .. (self.currentStateName or "nil") .. " to " .. name)

    -- Call exit on the current state if it exists
    if self.currentState and self.currentState.exit then
        self.currentState:exit()
    end

    self.currentState = newState
    self.currentStateName = name

    -- Call enter on the new state if it exists, passing any extra arguments
    if self.currentState.enter then
        self.currentState:enter(...)
    end
end

-- Delegate LÖVE callbacks to the current state

function StateManager:update(dt)
    if self.currentState and self.currentState.update then
        self.currentState:update(dt)
    end
end

function StateManager:draw()
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

function StateManager:keypressed(key, scancode, isrepeat)
    if self.currentState and self.currentState.keypressed then
        self.currentState:keypressed(key, scancode, isrepeat)
    end
end

function StateManager:mousepressed(x, y, button, istouch, presses)
    if self.currentState and self.currentState.mousepressed then
        self.currentState:mousepressed(x, y, button, istouch, presses)
    end
end

-- Add delegates for other callbacks (mousereleased, resize, etc.) as needed

return StateManager
