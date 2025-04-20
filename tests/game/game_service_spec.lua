-- tests/game/game_service_spec.lua
-- Unit tests for the GameService module

local GameService = require 'src.game.game_service'
local Card = require 'src.game.card' -- For card types
local CardSlots = require('src.game.card').Slots

-- Helper to create basic mock objects
local function createMockCard(id, title, costM, costD, activationEffect, convergenceEffect, vpValue)
    local card = {
        id = id, title = title,
        buildCost = { material = costM or 0, data = costD or 0 },
        activationEffect = activationEffect or function() end,
        convergenceEffect = convergenceEffect or function() end,
        vpValue = vpValue or 0,
        type = Card.Type.TECHNOLOGY, -- Default type for simplicity
        -- For Reactor tests
        getSlotProperties = function() 
            return {type = Card.Type.TECHNOLOGY, is_output = true}
        end,
        isSlotOpen = function() return true end
    }
    -- Simulate Card metatable for type checks if necessary (not needed currently)
    -- setmetatable(card, Card)
    return card
end

local function createMockPlayer(id, resources, hand, network)
    local player = {
        id = id, name = "Player " .. id,
        resources = resources or { energy=0, data=0, material=0 },
        hand = hand or {},
        network = network,
        spendResource_calls = {},
        addResource_calls = {},
        spendResource = function(self, type, amount)
            table.insert(self.spendResource_calls, { type = type, amount = amount })
            if self.resources[type] and self.resources[type] >= amount then
                self.resources[type] = self.resources[type] - amount
                return true
            end
            return false
        end,
        addResource = function(self, type, amount)
            table.insert(self.addResource_calls, { type = type, amount = amount })
            self.resources[type] = (self.resources[type] or 0) + amount
        end,
        getHandSize = function(self)
            return #self.hand
        end,
        getVictoryPoints = function(self)
            return self.vp or 0
        end,
        getNetwork = function(self)
            return self.network
        end,
        addCardToHand = function(self, card)
            table.insert(self.hand, card)
        end
    }
    return player
end

local function createMockNetwork(cards, validPlacementResult, pathResult)
    local cardLookup = {}
    if cards then
        for _, card in ipairs(cards) do
            cardLookup[card.id] = card
        end
    end
    
    -- Create a mock reactor for tests that need to find one
    local mockReactor = createMockCard("REACTOR_BASE", "Reactor Core", 0, 0)
    mockReactor.type = Card.Type.REACTOR
    -- Override the activation effect with the correct one for a reactor
    mockReactor.activationEffect = function(player, network)
        if player and player.addResource then
            player:addResource("energy", 1)
        end
    end
    cardLookup["REACTOR_BASE"] = mockReactor
    
    local network = {
        cards = cardLookup or {},
        placeCard_calls = {},
        findPath_calls = {},
        getCardAt_result = nil, -- Set this per test if needed
        isValidPlacement_result = validPlacementResult,
        findPathToReactor_result = pathResult,
        isValidPlacement = function(self, card, x, y)
            return table.unpack(self.isValidPlacement_result or {false, "Default mock invalid"})
        end,
        placeCard = function(self, card, x, y)
            table.insert(self.placeCard_calls, { card = card, x = x, y = y })
            self.cards[card.id] = card
        end,
        findPathToReactor = function(self, targetCard)
            table.insert(self.findPath_calls, { target = targetCard })
            return self.findPathToReactor_result
        end,
        getCardAt = function(self, x, y)
            -- Simplistic mock: return pre-set result
            return self.getCardAt_result
        end,
        -- Methods required by Rules module
        hasCardWithId = function(self, id)
            return self.cards[id] ~= nil
        end,
        getCardById = function(self, id)
            return self.cards[id]
        end,
        isEmpty = function(self)
            -- For testing, return false to allow placement validation to pass adjacency checks
            return false
        end,
        getSize = function(self)
            local count = 0
            for _ in pairs(self.cards) do count = count + 1 end
            return count
        end,
        findReactor = function(self)
            return self.cards["REACTOR_BASE"] or nil
        end
    }
    return network
end

