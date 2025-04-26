-- tests/game/game_service_spec.lua
-- Unit tests for the GameService module

local luassert = require "luassert"
local Card = require "src/game/card"
local Rules = require "src/game/rules"
local Network = require "src/game/network"
local Player = require "src/game/player"
local GameServiceModule = require "src/game/game_service"
local GameService = GameServiceModule.GameService
local TurnPhase = GameServiceModule.TurnPhase
local CardPorts = require('src.game.card').Ports

-- Helper to create basic mock objects
local function createMockCard(id, title, materialCost, dataCost, activationFunc)
    local card = {
        id = id or "MOCK_CARD",
        title = title or "Mock Card",
        type = Card.Type.TECHNOLOGY, -- Default type
        buildCost = {
            material = materialCost or 0,
            data = dataCost or 0
        },
        definedPorts = {}, -- Add this to be used by isPortDefined
        occupiedPorts = {}, -- Initialize for getOccupyingLinkId
        position = { x = 0, y = 0 }, -- Default position
        
        -- New format of activation effect
        activationEffect = {
            description = "Mock activation effect",
            activate = activationFunc or function() end
        },
        
        -- New format of convergence effect
        convergenceEffect = {
            description = "Mock convergence effect",
            activate = function() end
        },
        
        -- Add the new method that Card now has
        activateEffect = function(self, player, network)
            if self.activationEffect and self.activationEffect.activate then
                return self.activationEffect.activate(player, network)
            end
        end,
        
        getActivationDescription = function(self)
            return self.activationEffect and self.activationEffect.description or "[No Description]"
        end,
        
        getConvergenceDescription = function(self)
            return self.convergenceEffect and self.convergenceEffect.description or "[No Description]"
        end,
        
        -- Add activateConvergence method to the card mock
        activateConvergence = function(self, player, network)
            if self.convergenceEffect and self.convergenceEffect.activate then
                return self.convergenceEffect.activate(player, network)
            end
        end,

        -- Add mock methods for new checks
        isPortDefined = function(self, portIndex)
            return self.definedPorts[portIndex] == true
        end,
        getOccupyingLinkId = function(self, portIndex)
            return self.occupiedPorts[portIndex]
        end,
        -- Re-add isPortAvailable, mimicking the real Card logic
        isPortAvailable = function(self, portIndex)
            local isDefined = self:isPortDefined(portIndex)
            local isOccupied = self:getOccupyingLinkId(portIndex) ~= nil
            return isDefined and not isOccupied
        end,
    }
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
    mockReactor.activationEffect = {
        description = "Grants 1 Energy to the activator.",
        -- Accept all args passed by outer activateEffect, use the activatingPlayer (arg 2)
        activate = function(gameService, activatingPlayer, targetNetwork, targetNode) 
            if activatingPlayer and activatingPlayer.addResource then
                activatingPlayer:addResource("energy", 1)
            end
        end
    }
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
            service.currentPhase = TurnPhase.BUILD -- Ensure correct phase
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
            service.currentPhase = TurnPhase.BUILD -- Ensure correct phase
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
            service.currentPhase = TurnPhase.BUILD -- Ensure correct phase
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

        it("should return failure if not in Build phase", function()
            mockNetwork1.isValidPlacement_result = { true, "Valid" }
            service.currentPhase = TurnPhase.ACTIVATE -- Set wrong phase
            local success, msg = service:attemptPlacement(mockState, 1, 10, 20)
            assert.is_false(success)
            assert.matches("not allowed in Activate phase", msg)
        end)
    end)

    describe("GameService:discardCard()", function()
        it("should remove card, add material, and return success for valid index", function()
            local success, msg = service:discardCard(mockState, 2, 'material') -- Discard Card 2 for material
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
            local success, msg = service:discardCard(mockState, 99, 'material') -- Add type arg
            assert.is_false(success)
            assert.matches("Invalid card index", msg)
            assert.are.equal(2, #mockPlayer1.hand) -- Hand unchanged
            assert.are.equal(5, mockPlayer1.resources.material) -- Material unchanged
        end)

        it("should return failure if not in Build phase", function()
            service.currentPhase = TurnPhase.ACTIVATE -- Wrong phase
            local success, msg = service:discardCard(mockState, 1, 'material') -- Add type arg
            assert.is_false(success)
            assert.matches("Discarding not allowed in Activate phase", msg)
        end)
    end)

    describe("GameService:endTurn()", function()
        before_each(function()
            -- Mock Rules methods used by endTurn
            service.rules.isGameEndTriggered = function() return false end
            service.rules.shouldDrawCard = function() return false end
            service.drawCard = function() return nil end -- Mock drawCard
            service.currentPhase = TurnPhase.CONVERGE -- Set phase to allow ending turn by default
            -- Reset player hand explicitly before each test in this block
            if mockPlayer1 then mockPlayer1.hand = {} end
            if mockPlayer2 then mockPlayer2.hand = {} end
        end)

        it("should advance currentPlayerIndex and return success", function()
            -- service.currentPhase is set in before_each
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.are.equal(2, service.currentPlayerIndex) -- Advanced from 1 to 2
            assert.are.equal(TurnPhase.BUILD, service.currentPhase) -- Reset to Build
            assert.matches("Player 2.s turn %(Build Phase%)", msg)
        end)

        it("should wrap currentPlayerIndex correctly", function()
            service.currentPlayerIndex = 2 -- Start as player 2
             -- service.currentPhase is set in before_each
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.are.equal(1, service.currentPlayerIndex) -- Wrapped back to 1
            assert.are.equal(TurnPhase.BUILD, service.currentPhase) -- Reset to Build
            assert.matches("Player 1.s turn %(Build Phase%)", msg)
        end)

        it("should return GAME_OVER when end condition is triggered", function()
            service.rules.isGameEndTriggered = function() return true end
             -- service.currentPhase is set in before_each
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.are.equal("GAME_OVER", msg)
            assert.is_true(service.gameOver)
        end)

        it("should draw a card during cleanup if player hand is below minimum", function()
            local drawnCard = createMockCard("D1", "Drawn Card")
            service.drawCard = function() return drawnCard end -- Mock drawCard to return a card
            service.rules.shouldDrawCard = function(player) 
                -- Simplify mock to avoid getHandSize call
                return true -- Assume rule dictates draw for this test
            end
            mockPlayer1.hand = {} -- Hand is reset in before_each, confirm it's empty
            assert.are.equal(0, #mockPlayer1.hand, "Pre-condition: Hand size should be 0")
             -- service.currentPhase is set in before_each (CONVERGE)
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.are.equal(1, #mockPlayer1.hand, "Post-condition: Hand size should be 1 after draw")
            assert.are.same(drawnCard, mockPlayer1.hand[1])
        end)

        it("should NOT draw a card during cleanup if player hand is at minimum", function()
            local drawCalled = false
            service.drawCard = function() drawCalled = true; return nil end -- Monitor if called
            service.rules.shouldDrawCard = function(player) 
                 -- Simplify mock to avoid getHandSize call
                return false -- Assume rule dictates NO draw for this test
            end
            -- Create a hand exactly at minimum size
            mockPlayer1.hand = { 
                createMockCard("H1", "H1"), 
                createMockCard("H2", "H2"), 
                createMockCard("H3", "H3"),
                createMockCard("H4", "H4"),
                createMockCard("H5", "H5"),
                createMockCard("H6", "H6"),
                createMockCard("H7", "H7"),
                createMockCard("H8", "H8"),
                createMockCard("H9", "H9"),
                createMockCard("H10", "H10")
            }
            assert.are.equal(require('src.game.rules').MIN_HAND_SIZE, #mockPlayer1.hand, "Pre-condition: Hand size should be MIN_HAND_SIZE")
             -- service.currentPhase is set in before_each (CONVERGE)
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.is_false(drawCalled, "drawCard should not have been called")
            assert.are.equal(require('src.game.rules').MIN_HAND_SIZE, #mockPlayer1.hand) -- Hand unchanged
        end)
    

        it("should allow ending turn from Cleanup phase", function()
            service.currentPhase = TurnPhase.CLEANUP -- Explicitly set Cleanup phase
            local success, msg = service:endTurn(mockState)
            assert.is_true(success)
            assert.are.equal(2, service.currentPlayerIndex)
            assert.are.equal(TurnPhase.BUILD, service.currentPhase)
        end)
        
        it("should advance phase automatically if ending turn early", function()
            service.currentPhase = TurnPhase.BUILD -- Try ending turn from Build
            service.rules.shouldDrawCard = function() return false end -- Ensure no drawing interference
            local success, msg = service:endTurn(mockState) -- Pass mockState instead of nil
            assert.is_true(success) -- Should still be true
            assert.are.equal(2, service.currentPlayerIndex, "Should advance to player 2")
            assert.are.equal(TurnPhase.BUILD, service.currentPhase, "Phase should reset to BUILD for next player")
            assert.matches("Player 2.s turn %(Build Phase%)", msg, "Message should indicate next player's turn")
        end)
    end)
end)
