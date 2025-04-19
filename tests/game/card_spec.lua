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
            assert.is_function(card.actionEffect)
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

end) 
