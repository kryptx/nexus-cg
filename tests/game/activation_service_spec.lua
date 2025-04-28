-- tests/game/activation_service_spec.lua
-- Unit tests for the ActivationService module

local luassert = require "luassert"
local spy = require "luassert.spy"
local ActivationService = require "src.game.activation_service"
local Card = require "src.game.card"
local CardPorts = Card.Ports

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

-- Mock helpers for cards, players, and networks
local function createMockCard(id, title, x, y)
    local card = { id = id, title = title, position = { x = x, y = y }, type = "NODE",
        definedPorts = {}, occupiedPorts = {}, owner = nil, network = nil,
        activationEffect = { description = "Mock Activate", activate = function() end },
        convergenceEffect = { description = "Mock Converge", activate = function() end }
    }
    card.activateEffect = function(self, gs, activatingPlayer, targetNetwork, targetNode)
        if self.activationEffect and self.activationEffect.activate then
            return self.activationEffect.activate(gs, activatingPlayer, targetNetwork, targetNode)
        end
    end
    card.activateConvergence = function(self, gs, activatingPlayer, targetNetwork, targetNode)
        if self.convergenceEffect and self.convergenceEffect.activate then
            return self.convergenceEffect.activate(gs, activatingPlayer, targetNetwork, targetNode)
        end
    end
    card.isPortDefined = function(self, portIndex) return self.definedPorts[portIndex] == true end
    card.getOccupyingLinkId = function(self, portIndex) return self.occupiedPorts[portIndex] end
    card.isPortAvailable = function(self, portIndex)
        local isDefined = self:isPortDefined(portIndex)
        local isOccupied = self:getOccupyingLinkId(portIndex) ~= nil
        return isDefined and not isOccupied
    end
    card.getPortProperties = function(self, portIdx) return Card:getPortProperties(portIdx) end
    return card
end

local function createMockPlayer(id, resources)
    return {
        id = id,
        name = "Player " .. id,
        resources = resources or {},
        network = nil,
        spendResource = function(self, type, amount)
            self.resources[type] = (self.resources[type] or 0) - amount
        end
    }
end

local function createMockNetwork(cards)
    local net = { cards = cards or {}, cardsById = {} }
    for _, c in pairs(net.cards) do net.cardsById[c.id] = c end
    net.getCardById = function(self, id) return self.cardsById[id] end
    net.getCardAt = function(self, x, y)
        for _, c in pairs(self.cards) do
            if c.position and c.position.x == x and c.position.y == y then return c end
        end
        return nil
    end
    net.getAdjacentCoordForPort = function(self, x, y, portIndex)
        if portIndex == CardPorts.TOP_LEFT or portIndex == CardPorts.TOP_RIGHT then return { x = x, y = y - 1 } end
        if portIndex == CardPorts.BOTTOM_LEFT or portIndex == CardPorts.BOTTOM_RIGHT then return { x = x, y = y + 1 } end
        if portIndex == CardPorts.LEFT_TOP or portIndex == CardPorts.LEFT_BOTTOM then return { x = x - 1, y = y } end
        if portIndex == CardPorts.RIGHT_TOP or portIndex == CardPorts.RIGHT_BOTTOM then return { x = x + 1, y = y } end
        return nil
    end
    net.getOpposingPortIndex = function(self, portIndex)
        local opp = { [1]=3, [2]=4, [3]=1, [4]=2, [5]=7, [6]=8, [7]=5, [8]=6 }
        return opp[portIndex]
    end
    net.findReactor = function(self)
        for _, c in pairs(self.cards) do
            if c.type == Card.Type.REACTOR then
                return c
            end
        end
        return nil
    end
    return net
end

