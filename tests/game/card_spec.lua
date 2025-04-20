-- tests/game/card_spec.lua
-- Unit tests for the Card module

-- Assuming project root is added to LUA_PATH or busted is run from root
-- Alternatively, adjust require path if needed (e.g., '../src/game/card')
local Card = require 'src.game.card'

describe("Card Module", function()

    local testCardData

    before_each(function()
        -- Basic valid data for most tests
        testCardData = {
            id = "TEST_001",
            title = "Test Card",
            type = Card.Type.TECHNOLOGY,
            buildCost = { material = 1 },
            openSlots = {
                [Card.Slots.TOP_LEFT] = true, -- Culture Output
                [Card.Slots.RIGHT_BOTTOM] = true -- Resource Output (Corrected)
            }
        }
    end)

    describe("Card:new()", function()
        it("should create a card instance with valid data", function()
            local card = Card:new(testCardData)
            assert.is_table(card)
            assert.are.equal(testCardData.id, card.id)
            assert.are.equal(testCardData.title, card.title)
            assert.are.equal(testCardData.type, card.type)
            assert.are.equal(testCardData.buildCost.material, card.buildCost.material)
            assert.are.equal(0, card.buildCost.data) -- Check default
            assert.is_true(card.openSlots[Card.Slots.TOP_LEFT])
            assert.is_falsy(card.openSlots[Card.Slots.TOP_RIGHT]) -- Check default
        end)

        it("should use default values when optional data is omitted", function()
            local minimalData = { id = "MIN_001", type = Card.Type.RESOURCE }
            local card = Card:new(minimalData)
            assert.are.equal("Untitled Card", card.title)
            assert.are.equal(0, card.buildCost.material)
            assert.are.equal(0, card.buildCost.data)
            assert.are.equal(0, card.vpValue)
            assert.is_nil(next(card.openSlots))
            assert.is_falsy(card.art)
            assert.are.equal("", card.flavorText)
            assert.is_function(card.activationEffect)
            assert.is_function(card.convergenceEffect)
        end)

        it("should error if required 'id' is missing", function()
            testCardData.id = nil
            assert.error(function() Card:new(testCardData) end)
        end)

        it("should error if required 'type' is missing", function()
            testCardData.type = nil
            assert.error(function() Card:new(testCardData) end)
        end)
    end)

    describe("Card:isSlotOpen()", function()
        local card
        before_each(function()
            card = Card:new(testCardData)
        end)

        it("should return true for an explicitly open slot", function()
            assert.is_true(card:isSlotOpen(Card.Slots.TOP_LEFT))
            assert.is_true(card:isSlotOpen(Card.Slots.RIGHT_BOTTOM))
        end)

        it("should return false for a slot not explicitly opened", function()
            assert.is_false(card:isSlotOpen(Card.Slots.TOP_RIGHT))
            assert.is_false(card:isSlotOpen(Card.Slots.LEFT_TOP))
        end)

        it("should return false for an invalid/non-existent slot index", function()
            assert.is_false(card:isSlotOpen(99))
            assert.is_false(card:isSlotOpen("invalid"))
        end)
    end)

    describe("Connection Management", function()
        local card1, card2, card3
        before_each(function() 
            card1 = Card:new({ id = "C1", type = Card.Type.TECHNOLOGY })
            card2 = Card:new({ id = "C2", type = Card.Type.CULTURE })
            card3 = Card:new({ id = "C3", type = Card.Type.TECHNOLOGY })
        end)

        it("should initialize with an empty connections table", function()
            assert.is_table(card1.connections)
            assert.are.equal(0, #card1.connections)
        end)

        it("should add connections correctly", function()
            card1:addConnection(card2, Card.Slots.BOTTOM_RIGHT, Card.Slots.TOP_LEFT)
            assert.are.equal(1, #card1.connections)
            local conn = card1.connections[1]
            assert.are.same(card2, conn.target)
            assert.are.equal(Card.Slots.BOTTOM_RIGHT, conn.selfSlot)
            assert.are.equal(Card.Slots.TOP_LEFT, conn.targetSlot)
        end)

        it("should handle multiple connections", function()
            card1:addConnection(card2, 1, 3)
            card1:addConnection(card3, 4, 2)
            assert.are.equal(2, #card1.connections)
        end)

        it("should remove connections by target card", function()
            card1:addConnection(card2, 1, 3)
            card1:addConnection(card3, 4, 2)
            local result = card1:removeConnection(card2)
            assert.is_true(result)
            assert.are.equal(1, #card1.connections)
            assert.are.same(card3, card1.connections[1].target)
            
            local result_nonexistent = card1:removeConnection(card2) -- Try removing again
            assert.is_false(result_nonexistent)
            assert.are.equal(1, #card1.connections)
        end)

        it("should return false when trying to remove from empty connections", function()
            local result = card1:removeConnection(card2)
            assert.is_false(result)
        end)

        it("should get all connected cards", function()
            card1:addConnection(card2, 1, 3)
            card1:addConnection(card3, 4, 2)
            local connected = card1:getConnectedCards()
            assert.are.equal(2, #connected)
            -- Check presence (order might vary)
            local found2, found3 = false, false
            for _, c in ipairs(connected) do
                if c == card2 then found2 = true end
                if c == card3 then found3 = true end
            end
            assert.is_true(found2)
            assert.is_true(found3)
        end)

        it("should get connection details for a specific target", function()
            card1:addConnection(card2, Card.Slots.BOTTOM_RIGHT, Card.Slots.TOP_LEFT)
            local target, selfSlot, targetSlot = card1:getConnectionDetails(card2)
            assert.are.same(card2, target)
            assert.are.equal(Card.Slots.BOTTOM_RIGHT, selfSlot)
            assert.are.equal(Card.Slots.TOP_LEFT, targetSlot)
            
            local nonexistent = card1:getConnectionDetails(card3)
            assert.is_nil(nonexistent)
        end)
    end)

    describe("Card:canConnectTo()", function()
        local tech_output_card -- Tech output on bottom-right (4)
        local tech_input_card  -- Tech input on top-right (2)
        local cult_output_card -- Cult output on top-left (1)
        local cult_input_card  -- Cult input on bottom-left (3)
        local closed_slot_card

        before_each(function()
            tech_output_card = Card:new({ id = "TECH_OUT", type = Card.Type.TECHNOLOGY, openSlots = { [Card.Slots.BOTTOM_RIGHT] = true } })
            tech_input_card = Card:new({ id = "TECH_IN", type = Card.Type.TECHNOLOGY, openSlots = { [Card.Slots.TOP_RIGHT] = true } })
            cult_output_card = Card:new({ id = "CULT_OUT", type = Card.Type.CULTURE, openSlots = { [Card.Slots.TOP_LEFT] = true } })
            cult_input_card = Card:new({ id = "CULT_IN", type = Card.Type.CULTURE, openSlots = { [Card.Slots.BOTTOM_LEFT] = true } })
            closed_slot_card = Card:new({ id = "CLOSED", type = Card.Type.TECHNOLOGY, openSlots = { [Card.Slots.LEFT_TOP] = true } }) -- Has no top/bottom slots open
        end)

        it("should return true for valid connection (Tech Out -> Tech In, Down)", function()
            -- tech_output_card is ABOVE tech_input_card
            local canConnect, reason = tech_output_card:canConnectTo(tech_input_card, "down")
            assert.is_true(canConnect, reason)
            assert.matches("Slot 4.+Out.+Slot 2.+In", reason)
        end)

        it("should return true for valid connection (Cult Out -> Cult In, Right)", function()
             -- cult_output_card is LEFT of cult_input_card
             -- Need to open appropriate slots for this direction
             cult_output_card.openSlots = { [Card.Slots.RIGHT_BOTTOM] = true } -- Resource Out (Doesn't matter, just need a right slot open)
             cult_output_card.type = Card.Type.RESOURCE -- Make types match
             cult_input_card.openSlots = { [Card.Slots.LEFT_BOTTOM] = true } -- Resource In
             cult_input_card.type = Card.Type.RESOURCE
             
             local canConnect, reason = cult_output_card:canConnectTo(cult_input_card, "right")
             assert.is_true(canConnect, reason)
             assert.matches("Slot 8.+Out.+Slot 6.+In", reason)
        end)

        it("should return false if target card is invalid", function()
            local canConnect, reason = tech_output_card:canConnectTo(nil, "down")
            assert.is_false(canConnect)
            assert.matches("Invalid target", reason)
        end)

        it("should return false for invalid direction", function()
            local canConnect, reason = tech_output_card:canConnectTo(tech_input_card, "diagonal")
            assert.is_false(canConnect)
            assert.matches("Invalid direction", reason)
        end)

        it("should return false if facing slots are not open", function()
            -- tech_output_card (Bottom Right open) vs closed_slot_card (Top slots closed)
            local canConnect, reason = tech_output_card:canConnectTo(closed_slot_card, "down")
            assert.is_false(canConnect)
            assert.matches("No matching open slots", reason)

            -- Swap: closed_slot_card (Bottom slots closed) vs tech_input_card (Top Right open)
            local canConnect2, reason2 = closed_slot_card:canConnectTo(tech_input_card, "down")
            assert.is_false(canConnect2)
            assert.matches("No matching open slots", reason2)
        end)

        it("should return false if slot types do not match", function()
            -- Test Tech card with Tech Output (4) facing another Tech card with Cult Input (3)
            local tech_out_card_local = Card:new({ id = "TO_L", type = Card.Type.TECHNOLOGY, openSlots = { [Card.Slots.BOTTOM_RIGHT] = true } }) -- Tech Out (4)
            local tech_in_cult_slot = Card:new({ id = "TIC_L", type = Card.Type.TECHNOLOGY, openSlots = { [Card.Slots.TOP_LEFT] = true } }) -- Cult Out (1)
            
            -- tech_out_card_local is ABOVE tech_in_cult_slot. 
            -- Facing slots: TO_L Bottom-Right (4, Tech Out) vs TIC_L Top-Left (1, Cult Out)
            -- Types mismatch (Tech vs Cult)
            local canConnect, reason = tech_out_card_local:canConnectTo(tech_in_cult_slot, "down")
            assert.is_false(canConnect)
            assert.matches("No matching open slots", reason)
        end)

        it("should return false if both slots are inputs or both are outputs", function()
            -- Tech Input vs Tech Input
            local tech_input_card_2 = Card:new({ id = "TECH_IN2", type = Card.Type.TECHNOLOGY, openSlots = { [Card.Slots.BOTTOM_LEFT] = true } }) -- Tech Input (3)
            tech_input_card.openSlots = { [Card.Slots.TOP_RIGHT] = true } -- Tech Input (2)

            local canConnect, reason = tech_input_card:canConnectTo(tech_input_card_2, "down")
            assert.is_false(canConnect, "Input->Input should fail")
            assert.matches("No matching open slots", reason)

            -- Tech Output vs Tech Output
            local tech_output_card_2 = Card:new({ id = "TECH_OUT2", type = Card.Type.TECHNOLOGY, openSlots = { [Card.Slots.TOP_LEFT] = true } }) -- Cult Output (1)
            tech_output_card.openSlots = { [Card.Slots.BOTTOM_RIGHT] = true } -- Tech Output (4)
            tech_output_card_2.type = Card.Type.TECHNOLOGY -- Make type match Tech Out
            tech_output_card_2.openSlots = { [Card.Slots.TOP_RIGHT] = true } -- Open Tech In (2) - Need an open slot on the facing edge
            -- This setup is a bit contrived, but we need a Tech card with a TOP slot open
            -- Let's fake the slot properties temporarily for the output card
            local originalGetSlotProps = tech_output_card_2.getSlotProperties
            tech_output_card_2.getSlotProperties = function(self_arg, slotIdx) 
                if slotIdx == Card.Slots.TOP_RIGHT then return { type=Card.Type.TECHNOLOGY, is_output=true } end 
                return originalGetSlotProps(self_arg, slotIdx)
            end
            
            local canConnect2, reason2 = tech_output_card:canConnectTo(tech_output_card_2, "down")
            tech_output_card_2.getSlotProperties = originalGetSlotProps -- Restore mock
            assert.is_false(canConnect2, "Output->Output should fail")
            assert.matches("No matching open slots", reason2)
        end)
    end)

end) 
