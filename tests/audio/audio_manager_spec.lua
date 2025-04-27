---@diagnostic disable: undefined-field
-- tests/audio/audio_manager_spec.lua
-- Unit tests for the AudioManager module

local AudioManager = require 'src.audio.audio_manager'

-- Create a mock for love.audio since LOVE might not be available during testing
local mockLove = {
    audio = {
        newSource = function(path, sourceType)
            return {
                path = path,
                sourceType = sourceType,
                volume = 1.0,
                pitch = 1.0,
                playing = false,
                looping = false,
                
                setVolume = function(self, vol) self.volume = vol end,
                setPitch = function(self, p) self.pitch = p end,
                setLooping = function(self, loop) self.looping = loop end,
                play = function(self) self.playing = true end,
                stop = function(self) self.playing = false end,
                pause = function(self) self.playing = false end,
                isPlaying = function(self) return self.playing end,
                clone = function(self) 
                    local clone = {}
                    for k, v in pairs(self) do clone[k] = v end
                    clone.setVolume = self.setVolume
                    clone.setPitch = self.setPitch
                    clone.setLooping = self.setLooping
                    clone.play = self.play
                    clone.stop = self.stop
                    clone.pause = self.pause
                    clone.isPlaying = self.isPlaying
                    clone.clone = self.clone
                    return clone
                end
            }
        end
    }
}

-- Replace global love with our mock
_G.love = mockLove

