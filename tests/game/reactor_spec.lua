-- tests/game/reactor_spec.lua
-- Unit tests for the Reactor card functionality (now implemented directly with Card class)

local Card = require 'src.game.card'
local CardDefinitions = require 'src.game.data.card_definitions' -- Load definitions for comparison

-- Minimal mock player for owner assignment
local mockPlayer = { id = "player1", name = "Mock Player" }

describe("Reactor Card", function()
    local reactor
    
    before_each(function()
        -- Create a reactor card using Card class directly with the reactor definition
        reactor = Card:new(CardDefinitions["REACTOR_BASE"])
        reactor.owner = mockPlayer -- Set owner
        reactor.baseResourceProduction = false -- Add reactor-specific properties
    end)
    
    describe("Reactor Card Creation", function()
        it("should create a reactor with the correct type and properties from CardDefinitions", function()
            local baseData = CardDefinitions["REACTOR_BASE"]
            assert.is_table(reactor)
            assert.are.equal(baseData.id, reactor.id) -- Should match definition
            assert.are.equal(baseData.title, reactor.title)
            assert.are.equal(baseData.type, reactor.type)
            assert.are.equal(baseData.buildCost.material, reactor.buildCost.material)
            assert.are.equal(baseData.buildCost.data, reactor.buildCost.data)
            assert.are.equal(baseData.vpValue, reactor.vpValue)
            assert.is_table(reactor.activationEffect)
            assert.is_function(reactor.activationEffect.activate)
            assert.is_table(reactor.convergenceEffect)
            assert.is_function(reactor.convergenceEffect.activate)
            assert.are.same(mockPlayer, reactor.owner) -- Check owner is set
        end)
        
        it("should have properties matching CardDefinitions", function()
            local baseData = CardDefinitions["REACTOR_BASE"]
            -- Verify all slots defined in REACTOR_BASE are open
            for slotIndex, shouldBeOpen in pairs(baseData.openSlots) do
                assert.are.equal(shouldBeOpen, reactor:isSlotDefinedOpen(slotIndex), "Slot " .. slotIndex .. " mismatch")
            end
            -- Verify a sample of other properties
            assert.are.equal(baseData.flavorText, reactor.flavorText)
            -- Verify a slot NOT defined in REACTOR_BASE is closed (assuming baseData is comprehensive)
            -- This assumes the definition includes all 8 slots. If not, this needs adjustment.
            assert.is_false(reactor:isSlotDefinedOpen(99))
        end)
        
        it("should have reactor-specific properties", function()
            assert.is_false(reactor.baseResourceProduction)
            assert.is_table(reactor.connections) -- Should have connections table from Card
            assert.are.equal(0, #reactor.connections) -- Should be initially empty
        end)
    end)
    
    describe("Reactor Effects (from CardDefinitions)", function()
        local activatingPlayer
        local network
        local mockGameService -- Declare mock gameService

        before_each(function()
            -- Create mocks for effect execution
            activatingPlayer = {
                id = "activator", name = "Activator", resources = { energy=0 },
                addResource = function(self, type, amount) self.resources[type] = (self.resources[type] or 0) + amount end
            }
            -- Network mock needs owner for convergence effect
            network = { owner = mockPlayer } -- mockPlayer defined at top level of spec
            -- Mock the owner player as well
            mockPlayer.resources = { energy = 0 } 
            mockPlayer.addResource = function(self, type, amount) self.resources[type] = (self.resources[type] or 0) + amount end

            -- Create mock game service with necessary methods for these tests (none needed for reactor resources)
            mockGameService = {
                -- awardVP = function(self, player, amount) player:addVP(amount) end, -- Example if needed
                -- playerDrawCards = function(self, player, amount) print("Mock draw") end, -- Example if needed
                -- addResourceToAllPlayers = function(self, resource, amount) print("Mock add all") end -- Example if needed
            }
        end)

        it("activationEffect should grant 1 Energy to activating player", function()
            assert.is_table(reactor.activationEffect, "Reactor activationEffect should be a table")
            assert.is_function(reactor.activationEffect.activate, "Reactor activationEffect.activate should be a function")
            reactor.activationEffect.activate(mockGameService, activatingPlayer, network)
            assert.are.equal(1, mockPlayer.resources.energy) -- Check OWNER's energy now
            assert.are.equal(0, activatingPlayer.resources.energy) -- Activator should still have 0
        end)

        it("convergenceEffect should grant 1 Energy to owner player", function()
            assert.is_table(reactor.convergenceEffect, "Reactor convergenceEffect should be a table")
            assert.is_function(reactor.convergenceEffect.activate, "Reactor convergenceEffect.activate should be a function")
            reactor.convergenceEffect.activate(mockGameService, activatingPlayer, network)
            assert.are.equal(1, mockPlayer.resources.energy) -- Owner gets energy
            assert.are.equal(0, activatingPlayer.resources.energy) -- Activator does not
        end)
    end)
    
end) 
