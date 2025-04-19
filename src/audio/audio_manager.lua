-- src/audio/audio_manager.lua
-- Handles loading, playing and managing audio assets

local AudioManager = {}
AudioManager.__index = AudioManager

-- Check if LÖVE is available
local hasLove = type(love) == "table" and type(love.audio) == "table"

-- Constructor
function AudioManager:new()
    local instance = setmetatable({}, AudioManager)
    
    -- Sound effect collections
    instance.sounds = {} -- Map of sound IDs to LÖVE Source objects
    
    -- Music tracks
    instance.music = {} -- Map of music IDs to LÖVE Source objects
    instance.currentMusic = nil -- Currently playing music track ID
    
    -- Volume levels (0.0 to 1.0)
    instance.soundVolume = 0.7
    instance.musicVolume = 0.5
    
    -- Whether audio is enabled
    instance.soundEnabled = true
    instance.musicEnabled = true
    
    return instance
end

-- =====================
-- SOUND EFFECT METHODS
-- =====================

-- Load a sound effect
-- id: Unique identifier for the sound
-- path: File path to the sound file
-- returns: Success status
function AudioManager:loadSound(id, path)
    if self.sounds[id] then
        -- Sound already loaded, skip
        return true
    end
    
    if not hasLove then
        print("Failed to load sound: " .. id .. " from " .. path)
        print("LÖVE framework is not available")
        self.sounds[id] = {
            -- Create a mock sound object for testing
            path = path,
            volume = self.soundVolume,
            playing = false,
            setVolume = function(self, vol) self.volume = vol end,
            setPitch = function(self, p) self.pitch = p end,
            play = function(self) self.playing = true end,
            stop = function(self) self.playing = false end,
            clone = function(self) 
                local clone = {}
                for k, v in pairs(self) do clone[k] = v end
                return clone
            end
        }
        return true
    end
    
    local success, source = pcall(function()
        return love.audio.newSource(path, "static")
    end)
    
    if success then
        self.sounds[id] = source
        self.sounds[id]:setVolume(self.soundVolume)
        return true
    else
        print("Failed to load sound: " .. id .. " from " .. path)
        print(source) -- Error message
        return false
    end
end

-- Play a sound effect
-- id: Identifier of the sound to play
-- volume: Optional volume override (0.0 to 1.0)
-- pitch: Optional pitch modifier (default 1.0)
function AudioManager:playSound(id, volume, pitch)
    if not self.soundEnabled then return end
    
    local sound = self.sounds[id]
    if not sound then
        print("Sound not found: " .. id)
        return
    end
    
    -- Clone the source to allow multiple instances of the same sound
    local clone = sound.clone and sound:clone() or sound
    if clone.setVolume then
        clone:setVolume(volume or self.soundVolume)
    end
    
    if pitch and clone.setPitch then
        clone:setPitch(pitch)
    end
    
    if clone.play then
        clone:play()
    end
end

-- Set global sound volume
-- volume: New volume level (0.0 to 1.0)
function AudioManager:setSoundVolume(volume)
    self.soundVolume = math.max(0, math.min(1, volume))
    
    -- Update all loaded sounds
    for _, sound in pairs(self.sounds) do
        if sound.setVolume then
            sound:setVolume(self.soundVolume)
        end
    end
end

-- Toggle sound effects on/off
function AudioManager:toggleSound()
    self.soundEnabled = not self.soundEnabled
    return self.soundEnabled
end

-- =====================
-- MUSIC METHODS
-- =====================

-- Load a music track
-- id: Unique identifier for the music
-- path: File path to the music file
-- returns: Success status
function AudioManager:loadMusic(id, path)
    if self.music[id] then
        -- Music already loaded, skip
        return true
    end
    
    if not hasLove then
        print("Failed to load music: " .. id .. " from " .. path)
        print("LÖVE framework is not available")
        self.music[id] = {
            -- Create a mock music object for testing
            path = path,
            sourceType = "stream",
            volume = self.musicVolume,
            playing = false,
            looping = true,
            setVolume = function(self, vol) self.volume = vol end,
            setLooping = function(self, loop) self.looping = loop end,
            play = function(self) self.playing = true end,
            stop = function(self) self.playing = false end,
            pause = function(self) self.playing = false end,
            isPlaying = function(self) return self.playing end
        }
        return true
    end
    
    local success, source = pcall(function()
        return love.audio.newSource(path, "stream") -- Use streaming for music
    end)
    
    if success then
        self.music[id] = source
        self.music[id]:setVolume(self.musicVolume)
        self.music[id]:setLooping(true) -- Music tracks loop by default
        return true
    else
        print("Failed to load music: " .. id .. " from " .. path)
        print(source) -- Error message
        return false
    end
