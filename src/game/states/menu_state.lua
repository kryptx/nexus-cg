-- src/game/states/menu_state.lua
-- The main menu state

local MenuState = {}

function MenuState:init(stateManager, love_instance) -- Accept love_instance
    -- Initialization specific to MenuState, if any (e.g., load menu assets)
    print("MenuState init")
    self.initialized = true
    self.love = love_instance -- Store the love instance
    -- Load the logo image
    local success, err = pcall(function()
        self.logo = self.love.graphics.newImage('assets/images/nexus-logo.jpg')
    end)
    if not success then
        print("Error loading logo:", err)
        self.logo = nil -- Ensure logo is nil if loading failed
    end
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

    self.love.graphics.clear(19/255, 32/255, 48/255, 1) -- Set background to #132030
    self.love.graphics.setColor(1, 1, 1, 1) -- Use self.love

    -- Draw the logo if loaded
    if self.logo then
        local logoW = self.logo:getWidth()
        local logoH = self.logo:getHeight() -- Get height for positioning text
        -- Calculate scale factor to make logo width one-third the screen width
        local scaleFactor = (w / 3) / logoW -- Changed from w / 2 to w / 3
        -- Calculate the scaled dimensions
        local scaledW = logoW * scaleFactor
        local scaledH = logoH * scaleFactor

        -- Enable smooth filtering for this image
        self.logo:setFilter('linear', 'linear')

        -- Draw logo centered horizontally, maybe 1/6th down from the top, with scaling
        self.love.graphics.draw(self.logo, (w - scaledW) / 2, h / 6, 0, scaleFactor, scaleFactor)

        -- Optional: Reset filter if other draw calls expect nearest neighbor
        -- self.logo:setFilter('nearest', 'nearest')

        -- Adjust text position based on scaled logo height + some padding
        -- self.love.graphics.printf("NEXUS: The Convergence", 0, h / 6 + scaledH + 20, w, 'center') -- Removed as it's in the logo
        self.love.graphics.printf("Press Enter to Start", 0, h / 6 + scaledH + 40, w, 'center') -- Adjusted Y position slightly
    else
        -- Fallback text positions if logo fails to load
        self.love.graphics.printf("NEXUS: The Convergence", 0, h / 3, w, 'center') -- Keep this for fallback
        self.love.graphics.printf("Press Enter to Start", 0, h / 2, w, 'center') -- Use self.love
    end
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
