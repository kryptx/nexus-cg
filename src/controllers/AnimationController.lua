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
--  - type (e.g., 'cardPlay')
--  - duration
--  - card (the card object being animated)
--  - startWorldPos {x, y} (Converted from screen coords BEFORE calling)
--  - endWorldPos {x, y}
--  - startScale
--  - endScale
--  - easingType (optional, e.g., 'outBounce', 'inOutBack')
--  - rotation (optional, in radians)
--  - startAlpha (optional, default 1.0)
--  - endAlpha (optional, default 1.0)
function AnimationController:addAnimation(params)
    if not params or not params.type or not params.duration or not params.card or
       not params.startWorldPos or not params.endWorldPos or
       params.startScale == nil or params.endScale == nil then
        print("Warning: Invalid parameters for addAnimation.")
        return nil
    end

    local id = self.nextId
    self.nextId = self.nextId + 1

    local animation = {
        id = id,
        type = params.type,
        startTime = love.timer.getTime(),
        duration = params.duration,
        card = params.card,
        startWorldPos = { x = params.startWorldPos.x, y = params.startWorldPos.y },
        endWorldPos = { x = params.endWorldPos.x, y = params.endWorldPos.y },
        startScale = params.startScale,
        endScale = params.endScale,
        easingType = params.easingType or "outQuad", -- Default to outQuad if not specified
        startRotation = params.startRotation or 0,
        endRotation = params.endRotation or 0,
        startAlpha = params.startAlpha or 1.0,
        endAlpha = params.endAlpha or 1.0,
        progress = 0,      -- Calculated in update
        currentWorldPos = { x = params.startWorldPos.x, y = params.startWorldPos.y }, -- Calculated
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

            -- Interpolate position using easing function
            anim.currentWorldPos.x = Easing.apply(anim.progress, anim.startWorldPos.x, 
                                                 anim.endWorldPos.x - anim.startWorldPos.x, 
                                                 Easing[anim.easingType])
            anim.currentWorldPos.y = Easing.apply(anim.progress, anim.startWorldPos.y, 
                                                 anim.endWorldPos.y - anim.startWorldPos.y, 
                                                 Easing[anim.easingType])
            
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
