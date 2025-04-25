-- src/controllers/AnimationController.lua
-- Manages active visual animations like card movements.

local Easing = require('src.utils.easing') -- Require our easing module
local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController:new()
    local instance = setmetatable({}, AnimationController)
    instance.activeAnimations = {} -- Stores currently running animations
    instance.nextId = 1            -- Simple ID generator
    print("AnimationController initialized.")
    return instance
end

-- Starts a new animation
-- Params should contain:
--  - type (e.g., 'cardPlay', 'shudder', 'handShudder')
--  - duration
--  - card (the card object being animated)
--  - startWorldPos {x, y} (Converted from screen coords BEFORE calling) OR startScreenPos for handShudder
--  - endWorldPos {x, y} OR endScreenPos for handShudder
--  - startScale
--  - endScale
--  - easingType (optional, e.g., 'outBounce', 'inOutBack')
--  - rotation (optional, in radians)
--  - startAlpha (optional, default 1.0)
--  - endAlpha (optional, default 1.0)
function AnimationController:addAnimation(params)
    if not params or not params.type or not params.duration or not params.card then
        print("Warning: Invalid parameters for addAnimation.")
        return nil
    end
    
    -- Check coordinates based on animation type
    if params.type == 'handShudder' then
        if not params.startScreenPos or not params.endScreenPos or 
           params.startScale == nil or params.endScale == nil then
            print("Warning: Invalid parameters for handShudder animation.")
            return nil
        end
    else
        if not params.startWorldPos or not params.endWorldPos or 
           params.startScale == nil or params.endScale == nil then
            print("Warning: Invalid parameters for animation.")
            return nil
        end
    end

    local id = self.nextId
    self.nextId = self.nextId + 1

    local animation = {
        id = id,
        type = params.type,
        startTime = love.timer.getTime(),
        duration = params.duration,
        card = params.card,
        startWorldPos = params.startWorldPos and { x = params.startWorldPos.x, y = params.startWorldPos.y } or nil,
        endWorldPos = params.endWorldPos and { x = params.endWorldPos.x, y = params.endWorldPos.y } or nil,
        startScreenPos = params.startScreenPos and { x = params.startScreenPos.x, y = params.startScreenPos.y } or nil,
        endScreenPos = params.endScreenPos and { x = params.endScreenPos.x, y = params.endScreenPos.y } or nil,
        startScale = params.startScale,
        endScale = params.endScale,
        easingType = params.easingType or "outQuad", -- Default to outQuad if not specified
        startRotation = params.startRotation or 0,
        endRotation = params.endRotation or 0,
        startAlpha = params.startAlpha or 1.0,
        endAlpha = params.endAlpha or 1.0,
        progress = 0,      -- Calculated in update
        currentWorldPos = params.startWorldPos and { x = params.startWorldPos.x, y = params.startWorldPos.y } or nil,
        currentScreenPos = params.startScreenPos and { x = params.startScreenPos.x, y = params.startScreenPos.y } or nil,
        currentScale = params.startScale, -- Calculated
        currentRotation = params.startRotation or 0, -- Calculated
        currentAlpha = params.startAlpha or 1.0, -- Calculated
        isComplete = false
    }
    self.activeAnimations[id] = animation
    print(string.format("Started animation %d: %s for card %s with easing %s", 
          id, params.type, params.card.id, animation.easingType))
    return id
end

