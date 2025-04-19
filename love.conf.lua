-- love.conf.lua
-- Configuration file for the LÖVE project

function love.conf(t)
    t.window.title = "NEXUS: The Convergence" -- Set the window title
    t.window.width = 1280                 -- Set the initial window width
    t.window.height = 720                -- Set the initial window height
    t.window.resizable = true            -- Allow window resizing
    t.window.vsync = 1                   -- Enable VSync (1 = enabled, 0 = disabled)

    -- Optional: Enable console for debugging output on Windows
    -- t.console = true

    -- Optional: Specify modules to load (if not using all default modules)
    -- t.modules.joystick = false
    -- t.modules.physics = false
end 
