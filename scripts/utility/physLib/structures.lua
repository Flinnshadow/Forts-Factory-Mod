--scripts/utility/physLib/structures.lua


--#region Enumeration callback
---@diagnostic disable-next-line: lowercase-global
function c(idA, idB, linkPos, saveName)
    -- TODO: Optimize this to not get the savename in enumerate links as this is slow and most of the time not useful, instead the savename should be collected and then cached by the next thing
    -- to say it is colliding with the link
    --local saveName = GetLinkMaterialSaveName(nodeA, nodeB)
    local nodesRaw = PhysLib.NodesRaw
    local nodeA = nodesRaw[idA]
    local nodeB = nodesRaw[idB]
    local nodeALinks
    local nodeBLinks

    if not nodeA then
        local p = NodePosition(idA)
        nodeA = p
        nodeALinks = {}
        nodeA.links = nodeALinks
        nodeA.id = idA

        nodesRaw[idA] = nodeA
    else
        nodeALinks = nodeA.links
    end
    if not nodeB then
        local p = NodePosition(idB)
        nodeB = p
        nodeBLinks = {}
        nodeB.links = nodeBLinks
        nodeB.id = idB
        nodesRaw[idB] = nodeB
    else
        nodeBLinks = nodeB.links
    end
    nodeALinks[idB] = {node = nodeB, material = saveName}
    nodeBLinks[idA] = {node = nodeA, material = saveName}

    return true
end
---@diagnostic disable-next-line: lowercase-global
function d(idA, idB, linkPos, material)
    local existingLinks = PhysLib.ExistingLinks

    if not existingLinks[idA] then
        existingLinks[idA] = {}
    else
        if existingLinks[idB] and existingLinks[idB][idA] then
            return true
        end
    end
    existingLinks[idA][idB] = true

    local links = PhysLib.Links
    local nodesRaw = PhysLib.NodesRaw
    local nodeA = nodesRaw[idA]
    local nodeB = nodesRaw[idB]
    local nodeAx, nodeAy, nodeBx, nodeBy = nodeA.x, nodeA.y, nodeB.x, nodeB.y


    local minX, minY, maxX, maxY
    if nodeAx < nodeBx then
        minX = nodeAx
        maxX = nodeBx
    else
        minX = nodeBx
        maxX = nodeAx
    end
    if nodeAy < nodeBy then
        minY = nodeAy
        maxY = nodeBy
    else
        minY = nodeBy
        maxY = nodeAy
    end

    local link = {nodeA = nodeA, nodeB = nodeB, material = material, minX = minX, minY = minY, maxX = maxX, maxY = maxY, x = linkPos.x, y = linkPos.y}
    links[#links + 1] = link
    return true
end
--#endregion
function PhysLib.Structures:UpdateNodePositions()
    local nodes = PhysLib.Nodes
    local nodeCount = #nodes
    for i = 1, nodeCount do
        local node = nodes[i]
        local newPos = NodePosition(node.id)
        node.x = newPos.x
        node.y = newPos.y
    end
end
