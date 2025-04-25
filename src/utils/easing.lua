-- src/utils/easing.lua
-- Implementation of Robert Penner's easing functions
-- Based on: https://github.com/EmmanuelOga/easing

local Easing = {}

-- Utility function for power functions
local function pow(x, y)
    return x ^ y
end

-- Simple linear interpolation (no easing, consistent speed)
function Easing.linear(t)
    return t
end

-- Quadratic easing

function Easing.inQuad(t)
    return t * t
end

function Easing.outQuad(t)
    return t * (2 - t)
end

function Easing.inOutQuad(t)
    t = t * 2
    if t < 1 then return 0.5 * t * t end
    t = t - 1
    return -0.5 * (t * (t - 2) - 1)
end

-- Cubic easing

function Easing.inCubic(t)
    return t * t * t
end

function Easing.outCubic(t)
    t = t - 1
    return t * t * t + 1
end

function Easing.inOutCubic(t)
    t = t * 2
    if t < 1 then return 0.5 * t * t * t end
    t = t - 2
    return 0.5 * (t * t * t + 2)
end

-- Quartic easing

function Easing.inQuart(t)
    return t * t * t * t
end

function Easing.outQuart(t)
    t = t - 1
    return 1 - t * t * t * t
end

function Easing.inOutQuart(t)
    t = t * 2
    if t < 1 then return 0.5 * t * t * t * t end
    t = t - 2
    return -0.5 * (t * t * t * t - 2)
end

-- Quintic easing

function Easing.inQuint(t)
    return t * t * t * t * t
end

function Easing.outQuint(t)
    t = t - 1
    return t * t * t * t * t + 1
end

function Easing.inOutQuint(t)
    t = t * 2
    if t < 1 then return 0.5 * t * t * t * t * t end
    t = t - 2
    return 0.5 * (t * t * t * t * t + 2)
end

-- Sinusoidal easing

function Easing.inSine(t)
    return 1 - math.cos(t * (math.pi / 2))
end

function Easing.outSine(t)
    return math.sin(t * (math.pi / 2))
end

function Easing.inOutSine(t)
    return -0.5 * (math.cos(math.pi * t) - 1)
end

-- Exponential easing

function Easing.inExpo(t)
    if t == 0 then return 0 end
    return pow(2, 10 * (t - 1))
end

function Easing.outExpo(t)
    if t == 1 then return 1 end
    return 1 - pow(2, -10 * t)
end

function Easing.inOutExpo(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    t = t * 2
    if t < 1 then return 0.5 * pow(2, 10 * (t - 1)) end
    t = t - 1
    return 0.5 * (2 - pow(2, -10 * t))
end

-- Circular easing

function Easing.inCirc(t)
    return 1 - math.sqrt(1 - t * t)
end

function Easing.outCirc(t)
    t = t - 1
    return math.sqrt(1 - t * t)
end

function Easing.inOutCirc(t)
    t = t * 2
    if t < 1 then return -0.5 * (math.sqrt(1 - t * t) - 1) end
    t = t - 2
    return 0.5 * (math.sqrt(1 - t * t) + 1)
end

-- Elastic easing

function Easing.inElastic(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return -pow(2, 10 * (t - 1)) * math.sin((t - 1.1) * 5 * math.pi)
end

function Easing.outElastic(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return pow(2, -10 * t) * math.sin((t - 0.1) * 5 * math.pi) + 1
end

function Easing.inOutElastic(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    t = t * 2
    if t < 1 then return -0.5 * pow(2, 10 * (t - 1)) * math.sin((t - 1.1) * 5 * math.pi) end
    return 0.5 * pow(2, -10 * (t - 1)) * math.sin((t - 1.1) * 5 * math.pi) + 1
end

-- Back easing

function Easing.inBack(t)
    local s = 1.70158
    return t * t * ((s + 1) * t - s)
end

function Easing.outBack(t)
    local s = 1.70158
    t = t - 1
    return t * t * ((s + 1) * t + s) + 1
end

function Easing.inOutBack(t)
    local s = 1.70158 * 1.525
    t = t * 2
    if t < 1 then return 0.5 * (t * t * ((s + 1) * t - s)) end
    t = t - 2
    return 0.5 * (t * t * ((s + 1) * t + s) + 2)
end

-- Bounce easing

function Easing.outBounce(t)
    if t < 1/2.75 then
        return 7.5625 * t * t
    elseif t < 2/2.75 then
        t = t - 1.5/2.75
        return 7.5625 * t * t + 0.75
    elseif t < 2.5/2.75 then
        t = t - 2.25/2.75
        return 7.5625 * t * t + 0.9375
    else
        t = t - 2.625/2.75
        return 7.5625 * t * t + 0.984375
    end
end

function Easing.inBounce(t)
    return 1 - Easing.outBounce(1 - t)
end

function Easing.inOutBounce(t)
    if t < 0.5 then return Easing.inBounce(t * 2) * 0.5 end
    return Easing.outBounce(t * 2 - 1) * 0.5 + 0.5
end

-- Shudder easing (vibration effect with decay)
function Easing.shudder(t)
    -- Parameters for the shudder effect
    local frequency = 15  -- Higher = more shakes
    local amplitude = 0.2  -- Maximum deviation
    local decay = 2.5      -- How quickly the shudder decays
    
    -- Calculate diminishing amplitude over time (starts strong, ends subtle)
    local currentAmplitude = amplitude * math.exp(-decay * t)
    
    -- Generate oscillation with sine wave
    local oscillation = currentAmplitude * math.sin(frequency * math.pi * t)
    
    -- Return the oscillation component only - this creates a pure vibration
    -- that oscillates around 0 rather than drifting with t
    return oscillation
end

-- Apply easing function to a value
function Easing.apply(progress, start, change, easingFunc)
    easingFunc = easingFunc or Easing.linear
    return start + change * easingFunc(progress)
end

-- Main function for easing between two values
function Easing.ease(t, b, c, d, easingType)
    -- t: current time, b: beginning value, c: change in value, d: duration
    local func = Easing[easingType or "linear"] or Easing.linear
    return b + c * func(t / d)
end

return Easing 
