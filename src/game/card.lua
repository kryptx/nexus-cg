-- src/game/card.lua
-- Defines the structure and basic data for game cards.

local Card = {}
Card.__index = Card

-- Card Types (Constants)
Card.Type = {
    TECHNOLOGY = "Technology",
    CULTURE = "Culture",
    RESOURCE = "Resource",
    KNOWLEDGE = "Knowledge",
    REACTOR = "Reactor", -- Special type
}

-- Connection Port Indices (Constants, based on GDD 4.3)
-- Top: 1 (Cult Out), 2 (Tech In)
-- Bot: 3 (Cult In),  4 (Tech Out)
-- Lft: 5 (Know Out), 6 (Res In)
-- Rgt: 7 (Know In),  8 (Res Out)
Card.Ports = {
    TOP_LEFT    = 1, TOP_RIGHT   = 2,
    BOTTOM_LEFT = 3, BOTTOM_RIGHT= 4,
    LEFT_TOP    = 5, LEFT_BOTTOM = 6,
    RIGHT_TOP   = 7, RIGHT_BOTTOM= 8,
}

-- Static helper function to get port properties based on index
-- Returns { type = Card.Type.*, is_output = boolean } or nil
local portPropertiesCache = {}
do -- Precompute port properties
    local function computePortProperties(portIndex)
        if portIndex == Card.Ports.TOP_LEFT     then return { type = Card.Type.CULTURE,   is_output = true } end
        if portIndex == Card.Ports.TOP_RIGHT    then return { type = Card.Type.TECHNOLOGY, is_output = false } end
        if portIndex == Card.Ports.BOTTOM_LEFT  then return { type = Card.Type.CULTURE,   is_output = false } end
        if portIndex == Card.Ports.BOTTOM_RIGHT then return { type = Card.Type.TECHNOLOGY, is_output = true } end
        if portIndex == Card.Ports.LEFT_TOP     then return { type = Card.Type.KNOWLEDGE, is_output = true } end
        if portIndex == Card.Ports.LEFT_BOTTOM  then return { type = Card.Type.RESOURCE,  is_output = false } end
        if portIndex == Card.Ports.RIGHT_TOP    then return { type = Card.Type.KNOWLEDGE, is_output = false } end
        if portIndex == Card.Ports.RIGHT_BOTTOM then return { type = Card.Type.RESOURCE,  is_output = true } end
        return nil
    end
    for i=1, 8 do portPropertiesCache[i] = computePortProperties(i) end
end

function Card:getPortProperties(portIndex)
    return portPropertiesCache[portIndex]
end

-- Static helper function to check if two ports on adjacent edges align
-- e.g., TopLeft (1) aligns with BottomLeft (3)
--       TopRight (2) aligns with BottomRight (4)
--       LeftTop (5) aligns with RightTop (7)
--       LeftBottom (6) aligns with RightBottom (8)
function Card:portsAlign(portIndex1, portIndex2)
    local P = Card.Ports
    local alignments = {
        [P.TOP_LEFT] = P.BOTTOM_LEFT, [P.BOTTOM_LEFT] = P.TOP_LEFT,
        [P.TOP_RIGHT] = P.BOTTOM_RIGHT, [P.BOTTOM_RIGHT] = P.TOP_RIGHT,
        [P.LEFT_TOP] = P.RIGHT_TOP, [P.RIGHT_TOP] = P.LEFT_TOP,
        [P.LEFT_BOTTOM] = P.RIGHT_BOTTOM, [P.RIGHT_BOTTOM] = P.LEFT_BOTTOM,
    }
    return alignments[portIndex1] == portIndex2
end

-- Global ID counter for unique instance IDs
local nextInstanceId = 1

