-- src/game/network.lua
-- Manages a player's network of placed cards.

local Card = require('src.game.card') -- We'll be storing Card instances

local Network = {}
Network.__index = Network

-- Constructor for a new Network instance
function Network:new(ownerPlayer)
    local instance = setmetatable({}, Network)

    instance.owner = ownerPlayer or error("Network must have an owner (Player object).")
    instance.grid = {} -- Stores card instances by position: grid[y][x] = cardInstance
    instance.cards = {} -- Stores all cards currently in the network { [card.id] = cardInstance } for quick lookup

    print(string.format("Initialized Network for %s", ownerPlayer.name))
    return instance
end

-- Initialize the network with a reactor at the origin
function Network:initializeWithReactor(reactorCard)
    if not reactorCard then
        error("Cannot initialize Network: No reactor card provided.")
    end
    
    if reactorCard.type ~= require('src.game.card').Type.REACTOR then
        error(string.format("Cannot initialize Network: Card %s is not a reactor", reactorCard.title))
    end
    
    if self:getCardAt(0, 0) then
        error("Cannot initialize Network: Origin (0,0) is already occupied.")
    end
    
    print(string.format("[Network] Placing reactor '%s' at (0,0) for %s", reactorCard.title, self.owner.name))
    local success = self:placeCard(reactorCard, 0, 0)
    if not success then
        error("Failed to place reactor card at origin")
    end
    print(string.format("[Network] Successfully initialized network with reactor for %s", self.owner.name))
end

-- Place a card instance onto the network grid at specified coordinates
-- Note: This function assumes placement validity checks have already been done.
function Network:placeCard(cardInstance, x, y)
    if not cardInstance or type(cardInstance) ~= 'table' then -- or not getmetatable(cardInstance) == Card then
        error(string.format("Attempted to place invalid object at (%d,%d). Expected Card instance.", x, y))
        return false
    end

    if self:getCardAt(x, y) then
        error(string.format("Attempted to place card %s (%s) at occupied position (%d,%d).", cardInstance.title, cardInstance.id, x, y))
        return false
    end

    -- Initialize row if it doesn't exist
    if not self.grid[y] then
        self.grid[y] = {}
    end

    -- Store card in grid and lookup table
    self.grid[y][x] = cardInstance
    self.cards[cardInstance.id] = cardInstance

    -- Update card's state
    cardInstance.network = self
    cardInstance.position = { x = x, y = y }
    -- cardInstance.owner was likely set when added to hand/created, but ensure it matches network owner
    if cardInstance.owner ~= self.owner then
         print(string.format("Warning: Card %s (%s) owner mismatch during placement.", cardInstance.title, cardInstance.id))
         cardInstance.owner = self.owner
    end

    print(string.format("Placed card %s (%s) at (%d,%d) in %s's network.", cardInstance.title, cardInstance.id, x, y, self.owner.name))
    return true
end

-- Retrieve the card instance at a specific grid coordinate
function Network:getCardAt(x, y)
    if self.grid[y] and self.grid[y][x] then
        return self.grid[y][x]
    end
    return nil
end

-- Retrieve a card instance by its unique ID
function Network:getCardById(cardId)
    return self.cards[cardId]
end

-- Get adjacent coordinates (up, down, left, right)
function Network:getAdjacentCoords(x, y)
    return {
        { x = x, y = y - 1 }, -- Up
        { x = x, y = y + 1 }, -- Down
        { x = x - 1, y = y }, -- Left
        { x = x + 1, y = y }, -- Right
    }
end

-- Check if a coordinate has at least one adjacent card
function Network:hasAdjacentCard(x, y)
    local adjacentCoords = self:getAdjacentCoords(x, y)
    for _, coord in ipairs(adjacentCoords) do
        if self:getCardAt(coord.x, coord.y) then
            return true
        end
    end
    return false
end

