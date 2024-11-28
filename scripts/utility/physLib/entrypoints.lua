

function LoadPhysLib()
    NodesRaw = {}
    Nodes = {}
    NodeTree = {}

    EnumerateStructureLinks(0, -1, "c", true)
    EnumerateStructureLinks(1, -1, "c", true)
    EnumerateStructureLinks(2, -1, "c", true)
    UpdateNodeTable()
end

function ReloadPhysLib()
    NodesRaw = {}
    Nodes = {}
    NodeTree = {}

    EnumerateStructureLinks(0, -1, "c", true)
    EnumerateStructureLinks(1, -1, "c", true)
    EnumerateStructureLinks(2, -1, "c", true)
    UpdateNodeTable()
end


Dot = 0
function UpdatePhysLib(frame)
    -- Temporary
    local worldExtents = GetWorldExtents()
    local extents = {minX = worldExtents.MinX, minY = worldExtents.MinY, maxX = worldExtents.MaxX, maxY = worldExtents.MaxY}
    PhysicsObjectsTree = SubdividePoses(PhysicsObjects, extents)
    UpdateObjects()

    -- mod body update
    for i = 1, #Nodes do
        local node = Nodes[i]
        local newPos = NodePosition(node.id)
        node.x = newPos.x
        node.y = newPos.y
    end

    SubdivideStructures()




    -- HighlightCapsule(startPos, endPos, radius)

    -- for i = 1, 1 do
    --     local results = CapsuleCollisionOnStructure(startPos, endPos, radius)
    -- end
end


--#region events
function OnDeviceCreated(teamId, deviceId, saveName, nodeA, nodeB, t, upgradedId)
    LoadPhysLib()
end
function OnGroundDeviceCreated(teamId, deviceId, saveName, pos, upgradedId)
    LoadPhysLib()
end

function OnNodeCreated(nodeId, teamId, pos, foundation, selectable, extrusion)

    -- Just assign pos since we're using the x and y directly from that
    pos.links = {}
    pos.id = nodeId
    NodesRaw[nodeId] = pos
    UpdateNodeTable()
end
function OnNodeDestroyed(nodeId, selectable)

    local node = NodesRaw[nodeId]
    local linkedToNodes = node.links
    for otherLinkedNodeId, otherLink in pairs(linkedToNodes) do
        otherLink.node.links[nodeId] = nil
    end
    NodesRaw[nodeId] = nil
    UpdateNodeTable()

end
function OnNodeBroken(thisNodeId, nodeIdNew)

    -- Step 1, clear the links from the things that the node is linked to
    local existingNode = NodesRaw[thisNodeId]
    local linkedToNodes = existingNode.links
    for otherLinkedNodeId, otherLink in pairs(linkedToNodes) do
        otherLink.node.links[thisNodeId] = nil
    end

    -- Step 2, delete the node
    NodesRaw[thisNodeId] = nil
    -- Step 3, add the two nodes as normal
    local nodeA = NodePosition(thisNodeId)
    nodeA.links = {}
    nodeA.id = thisNodeId
    NodesRaw[thisNodeId] = nodeA
    local nodeB = NodePosition(nodeIdNew)
    nodeB.links = {}
    nodeB.id = nodeIdNew
    NodesRaw[nodeIdNew] = nodeB
    -- Step 4, recursively readd links to the nodes
    AddLinksRecursive(thisNodeId)
    AddLinksRecursive(nodeIdNew)

    UpdateNodeTable()
end

function OnLinkCreated(teamId, saveName, nodeIdA, nodeIdB, pos1, pos2, extrusion)
    local nodeA = NodesRaw[nodeIdA]
    local nodeB = NodesRaw[nodeIdB]

    nodeA.links[nodeIdB] = {node = nodeB, material = saveName}
    nodeB.links[nodeIdA] = {node = nodeA, material = saveName}
    UpdateNodeTable()
end
function OnLinkDestroyed(teamId, saveName, nodeIdA, nodeIdB, breakType)
    local nodeA = NodesRaw[nodeIdA]
    local nodeB = NodesRaw[nodeIdB]

    nodeA.links[nodeIdB] = nil
    nodeB.links[nodeIdA] = nil
    UpdateNodeTable()
end
--#endregion

--#region Events utility

function AddLinksRecursive(nodeId)
    local node = NodesRaw[nodeId]

    local linkCount = NodeLinkCount(nodeId)

    for index = 0, linkCount - 1 do
        local otherNodeId = NodeLinkedNodeId(nodeId, index)
        local otherNode = NodesRaw[otherNodeId]
        local saveName = GetLinkMaterialSaveName(nodeId, otherNodeId)
        node.links[otherNodeId] = {node = otherNode, material = saveName}
        otherNode.links[nodeId] = {node = node, material = saveName}
    end
end

function UpdateNodeTable()
    Nodes = FlattenTable(NodesRaw)
end

--#endregion