-- Constructor for a new Card instance
-- data: A table containing card definition details
function Card:new(data)
    local instance = setmetatable({}, Card)

    -- Core Properties
    instance.id = data.id or error("Card must have a unique id")
    instance.title = data.title or "Untitled Card"
    instance.type = data.type or error("Card must have a type (Card.Type)")
    instance.instanceId = nextInstanceId

    -- Gameplay Properties
    -- Ensure buildCost has both material and data, defaulting to 0
    local cost = data.buildCost or {}
    instance.buildCost = {
        material = cost.material or 0,
        data = cost.data or 0
    }
    
    -- Handle the two formats for effects:
    -- 1. Legacy format: function(player, network)
    -- 2. New format: { description = string, activate = function(player, network) }
    if type(data.activationEffect) == "function" then
        instance.activationEffect = {
            description = "[Legacy Effect]",
            activate = data.activationEffect
        }
    elseif type(data.activationEffect) == "table" and data.activationEffect.activate then
        instance.activationEffect = data.activationEffect
    else
        -- Default effect
        instance.activationEffect = {
            description = "No effect.",
            activate = function(player, network) print(instance.title .. " Activation Effect triggered.") end
        }
    end
    
    if type(data.convergenceEffect) == "function" then
        instance.convergenceEffect = {
            description = "[Legacy Effect]",
            activate = data.convergenceEffect
        }
    elseif type(data.convergenceEffect) == "table" and data.convergenceEffect.activate then
        instance.convergenceEffect = data.convergenceEffect
    else
        -- Default effect
        instance.convergenceEffect = {
            description = "No effect.",
            activate = function(player, network) print(instance.title .. " Convergence Effect triggered.") end
        }
    end
    
    instance.vpValue = data.vpValue or 0 -- End-game VP value

    -- Connection Ports (which of the 8 potential ports are defined as present by the card definition)
    instance.definedPorts = data.definedPorts or {}
    -- Runtime state tracking which ports are currently occupied by which link ID
    instance.occupiedPorts = {} -- Stores { [portIndex] = linkId, ... }

    -- Visual/Flavor
    instance.imagePath = data.imagePath or "assets/images/placeholder.png"
    instance.flavorText = data.flavorText or ""

    -- Runtime State (will be added when card is in play/hand)
    instance.owner = nil -- Player object
    instance.position = nil -- {x, y} grid position in network
    instance.network = nil -- Reference to the network it belongs to

    -- Connection Management (moved from Reactor)
    instance.connections = {}

    -- Increment the global instance ID counter
    nextInstanceId = nextInstanceId + 1

    return instance
end

-- Helper function to get the activation effect description
function Card:getActivationDescription()
    if self.activationEffect and self.activationEffect.description then
        return self.activationEffect.description
    end
    return "[No Description]"
end

-- Helper function to get the convergence effect description
function Card:getConvergenceDescription()
    if self.convergenceEffect and self.convergenceEffect.description then
        return self.convergenceEffect.description
    end
    return "[No Description]"
end

-- Execute the activation effect
-- Changed 3rd arg name to originalTargetNode to reflect its purpose better
function Card:activateEffect(gameService, activatingPlayer, originalTargetNode) 
    print(string.format("  [CARD DEBUG] >>> Entering Card:activateEffect for %s (ID: %s)", self.title, self.id))
    if self.activationEffect and self.activationEffect.activate then
        -- Ensure the card has network context to find the sourceNode
        if not self.network or not self.position or not self.network.getNodeAt then
            print(string.format("  [CARD ERROR] !!! Card %s cannot activate effect: Missing network context (network=%s, position=%s)", self.id, tostring(self.network), tostring(self.position)))
            return 
        end
        -- Retrieve the node structure for this card (the source node)
        local sourceNode = self.network:getNodeAt(self.position)
        if not sourceNode then
            print(string.format("  [CARD ERROR] !!! Card %s cannot activate effect: Failed to retrieve sourceNode from network at position (%s, %s)", self.id, self.position.x, self.position.y))
            return
        end

        -- Call the internal activate function with the correct context
        -- activate(gameService, activatingPlayer, sourceNetwork, sourceNode, targetNode)
        local result = self.activationEffect.activate(gameService, activatingPlayer, self.network, sourceNode, originalTargetNode) 
        print(string.format("  [CARD DEBUG] <<< Exiting Card:activateEffect for %s (ID: %s)", self.title, self.id))
        return result
    end
    print(string.format("  [CARD DEBUG] !!! Activation effect activate function not found for %s (ID: %s)", self.title, self.id))
end

