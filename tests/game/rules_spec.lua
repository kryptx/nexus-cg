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
    card.network = self
end

function Network:getSize()
    local count = 0
    for _ in pairs(self.cards) do count = count + 1 end
    return count
end

-- Add a mock findPathToReactor to the mock Network for testing Rules
function Network:findPathToReactor(targetCard)
    -- Simulate the specific case we're testing: BPU adjacent to Reactor
    -- The real function checks Current(Output) -> Neighbor(Input)
    -- Path BPU -> Reactor: Check BPU(Output) -> Reactor(Input). Fails.
    if targetCard.id == "BPU_TEST" and targetCard.position.x == 0 and targetCard.position.y == 1 then
        -- In this specific test setup, BPU is below Reactor.
        -- BPU Top edge (Input) faces Reactor Bottom edge (Output). No path.
        return nil
    end
    -- Add other specific mock path results here if needed for more tests
    -- Default to nil for unhandled cases in this mock
    return nil
end

describe("Rules Module", function()
    local rules
    local network
    local reactorCard
    local techCard1, techCard2
    
    before_each(function()
        rules = Rules:new()
        network = Network:new()
        
        -- Use Card:new directly instead of makeMockCard
        reactorCard = Card:new({
            id = "REACTOR_TEST",
            type = Card.Type.REACTOR,
            definedPorts = {
                [Card.Ports.TOP_LEFT] = true, [Card.Ports.TOP_RIGHT] = true,
                [Card.Ports.BOTTOM_LEFT] = true, [Card.Ports.BOTTOM_RIGHT] = true,
                [Card.Ports.LEFT_TOP] = true, [Card.Ports.LEFT_BOTTOM] = true,
                [Card.Ports.RIGHT_TOP] = true, [Card.Ports.RIGHT_BOTTOM] = true
            }
        })
        
        techCard1 = Card:new({
            id = "CONNECT_VALID",
            type = Card.Type.TECHNOLOGY, 
            definedPorts = {
                [Card.Ports.BOTTOM_LEFT] = true,   -- Culture Input (Connects to Reactor's Port 1 - Culture Output)
                [Card.Ports.RIGHT_BOTTOM] = true,  -- Resource Output (Irrelevant here),
            }
        })
        
        techCard2 = Card:new({
            id = "CONNECT_INVALID",
            type = Card.Type.KNOWLEDGE,
            definedPorts = {
                [Card.Ports.BOTTOM_RIGHT] = true, -- Tech Output (No corresponding Input on Reactor Top)
                [Card.Ports.LEFT_TOP] = true      -- Knowledge Output (Irrelevant here)
            }
        })
    end)
    
    describe("isPlacementValid()", function()
        -- REMOVED: Invalid test - Reactor placement is handled by Network:initializeWithReactor, not Rules:isPlacementValid
        -- it("should allow placing the first card (reactor) in an empty network", function()
        --     local valid, _ = rules:isPlacementValid(reactorCard, network, 0, 0)
        --     assert.is_true(valid)
        -- end)
        
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
            network:addCard(techCard1, 0, -1) -- Place it validly first
            local valid, reason = rules:isPlacementValid(techCard1, network, 1, 0) -- Try to place same card elsewhere
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
        
        it("should allow placement if at least one Input->Output connection exists", function()
            network:addCard(reactorCard, 0, 0)
            -- Place techCard1 (has Culture Input on Bottom Left) ABOVE reactor (at 0, -1)
            -- Reactor has Culture Output on Top Left (Port 1)
            -- techCard1 Port 3 (Input) should connect to Reactor Port 1 (Output)
            local valid, reason = rules:isPlacementValid(techCard1, network, 0, -1)
            assert.is_true(valid, "Placement should be valid. Reason: " .. tostring(reason))
        end)
        
        it("should reject placement if no valid Input->Output connection exists", function()
            network:addCard(reactorCard, 0, 0)
            -- Place techCard2 (NO Culture Input on Bottom Left) ABOVE reactor (at 0, -1)
            local valid, reason = rules:isPlacementValid(techCard2, network, 0, -1)
            assert.is_false(valid)
            assert.is_string(reason)
            assert.matches("No valid connection", reason, 1, true) -- Case-insensitive match
        end)
    end)
    
    describe("isActivationPathValid()", function()
        local bpuCard -- Basic Processing Unit mock

        before_each(function() 
            -- Add reactor to network 
            reactorCard = Card:new({ -- Re-create reactor in this scope using Card:new
                id = "REACTOR_TEST",
                type = Card.Type.REACTOR,
                definedPorts = {
                    [Card.Ports.TOP_LEFT] = true, [Card.Ports.TOP_RIGHT] = true,
                    [Card.Ports.BOTTOM_LEFT] = true, [Card.Ports.BOTTOM_RIGHT] = true,
                    [Card.Ports.LEFT_TOP] = true, [Card.Ports.LEFT_BOTTOM] = true,
                    [Card.Ports.RIGHT_TOP] = true, [Card.Ports.RIGHT_BOTTOM] = true
                }
            })
            network:addCard(reactorCard, 0, 0)

            -- Define BPU (Tech Input top-right) using Card:new
            bpuCard = Card:new({
                id = "BPU_TEST",
                type = Card.Type.TECHNOLOGY,
                -- position will be set by addCard
                definedPorts = {
                    [Card.Ports.TOP_RIGHT] = true,     -- Tech Input
                    [Card.Ports.BOTTOM_RIGHT] = true   -- Tech Output
                }
            })
            -- Add BPU below reactor
            network:addCard(bpuCard, 0, 1)
        end)

        it("should return false when target adjacent to reactor has no valid departing Output", function() 
            -- Path BPU -> Reactor requires BPU(Output) -> Reactor(Input).
            -- BPU has Input on top edge (port 2), Reactor has Output on bottom edge (port 4). Fails.
            -- The mock findPathToReactor simulates this failure case.
            local isValid, path, reason = rules:isActivationPathValid(network, reactorCard.id, bpuCard.id)
            
            assert.is_false(isValid)
            assert.is_nil(path)
            assert.is_string(reason)
            assert.are.equal("No valid activation path exists", reason)
        end)

        it("should return false if target is the reactor", function() 
            local isValid, path, reason = rules:isActivationPathValid(network, reactorCard.id, reactorCard.id)
            assert.is_false(isValid)
            assert.is_nil(path)
            assert.matches("Cannot activate the Reactor itself", reason)
        end)

        -- TODO: Add a test case for a path that *should* be valid under the new rules.
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
                        },
                        {
                            id = "p2",
                            getVictoryPoints = function() return 15 end,
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
                        },
                        {
                            id = "p2",
                            getVictoryPoints = function() return 15 end,
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
                network = network1 -- Add the network field directly
            }
            network1.getSize = function() return 3 end
            
            -- Second player has 8 VP and 5 cards in network (including reactor)
            -- Should get: 8 + (5-1) = 12 total
            local player2 = {
                id = "p2", 
                getVictoryPoints = function() return 8 end,
                network = network2 -- Add the network field directly
            }
            network2.getSize = function() return 5 end
            
            local gameService = {
                getPlayers = function() return {player1, player2} end,
                getCurrentParadigm = function() return {endGameScoring = function() return 0 end} end
            }
            
            local scores = rules:calculateFinalScores(gameService)
            assert.are.equal(7, scores.p1)
            assert.are.equal(12, scores.p2)
        end)

        -- TODO: Add tests for paradigm and resource conversion scoring
    end)
end) 
