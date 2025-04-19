-- tests/game/rules_spec.lua
-- Unit tests for the Rules module

local Rules = require 'src.game.rules'
local Card = require 'src.game.card'

-- Mock objects/dependencies
local Network = {}
Network.__index = Network

function Network:new()
    local instance = setmetatable({}, Network)
    instance.cards = {}
    instance.grid = {}
    return instance
end

function Network:getCardAt(x, y)
    if not self.grid[y] then return nil end
    return self.grid[y][x]
end

function Network:hasCardWithId(id)
    for _, card in pairs(self.cards) do
        if card.id == id then return true end
    end
    return false
end

function Network:getCardById(id)
    for _, card in pairs(self.cards) do
        if card.id == id then return card end
    end
    return nil
end

function Network:isEmpty()
    return next(self.cards) == nil
end

function Network:addCard(card, x, y)
    if not self.grid[y] then self.grid[y] = {} end
    self.grid[y][x] = card
    self.cards[card.id] = card
    card.position = {x = x, y = y}
end

function Network:getSize()
    local count = 0
    for _ in pairs(self.cards) do count = count + 1 end
    return count
end

describe("Rules Module", function()
    local rules
    local network
    local reactorCard
    local techCard1, techCard2
    
    before_each(function()
        rules = Rules:new()
        network = Network:new()
        
        -- Create test cards
        reactorCard = {
            id = "REACTOR_TEST",
            type = Card.Type.REACTOR,
            openSlots = {
                [Card.Slots.TOP_LEFT] = true, [Card.Slots.TOP_RIGHT] = true,
                [Card.Slots.BOTTOM_LEFT] = true, [Card.Slots.BOTTOM_RIGHT] = true,
                [Card.Slots.LEFT_TOP] = true, [Card.Slots.LEFT_BOTTOM] = true,
                [Card.Slots.RIGHT_TOP] = true, [Card.Slots.RIGHT_BOTTOM] = true
            },
            isSlotOpen = function(self, slot) return self.openSlots[slot] == true end
        }
        
        -- Tech card with input/output on top/bottom
        techCard1 = {
            id = "TECH_001",
            type = Card.Type.TECHNOLOGY,
            openSlots = {
                [Card.Slots.TOP_RIGHT] = true,     -- Tech Input
                [Card.Slots.BOTTOM_RIGHT] = true   -- Tech Output
            },
            isSlotOpen = function(self, slot) return self.openSlots[slot] == true end
        }
        
        -- Tech card with input/output on left/right
        techCard2 = {
            id = "TECH_002",
            type = Card.Type.TECHNOLOGY,
            openSlots = {
                [Card.Slots.RIGHT_TOP] = true,    -- Knowledge Input
                [Card.Slots.LEFT_TOP] = true      -- Knowledge Output
            },
            isSlotOpen = function(self, slot) return self.openSlots[slot] == true end
        }
    end)
    
    describe("isPlacementValid()", function()
        it("should allow placing the first card (reactor) in an empty network", function()
            local valid, _ = rules:isPlacementValid(reactorCard, network, 0, 0)
            assert.is_true(valid)
        end)
        
        it("should reject placement on an occupied position", function()
            network:addCard(reactorCard, 0, 0)
            local valid, reason = rules:isPlacementValid(techCard1, network, 0, 0)
            assert.is_false(valid)
            assert.is_string(reason)
            assert.is_truthy(reason:find("occupied"))
        end)
        
        it("should reject duplicate cards (uniqueness rule)", function()
            network:addCard(reactorCard, 0, 0)
            
            -- Add tech card somewhere, then try to add a duplicate
            network:addCard(techCard1, 0, 1)
            local valid, reason = rules:isPlacementValid(techCard1, network, 1, 0)
            assert.is_false(valid)
            assert.is_string(reason)
            assert.is_truthy(reason:find("Uniqueness"))
        end)
        
        it("should require adjacency to at least one existing card", function()
            network:addCard(reactorCard, 0, 0)
            
            -- Try to place at a non-adjacent position
            local valid, reason = rules:isPlacementValid(techCard1, network, 2, 2)
            assert.is_false(valid)
            assert.is_truthy(reason:find("adjacent"))
        end)
        
        -- More extensive connection validation would be tested here...
    end)
    
    describe("shouldDrawCard()", function()
        it("should return true when hand size is below minimum", function()
            local player = {
                getHandSize = function() return Rules.MIN_HAND_SIZE - 1 end
            }
            assert.is_true(rules:shouldDrawCard(player))
        end)
        
        it("should return false when hand size meets or exceeds minimum", function()
            local player = {
                getHandSize = function() return Rules.MIN_HAND_SIZE end
            }
            assert.is_false(rules:shouldDrawCard(player))
            
            player.getHandSize = function() return Rules.MIN_HAND_SIZE + 2 end
            assert.is_false(rules:shouldDrawCard(player))
        end)
    end)
    
    describe("isGameEndTriggered()", function()
        it("should return true when a player reaches the VP target", function()
            local gameService = {
                getPlayers = function() 
                    return {
                        { id = "p1", getVictoryPoints = function() return Rules.VICTORY_POINT_TARGET - 1 end },
                        { id = "p2", getVictoryPoints = function() return Rules.VICTORY_POINT_TARGET end }
                    }
                end,
                isDeckEmpty = function() return false end
            }
            
            assert.is_true(rules:isGameEndTriggered(gameService))
        end)
        
        it("should return true when the deck is empty", function()
            local gameService = {
                getPlayers = function() 
                    return {
                        { 
                            id = "p1", 
                            getVictoryPoints = function() return 10 end,
                            getHandSize = function() return Rules.MIN_HAND_SIZE - 1 end -- Less than minimum
                        },
                        { 
                            id = "p2", 
                            getVictoryPoints = function() return 15 end,
                            getHandSize = function() return Rules.MIN_HAND_SIZE end -- At minimum
                        }
                    }
                end,
                isDeckEmpty = function() return true end
            }
            
            assert.is_true(rules:isGameEndTriggered(gameService))
        end)
        
        it("should return false when neither end condition is met", function()
            local gameService = {
                getPlayers = function() 
                    return {
                        { 
                            id = "p1", 
                            getVictoryPoints = function() return 10 end,
                            getHandSize = function() return Rules.MIN_HAND_SIZE end -- At minimum
                        },
                        { 
                            id = "p2", 
                            getVictoryPoints = function() return 15 end,
                            getHandSize = function() return Rules.MIN_HAND_SIZE + 1 end -- Above minimum
                        }
                    }
                end,
                isDeckEmpty = function() return false end
            }
            
            assert.is_false(rules:isGameEndTriggered(gameService))
        end)
    end)
    
    describe("calculateFinalScores()", function()
        it("should include base VP and network size in final score", function()
            local network1, network2 = Network:new(), Network:new()
            
            -- First player has 5 VP and 3 cards in network (including reactor)
            -- Should get: 5 + (3-1) = 7 total
            local player1 = {
                id = "p1",
                getVictoryPoints = function() return 5 end,
                getNetwork = function() return network1 end
            }
            network1.getSize = function() return 3 end
            
            -- Second player has 8 VP and 5 cards in network (including reactor)
            -- Should get: 8 + (5-1) = 12 total
            local player2 = {
                id = "p2", 
                getVictoryPoints = function() return 8 end,
                getNetwork = function() return network2 end
            }
            network2.getSize = function() return 5 end
            
            local gameService = {
                getPlayers = function() return {player1, player2} end
            }
            
            local scores = rules:calculateFinalScores(gameService)
            assert.are.equal(7, scores.p1)
            assert.are.equal(12, scores.p2)
        end)
    end)
end) 