-- Execute the convergence effect
-- Changed 3rd arg name to initiatingNode (node on activator's net that linked)
function Card:activateConvergence(gameService, activatingPlayer, initiatingNode) 
    print(string.format("  [CARD DEBUG] >>> Entering Card:activateConvergence for %s (ID: %s)", self.title, self.id))
    if self.convergenceEffect and self.convergenceEffect.activate then
        -- Ensure the card has network context to find the sourceNode (the node being converged upon)
        if not self.network or not self.position or not self.network.getNodeAt then
            print(string.format("  [CARD ERROR] !!! Card %s cannot activate convergence: Missing network context (network=%s, position=%s)", self.id, tostring(self.network), tostring(self.position)))
            return 
        end
        -- Retrieve the node structure for this card (the source node)
        local sourceNode = self.network:getNodeAt(self.position)
        if not sourceNode then
            print(string.format("  [CARD ERROR] !!! Card %s cannot activate convergence: Failed to retrieve sourceNode from network at position (%s, %s)", self.id, self.position.x, self.position.y))
            return
        end

        -- Note: Convergence effects use the same activate function structure currently
        -- The distinction of who the owner/activator is happens inside the effect based on arguments
        -- Call the internal activate function:
        -- activate(gameService, activatingPlayer, sourceNetwork, sourceNode, targetNode)
        -- Here, sourceNetwork/Node refer to *this* card being converged upon.
        -- targetNode (the 5th arg) is interpreted as the node that *initiated* the link/activation from the other network.
        local result = self.convergenceEffect.activate(gameService, activatingPlayer, self.network, sourceNode, initiatingNode) 
        print(string.format("  [CARD DEBUG] <<< Exiting Card:activateConvergence for %s (ID: %s)", self.title, self.id))
        return result
    end
    print(string.format("  [CARD DEBUG] !!! Convergence effect activate function not found for %s (ID: %s)", self.title, self.id))
end

-- Marks a specific port as occupied (e.g., by a convergence link)
function Card:markPortOccupied(portIndex, linkId)
    if not linkId then
        print(string.format("Warning: Attempted to mark port %s occupied without a linkId on card %s.", tostring(portIndex), self.id or '?'))
        return
    end
    if portIndex and portIndex >= 1 and portIndex <= 8 then
        if self.occupiedPorts[portIndex] then
             print(string.format("Warning: Port %d on card %s is already occupied by link %s. Overwriting with %s.", portIndex, self.id or '?', self.occupiedPorts[portIndex], linkId))
        end
        self.occupiedPorts[portIndex] = linkId
        print(string.format("Card %s: Port %d marked as occupied by link %s.", self.id or '?', portIndex, linkId))
    else
        print(string.format("Warning: Attempted to mark invalid port index %s as occupied on card %s.", tostring(portIndex), self.id or '?'))
    end
end

-- Marks a specific port as unoccupied
function Card:markPortUnoccupied(portIndex)
    if portIndex and portIndex >= 1 and portIndex <= 8 then
        if self.occupiedPorts[portIndex] then
            print(string.format("Card %s: Port %d (occupied by %s) marked as unoccupied.", self.id or '?', portIndex, self.occupiedPorts[portIndex]))
            self.occupiedPorts[portIndex] = nil -- Use nil to mark as unoccupied
        end
    else
        print(string.format("Warning: Attempted to mark invalid port index %s as unoccupied on card %s.", tostring(portIndex), self.id or '?'))
    end
end

-- Clears a specific port (for link destruction)
function Card:clearPort(portIndex)
    if portIndex and portIndex >= 1 and portIndex <= 8 then
        if self.occupiedPorts[portIndex] then
            local linkId = self.occupiedPorts[portIndex]
            print(string.format("Card %s: Clearing port %d (occupied by link %s).", self.id or '?', portIndex, linkId))
            self.occupiedPorts[portIndex] = nil -- Use nil to mark as unoccupied
            return linkId
        else
            print(string.format("Card %s: Port %d was not occupied, nothing to clear.", self.id or '?', portIndex))
        end
    else
        print(string.format("Warning: Attempted to clear invalid port index %s on card %s.", tostring(portIndex), self.id or '?'))
    end
    return nil
end

-- Checks if a specific port is currently marked as occupied by any link
function Card:isPortOccupied(portIndex)
    -- Check occupiedPorts first (for convergence links)
    if self.occupiedPorts[portIndex] then
        return true
    end
    -- Check connections (for adjacency links established during placement)
    if self.connections then
        for _, conn in ipairs(self.connections) do
            if conn.selfPort == portIndex then
                return true -- Occupied by an adjacent card connection
            end
        end
    end
    return false
end

-- Gets the ID of the link occupying the port, or nil if unoccupied
function Card:getOccupyingLinkId(portIndex)
    return self.occupiedPorts[portIndex]
end

-- Checks if a specific port is defined as present on the card
function Card:isPortDefined(portIndex)
    return self.definedPorts[portIndex] == true
end

-- Helper function to check if a specific port is available for connection
-- A port is available if it's defined as present by the card type AND not currently occupied.
function Card:isPortAvailable(portIndex)
    local isDefined = self:isPortDefined(portIndex)
    local isOccupied = self:isPortOccupied(portIndex)
    return isDefined and not isOccupied
end

-- Get a list of all defined INPUT ports on this card
-- Returns: list of tables { index = portIndex, type = portType }
function Card:getInputPorts()
    local inputPorts = {}
    for portIndex = 1, 8 do
        if self:isPortDefined(portIndex) then
            local props = self:getPortProperties(portIndex)
            if props and not props.is_output then -- Check if it's an input
                table.insert(inputPorts, { index = portIndex, type = props.type })
            end
        end
    end
    return inputPorts
end

-- Get a list of all defined OUTPUT ports on this card
-- Returns: list of tables { index = portIndex, type = portType }
function Card:getOutputPorts()
    local outputPorts = {}
    for portIndex = 1, 8 do
        if self:isPortDefined(portIndex) then
            local props = self:getPortProperties(portIndex)
            if props and props.is_output then -- Check if it's an output
                table.insert(outputPorts, { index = portIndex, type = props.type })
            end
        end
    end
    return outputPorts
end

-- Check if this card has a specific OUTPUT port defined and present
function Card:hasOutputPort(portType, portIndex)
    if self:isPortDefined(portIndex) then
        local props = self:getPortProperties(portIndex)
        return props and props.is_output and props.type == portType
    end
    return false
end

-- === Connection Management Methods (Moved from Reactor) ===

-- Register a connection to another card
-- targetCard: The Card instance to connect to
-- selfPortIndex: The port index on this card used for the connection
-- targetPortIndex: The port index on the target card used for the connection
function Card:addConnection(targetCard, selfPortIndex, targetPortIndex)
    -- Ensure connections table exists (should be initialized in new, but belt-and-suspenders)
    self.connections = self.connections or {}
    table.insert(self.connections, {
        target = targetCard,
        selfPort = selfPortIndex,
        targetPort = targetPortIndex
    })
    -- Optional: Add print for debugging if needed
    -- print(string.format("Card %s: Added connection to %s (Ports: %d -> %d)", self.id or '?', targetCard.id or '?', selfPortIndex, targetPortIndex))
end

-- Remove a connection to another card
-- targetCard: The Card instance to disconnect from
function Card:removeConnection(targetCard)
    if not self.connections then return false end
    
    for i = #self.connections, 1, -1 do -- Iterate backwards for safe removal
        if self.connections[i].target == targetCard then
            -- Optional: Add print for debugging if needed
            -- print(string.format("Card %s: Removed connection to %s", self.id or '?', targetCard.id or '?'))
            table.remove(self.connections, i)
            -- Note: This only removes the connection from this card's perspective.
            -- The Network or GameService might need to call removeConnection on the other card too.
            return true 
        end
    end
    return false
end

-- Get all cards directly connected to this card
function Card:getConnectedCards()
    local cards = {}
    if not self.connections then return cards end
    
    for _, conn in ipairs(self.connections) do
        table.insert(cards, conn.target)
    end
    return cards
end

-- Get connection details (target card, self port, target port) for a specific connected card
function Card:getConnectionDetails(targetCard)
    if not self.connections then return nil end
    for _, conn in ipairs(self.connections) do
        if conn.target == targetCard then
            return conn.target, conn.selfPort, conn.targetPort
        end
    end
    return nil
end

-- Check if this card can connect to a target card in a specific direction
-- This needs to be updated to use the new `isPortAvailable` check.
function Card:canConnectTo(target, direction)
    if not target or not target.isPortAvailable or not target.getPortProperties then -- Updated check
        -- print("Warning: Invalid target provided to canConnectTo")
        return false, "Invalid target card"
    end

    -- Determine facing ports based on direction (from self's perspective)
    local selfPortIndices, targetPortIndices
    if direction == "down" then -- self is ABOVE target
        selfPortIndices = {Card.Ports.BOTTOM_LEFT, Card.Ports.BOTTOM_RIGHT}
        targetPortIndices = {Card.Ports.TOP_LEFT, Card.Ports.TOP_RIGHT}
    elseif direction == "up" then -- self is BELOW target
        selfPortIndices = {Card.Ports.TOP_LEFT, Card.Ports.TOP_RIGHT}
        targetPortIndices = {Card.Ports.BOTTOM_LEFT, Card.Ports.BOTTOM_RIGHT}
    elseif direction == "right" then -- self is LEFT of target
        selfPortIndices = {Card.Ports.RIGHT_TOP, Card.Ports.RIGHT_BOTTOM}
        targetPortIndices = {Card.Ports.LEFT_TOP, Card.Ports.LEFT_BOTTOM}
    elseif direction == "left" then -- self is RIGHT of target
        selfPortIndices = {Card.Ports.LEFT_TOP, Card.Ports.LEFT_BOTTOM}
        targetPortIndices = {Card.Ports.RIGHT_TOP, Card.Ports.RIGHT_BOTTOM}
    else
        -- print("Warning: Invalid direction provided to canConnectTo:", direction)
        return false, "Invalid direction"
    end

    -- Check all pairs of facing ports for a valid connection (GDD 4.3 Simplified Rule)
    -- "The placement is valid if at least one of these open Input ports [on Card B]
    -- aligns with a corresponding open Output port on Card A's adjacent edge."
    -- Here, 'self' is Card A, 'target' is Card B.

    local foundValidLink = false
    for _, targetPortIndex in ipairs(targetPortIndices) do
        if target:isPortAvailable(targetPortIndex) then -- Use the new check
            local targetProps = target:getPortProperties(targetPortIndex)
            if targetProps and not targetProps.is_output then -- Check if it's an INPUT port on the target (Card B)
                -- Now find the corresponding port on self (Card A)
                local correspondingSelfPortIndex
                if targetPortIndex == Card.Ports.TOP_LEFT then correspondingSelfPortIndex = Card.Ports.BOTTOM_LEFT
                elseif targetPortIndex == Card.Ports.TOP_RIGHT then correspondingSelfPortIndex = Card.Ports.BOTTOM_RIGHT
                elseif targetPortIndex == Card.Ports.BOTTOM_LEFT then correspondingSelfPortIndex = Card.Ports.TOP_LEFT
                elseif targetPortIndex == Card.Ports.BOTTOM_RIGHT then correspondingSelfPortIndex = Card.Ports.TOP_RIGHT
                elseif targetPortIndex == Card.Ports.LEFT_TOP then correspondingSelfPortIndex = Card.Ports.RIGHT_TOP
                elseif targetPortIndex == Card.Ports.LEFT_BOTTOM then correspondingSelfPortIndex = Card.Ports.RIGHT_BOTTOM
                elseif targetPortIndex == Card.Ports.RIGHT_TOP then correspondingSelfPortIndex = Card.Ports.LEFT_TOP
                elseif targetPortIndex == Card.Ports.RIGHT_BOTTOM then correspondingSelfPortIndex = Card.Ports.LEFT_BOTTOM
                end
                
                -- Check if the corresponding port on 'self' exists in the facing ports list
                local isFacing = false
                for _, sIdx in ipairs(selfPortIndices) do 
                    if sIdx == correspondingSelfPortIndex then isFacing = true; break; end
                end
                
                if isFacing and self:isPortAvailable(correspondingSelfPortIndex) then -- Use new check
                    local selfProps = self:getPortProperties(correspondingSelfPortIndex)
                    if selfProps and selfProps.is_output then -- Check if it's an OUTPUT port on self (Card A)
                        -- Check if types match (implicitly handled by GDD rule? No, GDD rule only requires *one* match)
                        -- The simplified rule doesn't require type matching for placement, only Input -> Output.
                        foundValidLink = true
                        break -- Found at least one valid Input->Output link, placement is valid
                    end
                end
            end
        end
    end

    if foundValidLink then
        return true
    else
        return false, "No matching Input->Output ports"
    end
end

-- Get the number of active convergence links attached to this card.
function Card:getConvergenceLinkCount()
    local count = 0
    for _ in pairs(self.occupiedPorts) do
        count = count + 1
    end
    return count
end

-- Retrieve a list of port indices that represent defined INPUT ports for this card.
function Card:getInputPorts()
    local inputPorts = {}
    for portIndex = 1, 8 do
        if self:isPortDefined(portIndex) then
            local props = self:getPortProperties(portIndex)
            if props and not props.is_output then -- Check if it's an input
                table.insert(inputPorts, { index = portIndex, type = props.type })
            end
        end
    end
    return inputPorts
end

-- TODO: Add functions related to activation, linking, etc.

-- Get a string representation of the card
function Card:toString()
    return string.format("Card[%s]: %s (%s) - ID: %s, InstanceID: %d", 
                        self.type, self.title, self.subtype, self.id, self.instanceId)
end

return Card