describe("AudioManager Module", function()
    local audioManager
    
    before_each(function()
        audioManager = AudioManager:new()
    end)
    
    describe("AudioManager:new()", function()
        it("should create a new AudioManager with default properties", function()
            assert.is_table(audioManager)
            assert.is_table(audioManager.sounds)
            assert.is_table(audioManager.music)
            assert.is_nil(audioManager.currentMusic)
            assert.are.equal(0.7, audioManager.soundVolume)
            assert.are.equal(0.5, audioManager.musicVolume)
            assert.is_true(audioManager.soundEnabled)
            assert.is_true(audioManager.musicEnabled)
        end)
    end)
    
    describe("Sound effects", function()
        it("should load sound effects", function()
            local success = audioManager:loadSound("test_sound", "path/to/sound.wav")
            assert.is_true(success)
            assert.is_table(audioManager.sounds["test_sound"])
        end)
        
        it("should not reload an already loaded sound", function()
            -- Load once
            audioManager:loadSound("test_sound", "path/to/sound.wav")
            
            -- Then try to load again, but with a different path
            local success = audioManager:loadSound("test_sound", "different/path.wav")
            
            -- It should return true (success) but not change the original sound
            assert.is_true(success)
            assert.are.equal("path/to/sound.wav", audioManager.sounds["test_sound"].path)
        end)
        
        it("should set sound volume when loading", function()
            audioManager.soundVolume = 0.5
            audioManager:loadSound("test_sound", "path/to/sound.wav")
            
            assert.are.equal(0.5, audioManager.sounds["test_sound"].volume)
        end)
        
        it("should play sounds", function()
            -- Load and play a sound
            audioManager:loadSound("test_sound", "path/to/sound.wav")
            audioManager:playSound("test_sound")
            
            -- Original sound source should still exist
            assert.is_table(audioManager.sounds["test_sound"])
            
            -- Since we cloned the source, the original shouldn't be playing
            assert.is_false(audioManager.sounds["test_sound"].playing)
        end)
        
        it("should not play sounds when disabled", function()
            audioManager:loadSound("test_sound", "path/to/sound.wav")
            audioManager.soundEnabled = false
            audioManager:playSound("test_sound")
            
            -- Verify sound wasn't started
            assert.is_false(audioManager.sounds["test_sound"].playing)
        end)
        
        it("should set custom volume and pitch when playing", function()
            audioManager:loadSound("test_sound", "path/to/sound.wav")
            
            -- Since we can't directly access the clone that gets played,
            -- we'll modify the clone function to save the last clone for testing
            local lastClone
            audioManager.sounds["test_sound"].clone = function(self)
                local clone = {
                    volume = self.volume,
                    pitch = self.pitch,
                    playing = false,
                    
                    setVolume = function(self, vol) self.volume = vol end,
                    setPitch = function(self, p) self.pitch = p end,
                    play = function(self) self.playing = true end
                }
                lastClone = clone
                return clone
            end
            
            -- Play with custom volume and pitch
            audioManager:playSound("test_sound", 0.3, 1.5)
            
            -- Check that the volume and pitch were set correctly
            assert.is_table(lastClone)
            assert.are.equal(0.3, lastClone.volume)
            assert.are.equal(1.5, lastClone.pitch)
            assert.is_true(lastClone.playing)
        end)
        
        it("should adjust all sound volumes when setting sound volume", function()
            audioManager:loadSound("sound1", "path/to/sound1.wav")
            audioManager:loadSound("sound2", "path/to/sound2.wav")
            
            audioManager:setSoundVolume(0.3)
            
            assert.are.equal(0.3, audioManager.soundVolume)
            assert.are.equal(0.3, audioManager.sounds["sound1"].volume)
            assert.are.equal(0.3, audioManager.sounds["sound2"].volume)
        end)
        
        it("should toggle sound on/off correctly", function()
            assert.is_true(audioManager.soundEnabled)
            
            -- Toggle off
            local result = audioManager:toggleSound()
            assert.is_false(audioManager.soundEnabled)
            assert.is_false(result)
            
            -- Toggle on
            result = audioManager:toggleSound()
            assert.is_true(audioManager.soundEnabled)
            assert.is_true(result)
        end)
    end)
    
    describe("Music", function()
        it("should load music tracks", function()
            local success = audioManager:loadMusic("test_music", "path/to/music.ogg")
            assert.is_true(success)
            assert.is_table(audioManager.music["test_music"])
            -- Music should be set to stream type
            assert.are.equal("stream", audioManager.music["test_music"].sourceType)
            -- Music should be set to loop by default
            assert.is_true(audioManager.music["test_music"].looping)
        end)
        
        it("should play music", function()
            audioManager:loadMusic("test_music", "path/to/music.ogg")
            audioManager:playMusic("test_music")
            
            assert.are.equal("test_music", audioManager.currentMusic)
            assert.is_true(audioManager.music["test_music"].playing)
        end)
        
        it("should stop current music when playing new music", function()
            audioManager:loadMusic("music1", "path/to/music1.ogg")
            audioManager:loadMusic("music2", "path/to/music2.ogg")
            
            audioManager:playMusic("music1")
            assert.are.equal("music1", audioManager.currentMusic)
            assert.is_true(audioManager.music["music1"].playing)
            
            audioManager:playMusic("music2")
            assert.are.equal("music2", audioManager.currentMusic)
            assert.is_false(audioManager.music["music1"].playing)
            assert.is_true(audioManager.music["music2"].playing)
        end)
        
        it("should stop music", function()
            audioManager:loadMusic("test_music", "path/to/music.ogg")
            audioManager:playMusic("test_music")
            
            audioManager:stopMusic()
            assert.is_nil(audioManager.currentMusic)
            assert.is_false(audioManager.music["test_music"].playing)
        end)
        
        it("should pause and resume music", function()
            audioManager:loadMusic("test_music", "path/to/music.ogg")
            audioManager:playMusic("test_music")
            
            audioManager:pauseMusic()
            assert.is_false(audioManager.music["test_music"].playing)
            
            audioManager:resumeMusic()
            assert.is_true(audioManager.music["test_music"].playing)
        end)
        
        it("should adjust all music volumes when setting music volume", function()
            audioManager:loadMusic("music1", "path/to/music1.ogg")
            audioManager:loadMusic("music2", "path/to/music2.ogg")
            
            audioManager:setMusicVolume(0.3)
            
            assert.are.equal(0.3, audioManager.musicVolume)
            assert.are.equal(0.3, audioManager.music["music1"].volume)
            assert.are.equal(0.3, audioManager.music["music2"].volume)
        end)
        
        it("should toggle music on/off correctly", function()
            audioManager:loadMusic("test_music", "path/to/music.ogg")
            audioManager:playMusic("test_music")
            
            assert.is_true(audioManager.musicEnabled)
            assert.is_true(audioManager.music["test_music"].playing)
            
            -- Toggle off
            local result = audioManager:toggleMusic()
            assert.is_false(audioManager.musicEnabled)
            assert.is_false(audioManager.music["test_music"].playing)
            assert.is_false(result)
            
            -- Toggle on
            result = audioManager:toggleMusic()
            assert.is_true(audioManager.musicEnabled)
            assert.is_true(audioManager.music["test_music"].playing)
            assert.is_true(result)
        end)
    end)
    
    describe("Cleanup", function()
        it("should clean up resources properly", function()
            audioManager:loadSound("test_sound", "path/to/sound.wav")
            audioManager:loadMusic("test_music", "path/to/music.ogg")
            audioManager:playMusic("test_music")
            
            audioManager:cleanup()
            
            assert.is_nil(next(audioManager.sounds))
            assert.is_nil(next(audioManager.music))
            assert.is_nil(audioManager.currentMusic)
        end)
    end)
    
end) 