describe("GameService Module", function()
    local service
    local mockState
    local mockPlayer1, mockPlayer2
    local mockNetwork1, mockNetwork2
    local mockCard1, mockCard2

    before_each(function()
        service = GameService:new()

        -- Setup basic mock state for most tests
        mockCard1 = createMockCard("C1", "Card 1", 1, 0)
        mockCard2 = createMockCard("C2", "Card 2", 0, 1)
        mockNetwork1 = createMockNetwork()
        mockNetwork2 = createMockNetwork()
        mockPlayer1 = createMockPlayer(1, { energy=5, data=5, material=5 }, { mockCard1, mockCard2 }, mockNetwork1)
        mockPlayer2 = createMockPlayer(2, { energy=5, data=5, material=5 }, {}, mockNetwork2)

        -- Set up GameService's internal state
        service.players = { mockPlayer1, mockPlayer2 }
        service.currentPlayerIndex = 1

        mockState = {
            players = service.players,
            currentPlayerIndex = service.currentPlayerIndex,
            renderer = { -- Mock renderer needed for potential coord funcs if service used them
                screenToWorldCoords = function() return 0, 0 end,
                worldToGridCoords = function() return 0, 0 end
            }
        }

        -- Ensure cards have the buildCost property
        mockCard1 = createMockCard("C1", "Card 1", 1, 0)
        mockCard2 = createMockCard("C2", "Card 2", 0, 1)
        mockPlayer1.hand = { mockCard1, mockCard2 }
        
        -- Set up common mocks for all placement tests
        mockPlayer1.resources = { energy = 5, data = 5, material = 5 }
        
        -- Add a mock for the Rules validation
        service.rules.isPlacementValid = function(card, network, x, y)
            -- For the affordability test case
            if card.buildCost and mockPlayer1.resources.material < card.buildCost.material then
                return true, "Valid but can't afford"
            end
            
            -- For the placement invalid test case
            if mockNetwork1.isValidPlacement_result and mockNetwork1.isValidPlacement_result[1] == false then
                return false, mockNetwork1.isValidPlacement_result[2]
            end
            
            -- For the placement valid test case
            return true, "Valid placement"
        end
    end)

    describe("GameService:attemptPlacement()", function()
        it("should place card and return success if valid and affordable", function()
            mockNetwork1.isValidPlacement_result = { true, "Valid" } -- Make placement valid
            local success, msg = service:attemptPlacement(mockState, 1, 10, 20) -- Try placing card 1

            assert.is_true(success)
            assert.matches("Placed 'Card 1'", msg)
            -- Check side effects
            assert.are.equal(4, mockPlayer1.resources.material) -- Cost 1M
            assert.are.equal(1, #mockNetwork1.placeCard_calls)
            assert.are.same(mockCard1, mockNetwork1.placeCard_calls[1].card)
            assert.are.equal(10, mockNetwork1.placeCard_calls[1].x)
            assert.are.equal(20, mockNetwork1.placeCard_calls[1].y)
            assert.are.equal(1, #mockPlayer1.hand) -- Card removed
            assert.are.same(mockCard2, mockPlayer1.hand[1])
        end)

        it("should return failure if placement is invalid", function()
            mockNetwork1.isValidPlacement_result = { false, "Test Invalid Reason" } -- Make placement invalid
            local success, msg = service:attemptPlacement(mockState, 1, 10, 20)

            assert.is_false(success)
            assert.matches("Test Invalid Reason", msg)
            -- Check no side effects
            assert.are.equal(5, mockPlayer1.resources.material)
            assert.are.equal(0, #mockNetwork1.placeCard_calls) -- Check if placeCard was called
            assert.are.equal(2, #mockPlayer1.hand)
        end)

        it("should return failure if placement is valid but unaffordable", function()
            mockNetwork1.isValidPlacement_result = { true, "Valid" }
            mockPlayer1.resources.material = 0 -- Make unaffordable
            local success, msg = service:attemptPlacement(mockState, 1, 10, 20)

            assert.is_false(success)
            assert.matches("Cannot afford", msg)
            -- Check no side effects
            assert.are.equal(0, mockPlayer1.resources.material)
            assert.are.equal(0, #mockNetwork1.placeCard_calls) -- Check if placeCard was called
            assert.are.equal(2, #mockPlayer1.hand)
        end)

        it("should return failure for invalid card index", function()
             local success, msg = service:attemptPlacement(mockState, 99, 10, 20)
             assert.is_false(success)
             assert.matches("Invalid card selection index", msg)
        end)
    end)

    describe("GameService:attemptActivation()", function()
        local targetCard
        local pathCard1, pathCard2
        local activationEffect1_calls, activationEffect2_calls

        before_each(function()
            activationEffect1_calls = 0
            activationEffect2_calls = 0
            pathCard1 = createMockCard("P1", "Path 1", 0, 0, function() activationEffect1_calls = activationEffect1_calls + 1 end)
            pathCard2 = createMockCard("P2", "Path 2", 0, 0, function() activationEffect2_calls = activationEffect2_calls + 1 end)
            targetCard = pathCard1
            mockNetwork1.getCardAt_result = targetCard -- Make getCardAt return the target
            mockNetwork1.cards[pathCard1.id] = pathCard1
            mockNetwork1.cards[pathCard2.id] = pathCard2
            
            -- Mock the Rules validation for activation paths
            service.rules.isActivationPathValid = function(_, network, startNodeId, targetNodeId)
                if network:hasCardWithId(startNodeId) and network:hasCardWithId(targetNodeId) then
                    if mockPlayer1.resources.energy >= 2 then -- Test affordability condition
                        return true, { pathCard1.id, pathCard2.id }, nil
                    else
                        return false, nil, "Not enough energy for activation. Cost: 2 E (Have: " .. mockPlayer1.resources.energy .. "E)"
                    end
                end
                return false, nil, "No valid activation path exists"
            end
        end)

        it("should activate path, spend energy, and return success if path found and affordable", function()
            mockPlayer1.resources.energy = 3 -- Make affordable (cost 2)

            local success, msg = service:attemptActivation(mockState, 5, 5) -- Coords don't matter much due to mock getCardAt

            assert.is_true(success)
            assert.matches("Activated path %(Cost 2 E%)", msg)
            assert.matches("Path 1 activated!", msg)
            assert.matches("Path 2 activated!", msg)
            -- Check side effects
            assert.are.equal(1, mockPlayer1.resources.energy) -- 3 - 2 = 1
            assert.are.equal(1, activationEffect1_calls) -- Target activates first
            assert.are.equal(1, activationEffect2_calls) -- Then previous node
        end)

        it("should return failure if path found but unaffordable", function()
            mockPlayer1.resources.energy = 1 -- Make unaffordable (cost 2)
            local success, msg = service:attemptActivation(mockState, 5, 5)

            assert.is_false(success)
            assert.matches("Not enough energy", msg)
            -- Check no side effects
            assert.are.equal(1, mockPlayer1.resources.energy)
            assert.are.equal(0, activationEffect1_calls)
            assert.are.equal(0, activationEffect2_calls)
        end)

        it("should return failure if no path found", function()
            -- Remove path cards from network to force path not found
            mockNetwork1.cards = { ["REACTOR_BASE"] = mockNetwork1.cards["REACTOR_BASE"] }
            local success, msg = service:attemptActivation(mockState, 5, 5)

            assert.is_false(success)
            assert.matches("No valid activation path", msg)
            -- Check no side effects
            assert.are.equal(5, mockPlayer1.resources.energy)
            assert.are.equal(0, activationEffect1_calls)
        end)

        it("should allow activating the Reactor and grant energy", function()
            local mockReactorCard = mockNetwork1:findReactor() -- Get the reactor from the mock network
            mockNetwork1.getCardAt_result = mockReactorCard -- Set getCardAt to return reactor
            mockPlayer1.resources.energy = 5 -- Ensure player has energy
            
            -- Mock path validation to return a path of length 0 (direct connection)
            service.rules.isActivationPathValid = function(_, network, startNodeId, targetNodeId)
                if targetNodeId == mockReactorCard.id then
                    return true, {}, nil -- Empty path, cost 0
                end
                return false, nil, "Path validation failed for test"
            end

            local playerEnergyBefore = mockPlayer1.resources.energy
            local success, msg = service:attemptActivation(mockState, 0, 0) -- Target reactor coords

            assert.is_true(success, "Reactor activation should succeed. Reason: " .. (msg or "nil"))
            -- Check for activation message (may or may not have newline depending on path length)
            assert.matches("Reactor Core activated!", msg)
            assert.are.equal(playerEnergyBefore + 1, mockPlayer1.resources.energy) -- Gained 1E from effect, spent 0E cost
        end)
        
        it("should activate Reactor even if path validation returns non-empty path", function()
            local mockReactorCard = mockNetwork1:findReactor() 
            mockNetwork1.getCardAt_result = mockReactorCard 
            mockPlayer1.resources.energy = 5 
            
            -- Mock path validation to return a path of length 1 (cost 1)
            service.rules.isActivationPathValid = function(_, network, startNodeId, targetNodeId)
                if targetNodeId == mockReactorCard.id then
                    return true, { mockReactorCard.id }, nil -- Path of length 1
                end
                return false, nil, "Path validation failed for test"
            end

            local playerEnergyBefore = mockPlayer1.resources.energy
            local success, msg = service:attemptActivation(mockState, 0, 0) 

            assert.is_true(success, "Reactor activation should succeed. Reason: " .. (msg or "nil"))
            -- Check for activation message (should include reactor)
            assert.matches("Reactor Core activated!", msg)
            assert.are.equal(playerEnergyBefore - 1 + 1, mockPlayer1.resources.energy) -- Cost 1E, Gained 1E
        end)

        it("should return failure if no card at target location", function()
             mockNetwork1.getCardAt_result = nil -- No card there
             local success, msg = service:attemptActivation(mockState, 5, 5)
             assert.is_false(success)
             assert.matches("No card at activation target", msg)
        end)
    end)

    describe("GameService:discardCard()", function()
        it("should remove card, add material, and return success for valid index", function()
            local success, msg = service:discardCard(mockState, 2) -- Discard Card 2
            assert.is_true(success)
            assert.matches("Discarded 'Card 2'", msg)
            -- Check side effects
            assert.are.equal(1, #mockPlayer1.hand)
            assert.are.same(mockCard1, mockPlayer1.hand[1])
            assert.are.equal(6, mockPlayer1.resources.material) -- Got 1M
            assert.are.equal(1, #mockPlayer1.addResource_calls)
            assert.are.equal('material', mockPlayer1.addResource_calls[1].type)
        end)

        it("should return failure for invalid card index", function()
            local success, msg = service:discardCard(mockState, 99)
            assert.is_false(success)
            assert.matches("Invalid card index", msg)
            assert.are.equal(2, #mockPlayer1.hand) -- Hand unchanged
            assert.are.equal(5, mockPlayer1.resources.material) -- Material unchanged
        end)
    end)

    describe("GameService:endTurn()", function()
        it("should advance currentPlayerIndex and return success", function()
            assert.are.equal(1, service.currentPlayerIndex)
            -- Mock rules to not trigger game end
            service.rules.isGameEndTriggered = function() return false end
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.matches("Player 2's turn", msg)
            assert.are.equal(2, service.currentPlayerIndex)
        end)

        it("should wrap currentPlayerIndex correctly", function()
            service.currentPlayerIndex = 2 -- Start at player 2
            -- Mock rules to not trigger game end
            service.rules.isGameEndTriggered = function() return false end
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.matches("Player 1's turn", msg)
            assert.are.equal(1, service.currentPlayerIndex)
        end)
        
        it("should return GAME_OVER when end condition is triggered", function()
            -- Mock rules to trigger game end
            service.rules.isGameEndTriggered = function() return true end 
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.are.equal("GAME_OVER", msg)
            assert.is_true(service.gameOver) -- Check game over flag
        end)

        it("should draw a card during cleanup if player hand is below minimum", function()
            mockPlayer1.hand = {} -- Empty hand
            service.deck = { createMockCard("D1", "Deck Card 1", 0, 0) } -- One card in deck
            service.rules.isGameEndTriggered = function() return false end
            -- Mock shouldDrawCard correctly accepting self (rules) and player
            service.rules.shouldDrawCard = function(rules_self, player_arg)
                assert(type(player_arg.getHandSize) == 'function', "Mock player missing getHandSize method in 'should draw' test")
                return true -- Always return true for this test case
            end
            
            assert.are.equal(0, #mockPlayer1.hand)
            local success, msg = service:endTurn(mockState)
            
            assert.is_true(success)
            assert.are.equal(1, #mockPlayer1.hand) -- Player drew a card
            assert.are.equal("D1", mockPlayer1.hand[1].id)
            assert.are.equal(0, #service.deck) -- Deck is now empty
            assert.are.equal(2, service.currentPlayerIndex) -- Turn advanced
        end)
        
        it("should NOT draw a card during cleanup if player hand is at minimum", function()
            -- Assume MIN_HAND_SIZE is at least 2 based on previous tests
            mockPlayer1.hand = { mockCard1, mockCard2 }
            service.deck = { createMockCard("D1", "Deck Card 1", 0, 0) }
            service.rules.isGameEndTriggered = function() return false end
            service.rules.MIN_HAND_SIZE = 2 -- Set explicitly for test clarity
            -- Mock shouldDrawCard correctly accepting self (rules) and player
            service.rules.shouldDrawCard = function(rules_self, player_arg) 
                assert(type(player_arg.getHandSize) == 'function', "Mock player missing getHandSize method in 'should NOT draw' test")
                return player_arg:getHandSize() < service.rules.MIN_HAND_SIZE
            end

            assert.are.equal(2, #mockPlayer1.hand)
            local success, msg = service:endTurn(mockState)
            
            assert.is_true(success)
            assert.are.equal(2, #mockPlayer1.hand) -- Hand size unchanged
            assert.are.equal(1, #service.deck)    -- Deck unchanged
            assert.are.equal(2, service.currentPlayerIndex) -- Turn advanced
        end)
    end)

end)
