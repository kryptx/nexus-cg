function love.conf(t)
    t.window.title = "NEXUS: The Convergence" -- Set the window title
    t.window.width = 1280                    -- Set the window width
    t.window.height = 720                   -- Set the window height
    t.window.vsync = 1                      -- Enable vertical sync (0 = off, 1 = on)
    t.window.resizable = true               -- Allow window resizing
    t.window.minwidth = 800                 -- Set minimum window width
    t.window.minheight = 600                -- Set minimum window height

    -- Enable standard modules
    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false -- Disable joystick for now
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false -- Disable physics for now
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = false   -- Disable touch for now
    t.modules.video = false   -- Disable video for now
    t.modules.window = true
    t.modules.thread = false  -- Disable thread for now
end
