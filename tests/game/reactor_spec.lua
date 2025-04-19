-- tests/game/reactor_spec.lua
-- Unit tests for the Reactor module

local Reactor = require 'src.game.reactor'
local Card = require 'src.game.card'

describe("Reactor Module", function()
    local reactor
    
    before_each(function()
        reactor = Reactor:new("player1")
    end)
    
    describe("Reactor:new()", function()
        it("should create a reactor with the correct type and properties", function()
            assert.is_table(reactor)
            assert.are.equal("REACTOR_player1", reactor.id)
            assert.are.equal("Reactor Core", reactor.title)
            assert.are.equal(Card.Type.REACTOR, reactor.type)
            assert.are.equal(0, reactor.buildCost.material)
            assert.are.equal(0, reactor.buildCost.data)
            assert.are.equal(0, reactor.vpValue)
            assert.is_function(reactor.actionEffect)
            assert.is_function(reactor.convergenceEffect)
        end)
        
        it("should have all 8 slots open", function()
            assert.is_true(reactor:isSlotOpen(Card.Slots.TOP_LEFT))
            assert.is_true(reactor:isSlotOpen(Card.Slots.TOP_RIGHT))
            assert.is_true(reactor:isSlotOpen(Card.Slots.BOTTOM_LEFT))
            assert.is_true(reactor:isSlotOpen(Card.Slots.BOTTOM_RIGHT))
            assert.is_true(reactor:isSlotOpen(Card.Slots.LEFT_TOP))
            assert.is_true(reactor:isSlotOpen(Card.Slots.LEFT_BOTTOM))
            assert.is_true(reactor:isSlotOpen(Card.Slots.RIGHT_TOP))
            assert.is_true(reactor:isSlotOpen(Card.Slots.RIGHT_BOTTOM))
        end)
        
        it("should have reactor-specific properties", function()
            assert.are.equal(1, reactor.baseIncomeEnergy)
            assert.is_false(reactor.baseResourceProduction)
            assert.is_table(reactor.connections)
            assert.are.equal(0, #reactor.connections)
        end)
    end)
    
    describe("Reactor:generateBaseIncome()", function()
        it("should return the correct base income values", function()
            local income = reactor:generateBaseIncome()
            assert.is_table(income)
            assert.are.equal(reactor.baseIncomeEnergy, income.energy)
            assert.are.equal(0, income.data)
            assert.are.equal(0, income.material)
        end)
    end)
    
    describe("Reactor:canConnectTo()", function()
        it("should allow connection to a card with open slots on the facing edge", function()
            -- Print the slot constants to help debug
            print("DEBUG - Card.Slots values:")
            for name, value in pairs(Card.Slots) do
                print("  " .. name .. " = " .. value)
            end
            
            local targetCard = {
                openSlots = {
                    [Card.Slots.TOP_LEFT] = true,  -- These are the TOP slots (Card is BELOW reactor)
                    [Card.Slots.TOP_RIGHT] = true
                },
                isSlotOpen = function(self, slot)
                    print("Checking target slot: " .. slot)
                    return self.openSlots[slot] == true
                end
            }
            
            -- The reactor would be ABOVE the target card ("down" means reactor is below)
            -- Correct parameter is "down" since we're testing connection from reactor
            -- (at position 0,0) to a card at position (0,1)
            print("Testing connection with direction 'down'")
            assert.is_true(reactor:canConnectTo(targetCard, "down"))
        end)
        
        it("should not allow connection when target card has no open slots on the facing edge", function()
            local targetCard = {
                openSlots = {
                    -- Only slots on the left/right, none on top
                    [Card.Slots.LEFT_TOP] = true,
                    [Card.Slots.RIGHT_TOP] = true
                },
                isSlotOpen = function(self, slot) return self.openSlots[slot] == true end
            }
            
            -- Reactor is above the target card, tries to connect to target's top edge
            assert.is_false(reactor:canConnectTo(targetCard, "down"))
        end)
        
        it("should return false for invalid directions", function()
            local targetCard = {
                openSlots = { [Card.Slots.BOTTOM_LEFT] = true },
                isSlotOpen = function(self, slot) return self.openSlots[slot] == true end
            }
            
            assert.is_false(reactor:canConnectTo(targetCard, "invalid_dir"))
        end)
    end)
    
    describe("Connection management", function()
        local targetCard1, targetCard2
        
        before_each(function()
            targetCard1 = { id = "TARGET1" }
            targetCard2 = { id = "TARGET2" }
        end)
        
        it("should add connections correctly", function()
            reactor:addConnection(targetCard1, Card.Slots.BOTTOM_LEFT, Card.Slots.TOP_LEFT)
            
            assert.are.equal(1, #reactor.connections)
            assert.are.equal(targetCard1, reactor.connections[1].target)
            assert.are.equal(Card.Slots.BOTTOM_LEFT, reactor.connections[1].reactorSlot)
            assert.are.equal(Card.Slots.TOP_LEFT, reactor.connections[1].targetSlot)
        end)
        
        it("should handle multiple connections", function()
            reactor:addConnection(targetCard1, Card.Slots.BOTTOM_LEFT, Card.Slots.TOP_LEFT)
            reactor:addConnection(targetCard2, Card.Slots.RIGHT_TOP, Card.Slots.LEFT_TOP)
            
            assert.are.equal(2, #reactor.connections)
        end)
        
        it("should remove connections by target card", function()
            reactor:addConnection(targetCard1, Card.Slots.BOTTOM_LEFT, Card.Slots.TOP_LEFT)
            reactor:addConnection(targetCard2, Card.Slots.RIGHT_TOP, Card.Slots.LEFT_TOP)
            
            local result = reactor:removeConnection(targetCard1)
            assert.is_true(result)
            assert.are.equal(1, #reactor.connections)
            assert.are.equal(targetCard2, reactor.connections[1].target)
        end)
        
        it("should return false when trying to remove non-existent connections", function()
            local nonExistentCard = { id = "NONEXISTENT" }
            local result = reactor:removeConnection(nonExistentCard)
            assert.is_false(result)
        end)
        
        it("should get all connected cards correctly", function()
            reactor:addConnection(targetCard1, Card.Slots.BOTTOM_LEFT, Card.Slots.TOP_LEFT)
            reactor:addConnection(targetCard2, Card.Slots.RIGHT_TOP, Card.Slots.LEFT_TOP)
            
            local connectedCards = reactor:getConnectedCards()
            assert.are.equal(2, #connectedCards)
            
            -- Check that both target cards are in the connected cards list
            local card1Found, card2Found = false, false
            for _, card in ipairs(connectedCards) do
                if card == targetCard1 then card1Found = true end
                if card == targetCard2 then card2Found = true end
            end
            
            assert.is_true(card1Found)
            assert.is_true(card2Found)
        end)
    end)
    
end) 
