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
local CardSlots = require('src.game.card').Slots

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
        openSlots = {},
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
        activate = function(player, network)
            if player and player.addResource then
                player:addResource("energy", 1)
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

    describe("GameService:attemptActivation()", function()
        local mockPath = { "TARGET_ID", "INTERMEDIATE_ID" } -- Corrected: Path TO reactor
        local mockTargetCard, mockIntermediateCard, mockReactorCard

        before_each(function()
            -- Set up common mocks for activation tests
            mockTargetCard = createMockCard("TARGET_ID", "Target Card")
            mockIntermediateCard = createMockCard("INTERMEDIATE_ID", "Intermediate Card")
            mockReactorCard = service.players[1].network.cards["REACTOR_BASE"] -- Get from mock network
            mockNetwork1.cards["TARGET_ID"] = mockTargetCard
            mockNetwork1.cards["INTERMEDIATE_ID"] = mockIntermediateCard
            mockNetwork1.getCardAt_result = mockTargetCard -- Assume click hits target by default
            mockNetwork1.findPathToReactor_result = { mockTargetCard, mockIntermediateCard } -- Return instances
            -- Correct mock to return path TO reactor
            service.rules.isActivationPathValid = function() return true, mockPath, nil end 
            mockPlayer1.resources = { energy=10, data=0, material=0 }
            -- DO NOT set phase here, set in each 'it' block
        end)

        it("should activate path, spend energy, and return success if path found and affordable", function()
            service.currentPhase = TurnPhase.ACTIVATE -- Set phase for this test
            local success, msg = service:attemptActivation(mockState, 0, 0) 
            assert.is_true(success)
            -- Path length is 2 (target, intermediate), cost is 2
            local expected_msg_pattern = "Activated path %(Cost 2 E%):\n"
                                        .. "%s*- Target Card activated!\n"
                                        .. "%s*- Intermediate Card activated!"
            assert.matches(expected_msg_pattern, msg) -- Removed final 'false' argument
            assert.are.equal(8, mockPlayer1.resources.energy) -- Spent 2 energy (10 - 2)
            assert.falsy(string.match(msg, "Reactor Core activated!"), "Reactor should not be in activation message")
        end)

        it("should return failure if path found but unaffordable", function()
            mockPlayer1.resources.energy = 1 -- Not enough for cost 2
            service.currentPhase = TurnPhase.ACTIVATE -- Set phase for this test
            local success, msg = service:attemptActivation(mockState, 0, 0)
            assert.is_false(success)
            assert.matches("Not enough energy", msg) -- Correct expected message
            assert.are.equal(1, mockPlayer1.resources.energy) -- Energy not spent
        end)

        it("should return failure if no path found", function()
            service.rules.isActivationPathValid = function() return false, nil, "No path mock reason" end
            service.currentPhase = TurnPhase.ACTIVATE -- Set phase for this test
            local success, msg = service:attemptActivation(mockState, 0, 0)
            assert.is_false(success)
            assert.matches("No valid activation path: No path mock reason", msg) -- Correct expected message
        end)

        it("should return failure when targeting the Reactor", function() -- Renamed test
            mockNetwork1.getCardAt_result = mockReactorCard -- Target the reactor
            -- Activation logic first checks if target is reactor, before rules check
            -- service.rules.isActivationPathValid = function() return false, nil, "Cannot activate reactor" end 
            service.currentPhase = TurnPhase.ACTIVATE -- Set phase for this test
            local success, message = service:attemptActivation(mockState, 0, 0)
            assert.is_false(success) -- Expect failure
            assert.matches("Cannot activate the Reactor itself", message) -- Check specific reason from GameService
        end)

        -- Removed the redundant reactor test

        it("should return failure if no card at target location", function()
            mockNetwork1.getCardAt_result = nil -- No card found at location
            service.currentPhase = TurnPhase.ACTIVATE -- Set phase for this test
            local success, msg = service:attemptActivation(mockState, 1, 1)
            assert.is_false(success)
            assert.matches("No card at activation target", msg) -- Correct expected message
        end)
        
        it("should return failure if not in Activate phase", function()
            service.currentPhase = TurnPhase.BUILD -- Wrong phase
            local success, msg = service:attemptActivation(mockState, 0, 0)
            assert.is_false(success)
            assert.matches("Activation not allowed in Build phase", msg)
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
                createMockCard("H3", "H3") 
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

    describe("GameService:findGlobalActivationPath", function()
        local service, p1, p2, p3, net1, net2, net3, p1_reactor, p1_node_a, p1_out_node, p2_in_node, p2_node_b, p3_node_c -- Declare all possible vars

        -- Helper to extract IDs for assertion clarity
        local function getPathIds(pathData)
            local ids = {}
            if pathData and pathData.path then
                for _, nodeInfo in ipairs(pathData.path) do
                    table.insert(ids, nodeInfo.card.id)
                end
            end
            return ids
        end
        
        local CardSlots = Card.Slots -- Cache for brevity

        -- Mock Card/Player/Network creators
        local function createMockCard(id, title, x, y) 
            local card = { id = id, title = title, position = { x = x, y = y }, type="NODE",
                definedOpenSlots = {}, occupiedSlots = nil, owner = nil, network = nil }
            -- Default mock methods, can be overridden in tests
            function card:getSlotProperties(slotIdx) return Card:getSlotProperties(slotIdx) end 
            function card:isSlotAvailable(slotIdx) return mockIsSlotAvail(self, slotIdx) end 
            return card
        end

        local function createMockPlayer(id, resources)
            return { id = id, name = "Player " .. id, resources = resources or {}, network = nil }
        end

        local function createMockNetwork(cards)
            local net = { cards = cards or {} }
            net.cardsById = {}
            for _, card in pairs(net.cards) do net.cardsById[card.id] = card end
            net.getCardById = function(self, id) return self.cardsById[id] end
            net.getCardAt = function(network, x, y)
                 for _, card in pairs(network.cards) do
                     if card.position and card.position.x == x and card.position.y == y then return card end
                 end
                 return nil
            end
            net.getAdjacentCoordForSlot = function(self, x, y, slotIndex) 
                 if slotIndex == CardSlots.TOP_LEFT or slotIndex == CardSlots.TOP_RIGHT then return {x=x, y=y-1} end
                 if slotIndex == CardSlots.BOTTOM_LEFT or slotIndex == CardSlots.BOTTOM_RIGHT then return {x=x, y=y+1} end
                 if slotIndex == CardSlots.LEFT_TOP or slotIndex == CardSlots.LEFT_BOTTOM then return {x=x-1, y=y} end
                 if slotIndex == CardSlots.RIGHT_TOP or slotIndex == CardSlots.RIGHT_BOTTOM then return {x=x+1, y=y} end
                 return nil 
            end
            net.getOpposingSlotIndex = function(self, slotIndex)
                local opposites = {
                    [1]=3, [2]=4, [3]=1, [4]=2, [5]=7, [6]=8, [7]=5, [8]=6
                } -- Use integer keys for direct mapping
                return opposites[slotIndex]
            end
            return net
        end

        -- Updated mockIsSlotAvail function
        local function mockIsSlotAvail(card, slotIdx) 
            if card.occupiedSlots and card.occupiedSlots[slotIdx] then
                return false -- Slot is explicitly occupied
            end
            -- Rely on defined open slots (or assume open if not defined)
            return card.definedOpenSlots == nil or card.definedOpenSlots[slotIdx] == true 
        end

        before_each(function()
            service = GameService:new()
            service.activeConvergenceLinks = {} -- Reset links
            
            -- Create players (ensure enough energy for tests)
            p1 = createMockPlayer(1, { energy=20 }) 
            p2 = createMockPlayer(2, { energy=10 })
            p3 = createMockPlayer(3, { energy=10 })
            service.players = {p1, p2, p3} -- Include p3 even if not always used

            -- Common Cards needed for multiple tests (P1/P2 link)
            p1_reactor = createMockCard("P1_R", "P1 Reactor", 0, 0); p1_reactor.type = Card.Type.REACTOR
            p1_out_node = createMockCard("P1_OUT", "P1 Out", 1, 0) 
            p1_out_node.definedOpenSlots = { 
                [CardSlots.RIGHT_BOTTOM] = true, -- Slot 8 (Res Out) for convergence
                [CardSlots.LEFT_TOP] = true      -- Slot 5 (Know Out) for adjacency to Reactor (Input 7)
            }
            p2_in_node = createMockCard("P2_IN", "P2 In", 0, 0) -- In P2's network
            p2_in_node.definedOpenSlots = { [CardSlots.LEFT_BOTTOM] = true } -- Slot 6 (Res In)

            -- Cards specific to multi-link test (P1_A, P2_B, P3_C)
            p1_node_a = createMockCard("P1_A", "P1 Node A", 1, 0) -- In P1's network, different from P1_OUT
            p1_node_a.definedOpenSlots = { 
                [CardSlots.RIGHT_TOP] = true, -- Slot 7 (Know In) for link from P2_B
                [CardSlots.LEFT_TOP] = true  -- Slot 5 (Know Out) for adjacency to Reactor
            }
            p2_node_b = createMockCard("P2_B", "P2 Node B", 0, 0) -- In P2's network
            p2_node_b.definedOpenSlots = { 
                [CardSlots.LEFT_TOP] = true,     -- Slot 5 (Know Out) for link to P1_A
                [CardSlots.LEFT_BOTTOM] = true   -- Slot 6 (Res In) for link from P3_C
            }
            p3_node_c = createMockCard("P3_C", "P3 Node C", 0, 0) -- In P3's network
            p3_node_c.definedOpenSlots = { [CardSlots.RIGHT_BOTTOM] = true } -- Slot 8 (Res Out)

            -- Create and assign networks
            -- Net1 needs R, OUT, and A for different tests
            net1 = createMockNetwork({p1_reactor, p1_out_node, p1_node_a}) 
            p1.network = net1
            p1_reactor.network = net1; p1_reactor.owner = p1; p1_reactor.position = {x=0,y=0}
            p1_out_node.network = net1; p1_out_node.owner = p1; p1_out_node.position = {x=1,y=0} -- Adjacent to R
            p1_node_a.network = net1; p1_node_a.owner = p1; p1_node_a.position = {x=1,y=0} -- Same pos as OUT, used in different tests

            -- Net2 needs IN and B
            net2 = createMockNetwork({p2_in_node, p2_node_b})
            p2.network = net2
            p2_in_node.network = net2; p2_in_node.owner = p2; p2_in_node.position = {x=0,y=0}
            p2_node_b.network = net2; p2_node_b.owner = p2; p2_node_b.position = {x=0,y=0} -- Same pos, different tests

            -- Net3 needs C
            net3 = createMockNetwork({p3_node_c})
            p3.network = net3
            p3_node_c.network = net3; p3_node_c.owner = p3; p3_node_c.position = {x=0,y=0}

            -- Assign mock methods to all cards
            local all_cards = {p1_reactor, p1_out_node, p2_in_node, p1_node_a, p2_node_b, p3_node_c}
            for _, card in pairs(all_cards) do
                 if card.type ~= Card.Type.REACTOR then
                     card.isSlotAvailable = mockIsSlotAvail -- Use shared mock
                 else 
                      card.isSlotAvailable = function() return true end -- Reactor always available
                 end
                 card.getSlotProperties = function(self, slotIdx) return Card:getSlotProperties(slotIdx) end
            end
        end)

        it("should find a path across a single convergence link", function()
            -- Uses p1_out_node and p2_in_node
            table.insert(service.activeConvergenceLinks, {
                linkId = "testLink1",
                initiatingPlayerIndex = 1, initiatingNodeId = "P1_OUT", 
                initiatingSlotIndex = CardSlots.RIGHT_BOTTOM, -- 8
                targetPlayerIndex = 2, targetNodeId = "P2_IN", 
                targetSlotIndex = CardSlots.LEFT_BOTTOM,   -- 6
                linkType = Card.Type.RESOURCE
            })
            local isValid, pathData, reason = service:findGlobalActivationPath(p2_in_node, p1_reactor, p1)
            assert.is_true(isValid, reason)
            assert.are.equal(3, pathData.cost)
            assert.is_true(pathData.isConvergenceStart)
            assert.are.same({ "P2_IN", "P1_OUT", "P1_R" }, getPathIds(pathData))
        end)

        it("should find a path within a single network (no convergence)", function()
            -- Uses p1_out_node -> p1_reactor
            service.activeConvergenceLinks = {} 
            local isValid, pathData, reason = service:findGlobalActivationPath(p1_out_node, p1_reactor, p1)
            assert.is_true(isValid, reason)
            assert.are.equal(2, pathData.cost)
            assert.is_false(pathData.isConvergenceStart)
            assert.are.same({ "P1_OUT", "P1_R" }, getPathIds(pathData))
        end)

        it("should not find a path if target is disconnected", function()
            -- Uses p2_in_node (in net2) and p1_reactor (in net1), no links
            service.activeConvergenceLinks = {} 
            local isValid, pathData, reason = service:findGlobalActivationPath(p2_in_node, p1_reactor, p1)
            assert.is_false(isValid)
            assert.matches("No valid activation path", reason or "", 1, true)
        end)

        it("should find a path when target is adjacent to the reactor", function()
             -- Uses p1_out_node -> p1_reactor
             service.activeConvergenceLinks = {} 
             local isValid, pathData, reason = service:findGlobalActivationPath(p1_out_node, p1_reactor, p1)
             assert.is_true(isValid, reason)
             assert.are.equal(2, pathData.cost)
             assert.is_false(pathData.isConvergenceStart)
             assert.are.same({ "P1_OUT", "P1_R" }, getPathIds(pathData))
        end)

        it("should not find a path if blocked by an occupied slot (adjacency)", function()
            -- Block p1_out_node's slot 5 needed to connect to reactor slot 7
            p1_out_node.occupiedSlots = { [CardSlots.LEFT_TOP] = "blocker_link" } -- Slot 5
            service.activeConvergenceLinks = {}
            local isValid, pathData, reason = service:findGlobalActivationPath(p1_out_node, p1_reactor, p1)
            assert.is_false(isValid)
            assert.matches("No valid activation path", reason or "", 1, true)
            p1_out_node.occupiedSlots = nil -- Cleanup
        end)

        it("should not find a path if blocked by an occupied slot (convergence)", function()
            -- Add link P1_OUT(8) -> P2_IN(6), then block P2_IN's slot 6
             table.insert(service.activeConvergenceLinks, {
                linkId = "testLink1", initiatingPlayerIndex = 1, initiatingNodeId = "P1_OUT", 
                initiatingSlotIndex = CardSlots.RIGHT_BOTTOM, -- 8
                targetPlayerIndex = 2, targetNodeId = "P2_IN", 
                targetSlotIndex = CardSlots.LEFT_BOTTOM, -- 6
                linkType = Card.Type.RESOURCE
            })
            p2_in_node.occupiedSlots = { [CardSlots.LEFT_BOTTOM] = "blocker_link" } -- Slot 6
            local isValid, pathData, reason = service:findGlobalActivationPath(p2_in_node, p1_reactor, p1)
            assert.is_false(isValid)
            assert.matches("No valid activation path", reason or "", 1, true)
            p2_in_node.occupiedSlots = nil -- Cleanup
        end)

        it("should find a path involving multiple convergence links", function()
            -- Uses p3_node_c -> p2_node_b -> p1_node_a -> p1_reactor
            -- Link 1: P2_B (Slot 5 Out) -> P1_A (Slot 7 In) - Knowledge
            table.insert(service.activeConvergenceLinks, {
                linkId = "link_P2B_P1A", initiatingPlayerIndex = 2, initiatingNodeId = "P2_B", 
                initiatingSlotIndex = CardSlots.LEFT_TOP, -- 5
                targetPlayerIndex = 1, targetNodeId = "P1_A", 
                targetSlotIndex = CardSlots.RIGHT_TOP, -- 7
                linkType = Card.Type.KNOWLEDGE
            })
            -- Link 2: P3_C (Slot 8 Out) -> P2_B (Slot 6 In) - Resource
            table.insert(service.activeConvergenceLinks, {
                linkId = "link_P3C_P2B", initiatingPlayerIndex = 3, initiatingNodeId = "P3_C", 
                initiatingSlotIndex = CardSlots.RIGHT_BOTTOM, -- 8
                targetPlayerIndex = 2, targetNodeId = "P2_B", 
                targetSlotIndex = CardSlots.LEFT_BOTTOM, -- 6
                linkType = Card.Type.RESOURCE
            })
            local isValid, pathData, reason = service:findGlobalActivationPath(p3_node_c, p1_reactor, p1)
            assert.is_true(isValid, reason)
            assert.are.equal(4, pathData.cost)
            assert.is_true(pathData.isConvergenceStart)
            assert.are.same({ "P3_C", "P2_B", "P1_A", "P1_R" }, getPathIds(pathData))
            -- Check owners
            assert.are.same(p3, pathData.path[1].owner)
            assert.are.same(p2, pathData.path[2].owner)
            assert.are.same(p1, pathData.path[3].owner)
            assert.are.same(p1, pathData.path[4].owner)
        end)
        
        -- TODO: Add more tests:
        -- - No path found (invalid link direction) -- Revisit this concept if needed
        
    end)

end)
