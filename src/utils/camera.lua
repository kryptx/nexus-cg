local Easing = require('src.utils.easing') -- Import Easing module
local camera = {}

---
--- Convert screen coordinates to world coordinates taking into account camera zoom, rotation, and pan.
--- @param state table The PlayState instance containing camera state fields: cameraX, cameraY, cameraZoom, cameraRotation
--- @param sx number Screen x-coordinate
--- @param sy number Screen y-coordinate
--- @return number wx World x-coordinate
--- @return number wy World y-coordinate
---
function camera.screenToWorld(state, sx, sy)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cx, cy = screenW / 2, screenH / 2
    -- Translate to pivot center
    local dx, dy = sx - cx, sy - cy
    -- Rotate by camera rotation
    local angle = state.cameraRotation or 0
    local cosA, sinA = math.cos(angle), math.sin(angle)
    local rx = dx * cosA - dy * sinA
    local ry = dx * sinA + dy * cosA
    -- Scale and pan
    local wx = rx / state.cameraZoom + state.cameraX
    local wy = ry / state.cameraZoom + state.cameraY
    return wx, wy
end

---
--- Apply zoom centered around the current mouse position, updating cameraZoom, cameraX, and cameraY.
--- @param state table The PlayState instance containing camera state fields: cameraX, cameraY, cameraZoom, minZoom, maxZoom
--- @param dyScroll number Amount of vertical wheel scroll (positive to zoom in, negative to zoom out)
---
function camera.zoom(state, dyScroll)
    -- Capture old camera values
    local oldZoom = state.cameraZoom
    local oldCameraX, oldCameraY = state.cameraX, state.cameraY
    -- Mouse position in screen coords
    local mouseX, mouseY = love.mouse.getPosition()
    -- Compute world position under cursor before zoom
    local worldMouseX, worldMouseY = camera.screenToWorld(state, mouseX, mouseY)
    -- Calculate new zoom level
    local zoomFactor = 1.1
    if dyScroll > 0 then
        state.cameraZoom = math.min(state.maxZoom, state.cameraZoom * zoomFactor)
    else
        state.cameraZoom = math.max(state.minZoom, state.cameraZoom / zoomFactor)
    end
    -- Adjust camera to keep world point under cursor
    local newZoom = state.cameraZoom
    local factor = oldZoom / newZoom
    state.cameraX = worldMouseX - (worldMouseX - oldCameraX) * factor
    state.cameraY = worldMouseY - (worldMouseY - oldCameraY) * factor
end

-- NEW: Function to handle camera animation
function camera.animateToTarget(state, animationController, targetX, targetY, targetRotation, targetZoom, duration)
    if animationController then
        local startPos = { x = state.cameraX, y = state.cameraY }
        local startRotation = state.cameraRotation
        local startZoom = state.cameraZoom
        -- Create a unique identifier for this camera animation
        local uniqueCardId = "camera_anim_" .. os.time() .. tostring(math.random())
        -- Add camera animation with easing, capturing numeric ID returned by the controller
        local numericAnimId = animationController:addAnimation({
            type = 'cameraMove',
            duration = duration,
            card = { id = uniqueCardId, instanceId = uniqueCardId },
            startWorldPos = startPos,
            endWorldPos = { x = targetX, y = targetY },
            startScale = startZoom,
            endScale = targetZoom,
            startRotation = startRotation,
            endRotation = targetRotation,
            easingType = "inOutQuad",
            meta = {
                animatingZoom = true,
                startZoom = startZoom,
                targetZoom = targetZoom
            }
        })
        -- Determine the key to use (numeric ID preferred, fallback to string)
        local animKey = numericAnimId or uniqueCardId
        -- Register completion callback for this animation
        animationController:registerCompletionCallback(animKey, function()
            state.cameraX = targetX
            state.cameraY = targetY
            state.cameraRotation = targetRotation
            state.cameraZoom = targetZoom
        end)
        -- Store animation key on the state for update tracking
        state.currentCameraAnimation = animKey
        -- Return the animation key so callers can attach callbacks
        return animKey
    else
        -- Fallback to instant movement
        state.cameraX = targetX
        state.cameraY = targetY
        state.cameraRotation = targetRotation
        state.cameraZoom = targetZoom
    end
end

-- NEW: Function to update camera state from animation
function camera.updateFromAnimation(state, animationController)
    if animationController and state.currentCameraAnimation then
        local activeAnims = animationController:getActiveAnimations()
        local cameraAnim = activeAnims and activeAnims[state.currentCameraAnimation]
        if cameraAnim then
            state.cameraX = cameraAnim.currentWorldPos.x
            state.cameraY = cameraAnim.currentWorldPos.y
            state.cameraRotation = cameraAnim.currentRotation
            -- Apply zoom animation if meta data indicates
            if cameraAnim.meta and cameraAnim.meta.animatingZoom then
                local zoomProgress = cameraAnim.progress
                local startZoom = cameraAnim.meta.startZoom
                local targetZoom = cameraAnim.meta.targetZoom
                local easedProgress = Easing.inOutQuad(zoomProgress)
                state.cameraZoom = startZoom + (targetZoom - startZoom) * easedProgress
            end
        else
            -- Animation might have finished, clear the tracking ID
            state.currentCameraAnimation = nil
        end
    end
end

return camera 
