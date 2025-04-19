-- tests/game/network_spec.lua
-- Unit tests for the Network module

local Network = require 'src.game.network'
local Player = require 'src.game.player'
local Card = require 'src.game.card'

describe("Network Module", function()
    local player
    local network
    local reactorCard
    local cardTechInputOnly -- Needs Tech Output from neighbor (e.g., Reactor bottom-right)
    local cardCultOutputOnly -- Provides Cult Output (e.g., top-left)
    local cardCultInputOnly -- Needs Cult Output from neighbor (e.g., cardCultOutputOnly top-left)
    local cardResourceInputOnly -- Needs Resource Output from neighbor (e.g., Reactor right-bottom)

    before_each(function()
        -- Mock Reactor definition
        local reactorData = {
            id = "REACTOR_BASE", type = Card.Type.REACTOR, title = "Reactor",
            openSlots = { -- All open
                [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true
            }
        }
        reactorCard = Card:new(reactorData)

        -- Mock Player setup
        player = Player:new(1, "Test Player Net")
        player.reactorCard = reactorCard -- Assign reactor BEFORE creating network
        reactorCard.owner = player -- Set owner here, before Network:new uses the card

        -- Create Network and initialize with reactor
        network = Network:new(player)
        network:initializeWithReactor(reactorCard)

        -- Define Test Node Cards
        cardTechInputOnly = Card:new({ id = "NODE_T_IN", type = Card.Type.TECHNOLOGY, title = "Tech In",
            openSlots = { [Card.Slots.TOP_RIGHT] = true } -- Tech Input only
        })
        cardCultOutputOnly = Card:new({ id = "NODE_C_OUT", type = Card.Type.CULTURE, title = "Cult Out",
            openSlots = { [Card.Slots.TOP_LEFT] = true } -- Cult Output only
        })
        cardCultInputOnly = Card:new({ id = "NODE_C_IN", type = Card.Type.CULTURE, title = "Cult In",
            openSlots = { [Card.Slots.BOTTOM_LEFT] = true } -- Cult Input only
        })
        cardResourceInputOnly = Card:new({ id = "NODE_R_IN", type = Card.Type.RESOURCE, title = "Res In",
            openSlots = { [Card.Slots.LEFT_BOTTOM] = true } -- Resource Input only
        })

        -- Set owner on test cards BEFORE placing them in network to avoid warnings
        cardTechInputOnly.owner = player
        cardCultOutputOnly.owner = player
        cardCultInputOnly.owner = player
        cardResourceInputOnly.owner = player
    end)

    describe("Network:new()", function()
        it("should create an empty network", function()
            local freshNetwork = Network:new(player)
            assert.is_true(freshNetwork:isEmpty())
        end)
        
        it("should initialize with reactor when initializeWithReactor is called", function()
            local freshNetwork = Network:new(player)
            freshNetwork:initializeWithReactor(reactorCard)
            local cardAtOrigin = freshNetwork:getCardAt(0, 0)
            assert.is_not_nil(cardAtOrigin)
            assert.are.same(reactorCard, cardAtOrigin)
            assert.are.same(freshNetwork, cardAtOrigin.network)
            assert.is_table(cardAtOrigin.position)
            assert.are.equal(0, cardAtOrigin.position.x)
            assert.are.equal(0, cardAtOrigin.position.y)
            assert.are.same(reactorCard, freshNetwork.cards[reactorCard.id])
        end)
    end)

    describe("Network:isValidPlacement()", function()
        -- === Basic Rule Checks ===
        it("should return false for occupied location", function()
            local isValid, reason = network:isValidPlacement(cardTechInputOnly, 0, 0) -- Try placing on Reactor
            assert.is_false(isValid)
            assert.matches("Position already occupied", reason, nil, true) -- Case insensitive match
        end)

        it("should return false for non-adjacent location", function()
            local isValid, reason = network:isValidPlacement(cardTechInputOnly, 2, 0) -- Not adjacent to (0,0)
            assert.is_false(isValid)
            assert.matches("Must be adjacent to at least one card", reason, nil, true)
        end)

        it("should return false if card ID already exists in network (Uniqueness)", function()
            network:placeCard(cardTechInputOnly, 0, 1) -- Place it first
            local duplicateCard = Card:new({ id = "NODE_T_IN", type = Card.Type.TECHNOLOGY, title="Duplicate"}) -- Same ID
            duplicateCard.owner = player -- Set owner before placement check
            local isValid, reason = network:isValidPlacement(duplicateCard, 1, 0) -- Try placing duplicate
            assert.is_false(isValid)
            assert.matches("already exists in network", reason, nil, true)
        end)

        -- === Connection Rule Checks (Adjacent to Reactor) ===
        it("should be valid adjacent to Reactor if card has matching Input (Tech In vs Reactor Bot-Right Output)", function()
            -- Place TechInput card below Reactor (0,1).
            -- Needs Input on its Top edge. Top-Right slot (2) is Tech Input.
            -- Reactor's corresponding Bottom-Right slot (4) is Tech Output & is open.
            local isValid, reason = network:isValidPlacement(cardTechInputOnly, 0, 1)
            assert.is_true(isValid, reason)
        end)

        it("should be valid adjacent to Reactor if card has matching Input (Res In vs Reactor Right-Bot Output)", function()
            -- Place ResInput card right of Reactor (1,0).
            -- Needs Input on its Left edge. Left-Bottom slot (6) is Res Input.
            -- Reactor's corresponding Right-Bottom slot (8) is Res Output & is open.
            local cardResourceInputOnly_local = Card:new({ id = "NODE_R_IN", type = Card.Type.RESOURCE, title = "Res In",
                openSlots = { [Card.Slots.LEFT_BOTTOM] = true } -- Left-Bottom(6) is Res Input
            })
            cardResourceInputOnly_local.owner = player -- Set owner
            local isValid, reason = network:isValidPlacement(cardResourceInputOnly_local, 1, 0)
            assert.is_true(isValid, reason)
        end)

        it("should be invalid adjacent to Reactor if card has NO open Input on connecting edge", function()
            -- Place CultOutput card below Reactor (0,1).
            -- Needs Input on its Top edge (Slots 1, 2). Card only has Cult Output (Slot 1 open).
            local isValid, reason = network:isValidPlacement(cardCultOutputOnly, 0, 1)
            assert.is_false(isValid)
            assert.matches("No valid connection found", reason, nil, true)
        end)

        -- === Connection Rule Checks (Adjacent to Node) ===
        it("should be valid adjacent to Node if matching Output->Input exists", function()
            -- Setup:
            -- Define a card that needs Tech Input (Top-Right 2) to place below Reactor
            -- And provides Tech Output (Bottom-Right 4) downwards.
            local card_T_TechOut = Card:new({ id="TTO", type=Card.Type.TECHNOLOGY, title="TTO",
                                             openSlots={ [Card.Slots.TOP_RIGHT]=true,
                                                         [Card.Slots.BOTTOM_RIGHT]=true }
                                           })
            card_T_TechOut.owner = player -- Set owner
            -- Verify placement below reactor is valid and place it.
            local place1_valid, reason1 = network:isValidPlacement(card_T_TechOut, 0, 1)
            assert.is_true(place1_valid, "Setup Failed: TTO placement at (0,1) invalid. Reason: " .. (reason1 or "nil"))
            network:placeCard(card_T_TechOut, 0, 1)

            -- Define a card that needs Tech Input (Top-Right 2) to place below TTO.
            local card_B_TechIn = Card:new({ id="BTI", type=Card.Type.TECHNOLOGY, title="BTI",
                                             openSlots={ [Card.Slots.TOP_RIGHT]=true }
                                           })
            card_B_TechIn.owner = player -- Set owner
            -- Test:
            -- Check validity of placing card_B_TechIn at (0,2) below card_T_TechOut.
            -- Expected: Valid because BTI's Top-Right(2) [Tech Input] matches
            -- TTO's corresponding Bottom-Right(4) [Tech Output].
            local isValid, reason = network:isValidPlacement(card_B_TechIn, 0, 2)
            assert.is_true(isValid, "Placement of BTI at (0,2) should be valid. Reason: " .. (reason or "nil"))
        end)

        it("should be invalid adjacent to Node if no matching Output->Input exists (type mismatch)", function()
            -- Setup: Place Tech Output card at (0,1)
            local card_T_TechOut = Card:new({ id="TTO", type=Card.Type.TECHNOLOGY, title="TTO", openSlots={ [Card.Slots.BOTTOM_RIGHT]=true, [Card.Slots.TOP_RIGHT]=true }})
            card_T_TechOut.owner = player -- Set owner
            network:placeCard(card_T_TechOut, 0, 1)

            -- Test: Try placing Cult Input card below it at (0,2)
            local card_B_CultIn = Card:new({ id="BCI", type=Card.Type.CULTURE, title="BCI", openSlots={ [Card.Slots.TOP_LEFT]=true }})
            card_B_CultIn.owner = player -- Set owner
            local isValid, reason = network:isValidPlacement(card_B_CultIn, 0, 2)
            assert.is_false(isValid)
            assert.matches("No valid connection found", reason, nil, true)
        end)

        it("should be invalid adjacent to Node if required Input slot on new card is closed", function()
             -- Setup: Place card providing Tech Output downwards at (0,1)
            local card_T_TechOut = Card:new({ id="TTO", type=Card.Type.TECHNOLOGY, title="TTO", openSlots={ [Card.Slots.BOTTOM_RIGHT]=true, [Card.Slots.TOP_RIGHT]=true }})
            card_T_TechOut.owner = player -- Set owner
            network:placeCard(card_T_TechOut, 0, 1)

            -- Test: Place card needing Tech Input below it at (0,2), but its Input slot is closed
            local card_B_TechIn_Closed = Card:new({ id="BTI", type=Card.Type.TECHNOLOGY, title="BTI", openSlots={}})
            card_B_TechIn_Closed.owner = player -- Set owner
            local isValid, reason = network:isValidPlacement(card_B_TechIn_Closed, 0, 2)
            assert.is_false(isValid)
            assert.matches("No valid connection found", reason, nil, true)
        end)

        it("should be invalid adjacent to Node if matching Output slot on adjacent card is closed", function()
            -- Setup: Place card providing NO Tech Output downwards at (0,1)
            local card_T_NoTechOut = Card:new({ id="TNTO", type=Card.Type.TECHNOLOGY, title="TNTO", openSlots={ [Card.Slots.TOP_RIGHT]=true }})
            card_T_NoTechOut.owner = player -- Set owner
            network:placeCard(card_T_NoTechOut, 0, 1)

            -- Test: Place card needing Tech Input below it at (0,2)
            local card_B_TechIn = Card:new({ id="BTI", type=Card.Type.TECHNOLOGY, title="BTI", openSlots={ [Card.Slots.TOP_RIGHT]=true }})
            card_B_TechIn.owner = player -- Set owner
            local isValid, reason = network:isValidPlacement(card_B_TechIn, 0, 2)
            assert.is_false(isValid)
            assert.matches("No valid connection found", reason, nil, true)
        end)
    end)

    describe("Network:findPathToReactor()", function()
        local card_T_Out_B_In -- Provides Tech Output down, Needs Tech Input top
        local card_B_In_T_Out -- Needs Tech Input top, Provides Tech Output down
        local card_T_Cult_Out -- Provides Cult Output down
        local card_Disconnected

        before_each(function()
            -- Cards for multi-step path
            card_T_Out_B_In = Card:new({ id="T_OB", type=Card.Type.TECHNOLOGY, title="T_OB",
                                        openSlots={ [Card.Slots.TOP_RIGHT]=true, [Card.Slots.BOTTOM_RIGHT]=true } })
            card_T_Out_B_In.owner = player -- Set owner
            card_B_In_T_Out = Card:new({ id="B_IT", type=Card.Type.TECHNOLOGY, title="B_IT",
                                        openSlots={ [Card.Slots.TOP_RIGHT]=true, [Card.Slots.BOTTOM_RIGHT]=true } })
            card_B_In_T_Out.owner = player -- Set owner
            card_T_Cult_Out = Card:new({ id="T_CO", type=Card.Type.CULTURE, title="T_CO",
                                        openSlots={ [Card.Slots.TOP_RIGHT]=true, [Card.Slots.BOTTOM_LEFT]=true } })
            card_T_Cult_Out.owner = player -- Set owner
            card_Disconnected = Card:new({ id="DISC", type=Card.Type.KNOWLEDGE, title="Disc" })
            card_Disconnected.owner = player -- Set owner

            -- Setup basic path for some tests: Reactor -> T_OB -> B_IT
            -- Place T_OB at (0,1)
            local valid1, _ = network:isValidPlacement(card_T_Out_B_In, 0, 1)
            if valid1 then network:placeCard(card_T_Out_B_In, 0, 1) end
            -- Place B_IT at (0,2)
            local valid2, _ = network:isValidPlacement(card_B_In_T_Out, 0, 2)
             if valid2 then network:placeCard(card_B_In_T_Out, 0, 2) end
        end)

        it("should find a direct path (1 step) to the reactor", function()
            local targetCard = network:getCardAt(0, 1) -- T_OB
            local path = network:findPathToReactor(targetCard)
            assert.is_table(path)
            assert.are.equal(1, #path)
            assert.are.same(targetCard, path[1])
        end)

        it("should find a multi-step path to the reactor", function()
            local targetCard = network:getCardAt(0, 2) -- B_IT
            local path = network:findPathToReactor(targetCard)
            assert.is_table(path)
            assert.are.equal(2, #path)
            assert.are.same(targetCard, path[1]) -- Target first
            assert.are.same(card_T_Out_B_In, path[2]) -- Then intermediate
        end)

        it("should return nil if the target card is the reactor", function()
             local path = network:findPathToReactor(reactorCard)
             assert.is_nil(path)
        end)

        it("should return nil if no valid Input<-Output path exists", function()
            -- Place a card needing Cult Input below T_OB (which provides Tech Output)
            local card_B_Cult_In = Card:new({ id="BCI", type=Card.Type.CULTURE, title="BCI", openSlots={ [Card.Slots.TOP_LEFT]=true }})
            -- card_B_Cult_In.owner = player -- Already set this in the outer it block
            local placeValid, _ = network:isValidPlacement(card_B_Cult_In, 0, 2) -- This placement itself is invalid, but test pathfind
            -- We need a card that *can* be placed but has no path back
            -- Place Cult Output card at (1,0) - valid vs reactor
            local placeCultValid, _ = network:isValidPlacement(card_T_Cult_Out, 1, 0)
            if placeCultValid then network:placeCard(card_T_Cult_Out, 1, 0) end
            -- Now try to activate it - it provides Cult Output, needs Tech Input, Reactor has no Cult Input
            local targetCard = network:getCardAt(1, 0)
            local path = network:findPathToReactor(targetCard)
            assert.is_nil(path)
        end)

        it("should return nil for a disconnected card", function()
             -- Place card at (5,5) - invalid placement, but we force it for testing pathfinding
             network.grid[5] = network.grid[5] or {}
             network.grid[5][5] = card_Disconnected
             network.cards[card_Disconnected.id] = card_Disconnected
             card_Disconnected.network = network
             card_Disconnected.position = { x=5, y=5 }

             local path = network:findPathToReactor(card_Disconnected)
             assert.is_nil(path)
        end)

        it("should return nil if target card is nil or not in network", function()
            local path1 = network:findPathToReactor(nil)
            assert.is_nil(path1)
            local notInNetworkCard = Card:new({ id="NotInNet", type=Card.Type.KNOWLEDGE, title="NIN" })
            notInNetworkCard.owner = player -- Set owner (though not placed, good practice)
            local path2 = network:findPathToReactor(notInNetworkCard)
            assert.is_nil(path2)
        end)

        -- TODO: Add tests for cycles? BFS should handle simple cycles correctly by default via visited table.
    end)

end)
