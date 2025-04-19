-- tests/game/states/menu_state_spec.lua

local busted = require('busted')
local assert = require('luassert')
local spy = require('luassert.spy') -- Require at the top level
local match = require('luassert.match') -- Require match

-- No need for the global love mock anymore if MenuState uses injected dependency

local MenuState = require('src.game.states.menu_state')

describe("MenuState", function()
    -- local spy = require('luassert.spy') -- Remove require from here
    local menuState
    local mockStateManager
    -- Remove originalLove variables
    local mockLove -- Single mock love object

    before_each(function()
        -- Remove storing/replacing global love functions

        -- Create mock love object directly
        mockLove = {
            graphics = {
                getWidth = spy.new(function() return 800 end), -- Use spy.new
                getHeight = spy.new(function() return 600 end), -- Use spy.new
                clear = spy.new(function() end), -- Use spy.new
                setColor = spy.new(function() end), -- Use spy.new
                printf = spy.new(function() end) -- Use spy.new
            },
            window = {
                setTitle = spy.new(function() end) -- Use spy.new
            },
            event = {
                quit = spy.new(function() end) -- Use spy.new
            }
        }

        -- Mock StateManager
        mockStateManager = {
            changeState = spy.new(function() end) -- Use spy.new
        }

        -- Create a new MenuState instance for each test
        menuState = setmetatable({}, { __index = MenuState })
        -- init/enter will be called in tests, passing mockLove
    end)

    -- after_each(function()
    --     -- Remove restoring global love functions
    --     spy.restore() -- Use spy.restore for global cleanup
    -- end)

    it("should initialize correctly when init is called", function()
        -- Pass mockLove to init
        menuState:init(mockStateManager, mockLove)
        assert.is_true(menuState.initialized)
        assert.same(mockLove, menuState.love) -- Verify mockLove was stored
    end)

    describe(":enter()", function()
        it("should call init with dependencies if not initialized", function()
            -- Use spy.on to replace the method on the object
            local init_spy = spy.on(menuState, 'init')
            -- Pass mockLove to enter
            menuState:enter(mockStateManager, mockLove)
            -- Assert against the spy object returned by spy.on
            assert.spy(init_spy).was.called(1)
            -- Check that init was called with mockLove, using match.is_ref for self
            assert.spy(init_spy).was.called_with(match.is_ref(menuState), mockStateManager, mockLove)
            -- Also check that enter stored mockLove if init ran
            assert.same(mockLove, menuState.love)
            init_spy:revert() -- Put revert back here
        end)

        it("should not call init if already initialized", function()
            -- Initialize first, passing mockLove
            menuState:init(mockStateManager, mockLove)
            -- Use spy.on to replace the method on the object
            local init_spy = spy.on(menuState, 'init')
            -- Pass mockLove to enter
            menuState:enter(mockStateManager, mockLove)
            -- Assert against the spy object returned by spy.on
            assert.spy(init_spy).was.not_called()
            init_spy:revert() -- Put revert back here
        end)

        it("should set the window title using injected love object", function()
            -- Pass mockLove to enter
            menuState:enter(mockStateManager, mockLove)
            -- Check the spy on the mockLove object
            assert.spy(mockLove.window.setTitle).was.called(1)
            assert.spy(mockLove.window.setTitle).was.called_with("NEXUS: The Convergence - Main Menu")
        end)
    end)

    describe(":draw()", function()
        it("should call graphics functions on injected love object", function()
             -- Enter first to initialize and set love object
            menuState:enter(mockStateManager, mockLove)
            menuState:draw(mockStateManager)
            -- Check spies on the mockLove object
            assert.spy(mockLove.graphics.clear).was.called(1)
            assert.spy(mockLove.graphics.setColor).was.called(1)
            assert.spy(mockLove.graphics.printf).was.called(2) -- Title and prompt
            assert.spy(mockLove.graphics.getWidth).was.called(1)
            assert.spy(mockLove.graphics.getHeight).was.called(1)
        end)
    end)

    describe(":keypressed()", function()
        before_each(function()
             -- Enter first to initialize and set love object
            menuState:enter(mockStateManager, mockLove)
        end)

        -- No changes needed here for stateManager calls
        it("should change state to 'play' on 'return' key", function()
            menuState:keypressed(mockStateManager, 'return')
            assert.spy(mockStateManager.changeState).was.called(1)
            assert.spy(mockStateManager.changeState).was.called_with(mockStateManager, 'play')
        end)

        it("should change state to 'play' on 'kpenter' key", function()
            menuState:keypressed(mockStateManager, 'kpenter')
            assert.spy(mockStateManager.changeState).was.called(1)
            assert.spy(mockStateManager.changeState).was.called_with(mockStateManager, 'play')
        end)

        it("should call quit on injected love object event on 'escape' key", function()
            menuState:keypressed(mockStateManager, 'escape')
            -- Check the spy on the mockLove object
            assert.spy(mockLove.event.quit).was.called(1)
        end)

        it("should not change state or quit on other keys", function()
            menuState:keypressed(mockStateManager, 'a')
            menuState:keypressed(mockStateManager, 'space')
            assert.spy(mockStateManager.changeState).was.not_called()
             -- Check the spy on the mockLove object
            assert.spy(mockLove.event.quit).was.not_called()
        end)
    end)

end) 