end

-- Play a music track
-- id: Identifier of the music to play
-- fadeTime: Optional time to fade in (seconds)
function AudioManager:playMusic(id, fadeTime)
    if not self.musicEnabled then return end
    
    local music = self.music[id]
    if not music then
        print("Music track not found: " .. id)
        return
    end
    
    -- Stop currently playing music
    if self.currentMusic and self.music[self.currentMusic] then
        if self.music[self.currentMusic].stop then
            self.music[self.currentMusic]:stop()
        end
    end
    
    -- Set as current and play
    self.currentMusic = id
    if music.setVolume then
        music:setVolume(fadeTime and 0 or self.musicVolume)
    end
    if music.play then
        music:play()
    end
    
    -- Handle fade-in if specified
    if fadeTime then
        -- In a real implementation, you would use a tween library
        -- or track this in an update function to gradually increase volume
        -- This is a placeholder
        print("Fading in music over " .. fadeTime .. " seconds")
    end
end

-- Stop the currently playing music
-- fadeTime: Optional time to fade out (seconds)
function AudioManager:stopMusic(fadeTime)
    if not self.currentMusic then return end
    
    local music = self.music[self.currentMusic]
    if not music then return end
    
    if fadeTime then
        -- In a real implementation, implement fade-out
        -- This is a placeholder
        print("Fading out music over " .. fadeTime .. " seconds")
    end
    
    if music.stop then
        music:stop()
    end
    self.currentMusic = nil
end

-- Pause the currently playing music
function AudioManager:pauseMusic()
    if not self.currentMusic then return end
    
    local music = self.music[self.currentMusic]
    if music and music.isPlaying and music.pause and music:isPlaying() then
        music:pause()
    end
end

-- Resume paused music
function AudioManager:resumeMusic()
    if not self.musicEnabled or not self.currentMusic then return end
    
    local music = self.music[self.currentMusic]
    if music and music.isPlaying and music.play and not music:isPlaying() then
        music:play()
    end
end

-- Set global music volume
-- volume: New volume level (0.0 to 1.0)
function AudioManager:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
    
    -- Update all loaded music tracks
    for _, music in pairs(self.music) do
        if music.setVolume then
            music:setVolume(self.musicVolume)
        end
    end
end

-- Toggle music on/off
function AudioManager:toggleMusic()
    self.musicEnabled = not self.musicEnabled
    
    if self.musicEnabled then
        self:resumeMusic()
    else
        self:pauseMusic()
    end
    
    return self.musicEnabled
end

-- =====================
-- GENERAL METHODS
-- =====================

-- Load common game sounds and music from the assets folders
function AudioManager:loadDefaultAssets()
    -- Only attempt to load assets if they're likely to exist
    -- This helps avoid error spam in tests
    if not hasLove then
        print("Skipping audio asset loading - LÖVE framework not available")
        return
    end
    
    -- Load sound effects
    local soundsDir = "assets/sounds/"
    self:loadSound("card_place", soundsDir .. "card_place.wav")
    self:loadSound("card_draw", soundsDir .. "card_draw.wav")
    self:loadSound("button_click", soundsDir .. "button_click.wav")
    self:loadSound("activation", soundsDir .. "activation.wav")
    self:loadSound("convergence", soundsDir .. "convergence.wav")
    self:loadSound("paradigm_shift", soundsDir .. "paradigm_shift.wav")
    
    -- Load music tracks
    local musicDir = "assets/music/"
    self:loadMusic("menu", musicDir .. "menu_theme.ogg")
    self:loadMusic("gameplay", musicDir .. "gameplay_theme.ogg")
end

-- Clean up and release all audio resources
function AudioManager:cleanup()
    -- Stop all playing sounds
    self:stopMusic()
    
    -- Release resources (not strictly necessary with LÖVE)
    self.sounds = {}
    self.music = {}
end

return AudioManager