-- Check if placing cardToPlace at (x, y) is valid according to GDD 4.3
-- Returns: boolean (isValid), string (reason for failure or success message)
function Network:isValidPlacement(cardToPlace, x, y)
    -- 1. Check if target location is already occupied
    if self:getCardAt(x, y) then
        return false, string.format("Position already occupied")
    end

    -- 2. Check Uniqueness Rule (GDD 4.3)
    if self.cards[cardToPlace.id] then
        return false, string.format("Card already exists in network")
    end

    -- 3. Check Connectivity Rule (GDD 4.3): Must be adjacent to at least one existing card
    local adjacentCards = {}
    local adjacentCoords = self:getAdjacentCoords(x, y)
    for _, coord in ipairs(adjacentCoords) do
        local adjCard = self:getCardAt(coord.x, coord.y)
        if adjCard then
            table.insert(adjacentCards, { card = adjCard, x = coord.x, y = coord.y })
        end
    end

    if #adjacentCards == 0 then
        return false, string.format("Must be adjacent to at least one card")
    end

    -- 4. Check Connection Point Matching Rule (GDD 4.3 - Simplified)
    --    Rule: At least one open INPUT on the card being placed (cardToPlace)
    --          must align with a corresponding open OUTPUT on an adjacent card.
    --    Special Case: The Reactor acts as a universal OUTPUT for any adjacent INPUT requirement.
    local connectionRequirementMet = false
    for _, adjData in ipairs(adjacentCards) do
        local adjCard = adjData.card
        local ax, ay = adjData.x, adjData.y

        -- Determine connecting edges and slots based on relative position
        local newCardSlotsToCheck, adjCardSlotsToCheck
        if ax == x and ay == y - 1 then -- adjCard is ABOVE newCard
            newCardSlotsToCheck = { Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT }       -- Top edge of new card
            adjCardSlotsToCheck = { Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT } -- Bottom edge of adjacent card
        elseif ax == x and ay == y + 1 then -- adjCard is BELOW newCard
            newCardSlotsToCheck = { Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT }
            adjCardSlotsToCheck = { Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT }
        elseif ax == x - 1 and ay == y then -- adjCard is LEFT of newCard
            newCardSlotsToCheck = { Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM }
            adjCardSlotsToCheck = { Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM }
        elseif ax == x + 1 and ay == y then -- adjCard is RIGHT of newCard
            newCardSlotsToCheck = { Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM }
            adjCardSlotsToCheck = { Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM }
        end

        -- Check for a valid Output -> Input link across the connecting edge
        if newCardSlotsToCheck then
            for i = 1, #newCardSlotsToCheck do
                local newSlotIdx = newCardSlotsToCheck[i]
                local adjSlotIdx = adjCardSlotsToCheck[i] -- Corresponding slot on the adjacent card

                local newProps = cardToPlace:getSlotProperties(newSlotIdx)
                local adjProps = adjCard:getSlotProperties(adjSlotIdx)

                -- Check if the slot on the card being placed is an OPEN INPUT
                if newProps and not newProps.is_output and cardToPlace:isSlotOpen(newSlotIdx) then
                    -- Now check the corresponding slot on the adjacent card
                    if adjProps then
                        if adjCard.type == Card.Type.REACTOR then
                            -- Reactor Case: Check if the corresponding slot on the reactor is OPEN (acts as universal Output)
                            if adjCard:isSlotOpen(adjSlotIdx) then
                                print(string.format("  Connection found via Reactor: New Input Slot %d -> Reactor Output Slot %d", newSlotIdx, adjSlotIdx))
                                connectionRequirementMet = true
                                goto found_connection -- Use goto to break out of nested loops
                            end
                        else
                            -- Normal Node Case: Check if the adjacent slot is an OPEN OUTPUT of the SAME TYPE
                            if adjProps.is_output and adjCard:isSlotOpen(adjSlotIdx) and newProps.type == adjProps.type then
                                print(string.format("  Connection found via Node: New Input Slot %d (%s) -> Adj Output Slot %d (%s)", newSlotIdx, newProps.type, adjSlotIdx, adjProps.type))
                                connectionRequirementMet = true
                                goto found_connection -- Use goto to break out of nested loops
                            end
                        end
                    end
                end
            end
        end
    end
    ::found_connection::

    if not connectionRequirementMet then
        return false, string.format("No valid connection found")
    end

    -- All checks passed
    return true, string.format("Placement at (%d,%d) is valid.", x, y)
end

