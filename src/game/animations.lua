-- src/game/animations.lua
-- Defines configuration generators for common animations

local Animations = {}

-- Generates the configuration for the card placement animation
function Animations.getCardPlayConfig(renderer, targetPlayer, cardToPlace, startWorldPos, endWorldPos)
    return {
        type = 'cardPlay',
        duration = 0.5,
        card = cardToPlace,
        startWorldPos = startWorldPos,
        endWorldPos = endWorldPos,
        startScale = renderer.HAND_CARD_SCALE or 0.6,
        endScale = 1.0,
        startRotation = (targetPlayer.orientation or 0) + math.pi * 0.1,
        endRotation = (targetPlayer.orientation or 0),
        easingType = "outBack",
        startAlpha = 0.9,
        endAlpha = 1.0,
        context = 'grid'
    }
end

-- Generates the configuration for the hand card shudder animation (e.g., for errors)
function Animations.getHandShudderConfig(renderer, currentPlayer, selectedCard, centerX, centerY, errorType)
    return {
        type = 'handShudder',
        duration = 0.4,
        card = selectedCard,
        startScreenPos = { x = centerX, y = centerY },
        endScreenPos = { x = centerX, y = centerY },
        startScale = renderer.HAND_CARD_SCALE or 0.6,
        endScale = renderer.HAND_CARD_SCALE or 0.6,
        startRotation = math.pi * 0.1,
        endRotation = (currentPlayer.orientation or 0),
        startAlpha = 0.8,
        endAlpha = 1.0,
        easingType = "shudder",
        meta = { errorType = errorType or "generic" },
        context = 'hand'
    }
end

return Animations 
