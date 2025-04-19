-- tests/core/state_manager_spec.lua
-- Unit tests for the StateManager module

local StateManager = require 'src.core.state_manager'

describe("StateManager Module", function()
    local sm

    before_each(function()
        sm = StateManager:new()
    end)

    describe("StateManager:new()", function()
        it("should create an instance with empty states and no current state", function()
            assert.is_table(sm)
            assert.is_table(sm.states)
            assert.is_nil(next(sm.states)) -- Check empty
            assert.is_nil(sm.currentState)
            assert.is_nil(sm.currentStateName)
        end)
    end)

    describe("StateManager:registerState()", function()
        local mockState1 = { name = "Mock State 1" }

        it("should register a state object with a name", function()
            sm:registerState('mock1', mockState1)
            assert.are.same(mockState1, sm.states['mock1'])
        end)

        it("should allow overwriting a registered state (with warning)", function()
            local mockState2 = { name = "Mock State 2" }
            sm:registerState('mock1', mockState1)
            -- How to check for print warning? Can't easily with default Busted.
            -- Just check that overwrite happened.
            sm:registerState('mock1', mockState2)
            assert.are.same(mockState2, sm.states['mock1'])
        end)

        it("should error if name is missing", function()
            assert.error(function() sm:registerState(nil, mockState1) end)
        end)

        it("should error if state object is missing", function()
            assert.error(function() sm:registerState('mock1', nil) end)
        end)
    end)

    describe("StateManager:changeState()", function()
        local state1, state2
        local state1_enter_called, state1_exit_called, state1_exit_manager_arg
        local state2_enter_called, state2_exit_called, state2_enter_manager_arg
        local state2_enter_args

        before_each(function()
            state1_enter_called = 0
            state1_exit_called = 0
            state1_exit_manager_arg = nil
            state2_enter_called = 0
            state2_exit_called = 0
            state2_enter_manager_arg = nil
            state2_enter_args = nil

            state1 = {
                enter = function(self, manager, ...) state1_enter_called = state1_enter_called + 1 end,
                exit = function(self, manager) state1_exit_called = state1_exit_called + 1; state1_exit_manager_arg = manager end
            }
            state2 = {
                enter = function(self, manager, ...) state2_enter_called = state2_enter_called + 1; state2_enter_manager_arg = manager; state2_enter_args = {...} end,
                exit = function(self, manager) state2_exit_called = state2_exit_called + 1 end
            }
            sm:registerState('s1', state1)
            sm:registerState('s2', state2)
        end)

        it("should switch the current state and name", function()
            assert.is_nil(sm.currentState)
            sm:changeState('s1')
            assert.are.same(state1, sm.currentState)
            assert.are.equal('s1', sm.currentStateName)
        end)

        it("should call enter() on the new state, passing the manager", function()
            sm:changeState('s1')
            assert.are.equal(1, state1_enter_called)
            assert.are.equal(0, state1_exit_called)
            assert.are.equal(0, state2_enter_called)
            assert.are.equal(0, state2_exit_called)
        end)

        it("should call exit() on the previous state, passing the manager", function()
            sm:changeState('s1')
            sm:changeState('s2')
            assert.are.equal(1, state1_enter_called)
            assert.are.equal(1, state1_exit_called)
            assert.are.same(sm, state1_exit_manager_arg, "Manager should be passed to exit()")
            assert.are.equal(1, state2_enter_called)
            assert.are.equal(0, state2_exit_called)
        end)

        it("should not call exit() if there was no previous state", function()
             sm:changeState('s1')
             assert.are.equal(0, state1_exit_called)
        end)

        it("should pass manager and extra arguments to the enter() method", function()
            sm:changeState('s2', 10, "hello", true)
            assert.are.equal(1, state2_enter_called)
            assert.are.same(sm, state2_enter_manager_arg, "Manager should be passed to enter()")
            assert.is_table(state2_enter_args)
            assert.are.equal(4, #state2_enter_args)
            assert.are.equal(10, state2_enter_args[2])
            assert.are.equal("hello", state2_enter_args[3])
            assert.is_true(state2_enter_args[4])
        end)

        it("should error if switching to an unregistered state", function()
            assert.error(function() sm:changeState('s3') end)
        end)
    end)

    describe("Callback Delegation", function()
        local state1, state2
        local s1_update_manager, s1_draw_manager, s1_key_manager, s1_mouse_manager
        local s2_update_manager, s2_draw_manager, s2_key_manager, s2_mouse_manager
        local s1_updated, s1_drawn, s1_keypressed, s1_mousepressed
        local s2_updated, s2_drawn, s2_keypressed, s2_mousepressed

        before_each(function()
            s1_updated = 0; s1_drawn = 0; s1_keypressed = 0; s1_mousepressed = 0
            s2_updated = 0; s2_drawn = 0; s2_keypressed = 0; s2_mousepressed = 0
            s1_update_manager = nil; s1_draw_manager = nil; s1_key_manager = nil; s1_mouse_manager = nil
            s2_update_manager = nil; s2_draw_manager = nil; s2_key_manager = nil; s2_mouse_manager = nil

            state1 = {
                update = function(self, manager, dt) s1_updated = s1_updated + 1; s1_update_manager = manager end,
                draw = function(self, manager) s1_drawn = s1_drawn + 1; s1_draw_manager = manager end,
                keypressed = function(self, manager, k) s1_keypressed = s1_keypressed + 1; s1_key_manager = manager end,
                mousepressed = function(self, manager, x, y, b) s1_mousepressed = s1_mousepressed + 1; s1_mouse_manager = manager end,
            }
            state2 = {
                update = function(self, manager, dt) s2_updated = s2_updated + 1; s2_update_manager = manager end,
                draw = function(self, manager) s2_drawn = s2_drawn + 1; s2_draw_manager = manager end,
                keypressed = function(self, manager, k) s2_keypressed = s2_keypressed + 1; s2_key_manager = manager end,
                mousepressed = function(self, manager, x, y, b) s2_mousepressed = s2_mousepressed + 1; s2_mouse_manager = manager end,
            }
            sm:registerState('s1', state1)
            sm:registerState('s2', state2)
        end)

        it("should delegate update() to the current state, passing manager", function()
            sm:changeState('s1')
            sm:update(0.1)
            assert.are.equal(1, s1_updated)
            assert.are.same(sm, s1_update_manager)
            assert.are.equal(0, s2_updated)
            sm:changeState('s2')
            sm:update(0.1)
            assert.are.equal(1, s1_updated)
            assert.are.equal(1, s2_updated)
            assert.are.same(sm, s2_update_manager)
        end)

        it("should delegate draw() to the current state, passing manager", function()
            sm:changeState('s1')
            sm:draw()
            assert.are.equal(1, s1_drawn)
            assert.are.same(sm, s1_draw_manager)
            assert.are.equal(0, s2_drawn)
            sm:changeState('s2')
            sm:draw()
            assert.are.equal(1, s1_drawn)
            assert.are.equal(1, s2_drawn)
            assert.are.same(sm, s2_draw_manager)
        end)

        it("should delegate keypressed() to the current state, passing manager", function()
            sm:changeState('s1')
            sm:keypressed('a')
            assert.are.equal(1, s1_keypressed)
            assert.are.same(sm, s1_key_manager)
            assert.are.equal(0, s2_keypressed)
            sm:changeState('s2')
            sm:keypressed('b')
            assert.are.equal(1, s1_keypressed)
            assert.are.equal(1, s2_keypressed)
            assert.are.same(sm, s2_key_manager)
        end)

        it("should delegate mousepressed() to the current state, passing manager", function()
            sm:changeState('s1')
            sm:mousepressed(1, 2, 3)
            assert.are.equal(1, s1_mousepressed)
            assert.are.same(sm, s1_mouse_manager)
            assert.are.equal(0, s2_mousepressed)
            sm:changeState('s2')
            sm:mousepressed(4, 5, 6)
            assert.are.equal(1, s1_mousepressed)
            assert.are.equal(1, s2_mousepressed)
            assert.are.same(sm, s2_mouse_manager)
        end)

        it("should not error if current state doesn't implement a callback", function()
            local state3 = {} -- No methods
            sm:registerState('s3', state3)
            sm:changeState('s3')
            assert.does_not.error(function() sm:update(0.1) end)
            assert.does_not.error(function() sm:draw() end)
            assert.does_not.error(function() sm:keypressed('a') end)
            assert.does_not.error(function() sm:mousepressed(1,1,1) end)
        end)

    end)

end)