-- Find a valid activation path from a target card back to the Reactor (GDD 4.5)
-- Path follows Input <- Output links.
-- targetCard: The Card instance that is the target endpoint of the activation.
-- Returns: A table (list) of Card instances representing the path [targetCard, ..., nodeBeforeReactor]
--          or nil if no valid path is found.
function Network:findPathToReactor(targetCard)
    if not targetCard or not targetCard.position or targetCard.network ~= self then
        print("Error: Invalid target card provided for pathfinding.")
        return nil
    end

    if targetCard.type == Card.Type.REACTOR then
        print("Cannot activate the Reactor itself.")
        return nil
    end

    print(string.format("Finding path from %s (%d,%d) to Reactor...", targetCard.title, targetCard.position.x, targetCard.position.y))

    -- We need to perform a search (e.g., BFS or DFS) backwards from the target.
    -- Each step must go from an OPEN INPUT slot on the current card
    -- to a corresponding OPEN OUTPUT slot on the previous card in the path.

    -- Let's use Breadth-First Search (BFS) to find the shortest path (in terms of nodes).
    -- queue stores tables: { card = currentCard, path = {currentCard, ...} }
    local queue = { { card = targetCard, path = { targetCard } } }
    local visited = { [targetCard.id] = true } -- Track visited card IDs to prevent cycles

    while #queue > 0 do
        local current = table.remove(queue, 1) -- Dequeue
        local currentCard = current.card
        local currentPath = current.path

        -- print(string.format("  Checking card: %s at (%d,%d)", currentCard.title, currentCard.position.x, currentCard.position.y))

        -- Check neighbors to find the *previous* card in the path (following Input <- Output)
        local adjacentCoords = self:getAdjacentCoords(currentCard.position.x, currentCard.position.y)
        for _, coord in ipairs(adjacentCoords) do
            local neighborCard = self:getCardAt(coord.x, coord.y)

            if neighborCard and not visited[neighborCard.id] then
                -- Determine connecting edge slots
                local currentCardSlotsToCheck, neighborCardSlotsToCheck
                local cx, cy = currentCard.position.x, currentCard.position.y
                local nx, ny = neighborCard.position.x, neighborCard.position.y

                if nx == cx and ny == cy - 1 then -- neighborCard is ABOVE currentCard
                    currentCardSlotsToCheck = { Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT }       -- Top edge of current card
                    neighborCardSlotsToCheck = { Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT } -- Bottom edge of neighbor card
                elseif nx == cx and ny == cy + 1 then -- neighborCard is BELOW currentCard
                    currentCardSlotsToCheck = { Card.Slots.BOTTOM_LEFT, Card.Slots.BOTTOM_RIGHT }
                    neighborCardSlotsToCheck = { Card.Slots.TOP_LEFT, Card.Slots.TOP_RIGHT }
                elseif nx == cx - 1 and ny == cy then -- neighborCard is LEFT of currentCard
                    currentCardSlotsToCheck = { Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM }
                    neighborCardSlotsToCheck = { Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM }
                elseif nx == cx + 1 and ny == cy then -- neighborCard is RIGHT of currentCard
                    currentCardSlotsToCheck = { Card.Slots.RIGHT_TOP, Card.Slots.RIGHT_BOTTOM }
                    neighborCardSlotsToCheck = { Card.Slots.LEFT_TOP, Card.Slots.LEFT_BOTTOM }
                end

                -- Check for a valid Output -> Input link (Current -> Neighbor)
                if currentCardSlotsToCheck then
                    for i = 1, #currentCardSlotsToCheck do
                        local currentSlotIdx = currentCardSlotsToCheck[i]
                        local neighborSlotIdx = neighborCardSlotsToCheck[i]

                        local currentProps = currentCard:getSlotProperties(currentSlotIdx)
                        local neighborProps = neighborCard:getSlotProperties(neighborSlotIdx)

                        -- Is current slot an OPEN OUTPUT?
                        if currentProps and currentProps.is_output and currentCard:isSlotOpen(currentSlotIdx) then
                            -- Is neighbor slot an OPEN INPUT of the same TYPE?
                            if neighborProps and not neighborProps.is_output and neighborCard:isSlotOpen(neighborSlotIdx) and currentProps.type == neighborProps.type then
                                -- Valid Output -> Input link found!
                                -- print(string.format("    Found valid link: Current Output Slot %d (%s) -> Neighbor Input Slot %d (%s) [%s]", currentSlotIdx, currentProps.type, neighborSlotIdx, neighborProps.type, neighborCard.title))

                                -- Check if neighbor is the Reactor
                                if neighborCard.type == Card.Type.REACTOR then
                                    print("  Path found to Reactor!")
                                    return currentPath -- Found the path!
                                end

                                -- Neighbor is not Reactor, add to queue if not visited
                                if not visited[neighborCard.id] then
                                    visited[neighborCard.id] = true
                                    local newPath = {}
                                    for _, pCard in ipairs(currentPath) do table.insert(newPath, pCard) end -- Copy path
                                    table.insert(newPath, neighborCard) -- Add neighbor to path
                                    table.insert(queue, { card = neighborCard, path = newPath })
                                    -- print(string.format("    Enqueued neighbor: %s", neighborCard.title))
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    print("No valid path found to Reactor.")
    return nil -- No path found
end

-- Find the player's Reactor card in the network
-- Returns: The reactor Card instance or nil if none found
function Network:findReactor()
    for id, card in pairs(self.cards) do
        if card.type == Card.Type.REACTOR then
            return card
        end
    end
    return nil
end

-- Check if a card with the given ID exists in the network
-- Returns: boolean indicating if the card exists
function Network:hasCardWithId(cardId)
    return self.cards[cardId] ~= nil
end

-- Check if the network is empty (has no cards)
-- Returns: boolean indicating if the network is empty
function Network:isEmpty()
    -- Use next() to check if the cards table has any entries
    return next(self.cards) == nil
end

-- TODO: Implement network iteration/visualization helpers

return Network
