-- src/core/state_manager.lua
-- Manages game states (e.g., menu, playing, game over)

local StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local instance = setmetatable({}, StateManager)
    instance.states = {} -- Stores all registered states {name = state_object}
    instance.currentState = nil
    instance.currentStateName = nil
    -- Add a reference to self for convenience in delegate methods
    -- instance.manager = instance -- Optional, could pass 'self' directly
    return instance
end

-- Renamed for clarity to match main.lua usage
function StateManager:registerState(name, state)
    if not name or not state then
        error("Attempted to register state without a valid name or state object.")
        return
    end
    if self.states[name] then
        print("Warning: Overwriting existing state: " .. name)
    end
    self.states[name] = state
    -- Pass the manager to the state if it has a method to accept it (optional DI approach)
    -- if state.setManager then state:setManager(self) end 
    print("Registered state: " .. name)
end

-- Renamed for clarity to match main.lua usage
function StateManager:changeState(name, ...)
    local newState = self.states[name]
    if not newState then
        error("Attempted to switch to unregistered state: " .. name)
        return
    end

    print("Switching state from " .. (self.currentStateName or "nil") .. " to " .. name)

    -- Call exit on the current state if it exists
    if self.currentState and self.currentState.exit then
        self.currentState:exit(self) -- Pass manager to exit
    end

    self.currentState = newState
    self.currentStateName = name

    -- Call enter on the new state if it exists, passing any extra arguments
    if self.currentState.enter then
        -- Pass manager, the global love object, and then any extra arguments
        self.currentState:enter(self, love, ...) 
    end
end

-- Helper to check if current state implements a method
function StateManager:respondsTo(methodName)
    return self.currentState and type(self.currentState[methodName]) == 'function'
end

-- Delegate LÖVE callbacks to the current state, passing the manager instance

function StateManager:update(dt)
    if self:respondsTo("update") then
        self.currentState:update(self, dt)
    end
end

function StateManager:draw()
    if self:respondsTo("draw") then
        self.currentState:draw(self)
    end
end

function StateManager:keypressed(key, scancode, isrepeat)
    if self:respondsTo("keypressed") then
        self.currentState:keypressed(self, key, scancode, isrepeat)
    end
end

function StateManager:mousepressed(x, y, button, istouch, presses)
    if self:respondsTo("mousepressed") then
        self.currentState:mousepressed(self, x, y, button, istouch, presses)
    end
end

function StateManager:mousereleased(x, y, button, istouch)
     if self:respondsTo("mousereleased") then
        self.currentState:mousereleased(self, x, y, button, istouch)
    end
end

function StateManager:mousemoved(x, y, dx, dy, istouch)
     if self:respondsTo("mousemoved") then
        self.currentState:mousemoved(self, x, y, dx, dy, istouch)
    end
end

function StateManager:wheelmoved(x, y)
     if self:respondsTo("wheelmoved") then
        self.currentState:wheelmoved(self, x, y)
    end
end

function StateManager:resize(w, h)
    if self:respondsTo("resize") then
        self.currentState:resize(self, w, h)
    end
end

function StateManager:quit()
    if self:respondsTo("quit") then
        self.currentState:quit(self)
    end
end

return StateManager