-- Update all active animations
function AnimationController:update(dt)
    local currentTime = love.timer.getTime()
    local completedIds = {}

    for id, anim in pairs(self.activeAnimations) do
        if not anim.isComplete then
            local elapsedTime = currentTime - anim.startTime
            anim.progress = math.min(elapsedTime / anim.duration, 1.0) -- Clamp progress to 0-1

            -- Get the eased progress
            local easedProgress = Easing[anim.easingType](anim.progress)
            
            if anim.type == 'shudder' then
                -- For shudder animations, we apply the regular easing to scale and alpha
                -- but use the special shudder easing for position and rotation
                
                -- Keep position close to original position but add shake
                local shudderX = Easing.shudder(anim.progress) * 20 -- Range -4 to 4 pixels
                local shudderY = Easing.shudder(anim.progress + 0.5) * 10 -- Offset phase for Y
                
                -- Position stays at start with pure shake
                anim.currentWorldPos.x = anim.startWorldPos.x + shudderX
                anim.currentWorldPos.y = anim.startWorldPos.y + shudderY
                
                -- Add shudder to rotation too (more pronounced)
                anim.currentRotation = anim.startRotation + Easing.shudder(anim.progress + 0.25) * 0.15
                
                -- Use standard easing for scale
                anim.currentScale = Easing.apply(anim.progress, anim.startScale, 
                                                anim.endScale - anim.startScale, 
                                               Easing.outQuad)
                                               
                -- For alpha, we want it to fade in at the end
                -- This creates a stronger visual impact at start that fades to normal
                local alphaEasing = function(t) return math.min(1, t * 3) end -- Custom function for quicker fade-in
                anim.currentAlpha = Easing.apply(anim.progress, anim.startAlpha, 
                                                anim.endAlpha - anim.startAlpha, 
                                                alphaEasing)
            elseif anim.type == 'handShudder' then
                -- For hand shudder animations, similar to world shudder but in screen space
                
                -- Keep position close to original position but add shake
                local shudderX = Easing.shudder(anim.progress) * 10 -- Smaller range for hand card
                local shudderY = Easing.shudder(anim.progress + 0.5) * 5 -- Offset phase for Y
                
                -- Position stays at start with pure shake (in screen coordinates)
                anim.currentScreenPos.x = anim.startScreenPos.x + shudderX
                anim.currentScreenPos.y = anim.startScreenPos.y + shudderY
                
                -- Add shudder to rotation too (more pronounced)
                anim.currentRotation = anim.startRotation + Easing.shudder(anim.progress + 0.25) * 0.15
                
                -- Use standard easing for scale
                anim.currentScale = Easing.apply(anim.progress, anim.startScale, 
                                                anim.endScale - anim.startScale, 
                                               Easing.outQuad)
                                               
                -- For alpha, we want it to fade in at the end
                -- This creates a stronger visual impact at start that fades to normal
                local alphaEasing = function(t) return math.min(1, t * 3) end -- Custom function for quicker fade-in
                anim.currentAlpha = Easing.apply(anim.progress, anim.startAlpha, 
                                                anim.endAlpha - anim.startAlpha, 
                                                alphaEasing)
            else
                -- Standard animations use the configured easing for all properties
                -- Interpolate position using easing function
                if anim.currentWorldPos then
                    anim.currentWorldPos.x = Easing.apply(anim.progress, anim.startWorldPos.x, 
                                                       anim.endWorldPos.x - anim.startWorldPos.x, 
                                                       Easing[anim.easingType])
                    anim.currentWorldPos.y = Easing.apply(anim.progress, anim.startWorldPos.y, 
                                                       anim.endWorldPos.y - anim.startWorldPos.y, 
                                                       Easing[anim.easingType])
                end
                
                -- Interpolate scale, rotation, and alpha
                anim.currentScale = Easing.apply(anim.progress, anim.startScale, 
                                                anim.endScale - anim.startScale, 
                                                Easing[anim.easingType])
                anim.currentRotation = Easing.apply(anim.progress, anim.startRotation, 
                                                anim.endRotation - anim.startRotation, 
                                                Easing[anim.easingType])
                anim.currentAlpha = Easing.apply(anim.progress, anim.startAlpha, 
                                                anim.endAlpha - anim.startAlpha, 
                                                Easing[anim.easingType])
            end

            if anim.progress >= 1.0 then
                anim.isComplete = true
                table.insert(completedIds, id)
                print(string.format("Animation %d complete.", id))
                -- TODO: Maybe add optional onComplete callback?
            end
        end
    end

    -- Remove completed animations
    for _, id in ipairs(completedIds) do
        self.activeAnimations[id] = nil
    end
end

-- Get the current state of all active animations (for rendering)
function AnimationController:getActiveAnimations()
    -- Return a shallow copy or iterator if modification during iteration is a concern
    return self.activeAnimations
end

-- Get a set/list of card IDs currently being animated
function AnimationController:getAnimatingCardIds()
    local ids = {}
    for _, anim in pairs(self.activeAnimations) do
        ids[anim.card.id] = true -- Use map as a set for quick lookup
    end
    return ids
end

-- Forcefully remove an animation (e.g., if the card is destroyed mid-flight)
function AnimationController:removeAnimation(id)
    if self.activeAnimations[id] then
        print(string.format("Forcefully removing animation %d", id))
        self.activeAnimations[id] = nil
        return true
    end
    return false
end

return AnimationController 
