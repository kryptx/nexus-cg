-- tests/game/player_spec.lua
-- Unit tests for the Player module

local Player = require 'src.game.player'
local Card = require 'src.game.card' -- Need for Card.Type constants and creating mock cards

describe("Player Module", function()
    local player
    local player_id = 1
    local player_name = "Test Player"

    before_each(function()
        -- Create a fresh player instance for each test
        player = Player:new({ id = player_id, name = player_name })
    end)

    describe("Player:new()", function()
        it("should create a player instance with correct ID and name", function()
            assert.is_table(player)
            assert.are.equal(player_id, player.id)
            assert.are.equal(player_name, player.name)
        end)

        it("should default name if not provided", function()
            local player_no_name = Player:new({ id = 99 })
            assert.are.equal("Player 99", player_no_name.name)
        end)

        it("should initialize resources to zero", function()
            assert.are.equal(0, player.resources.energy)
            assert.are.equal(0, player.resources.data)
            assert.are.equal(0, player.resources.material)
        end)

        it("should initialize VP to zero", function()
            assert.are.equal(0, player.vp)
        end)

        it("should initialize an empty hand", function()
            assert.is_table(player.hand)
            assert.is_nil(next(player.hand))
        end)

        it("should initialize network to nil", function()
            assert.is_nil(player.network)
        end)

        it("should initialize available convergence links", function()
            assert.is_table(player.usedConvergenceLinkSets)
            assert.are.equal(false, player.usedConvergenceLinkSets[Card.Type.TECHNOLOGY])
            assert.are.equal(false, player.usedConvergenceLinkSets[Card.Type.CULTURE])
            assert.are.equal(false, player.usedConvergenceLinkSets[Card.Type.RESOURCE])
            assert.are.equal(false, player.usedConvergenceLinkSets[Card.Type.KNOWLEDGE])
            assert.are.equal(0, player.initiatedLinksCount)
        end)

        it("should error if ID is missing", function()
            assert.error(function() Player:new({ name = "No ID" }) end)
        end)
    end)

    describe("Resource Management", function()
        it("addResource should increase the correct resource", function()
            player:addResource('energy', 5)
            assert.are.equal(5, player.resources.energy)
            player:addResource('energy', 3)
            assert.are.equal(8, player.resources.energy)
            player:addResource('data', 2)
            assert.are.equal(2, player.resources.data)
            assert.are.equal(0, player.resources.material)
        end)

        it("addResource should ignore unknown resource types", function()
            -- Current implementation prints a warning, doesn't error
            player:addResource('food', 10)
            -- No easy way to check for print output in Busted by default
            -- We just ensure other resources weren't affected
            assert.are.equal(0, player.resources.energy)
            assert.are.equal(0, player.resources.data)
            assert.are.equal(0, player.resources.material)
        end)

        it("spendResource should decrease the correct resource and return true if sufficient", function()
            player:addResource('material', 10)
            local success = player:spendResource('material', 4)
            assert.is_true(success)
            assert.are.equal(6, player.resources.material)
        end)

        it("spendResource should not change resource and return false if insufficient", function()
            player:addResource('material', 3)
            local success = player:spendResource('material', 4)
            assert.is_false(success)
            assert.are.equal(3, player.resources.material)
        end)

        it("spendResource should return false for unknown resource types", function()
            local success = player:spendResource('food', 1)
            assert.is_false(success)
        end)
    end)

    describe("Hand Management", function()
        local mockCard1, mockCard2

        before_each(function()
            -- Create mock card instances (need minimal valid structure)
            mockCard1 = Card:new({ id = "MC_001", type = Card.Type.KNOWLEDGE, title = "Mock Card 1" })
            mockCard2 = Card:new({ id = "MC_002", type = Card.Type.RESOURCE, title = "Mock Card 2" })
        end)

        it("addCardToHand should add a valid card instance to the hand", function()
            assert.is_nil(next(player.hand))
            player:addCardToHand(mockCard1)
            assert.are.equal(1, #player.hand)
            assert.are.same(mockCard1, player.hand[1])

            player:addCardToHand(mockCard2)
            assert.are.equal(2, #player.hand)
            assert.are.same(mockCard2, player.hand[2])
        end)

        it("addCardToHand should set the card's owner", function()
            player:addCardToHand(mockCard1)
            assert.are.same(player, mockCard1.owner)
        end)

        it("addCardToHand should error if adding non-card object", function()
            assert.error(function() player:addCardToHand({ title = "Not a Card" }) end)
            assert.error(function() player:addCardToHand(nil) end)
            assert.error(function() player:addCardToHand(123) end)
        end)
    end)

end) 
