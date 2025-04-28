require 'tests.test_helper'
local CameraUtil = require('src.utils.camera')
local Easing = require('src.utils.easing') -- Need easing for update test
local spy = require 'luassert.spy' -- For mocking controller

describe("CameraUtil Module", function()
    local state
    local mouseX, mouseY
    local mockAnimationController -- Declare mock controller

    before_each(function()
        -- Mock screen size and mouse position (using test_helper defaults, override if needed)
        love.graphics.getWidth = function() return 200 end -- Override needed for this test's coords
        love.graphics.getHeight = function() return 100 end -- Override needed for this test's coords
        mouseX, mouseY = 100, 50
        love.mouse.getPosition = function() return mouseX, mouseY end -- Keep this override for specific test coords

        state = {
            cameraX = 0,
            cameraY = 0,
            cameraZoom = 1.0,
            cameraRotation = 0.0,
            minZoom = 0.5,
            maxZoom = 3.0
        }

        -- Create a new mock AnimationController for each test
        mockAnimationController = {
            addAnimation = spy.new(function() end),
            registerCompletionCallback = spy.new(function(id, cb) end),
            getActiveAnimations = spy.new(function() return {} end)
        }
    end)

    it("screenToWorld maps screen center to world origin with default state", function()
        local wx, wy = CameraUtil.screenToWorld(state, mouseX, mouseY)
        -- Center of screen should map to (0,0)
        assert.is_true(math.abs(wx) < 1e-6)
        assert.is_true(math.abs(wy) < 1e-6)
    end)

    it("zoom maintains world point under cursor invariant and increases zoom on scroll up", function()
        -- Set initial camera state
        state.cameraX = 10
        state.cameraY = 20
        state.cameraZoom = 1.0

        -- Record world point under cursor before zoom
        local bwx, bwy = CameraUtil.screenToWorld(state, mouseX, mouseY)
        -- Zoom in
        CameraUtil.zoom(state, 1)
        -- Record world point after zoom
        local awx, awy = CameraUtil.screenToWorld(state, mouseX, mouseY)

        -- World point should remain the same under cursor
        assert.is_true(math.abs(bwx - awx) < 1e-6)
        assert.is_true(math.abs(bwy - awy) < 1e-6)
        -- Zoom factor should increase
        assert.is_true(state.cameraZoom > 1.0)
    end)

    it("zoom does not exceed maxZoom or go below minZoom boundaries", function()
        -- Test maxZoom boundary
        state.cameraZoom = state.maxZoom
        CameraUtil.zoom(state, 1)
        assert.are.equal(state.maxZoom, state.cameraZoom)
        -- Test minZoom boundary
        state.cameraZoom = state.minZoom
        CameraUtil.zoom(state, -1)
        assert.are.equal(state.minZoom, state.cameraZoom)
    end)

    describe("animateToTarget", function() -- New describe block
        it("should add animation when animationController is provided", function()
            -- Arrange
            local targetX, targetY = 100, 200
            local targetRot, targetZoom = math.pi / 4, 1.5
            local duration = 0.5
            local capturedArgs = nil
            local addCalls = 0
            mockAnimationController.addAnimation = function(self, args)
                addCalls = addCalls + 1
                capturedArgs = args
            end
            local registerCalls = {}
            mockAnimationController.registerCompletionCallback = function(self, id, cb)
                table.insert(registerCalls, { id = id, cb = cb })
            end
            -- Act
            CameraUtil.animateToTarget(state, mockAnimationController, targetX, targetY, targetRot, targetZoom, duration)
            -- Assert
            assert.are.equal(1, addCalls)
            assert.are.equal('cameraMove', capturedArgs.type)
            assert.are.equal(duration, capturedArgs.duration)
            assert.are.equal(state.cameraX, capturedArgs.startWorldPos.x)
            assert.are.equal(state.cameraY, capturedArgs.startWorldPos.y)
            assert.are.equal(targetX, capturedArgs.endWorldPos.x)
            assert.are.equal(targetY, capturedArgs.endWorldPos.y)
            assert.are.equal(targetRot, capturedArgs.endRotation)
            assert.are.equal(targetZoom, capturedArgs.endScale)
            assert.are.equal(1, #registerCalls)
            assert.is_function(registerCalls[1].cb)
            assert.truthy(state.currentCameraAnimation)
        end)

        it("should set state directly when animationController is nil", function()
            -- Arrange
            local targetX, targetY = 100, 200
            local targetRot, targetZoom = math.pi / 4, 1.5
            local duration = 0.5

            -- Act
            CameraUtil.animateToTarget(state, nil, targetX, targetY, targetRot, targetZoom, duration)

            -- Assert
            assert.spy(mockAnimationController.addAnimation).was_not_called()
            assert.are.equal(targetX, state.cameraX)
            assert.are.equal(targetY, state.cameraY)
            assert.are.equal(targetRot, state.cameraRotation)
            assert.are.equal(targetZoom, state.cameraZoom)
            assert.is_nil(state.currentCameraAnimation)
        end)

        it("completion callback should set final state", function()
            -- Arrange
            local targetX, targetY = 50, -50
            local targetRot, targetZoom = 0, 2.0
            local duration = 0.1
            local capturedCallback = nil
            local registerCalls = {}
            mockAnimationController.registerCompletionCallback = function(self, id, cb)
                table.insert(registerCalls, { id = id, cb = cb })
                capturedCallback = cb
            end
            -- Act
            CameraUtil.animateToTarget(state, mockAnimationController, targetX, targetY, targetRot, targetZoom, duration)
            -- Assert before executing callback
            assert.are.equal(1, #registerCalls)
            assert.is_function(capturedCallback)
            -- Simulate callback execution
            capturedCallback()
            -- Assert state after callback
            assert.are.equal(targetX, state.cameraX)
            assert.are.equal(targetY, state.cameraY)
            assert.are.equal(targetRot, state.cameraRotation)
            assert.are.equal(targetZoom, state.cameraZoom)
        end)
    end)

    describe("updateFromAnimation", function() -- New describe block
        it("should update camera state from active animation data", function()
            -- Arrange
            local animId = "test_cam_anim_123"
            state.currentCameraAnimation = animId
            local currentPos = { x = 55, y = 66 }
            local currentRot = 0.5
            local currentZoom = 1.2
            local activeAnims = {
                [animId] = {
                    currentWorldPos = currentPos,
                    currentRotation = currentRot,
                    progress = 0.5, -- Dummy progress
                    meta = {
                        animatingZoom = true,
                        startZoom = 1.0,
                        targetZoom = 1.4 -- Based on currentZoom calculation below
                    }
                }
            }
            -- Override getActiveAnimations to return our activeAnims
            mockAnimationController.getActiveAnimations = spy.new(function() return activeAnims end)

            -- Calculate expected zoom based on easing
            local expectedZoom = 1.0 + (1.4 - 1.0) * Easing.inOutQuad(0.5)

            -- Act
            CameraUtil.updateFromAnimation(state, mockAnimationController)

            -- Assert
            assert.spy(mockAnimationController.getActiveAnimations).was_called(1)
            assert.are.equal(currentPos.x, state.cameraX)
            assert.are.equal(currentPos.y, state.cameraY)
            assert.are.equal(currentRot, state.cameraRotation)
            assert.is_true(math.abs(expectedZoom - state.cameraZoom) < 1e-6, "Zoom should be updated with easing")
            assert.are.equal(animId, state.currentCameraAnimation) -- Should not be cleared yet
        end)

        it("should clear currentCameraAnimation if animation is no longer active", function()
            -- Arrange
            state.currentCameraAnimation = "old_anim_id"
            -- Override getActiveAnimations to return no animations
            mockAnimationController.getActiveAnimations = spy.new(function() return {} end)

            -- Act
            CameraUtil.updateFromAnimation(state, mockAnimationController)

            -- Assert
            assert.spy(mockAnimationController.getActiveAnimations).was_called(1)
            assert.is_nil(state.currentCameraAnimation)
        end)

        it("should do nothing if no currentCameraAnimation is set", function()
            -- Arrange
            state.currentCameraAnimation = nil
            local originalX, originalY = state.cameraX, state.cameraY

            -- Act
            CameraUtil.updateFromAnimation(state, mockAnimationController)

            -- Assert
            assert.spy(mockAnimationController.getActiveAnimations).was_not_called()
            assert.are.equal(originalX, state.cameraX)
            assert.are.equal(originalY, state.cameraY)
        end)

        it("should handle animations without zoom metadata gracefully", function()
            -- Arrange
            local animId = "no_zoom_anim"
            state.currentCameraAnimation = animId
            local currentPos = { x = 10, y = 10 }
            local currentRot = 0.1
            local originalZoom = state.cameraZoom
            local activeAnims = {
                [animId] = {
                    currentWorldPos = currentPos,
                    currentRotation = currentRot,
                    meta = {} -- No animatingZoom info
                }
            }
            -- Override getActiveAnimations to return our activeAnims without zoom metadata
            mockAnimationController.getActiveAnimations = spy.new(function() return activeAnims end)

            -- Act
            CameraUtil.updateFromAnimation(state, mockAnimationController)

            -- Assert
            assert.are.equal(currentPos.x, state.cameraX)
            assert.are.equal(currentPos.y, state.cameraY)
            assert.are.equal(currentRot, state.cameraRotation)
            assert.are.equal(originalZoom, state.cameraZoom) -- Zoom should not change
        end)
    end)
end) 
