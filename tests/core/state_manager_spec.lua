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

    describe("StateManager:register()", function()
        local mockState1 = { name = "Mock State 1" }

        it("should register a state object with a name", function()
            sm:register('mock1', mockState1)
            assert.are.same(mockState1, sm.states['mock1'])
        end)

        it("should allow overwriting a registered state (with warning)", function()
            local mockState2 = { name = "Mock State 2" }
            sm:register('mock1', mockState1)
            -- How to check for print warning? Can't easily with default Busted.
            -- Just check that overwrite happened.
            sm:register('mock1', mockState2)
            assert.are.same(mockState2, sm.states['mock1'])
        end)

        it("should error if name is missing", function()
            assert.error(function() sm:register(nil, mockState1) end)
        end)

        it("should error if state object is missing", function()
            assert.error(function() sm:register('mock1', nil) end)
        end)
    end)

    describe("StateManager:switchState()", function()
        local state1, state2
        local state1_enter_called, state1_exit_called
        local state2_enter_called, state2_exit_called
        local state2_enter_args

        before_each(function()
            state1_enter_called = 0
            state1_exit_called = 0
            state2_enter_called = 0
            state2_exit_called = 0
            state2_enter_args = nil

            state1 = {
                enter = function(self) state1_enter_called = state1_enter_called + 1 end,
                exit = function(self) state1_exit_called = state1_exit_called + 1 end
            }
            state2 = {
                enter = function(self, ...) state2_enter_called = state2_enter_called + 1; state2_enter_args = {...} end,
                exit = function(self) state2_exit_called = state2_exit_called + 1 end
            }
            sm:register('s1', state1)
            sm:register('s2', state2)
        end)

        it("should switch the current state and name", function()
            assert.is_nil(sm.currentState)
            sm:switchState('s1')
            assert.are.same(state1, sm.currentState)
            assert.are.equal('s1', sm.currentStateName)
        end)

        it("should call enter() on the new state", function()
            sm:switchState('s1')
            assert.are.equal(1, state1_enter_called)
            assert.are.equal(0, state1_exit_called)
            assert.are.equal(0, state2_enter_called)
            assert.are.equal(0, state2_exit_called)
        end)

        it("should call exit() on the previous state when switching", function()
            sm:switchState('s1') -- Enter s1
            sm:switchState('s2') -- Exit s1, Enter s2
            assert.are.equal(1, state1_enter_called)
            assert.are.equal(1, state1_exit_called) -- Should have been called
            assert.are.equal(1, state2_enter_called)
            assert.are.equal(0, state2_exit_called)
        end)

        it("should not call exit() if there was no previous state", function()
             sm:switchState('s1')
             assert.are.equal(0, state1_exit_called)
        end)

        it("should pass extra arguments to the enter() method", function()
            sm:switchState('s2', 10, "hello", true)
            assert.are.equal(1, state2_enter_called)
            assert.is_table(state2_enter_args)
            assert.are.equal(3, #state2_enter_args)
            assert.are.equal(10, state2_enter_args[1])
            assert.are.equal("hello", state2_enter_args[2])
            assert.is_true(state2_enter_args[3])
        end)

        it("should error if switching to an unregistered state", function()
            assert.error(function() sm:switchState('s3') end)
        end)
    end)

    describe("Callback Delegation", function()
        local state1, state2
        local s1_updated, s1_drawn, s1_keypressed, s1_mousepressed
        local s2_updated, s2_drawn, s2_keypressed, s2_mousepressed

        before_each(function()
            s1_updated = 0; s1_drawn = 0; s1_keypressed = 0; s1_mousepressed = 0
            s2_updated = 0; s2_drawn = 0; s2_keypressed = 0; s2_mousepressed = 0

            state1 = {
                update = function(self, dt) s1_updated = s1_updated + 1 end,
                draw = function(self) s1_drawn = s1_drawn + 1 end,
                keypressed = function(self, k) s1_keypressed = s1_keypressed + 1 end,
                mousepressed = function(self, x, y, b) s1_mousepressed = s1_mousepressed + 1 end,
            }
            state2 = {
                update = function(self, dt) s2_updated = s2_updated + 1 end,
                draw = function(self) s2_drawn = s2_drawn + 1 end,
                keypressed = function(self, k) s2_keypressed = s2_keypressed + 1 end,
                mousepressed = function(self, x, y, b) s2_mousepressed = s2_mousepressed + 1 end,
            }
            sm:register('s1', state1)
            sm:register('s2', state2)
        end)

        it("should delegate update() to the current state", function()
            sm:switchState('s1')
            sm:update(0.1)
            assert.are.equal(1, s1_updated)
            assert.are.equal(0, s2_updated)
            sm:switchState('s2')
            sm:update(0.1)
            assert.are.equal(1, s1_updated)
            assert.are.equal(1, s2_updated)
        end)

        it("should delegate draw() to the current state", function()
            sm:switchState('s1')
            sm:draw()
            assert.are.equal(1, s1_drawn)
            assert.are.equal(0, s2_drawn)
            sm:switchState('s2')
            sm:draw()
            assert.are.equal(1, s1_drawn)
            assert.are.equal(1, s2_drawn)
        end)

        it("should delegate keypressed() to the current state", function()
            sm:switchState('s1')
            sm:keypressed('a')
            assert.are.equal(1, s1_keypressed)
            assert.are.equal(0, s2_keypressed)
            sm:switchState('s2')
            sm:keypressed('b')
            assert.are.equal(1, s1_keypressed)
            assert.are.equal(1, s2_keypressed)
        end)

        it("should delegate mousepressed() to the current state", function()
            sm:switchState('s1')
            sm:mousepressed(1, 2, 3)
            assert.are.equal(1, s1_mousepressed)
            assert.are.equal(0, s2_mousepressed)
            sm:switchState('s2')
            sm:mousepressed(4, 5, 6)
            assert.are.equal(1, s1_mousepressed)
            assert.are.equal(1, s2_mousepressed)
        end)

        it("should not error if current state doesn't implement a callback", function()
            local state3 = {} -- No methods
            sm:register('s3', state3)
            sm:switchState('s3')
            assert.does_not_error(function() sm:update(0.1) end)
            assert.does_not_error(function() sm:draw() end)
            assert.does_not_error(function() sm:keypressed('a') end)
            assert.does_not_error(function() sm:mousepressed(1,1,1) end)
        end)

    end)

end)
