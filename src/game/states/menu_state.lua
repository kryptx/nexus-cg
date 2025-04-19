-- src/game/states/menu_state.lua
-- The main menu state

local MenuState = {}

function MenuState:init(stateManager, love_instance) -- Accept love_instance
    -- Initialization specific to MenuState, if any (e.g., load menu assets)
    print("MenuState init")
    self.initialized = true
    self.love = love_instance -- Store the love instance
end

function MenuState:enter(stateManager, love_instance) -- Accept love_instance here too for consistency
    -- Called when entering this state
    print("Entering Menu State")
    self.love = love_instance -- Ensure self.love is set from the enter argument
    if not self.initialized then -- Simple flag to run init only once
        self:init(stateManager, love_instance) -- Pass love_instance to init
    end
    self.love.window.setTitle("NEXUS: The Convergence - Main Menu") -- Use self.love
end

function MenuState:update(stateManager, dt)
    -- Update logic for the menu (e.g., button hover effects)
    -- For now, does nothing
end

function MenuState:draw(stateManager)
    -- Draw the menu screen
    local w = self.love.graphics.getWidth() -- Use self.love
    local h = self.love.graphics.getHeight() -- Use self.love

    self.love.graphics.clear(0.2, 0.2, 0.25, 1) -- Use self.love
    self.love.graphics.setColor(1, 1, 1, 1) -- Use self.love
    self.love.graphics.printf("NEXUS: The Convergence", 0, h / 3, w, 'center') -- Use self.love
    self.love.graphics.printf("Press Enter to Start", 0, h / 2, w, 'center') -- Use self.love
end

function MenuState:keypressed(stateManager, key)
    if key == 'return' or key == 'kpenter' then
        print("Enter pressed, changing to Play State")
        stateManager:changeState('play') -- Use passed-in manager
    elseif key == 'escape' then
        self.love.event.quit() -- Use self.love
    end
end

-- Add other necessary methods like mousepressed if using UI buttons

return MenuState 
