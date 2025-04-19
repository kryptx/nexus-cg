-- tests/game/game_service_spec.lua
-- Unit tests for the GameService module

local GameService = require 'src.game.game_service'
local Card = require 'src.game.card' -- For card types

-- Helper to create basic mock objects
local function createMockCard(id, title, costM, costD, actionEffect)
    local card = {
        id = id, title = title,
        buildCost = { material = costM or 0, data = costD or 0 },
        actionEffect = actionEffect or function() end,
        -- Add other fields if needed by service methods being tested
        type = Card.Type.TECHNOLOGY -- Default type for simplicity
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
        end
    }
    return player
end

local function createMockNetwork(cards, validPlacementResult, pathResult)
    local network = {
        cards = cards or {},
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
        end,
        findPathToReactor = function(self, targetCard)
            table.insert(self.findPath_calls, { target = targetCard })
            return self.findPathToReactor_result
        end,
        getCardAt = function(self, x, y)
            -- Simplistic mock: return pre-set result
            return self.getCardAt_result
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

        mockState = {
            players = { mockPlayer1, mockPlayer2 },
            currentPlayerIndex = 1,
            renderer = { -- Mock renderer needed for potential coord funcs if service used them
                screenToWorldCoords = function() return 0, 0 end,
                worldToGridCoords = function() return 0, 0 end
            }
        }
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
        local actionEffect1_calls, actionEffect2_calls

        before_each(function()
            actionEffect1_calls = 0
            actionEffect2_calls = 0
            pathCard1 = createMockCard("P1", "Path 1", 0, 0, function() actionEffect1_calls = actionEffect1_calls + 1 end)
            pathCard2 = createMockCard("P2", "Path 2", 0, 0, function() actionEffect2_calls = actionEffect2_calls + 1 end)
            targetCard = pathCard1 -- Usually target is first element of path
            mockNetwork1.getCardAt_result = targetCard -- Make getCardAt return the target
        end)

        it("should activate path, spend energy, and return success if path found and affordable", function()
            mockNetwork1.findPathToReactor_result = { pathCard1, pathCard2 } -- Path length 2
            mockPlayer1.resources.energy = 3 -- Make affordable (cost 2)

            local success, msg = service:attemptActivation(mockState, 5, 5) -- Coords don't matter much due to mock getCardAt

            assert.is_true(success)
            assert.matches("Activated path %(Cost 2 E%)", msg)
            assert.matches("Path 1 activated!", msg)
            assert.matches("Path 2 activated!", msg)
            -- Check side effects
            assert.are.equal(1, mockPlayer1.resources.energy) -- 3 - 2 = 1
            assert.are.equal(1, actionEffect1_calls) -- Target activates first
            assert.are.equal(1, actionEffect2_calls) -- Then previous node
            assert.are.equal(1, #mockNetwork1.findPath_calls)
            assert.are.same(targetCard, mockNetwork1.findPath_calls[1].target)
        end)

        it("should return failure if path found but unaffordable", function()
             mockNetwork1.findPathToReactor_result = { pathCard1, pathCard2 } -- Path length 2
             mockPlayer1.resources.energy = 1 -- Make unaffordable (cost 2)
             local success, msg = service:attemptActivation(mockState, 5, 5)

             assert.is_false(success)
             assert.matches("Not enough energy", msg)
             -- Check no side effects
             assert.are.equal(1, mockPlayer1.resources.energy)
             assert.are.equal(0, actionEffect1_calls)
             assert.are.equal(0, actionEffect2_calls)
        end)

        it("should return failure if no path found", function()
             mockNetwork1.findPathToReactor_result = nil -- No path
             local success, msg = service:attemptActivation(mockState, 5, 5)

             assert.is_false(success)
             assert.matches("No valid activation path", msg)
             -- Check no side effects
             assert.are.equal(5, mockPlayer1.resources.energy)
             assert.are.equal(0, actionEffect1_calls)
        end)

        it("should return failure if target card is Reactor", function()
            mockNetwork1.getCardAt_result = createMockCard("REACTOR", "Reactor", 0, 0)
            mockNetwork1.getCardAt_result.type = Card.Type.REACTOR -- Set type
            local success, msg = service:attemptActivation(mockState, 0, 0)
            assert.is_false(success)
            assert.matches("Cannot activate the Reactor", msg)
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
            assert.are.equal(1, mockState.currentPlayerIndex)
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.matches("Player 2's turn", msg)
            assert.are.equal(2, mockState.currentPlayerIndex)
        end)

        it("should wrap currentPlayerIndex correctly", function()
            mockState.currentPlayerIndex = 2 -- Start at player 2
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.matches("Player 1's turn", msg)
            assert.are.equal(1, mockState.currentPlayerIndex)
        end)
    end)

end)
