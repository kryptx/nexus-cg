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
-- Returns: boolean (foundAny), list<pathData> | nil, reason | nil
-- pathData = { path={ {card=Card, owner=Player, traversedLinkType=string|nil}, ... }, cost=int, isConvergenceStart=bool }
function ActivationService:findGlobalActivationPaths(targetCard, activatorReactor, activatingPlayer)
    local gs = self.gameService
    print(string.format("[Pathfinder] START (Find All Shortest): Target=%s (%s, P%d), Reactor=%s (%s, P%d), Activator=P%d",
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
        return false, nil, "Invalid arguments to findGlobalActivationPaths"
    end

    local queue = {}
    local visitedCost = {} -- Track visited card INSTANCES and the minimum cost to reach them { [playerID_cardID] = cost }
    local shortestPaths = {}
    local minCostFound = math.huge

    local startOwner = targetCard.owner
    if not startOwner then
        print(string.format("[Pathfinder] FAIL: Target card %s has no owner!", targetCard.id))
        return false, nil, string.format("Target card %s has no owner!", targetCard.id)
    end

    local initialPath = { { card = targetCard, owner = startOwner, traversedLinkType = nil } }
    table.insert(queue, { node = targetCard, owner = startOwner, path = initialPath })

    local startVisitedKey = startOwner.id .. "_" .. targetCard.id
    visitedCost[startVisitedKey] = 1 -- Cost is path length (1 initially)
    print(string.format("[Pathfinder] Initial Queue: Target %s (P%d). Visited Key: %s, Initial Cost: 1", targetCard.id, startOwner.id, startVisitedKey))

    while #queue > 0 do
        local currentState = table.remove(queue, 1)
        local currentNode = currentState.node
        local currentOwner = currentState.owner
        local currentPath = currentState.path
        local currentCost = #currentPath
        local currentVisitedKey = currentOwner.id .. "_" .. currentNode.id
        print(string.format("[Pathfinder] Dequeue: Current=%s (P%d), PathLen=%d, VisitedKey=%s", currentNode.id, currentOwner.id, currentCost, currentVisitedKey))

        -- Pruning: If we've already found shorter paths, or this path is longer than the min cost to reach this node, skip
        if currentCost > minCostFound or currentCost > (visitedCost[currentVisitedKey] or math.huge) then
            print(string.format("  >> Pruning path: CurrentCost (%d) > minCostFound (%d) or visitedCost[%s] (%d)", currentCost, minCostFound, currentVisitedKey, visitedCost[currentVisitedKey] or -1))
            goto continue -- Use goto to skip to the end of the loop iteration
        end

        if currentNode == activatorReactor then
            print(string.format("[Pathfinder] Reached Reactor %s. Path Cost=%d.", activatorReactor.id, currentCost))
            if currentCost < minCostFound then
                print(string.format("  >> New shortest path found! Old minCost=%f, New minCost=%f. Resetting paths.", minCostFound, currentCost))
                minCostFound = currentCost
                shortestPaths = {} -- Reset shortest paths
            end
            -- Only add if it matches the current minimum cost
            if currentCost == minCostFound then
                local isConvergenceStart = false
                if #currentPath > 1 then
                    isConvergenceStart = currentPath[1].owner ~= currentPath[2].owner
                end
                local activationPath = shallow_copy(currentPath)
                local pathData = {
                    path = activationPath,
                    cost = currentCost, -- Use actual path length
                    isConvergenceStart = isConvergenceStart
                }
                print(string.format("  >> Storing shortest path. Total shortest paths now: %d", #shortestPaths + 1))
                table.insert(shortestPaths, pathData)
            end
            -- Continue searching for other paths of the same length
            goto continue -- Don't explore neighbors from the reactor
        end

        -- Explore Neighbors (Adjacency within the same network)
        print(string.format("  [Pathfinder Adjacency] Exploring neighbors of %s (P%d)...", currentNode.id, currentOwner.id))
        for portIndex = 1, 8 do
            local portProps = currentNode:getPortProperties(portIndex)
            if portProps and portProps.is_output and currentNode:isPortAvailable(portIndex) then
                local adjacentPos = currentNode.network:getAdjacentCoordForPort(currentNode.position.x, currentNode.position.y, portIndex)
                if adjacentPos then
                    local neighborNode = currentOwner.network:getCardAt(adjacentPos.x, adjacentPos.y)
                    if neighborNode then
                        local neighborVisitedKey = currentOwner.id .. "_" .. neighborNode.id
                        local neighborCost = currentCost + 1
                        -- Check cost before checking port properties for efficiency
                        if neighborCost <= (visitedCost[neighborVisitedKey] or math.huge) and neighborCost <= minCostFound then
                           local neighborPortIndex = currentNode.network:getOpposingPortIndex(portIndex)
                           local neighborProps = neighborNode:getPortProperties(neighborPortIndex)
                           if neighborProps and not neighborProps.is_output and neighborNode:isPortAvailable(neighborPortIndex) and neighborProps.type == portProps.type then
                               visitedCost[neighborVisitedKey] = neighborCost -- Update cost if lower or equal
                               local newPath = shallow_copy(currentPath)
                               table.insert(newPath, { card = neighborNode, owner = currentOwner, traversedLinkType = nil })
                               print(string.format("      >> Enqueueing ADJACENT: %s (P%d) at cost %f", neighborNode.id, currentOwner.id, neighborCost))
                               table.insert(queue, { node = neighborNode, owner = currentOwner, path = newPath })
                            else
                               print(string.format("      >> FAILED ADJACENCY CHECK #3: Neighbor %s (P%d) Port %d. Props=%s, IsOutput=%s, Available=%s, TypeMatch=%s",
                                    neighborNode.id, currentOwner.id, neighborPortIndex,
                                    tostring(neighborProps),
                                    neighborProps and tostring(neighborProps.is_output),
                                    neighborNode:isPortAvailable(neighborPortIndex),
                                    neighborProps and portProps and tostring(neighborProps.type == portProps.type)))
                           end
                        else
                            print(string.format("      >> SKIPPING ADJACENT (Cost Check): Neighbor %s (P%d). neighborCost (%d) vs visitedCost (%d) or minCostFound (%d)",
                                neighborNode.id, currentOwner.id, neighborCost, visitedCost[neighborVisitedKey] or -1, minCostFound))
                        end
                    else
                        print(string.format("      >> FAILED ADJACENCY CHECK #2: No neighbor node @(%s,%s)",
                            tostring(adjacentPos and adjacentPos.x), tostring(adjacentPos and adjacentPos.y)))
                    end
                else
                    print(string.format("      >> FAILED ADJACENCY CHECK #1b: adjacentPos is nil for Port %d", portIndex))
                end
            else
               if portProps then print(string.format("      >> SKIPPING Port %d: IsOutput=%s, Available=%s", portIndex, tostring(portProps.is_output), currentNode:isPortAvailable(portIndex))) end
            end
        end -- end for portIndex

        -- Explore Neighbors (Convergence Links)
        print(string.format("  [Pathfinder Convergence] Exploring links for %s (P%d)...", currentNode.id, currentOwner.id))
        for _, link in ipairs(gs.activeConvergenceLinks) do
            local neighborNode, neighborOwner, neighborNodeId, neighborPlayerIndex, neighborPortIndex, currentPortIndex
            local isInitiator = false -- Track if the current node is the link initiator
            if link.initiatingNodeId == currentNode.id and link.initiatingPlayerIndex == currentOwner.id then
                neighborNodeId, neighborPlayerIndex = link.targetNodeId, link.targetPlayerIndex
                neighborPortIndex, currentPortIndex = link.targetPortIndex, link.initiatingPortIndex
                isInitiator = true
            elseif link.targetNodeId == currentNode.id and link.targetPlayerIndex == currentOwner.id then
                neighborNodeId, neighborPlayerIndex = link.initiatingNodeId, link.initiatingPlayerIndex
                neighborPortIndex, currentPortIndex = link.initiatingPortIndex, link.targetPortIndex
                isInitiator = false
            end

            if neighborNodeId and neighborPlayerIndex then
                neighborOwner = gs.players[neighborPlayerIndex]
                neighborNode = neighborOwner and neighborOwner.network:getCardById(neighborNodeId) or nil
                if neighborNode then
                    local neighborVisitedKeyConv = neighborOwner.id .. "_" .. neighborNode.id
                    local neighborCost = currentCost + 1
                    if neighborCost <= (visitedCost[neighborVisitedKeyConv] or math.huge) and neighborCost <= minCostFound then
                        local outputNode, inputNode, outputPortIdx, inputPortIdx
                        if isInitiator then
                            outputNode, inputNode = currentNode, neighborNode
                            outputPortIdx, inputPortIdx = currentPortIndex, neighborPortIndex
                        else
                            outputNode, inputNode = neighborNode, currentNode
                            outputPortIdx, inputPortIdx = neighborPortIndex, currentPortIndex
                        end
                        local oProps, iProps = outputNode:getPortProperties(outputPortIdx), inputNode:getPortProperties(inputPortIdx)
                        -- Check link validity (port types, availability/occupation)
                        if oProps and oProps.is_output and iProps and not iProps.is_output and
                           (outputNode:getOccupyingLinkId(outputPortIdx) == nil or outputNode:getOccupyingLinkId(outputPortIdx) == link.linkId) and
                           (inputNode:getOccupyingLinkId(inputPortIdx) == nil or inputNode:getOccupyingLinkId(inputPortIdx) == link.linkId) and
                           oProps.type == iProps.type then
                            visitedCost[neighborVisitedKeyConv] = neighborCost -- Update cost
                            local newPath = shallow_copy(currentPath)
                            table.insert(newPath, { card = neighborNode, owner = neighborOwner, traversedLinkType = link.linkType })
                            print(string.format("      >> Enqueueing CONVERGENCE: %s (P%d) via Link %s (%s) at cost %f", neighborNode.id, neighborOwner.id, link.linkId, link.linkType, neighborCost))
                            table.insert(queue, { node = neighborNode, owner = neighborOwner, path = newPath })
                        else
                            print(string.format("      >> FAILED CONVERGENCE CHECK #3: Link %s. oProps=%s, iProps=%s, oOcc=%s, iOcc=%s, TypeMatch=%s",
                                link.linkId, tostring(oProps), tostring(iProps),
                                tostring(outputNode:getOccupyingLinkId(outputPortIdx)),
                                tostring(inputNode:getOccupyingLinkId(inputPortIdx)),
                                oProps and iProps and tostring(oProps.type == iProps.type)))
                        end
                    else
                         print(string.format("      >> SKIPPING CONVERGENCE (Cost Check): Neighbor %s (P%d). neighborCost (%d) vs visitedCost (%d) or minCostFound (%s)",
                                neighborNode.id, neighborOwner.id, neighborCost, visitedCost[neighborVisitedKeyConv] or -1, minCostFound))
                    end
                else
                    print(string.format("      >> FAILED CONVERGENCE CHECK #2: Could not find neighbor node %s for P%d", neighborNodeId, neighborPlayerIndex))
                end
            end -- End if neighborNodeId and neighborPlayerIndex
        end -- End for link in links

        ::continue:: -- Label for goto, used for skipping exploration from pruned paths or reactor
    end

    if #shortestPaths > 0 then
        print(string.format("[Pathfinder] SUCCESS: Found %d shortest path(s) with cost %d.", #shortestPaths, minCostFound))
        return true, shortestPaths, nil
    else
        print("[Pathfinder] FAIL: Queue empty or no paths reached reactor within cost limits.")
        return false, nil, "No valid activation path exists to the activator's reactor."
    end
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

    local foundAny, shortestPathsData, reason
    -- Allow overrides via GameService for testing if defined, else use internal pathfinder
    -- TODO: Update external calls if gs.findGlobalActivationPath is used for testing override
    if gs.findGlobalActivationPaths then -- Check for potentially overridden function
        foundAny, shortestPathsData, reason = gs:findGlobalActivationPaths(targetCard, activatorReactor, activatingPlayer)
    else
        foundAny, shortestPathsData, reason = self:findGlobalActivationPaths(targetCard, activatorReactor, activatingPlayer)
    end

    local path, cost, isConvStart
    if foundAny and shortestPathsData and #shortestPathsData > 0 then
        -- TODO: Implement choice mechanism here. For now, just take the first path.
        local firstPathData = shortestPathsData[1]
        path = firstPathData.path
        cost = firstPathData.cost - 1 -- Activation cost is path length - 1
        isConvStart = firstPathData.isConvergenceStart
        print(string.format("[Activation] Using first of %d shortest paths found. Cost: %d", #shortestPathsData, cost))
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
    -- We need to return the list of nodes { card=..., owner=... } as well for the new effect
    local nodesInChain = {}
    if self.currentActivationChainPath then -- Use the full path if stored
        for _, pathElement in ipairs(self.currentActivationChainPath) do
            -- Ensure we don't add the reactor
            if pathElement.card and pathElement.card.type ~= Card.Type.REACTOR then
                table.insert(nodesInChain, { card = pathElement.card, owner = pathElement.owner })
            end
        end
    else
        -- Fallback or warning if full path isn't stored (this might need adjustment depending on where path info is finalized)
        print("Warning: ActivationService:getActivationChainInfo called but currentActivationChainPath is not set.")
    end
    
    return { 
        length = #self.currentActivationChainCards,
        cards = self.currentActivationChainCards, -- List of card types
        links = self.currentActivationChainLinks, -- List of link types traversed
        nodes = nodesInChain -- List of {card=..., owner=...} excluding reactor
    }
end

-- Internal helper to process a path, potentially pausing for input
function ActivationService:_processActivationPath(path, activatingPlayer, isConvergenceStart, activationMessages)
    local gs = self.gameService
    self.currentActivationChainPath = path -- Store the full path being processed
    
    for i, elem in ipairs(path) do
        local cardNode, owner = elem.card, elem.owner
        if cardNode.type == Card.Type.REACTOR then goto continue end

        table.insert(self.currentActivationChainCards, cardNode.type)
        if elem.traversedLinkType then
            table.insert(self.currentActivationChainLinks, elem.traversedLinkType)
        end

        local effectType, status = 'standard', nil
        -- Determine if it's a convergence effect based on ownership OR if it's the start of a convergence path
        if owner ~= activatingPlayer or (i == 1 and isConvergenceStart) then
            effectType = 'convergence'
            -- Pass activatingPlayer, sourceNetwork (owner's), sourceNode (card's), and initiatingNode (from path? TBD)
            -- The 4th arg to activateConvergence is initiatingNode - we might need this in the path elem
            -- For now, passing nil as the initiating node, might need refinement based on effect needs
            status = cardNode:activateConvergence(gs, activatingPlayer, nil)
        else
            effectType = 'standard'
            -- Pass activatingPlayer, sourceNetwork (owner's), sourceNode (card's), and targetNode (original target?)
            -- The 4th arg to activateEffect is originalTargetNode - how do we get this here? Maybe pass only needed context?
            -- Sticking to original call signature for now, might need update:
            status = cardNode:activateEffect(gs, activatingPlayer, cardNode.owner.network, cardNode) 
        end
        table.insert(activationMessages, string.format("  - %s activated (%s)!", cardNode.title, effectType))

        if status == 'waiting' then
            -- Pause remaining path
            local remaining = {}
            for j = i+1, #path do table.insert(remaining, path[j]) end
            if #remaining > 0 then
                self.pausedActivationPath = remaining
                self.pausedActivationContext = { activatingPlayer = activatingPlayer, isConvergenceStart = isConvergenceStart }
            else 
                -- If waiting on the very last node, clear paused path
                self.pausedActivationPath = nil
                self.pausedActivationContext = nil
            end
            return true, table.concat(activationMessages, '\n') .. '\nActivation paused, waiting for input...'
        end
        ::continue::
    end

    -- Completed - Clear full path as well
    self.pausedActivationPath = nil; self.pausedActivationContext = nil
    self.currentActivationChainPath = nil 
    return true, table.concat(activationMessages, '\n')
end

return ActivationService 
