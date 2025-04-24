-- src/game/activation_service.lua
-- Extracted service for handling card activation (local and global) and pathfinding logic

local Card = require('src.game.card') -- Needed for checking types

-- Helper function for BFS path tracking (shallow copy)
local function shallow_copy(original)
    if type(original) ~= 'table' then return original end
    local copy = {}
    for k, v in ipairs(original) do copy[k] = v end
    for k, v in pairs(original) do
        if type(k) ~= 'number' or k < 1 or k > #original then copy[k] = v end
    end
    return copy
end

local ActivationService = {}
ActivationService.__index = ActivationService

-- gameService: reference to GameService for state, rules, audio, links
function ActivationService:new(gameService)
    local instance = setmetatable({}, ActivationService)
    instance.gameService = gameService
    instance.pausedActivationPath = nil      -- Remaining path nodes after a pause
    instance.pausedActivationContext = nil   -- { activatingPlayer, isConvergenceStart }
    instance.currentActivationChainCards = {}
    instance.currentActivationChainLinks = {}
    return instance
end

-- Find Activation Path (Global BFS)
-- Searches across networks using adjacency and convergence links.
-- Returns: boolean (isValid), pathData { path={ {card=Card, owner=Player}, ... }, cost=int, isConvergenceStart=bool }, reason (string)
function ActivationService:findGlobalActivationPath(targetCard, activatorReactor, activatingPlayer)
    local gs = self.gameService
    print(string.format("[Pathfinder] START: Target=%s (%s, P%d), Reactor=%s (%s, P%d), Activator=P%d",
        targetCard and targetCard.title or "NIL",
        targetCard and targetCard.id or "NIL",
        targetCard and targetCard.owner and targetCard.owner.id or -1,
        activatorReactor and activatorReactor.title or "NIL",
        activatorReactor and activatorReactor.id or "NIL",
        activatorReactor and activatorReactor.owner and activatorReactor.owner.id or -1,
        activatingPlayer and activatingPlayer.id or -1
    ))

    if not targetCard or not activatorReactor or not activatingPlayer then
        print("[Pathfinder] FAIL: Invalid arguments.")
        return false, nil, "Invalid arguments to findGlobalActivationPath"
    end

    local queue = {}
    local visited = {} -- Track visited card INSTANCES to prevent cycles

    local startOwner = targetCard.owner
    if not startOwner then
        print(string.format("[Pathfinder] FAIL: Target card %s has no owner!", targetCard.id))
        return false, nil, string.format("Target card %s has no owner!", targetCard.id)
    end
    -- Path elements now include traversedLinkType
    local initialPath = { { card = targetCard, owner = startOwner, traversedLinkType = nil } }
    table.insert(queue, { node = targetCard, owner = startOwner, path = initialPath })

    -- Use composite key for visited set: playerID_cardID
    local startVisitedKey = startOwner.id .. "_" .. targetCard.id
    visited[startVisitedKey] = true 
    print(string.format("[Pathfinder] Initial Queue: Target %s (P%d). Visited Key: %s", targetCard.id, startOwner.id, startVisitedKey))

    while #queue > 0 do
        local currentState = table.remove(queue, 1)
        local currentNode = currentState.node
        local currentOwner = currentState.owner
        local currentPath = currentState.path
        local currentVisitedKey = currentOwner.id .. "_" .. currentNode.id
        print(string.format("[Pathfinder] Dequeue: Current=%s (P%d), PathLen=%d, VisitedKey=%s", currentNode.id, currentOwner.id, #currentPath, currentVisitedKey))

        if currentNode == activatorReactor then
            local isConvergenceStart = false
            if #currentPath > 1 then
                isConvergenceStart = currentPath[1].owner ~= currentPath[2].owner
            end

            local activationPath = shallow_copy(currentPath)

            local pathData = {
                path = activationPath,
                cost = #activationPath, 
                isConvergenceStart = isConvergenceStart
            }
            print(string.format("[Pathfinder] SUCCESS: Reached Reactor %s. Path Cost=%d, ConvStart=%s", activatorReactor.id, pathData.cost, tostring(isConvergenceStart)))
            return true, pathData, nil
        end

        -- Explore Neighbors (Adjacency within the same network)
        print(string.format("  [Pathfinder Adjacency] Exploring neighbors of %s (P%d)...", currentNode.id, currentOwner.id))
        for portIndex = 1, 8 do
            local portProps = currentNode:getPortProperties(portIndex)
            if portProps and portProps.is_output and currentNode:isPortAvailable(portIndex) then
                local adjacentPos = currentNode.network:getAdjacentCoordForPort(currentNode.position.x, currentNode.position.y, portIndex)
                if adjacentPos then
                    local neighborNode = currentOwner.network:getCardAt(adjacentPos.x, adjacentPos.y)
                    local neighborVisitedKey = neighborNode and (currentOwner.id .. "_" .. neighborNode.id) or nil
                    if neighborNode and not visited[neighborVisitedKey] then 
                        local neighborPortIndex = currentNode.network:getOpposingPortIndex(portIndex)
                        local neighborProps = neighborNode:getPortProperties(neighborPortIndex)
                        if neighborProps and not neighborProps.is_output and neighborNode:isPortAvailable(neighborPortIndex) and neighborProps.type == portProps.type then
                            visited[neighborVisitedKey] = true
                            local newPath = shallow_copy(currentPath)
                            table.insert(newPath, { card = neighborNode, owner = currentOwner, traversedLinkType = nil })
                            print(string.format("      >> Enqueueing ADJACENT: %s (P%d)", neighborNode.id, currentOwner.id))
                            table.insert(queue, { node = neighborNode, owner = currentOwner, path = newPath })
                        end
                    end
                end
            end
        end

        -- Explore Neighbors (Convergence Links)
        print(string.format("  [Pathfinder Convergence] Exploring links for %s (P%d)...", currentNode.id, currentOwner.id))
        for _, link in ipairs(gs.activeConvergenceLinks) do
            local neighborNode, neighborOwner, neighborNodeId, neighborPlayerIndex, neighborPortIndex, currentPortIndex
            if link.initiatingNodeId == currentNode.id and link.initiatingPlayerIndex == currentOwner.id then
                neighborNodeId, neighborPlayerIndex = link.targetNodeId, link.targetPlayerIndex
                neighborPortIndex, currentPortIndex = link.targetPortIndex, link.initiatingPortIndex
            elseif link.targetNodeId == currentNode.id and link.targetPlayerIndex == currentOwner.id then
                neighborNodeId, neighborPlayerIndex = link.initiatingNodeId, link.initiatingPlayerIndex
                neighborPortIndex, currentPortIndex = link.initiatingPortIndex, link.targetPortIndex
            end
            if neighborNodeId and neighborPlayerIndex then
                neighborOwner = gs.players[neighborPlayerIndex]
                neighborNode = neighborOwner and neighborOwner.network:getCardById(neighborNodeId) or nil
            end
            local neighborVisitedKeyConv = neighborNode and (neighborOwner.id .. "_" .. neighborNode.id) or nil
            if neighborNode and not visited[neighborVisitedKeyConv] then
                local outputNode, inputNode, outputPortIdx, inputPortIdx
                if link.initiatingNodeId == currentNode.id then
                    outputNode, inputNode = currentNode, neighborNode
                    outputPortIdx, inputPortIdx = currentPortIndex, neighborPortIndex
                else
                    outputNode, inputNode = neighborNode, currentNode
                    outputPortIdx, inputPortIdx = neighborPortIndex, currentPortIndex
                end
                local oProps, iProps = outputNode:getPortProperties(outputPortIdx), inputNode:getPortProperties(inputPortIdx)
                if oProps and oProps.is_output and iProps and not iProps.is_output and
                   (outputNode:getOccupyingLinkId(outputPortIdx) == nil or outputNode:getOccupyingLinkId(outputPortIdx) == link.linkId) and
                   (inputNode:getOccupyingLinkId(inputPortIdx) == nil or inputNode:getOccupyingLinkId(inputPortIdx) == link.linkId) and
                   oProps.type == iProps.type then
                    visited[neighborVisitedKeyConv] = true
                    local newPath = shallow_copy(currentPath)
                    table.insert(newPath, { card = neighborNode, owner = neighborOwner, traversedLinkType = link.linkType })
                    print(string.format("      >> Enqueueing CONVERGENCE: %s (P%d) via Link %s (%s)", neighborNode.id, neighborOwner.id, link.linkId, link.linkType))
                    table.insert(queue, { node = neighborNode, owner = neighborOwner, path = newPath })
                end
            end
        end
    end

    print("[Pathfinder] FAIL: Queue empty, Reactor not found.")
    return false, nil, "No valid activation path exists to the activator's reactor."
end

-- Update attemptActivationGlobal to use internal pathfinder
function ActivationService:attemptActivationGlobal(activatingPlayerIndex, targetPlayerIndex, targetGridX, targetGridY)
    local gs = self.gameService
    -- Phase and input checks remain in GameService

    local activatingPlayer = gs.players[activatingPlayerIndex]
    local targetPlayer = gs.players[targetPlayerIndex]
    if not activatingPlayer or not targetPlayer then return false, "Invalid player index provided." end

    local targetCard = targetPlayer.network:getCardAt(targetGridX, targetGridY)
    if not targetCard then return false, "No card at target location." end
    if targetCard.type == Card.Type.REACTOR then
        return false, "Cannot activate the Reactor itself."
    end

    local activatorReactor = activatingPlayer.network:findReactor()
    if not activatorReactor then return false, "Error: Activating player's reactor not found." end

    local isValid, pathData, reason
    -- Allow overrides via GameService for testing if defined, else use internal pathfinder
    if gs.findGlobalActivationPath then
        isValid, pathData, reason = gs:findGlobalActivationPath(targetCard, activatorReactor, activatingPlayer)
    else
        isValid, pathData, reason = self:findGlobalActivationPath(targetCard, activatorReactor, activatingPlayer)
    end
    local path, cost, isConvStart
    if isValid and pathData then
        path = pathData.path; cost = pathData.cost - 1; isConvStart = pathData.isConvergenceStart
    else
        return false, string.format("No valid global activation path: %s", reason or "Unknown reason")
    end

    if activatingPlayer.resources.energy < cost then
        return false, string.format("Not enough energy. Cost: %d E (Have: %d E)", cost, activatingPlayer.resources.energy)
    end

    -- Deduct energy and play sound
    activatingPlayer:spendResource('energy', cost)
    gs.audioManager:playSound('activation')

    local messages = { string.format("Activated global path (Cost %d E):", cost) }
    -- Process the path (handles pausing if needed)
    local status, msg = self:_processActivationPath(path, activatingPlayer, isConvStart, messages)
    return status, msg
end

-- Internal helper to process a path, potentially pausing for input
function ActivationService:_processActivationPath(path, activatingPlayer, isConvergenceStart, activationMessages)
    local gs = self.gameService
    for i, elem in ipairs(path) do
        local cardNode, owner = elem.card, elem.owner
        if cardNode.type == Card.Type.REACTOR then goto continue end

        table.insert(self.currentActivationChainCards, cardNode.type)
        if elem.traversedLinkType then
            table.insert(self.currentActivationChainLinks, elem.traversedLinkType)
        end

        local effectType, status = 'standard', nil
        if i == 1 and isConvergenceStart or owner ~= activatingPlayer then
            effectType = 'convergence'
            status = cardNode:activateConvergence(gs, activatingPlayer, owner.network, cardNode)
        else
            status = cardNode:activateEffect(gs, activatingPlayer, owner.network, cardNode)
        end
        table.insert(activationMessages, string.format("  - %s activated (%s)!", cardNode.title, effectType))

        if status == 'waiting' then
            -- Pause remaining
            local remaining = {}
            for j = i+1, #path do table.insert(remaining, path[j]) end
            if #remaining > 0 then
                self.pausedActivationPath = remaining
                self.pausedActivationContext = { activatingPlayer = activatingPlayer, isConvergenceStart = isConvergenceStart }
            end
            return true, table.concat(activationMessages, '\n') .. '\nActivation paused, waiting for input...'
        end
        ::continue::
    end

    -- Completed
    self.pausedActivationPath = nil; self.pausedActivationContext = nil
    return true, table.concat(activationMessages, '\n')
end

-- Resume a paused activation
function ActivationService:resumeActivation()
    if not self.pausedActivationPath or not self.pausedActivationContext then
        return false, "No paused activation found."
    end
    local path = self.pausedActivationPath
    local ctx = self.pausedActivationContext
    -- Clear before resume
    self.pausedActivationPath = nil; self.pausedActivationContext = nil

    local messages = {"[Resumed Activation]"}
    local status, msg = self:_processActivationPath(path, ctx.activatingPlayer, ctx.isConvergenceStart, messages)
    return status, msg
end

-- Get info about current activation chain
function ActivationService:getActivationChainInfo()
    return { length = #self.currentActivationChainCards,
             cards = self.currentActivationChainCards,
             links = self.currentActivationChainLinks }
end

return ActivationService 
