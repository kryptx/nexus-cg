-- src/game/states/menu_state.lua
-- The main menu state

local MenuState = {}

function MenuState:enter()
    print("Entered Menu State")
end

function MenuState:update(dt)
    -- Menu logic (e.g., wait for 'Enter' key)
end

function MenuState:draw()
    love.graphics.printf("Main Menu\nPress Enter to Play\nPress Esc to Quit", 0, love.graphics.getHeight()/2 - 30, love.graphics.getWidth(), "center")
end

function MenuState:keypressed(key)
    if key == "return" or key == "kpenter" then
        GameState:switchState('play') -- GameState is global in main.lua for now
    elseif key == "escape" then
        love.event.quit()
    end
end

return MenuState 