-- ==========================================
-- Tests for global activation pathfinding
-- ==========================================
describe("ActivationService:findGlobalActivationPaths", function()
    local gameService, service, p1, p2, p3, net1, net2, net3
    local p1_reactor, p1_out_node, p1_node_a, p2_in_node, p2_node_b, p3_node_c

    before_each(function()
        -- Fake GameService context
        gameService = { players = {}, activeConvergenceLinks = {} }
        service = ActivationService:new(gameService)
        -- Create mock players
        p1 = createMockPlayer(1, { energy = 20 })
        p2 = createMockPlayer(2, { energy = 10 })
        p3 = createMockPlayer(3, { energy = 10 })
        gameService.players = { p1, p2, p3 }
        -- Create reactor and node mocks
        p1_reactor = createMockCard("P1_R", "P1 Reactor", 0, 0)
        p1_reactor.type = Card.Type.REACTOR
        p1_reactor.definedPorts = { [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true }
        p1_out_node = createMockCard("P1_OUT", "P1 Out", 1, 0)
        p1_out_node.definedPorts = { [CardPorts.LEFT_TOP]=true, [CardPorts.RIGHT_BOTTOM]=true }
        p1_node_a = createMockCard("P1_A", "P1 Node A", 1, 0)
        p1_node_a.definedPorts = { [CardPorts.LEFT_TOP]=true, [CardPorts.RIGHT_TOP]=true }
        p2_in_node = createMockCard("P2_IN", "P2 In", 0, 0)
        p2_in_node.definedPorts = { [CardPorts.LEFT_BOTTOM]=true }
        p2_node_b = createMockCard("P2_B", "P2 Node B", 0, 0)
        p2_node_b.definedPorts = { [CardPorts.LEFT_TOP]=true, [CardPorts.LEFT_BOTTOM]=true }
        p3_node_c = createMockCard("P3_C", "P3 Node C", 0, 0)
        p3_node_c.definedPorts = { [CardPorts.RIGHT_BOTTOM]=true }
        -- Assign networks and owners
        net1 = createMockNetwork({ p1_reactor, p1_out_node, p1_node_a })
        p1.network = net1
        p1_reactor.owner, p1_reactor.network = p1, net1; p1_reactor.position = {x=0,y=0}
        p1_out_node.owner, p1_out_node.network = p1, net1; p1_out_node.position = {x=1,y=0}
        p1_node_a.owner, p1_node_a.network = p1, net1; p1_node_a.position = {x=1,y=0}
        net2 = createMockNetwork({ p2_in_node, p2_node_b })
        p2.network = net2
        p2_in_node.owner, p2_in_node.network = p2, net2; p2_in_node.position = {x=0,y=0}
        p2_node_b.owner, p2_node_b.network = p2, net2; p2_node_b.position = {x=0,y=0}
        net3 = createMockNetwork({ p3_node_c })
        p3.network = net3
        p3_node_c.owner, p3_node_c.network = p3, net3; p3_node_c.position = {x=0,y=0}
    end)

    it("should find a path across a single convergence link", function()
        table.insert(gameService.activeConvergenceLinks, {
            linkId = "testLink1",
            initiatingPlayerIndex = 1, initiatingNodeId = "P1_OUT",
            initiatingPortIndex = CardPorts.RIGHT_BOTTOM,
            targetPlayerIndex = 2, targetNodeId = "P2_IN",
            targetPortIndex = CardPorts.LEFT_BOTTOM,
            linkType = Card.Type.RESOURCE
        })
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p2_in_node, p1_reactor, p1)
        assert.is_true(foundAny, reason)
        assert.is_table(pathsData)
        assert.are.equal(1, #pathsData)
        local pathData = pathsData[1]
        assert.are.equal(3, pathData.cost)
        assert.is_true(pathData.isConvergenceStart)
        assert.are.same({"P2_IN","P1_OUT","P1_R"}, getPathIds(pathData))
    end)

    it("should find a path within a single network (no convergence)", function()
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p1_out_node, p1_reactor, p1)
        assert.is_true(foundAny, reason)
        assert.is_table(pathsData)
        assert.are.equal(1, #pathsData)
        local pathData = pathsData[1]
        assert.are.equal(2, pathData.cost)
        assert.is_false(pathData.isConvergenceStart)
        assert.are.same({"P1_OUT","P1_R"}, getPathIds(pathData))
    end)

    it("should not find a path if target is disconnected", function()
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p2_in_node, p1_reactor, p1)
        assert.is_false(foundAny)
        assert.is_nil(pathsData)
        assert.matches("No valid activation path", reason or "", 1, true)
    end)

    it("should find a path when target is adjacent to the reactor", function()
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p1_out_node, p1_reactor, p1)
        assert.is_true(foundAny, reason)
        assert.is_table(pathsData)
        assert.are.equal(1, #pathsData)
        local pathData = pathsData[1]
        assert.are.equal(2, pathData.cost)
        assert.is_false(pathData.isConvergenceStart)
        assert.are.same({"P1_OUT","P1_R"}, getPathIds(pathData))
    end)

    it("should not find a path if blocked by an occupied port (adjacency)", function()
        p1_out_node.occupiedPorts = { [CardPorts.LEFT_TOP] = "blocker" }
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p1_out_node, p1_reactor, p1)
        assert.is_false(foundAny)
        assert.is_nil(pathsData)
        p1_out_node.occupiedPorts = {}
    end)

    it("should not find a path if blocked by an occupied port (convergence)", function()
        table.insert(gameService.activeConvergenceLinks, {
            linkId = "testLink1", initiatingPlayerIndex = 1, initiatingNodeId = "P1_OUT",
            initiatingPortIndex = CardPorts.RIGHT_BOTTOM, targetPlayerIndex = 2, targetNodeId = "P2_IN",
            targetPortIndex = CardPorts.LEFT_BOTTOM, linkType = Card.Type.RESOURCE
        })
        p2_in_node.occupiedPorts = { [CardPorts.LEFT_BOTTOM] = "blocker" }
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p2_in_node, p1_reactor, p1)
        assert.is_false(foundAny)
        assert.is_nil(pathsData)
        p2_in_node.occupiedPorts = {}
    end)

    it("should find a path involving multiple convergence links", function()
        table.insert(gameService.activeConvergenceLinks, {
            linkId = "link_P2B_P1A", initiatingPlayerIndex = 2, initiatingNodeId = "P2_B",
            initiatingPortIndex = CardPorts.LEFT_TOP, targetPlayerIndex = 1, targetNodeId = "P1_A",
            targetPortIndex = CardPorts.RIGHT_TOP, linkType = Card.Type.KNOWLEDGE
        })
        table.insert(gameService.activeConvergenceLinks, {
            linkId = "link_P3C_P2B", initiatingPlayerIndex = 3, initiatingNodeId = "P3_C",
            initiatingPortIndex = CardPorts.RIGHT_BOTTOM, targetPlayerIndex = 2, targetNodeId = "P2_B",
            targetPortIndex = CardPorts.LEFT_BOTTOM, linkType = Card.Type.RESOURCE
        })
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p3_node_c, p1_reactor, p1)
        assert.is_true(foundAny, reason)
        assert.is_table(pathsData)
        assert.are.equal(1, #pathsData)
        local pathData = pathsData[1]
        assert.are.equal(4, pathData.cost)
        assert.is_true(pathData.isConvergenceStart)
        assert.are.same({"P3_C","P2_B","P1_A","P1_R"}, getPathIds(pathData))
        -- Check owners
        assert.are.same(p3, pathData.path[1].owner)
        assert.are.same(p2, pathData.path[2].owner)
        assert.are.same(p1, pathData.path[3].owner)
        assert.are.same(p1, pathData.path[4].owner)
    end)

    it("should find specific path from P2_IC to P1_ST via knowledge link", function()
        -- Setup additional mocks for this scenario
        local p1_st = createMockCard("P1_ST", "Seed Thought", 1, 0)
        p1_st.definedPorts = {
            [CardPorts.LEFT_TOP] = true, [CardPorts.LEFT_BOTTOM] = true,
            [CardPorts.TOP_LEFT] = true, [CardPorts.BOTTOM_LEFT] = true,
            [CardPorts.RIGHT_TOP] = true
        }
        local p2_ic = createMockCard("P2_IC", "Initial Circuit", 0, -1)
        p2_ic.definedPorts = {
            [CardPorts.BOTTOM_LEFT] = true, [CardPorts.BOTTOM_RIGHT] = true,
            [CardPorts.TOP_LEFT] = true, [CardPorts.LEFT_TOP] = true,
            [CardPorts.RIGHT_BOTTOM] = true
        }
        -- Add to networks
        net1.cards["P1_ST"] = p1_st; net1.cardsById["P1_ST"] = p1_st
        p1_st.owner, p1_st.network = p1, net1
        net2.cards["P2_IC"] = p2_ic; net2.cardsById["P2_IC"] = p2_ic
        p2_ic.owner, p2_ic.network = p2, net2
        -- Assign port methods
        for _, c in ipairs({p1_st, p2_ic}) do
            c.isPortDefined = function(self, i) return self.definedPorts[i] end
            c.getOccupyingLinkId = function(self, i) return self.occupiedPorts and self.occupiedPorts[i] end
            c.isPortAvailable = function(self, i) return self.definedPorts[i] and not (self.occupiedPorts and self.occupiedPorts[i]) end
            c.getPortProperties = function(self, i) return Card:getPortProperties(i) end
        end
        -- Add convergence link
        table.insert(gameService.activeConvergenceLinks, {
            linkId = "link_P2IC_P1ST", initiatingPlayerIndex = 2, initiatingNodeId = "P2_IC",
            initiatingPortIndex = CardPorts.LEFT_TOP, targetPlayerIndex = 1, targetNodeId = "P1_ST",
            targetPortIndex = CardPorts.RIGHT_TOP, linkType = Card.Type.KNOWLEDGE
        })
        local foundAny, pathsData, reason = service:findGlobalActivationPaths(p2_ic, p1_reactor, p1)
        assert.is_true(foundAny, reason)
        assert.is_table(pathsData)
        assert.are.equal(1, #pathsData)
        local pathData = pathsData[1]
        assert.are.equal(3, pathData.cost)
        assert.is_true(pathData.isConvergenceStart)
        assert.are.same({"P2_IC","P1_ST","P1_R"}, getPathIds(pathData))
        -- Owners check
        assert.are.same(p2, pathData.path[1].owner)
        assert.are.same(p1, pathData.path[2].owner)
        assert.are.same(p1, pathData.path[3].owner)
    end)
end)
