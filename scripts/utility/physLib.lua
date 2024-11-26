--#region Includes
dofile("scripts/forts.lua")
dofile(path .. "/math/vector.lua")
dofile(path .. "/utility/BetterLog.lua")
--#endregion

--#region Global tables

NodesRaw = {}
Nodes = {}
NodeTree = {}
--#endregion

--#region Entrypoints


function LoadPhysLib()
    NodesRaw = {}
    Nodes = {}
    NodeTree = {}

    EnumerateStructureLinks(0, -1, "c", true)
    EnumerateStructureLinks(1, -1, "c", true)
    EnumerateStructureLinks(2, -1, "c", true)
    UpdateNodeTable()
end

function UpdatePhysLib(frame)

    -- mod body update
    for i = 1, #Nodes do
        local node = Nodes[i]
        local newPos = NodePosition(node.id)
        node.x = newPos.x
        node.y = newPos.y
    end

    SubdivideStructures()




end
--#endregion

--#region Events

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
--endregion

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

--#region Enumeration callback
function c(idA, idB)
    -- TODO: Optimize this to not get the savename in enumerate links as this is slow and most of the time not useful, instead the savename should be collected and then cached by the next thing
    -- to say it is colliding with the link
    --local saveName = GetLinkMaterialSaveName(nodeA, nodeB)

    local nodeA = NodesRaw[idA]
    local nodeB = NodesRaw[idB]

    if not nodeA then
        local p = NodePosition(idA)
        nodeA = p
        nodeA.links = {}
        nodeA.id = idA
        NodesRaw[idA] = nodeA
    end
    if not nodeB then
        local p = NodePosition(idB)
        nodeB = p
        nodeB.links = {}
        nodeB.id = idB
        NodesRaw[idB] = nodeB
    end
    local saveName = GetLinkMaterialSaveName(idA, idB)
    nodeA.links[idB] = {node = nodeB, material = saveName}
    nodeB.links[idA] = {node = nodeA, material = saveName}

    return true
end
--#endregion

--#region Subdivision

function SubdivideStructures()
    --for i = 1, 50 do
   NodeTree = SubdivideGroup(Nodes, 0)
    --end
end
SDTYPE_BOTH_THRESHOLD_MAX = 1.1
SDTYPE_BOTH_THRESHOLD_MIN = 1/SDTYPE_BOTH_THRESHOLD_MAX


SDTYPE_VERTICAL = 0
SDTYPE_HORIZONTAL = 1
SDTYPE_BOTH = 2




function SubdivideGroup(nodes, depth)
    local rect = GetNodeRectangle(nodes)
    local count = rect.count
    --Degenerate case: two nodes positioned mathematically perfectly on top of each other (this occurs when nodes rotate too far and split)
    if count <= 1 or rect.width + rect.height == 0 then
        local extendedFamily = GetNodeGroupExtendedFamily(nodes)
        rect = GetNodeRectanglePairs(extendedFamily)
        return {children = nodes, rect = rect, deepest = true}
    end

    local widthHeightRatio = rect.width / rect.height

    local subTree

    if (widthHeightRatio > SDTYPE_BOTH_THRESHOLD_MAX) then
        --Divide vertically
        subTree = DivideNodesVertically(nodes, rect.x)
    elseif (widthHeightRatio < SDTYPE_BOTH_THRESHOLD_MIN) then
        --Divide horizontally
        subTree = DivideNodesHorizontally(nodes, rect.y)
    else
        --Divide both
        subTree = DivideNodesVerticallyAndHorizontally(nodes, rect)
    end
    local children = {}
    for i = 1, #subTree do
        local group = subTree[i]

        if group == 0 or #group == 0 then continue end
        children[i] = SubdivideGroup(group, depth + 1)
    end

    -- Call back the minimum quad extent
    for i = 1, #children do
        local child = children[i]
        if not child then continue end
        local childRect = child.rect
        rect.minX = (rect.minX < childRect.minX) and rect.minX or childRect.minX
        rect.maxX = (rect.maxX > childRect.maxX) and rect.maxX or childRect.maxX
        rect.minY = (rect.minY < childRect.minY) and rect.minY or childRect.minY
        rect.maxY = (rect.maxY > childRect.maxY) and rect.maxY or childRect.maxY
    end
    children.type = subTree.type
    return {children = children, rect = rect, deepest = false}
end

--#endregion

--#region Rect shape subdivision handlers
function DivideNodesVertically(nodes, center)
    local subTree1, subTree2 = {}, {}
    local count1, count2 = 0, 0


    for i = 1, #nodes do
        local v = nodes[i]

        if v.x < center then
            count1 = count1 + 1
            subTree1[count1] = v
        else
            count2 = count2 + 1
            subTree2[count2] = v
        end
    end

    return { subTree1, subTree2, type = 1 }
end

function DivideNodesHorizontally(nodes, center)
    local subTree1, subTree2 = {}, {}
    local count1, count2 = 0, 0

    for i = 1, #nodes do
        local v = nodes[i]

        if v.y < center then
            count1 = count1 + 1
            subTree1[count1] = v
        else
            count2 = count2 + 1
            subTree2[count2] = v
        end
    end

    return { subTree1, subTree2, type = 2 }
end

function DivideNodesVerticallyAndHorizontally(nodes, center)
    local subTree1, subTree2, subTree3, subTree4 = {}, {}, {}, {}
    local count1, count2, count3, count4 = 0, 0, 0, 0

    local centerY = center.y

    for i = 1, #nodes do
        local v = nodes[i]
        local y = v.y
        if v.x < center.x then
            if y < centerY then
                count1 = count1 + 1
                subTree1[count1] = v
            else
                count2 = count2 + 1
                subTree2[count2] = v
            end
        else
            if y < centerY then
                count3 = count3 + 1
                subTree3[count3] = v
            else
                count4 = count4 + 1
                subTree4[count4] = v
            end
        end
    end
    return { subTree1, subTree2, subTree3, subTree4, type = 3 }
end
--#endregion

--#region Circle collision
function CircleCollisionOnStructure(pos, radius)
    local results = {}
    CircleCollisionsOnBranch(pos, radius, NodeTree, results)
    return results
end

function CircleCollisionsOnBranch(position, radius, branch, results)
    if not branch then return end
    
    if branch.deepest then
        -- Deepest level: Test if within the bounding squares of individual nodes
        local nodes = branch.children

        for i = 1, #nodes do
            local node = nodes[i]
            --SpawnCircle(node, 15, White(), 0.04)

            CircleCollisionOnLinks(position, radius, node, results)

        end
        --HighlightExtents(branch.rect, 0.06, Red())
        return
    end
    
    
    local x = position.x
    local y = position.y
    local rect = branch.rect
    local children = branch.children


    
    for i = 1, #children do
        local child = children[i]
        if not child then continue end
        local childRect = child.rect
        local minX = childRect.minX
        local minY = childRect.minY
        local maxX = childRect.maxX
        local maxY = childRect.maxY

        if x > minX - radius and x < maxX + radius and y > minY - radius and y < maxY + radius then
            CircleCollisionsOnBranch(position, radius, child, results)

        end
    end


end



--TODO - this function is being called twice, please fix, also cache normals
-- It may not be feasible to check if a link is already tested, as the cost of checking may be greater than the cost of testing
-- Perhaps we could fix it further up the pipeline?
function CircleCollisionOnLinks(position, radius, node, results)
    for _, link in pairs(node.links) do
        -- --SpawnLine(node, link.node, White(), 0.06)



        local positionX = position.x
        local positionY = position.y
        local nodeA = node
        local nodeB = link.node
        local nodeAX = nodeA.x
        local nodeAY = nodeA.y
        local nodeBX = nodeB.x
        local nodeBY = nodeB.y
        -- Now you might be thinking to yourself, "DeltaWing, this is actually fucking disgusting", and you'd be correct. However, metatables are horrifically slow, and because
        -- lua is interpreted it is unfortunately much faster to manually type out everything, no matter how soul crushing that may be. Not to mention unreadable.
        -- But it's fast at least!
        local linkX, linkY = nodeBX - nodeAX, nodeBY - nodeAY
        local posToNodeAX, posToNodeAY = nodeAX - positionX, nodeAY - positionY
        local posToNodeBX, posToNodeBY = nodeBX - positionX, nodeBY - positionY

        
    
    
        


        --SpawnLine(nodeA, nodeB, Green(), 0.06)
        local linkPerpX, linkPerpY = -linkY, linkX


        local crossDistToNodeA = posToNodeAX * linkPerpY - posToNodeAY * linkPerpX
        local crossDistToNodeB = posToNodeBX * linkPerpY - posToNodeBY * linkPerpX

        if (crossDistToNodeA > 0) then
            local posToNodeASquaredX = posToNodeAX * posToNodeAX
            local posToNodeASquaredY = posToNodeAY * posToNodeAY
            if posToNodeASquaredX + posToNodeASquaredY > radius * radius then continue end
            local dist = -math.sqrt(posToNodeASquaredX + posToNodeASquaredY)
            local linkNormalX = posToNodeAX / dist
            local linkNormalY = posToNodeAY / dist
            results[#results + 1] = {nodeA = nodeA, nodeB = nodeB, normal = {x = linkNormalX, y = linkNormalY}, pos = {x = nodeA.x, y = nodeA.y}, distance = dist, material = link.material, type = 2}
            continue
        end
        if (crossDistToNodeB < 0) then
            local posToNodeBSquaredX = posToNodeBX * posToNodeBX
            local posToNodeBSquaredY = posToNodeBY * posToNodeBY
            if posToNodeBSquaredX + posToNodeBSquaredY > radius * radius then continue end
            local dist = -math.sqrt(posToNodeBSquaredX + posToNodeBSquaredY)
            local linkNormalX = posToNodeBX / dist
            local linkNormalY = posToNodeBY / dist
            results[#results + 1] = {nodeA = nodeA, nodeB = nodeB, normal = {x = linkNormalX, y = linkNormalY}, pos = {x = nodeB.x, y = nodeB.y}, distance = dist, material = link.material, type = 2}
            continue
        end
        
        local mag = math.sqrt(linkX * linkX + linkY * linkY)
        local linkNormalX, linkNormalY = linkY / mag, -linkX / mag
        
        local dist = -posToNodeAX * linkNormalX + -posToNodeAY * linkNormalY -- dot product (can't have nice things)
        if dist < 0 then
            dist = -dist
            linkNormalX = -linkNormalX
            linkNormalY = -linkNormalY
        end
        
        if dist < radius then 
            local distToNodeA = posToNodeAX * linkNormalY - posToNodeAY * linkNormalX
            local distToNodeB = posToNodeBX * linkNormalY - posToNodeBY * linkNormalX
           
            
            -- Collision case 1: Circle is intersecting with the link

            local totalDist = -distToNodeA + distToNodeB
            local t = -distToNodeA / totalDist
            local posX, posY = nodeAX + linkX * t, nodeAY + linkY * t

            results[#results + 1] = {nodeA = nodeA, nodeB = nodeB, normal = {x = linkNormalX, y = linkNormalY}, pos = {x = posX, y = posY}, distance = dist, material = link.material, type = 1}
            continue
        end
    end
end
--#endregion

--#region Utility
function GetNodeRectangle(nodes)
    local huge = math.huge
    local count = #nodes
    local minX, minY, maxX, maxY = huge, huge, -huge, -huge
    local averageX, averageY = 0, 0


    for i = 1, count do
        local v = nodes[i]
        local x, y = v.x, v.y

        -- Update sums for average
        averageX = averageX + x
        averageY = averageY + y

        -- Update bounds
        minX = (x < minX) and x or minX
        maxX = (x > maxX) and x or maxX

        minY = (y < minY) and y or minY
        maxY = (y > maxY) and y or maxY
    end



    return {
        minX = minX,
        minY = minY,
        maxX = maxX,
        maxY = maxY,
        width = maxX - minX,
        height = maxY - minY,
        x = averageX / count,
        y = averageY / count,
        count = count
    }
end

function GetIndiceCount(input)
    local count = 0
    for k, v in pairs(input) do
        count = count + 1
    end
    return count
end

function GetNodeGroupExtendedFamily(nodes)
    local extendedFamily = {}


    for i = 1, #nodes do
        local node = nodes[i]
        extendedFamily[node.id] = node
        for to, link in pairs(node.links) do
            extendedFamily[to] = link.node
        end
    end
    return extendedFamily
end

function GetAveragePosOfNodes(nodes)
    local averageX = 0
    local averageY = 0
    local count = 0

    for i = 1, #nodes do
        local v = nodes[i]
        count = count + 1
        averageX = averageX + v.x
        averageY = averageY + v.y
        -- Vector addition is PAINFULLY slow
    end
    return { x = averageX / count, y = averageY / count }
end

function GetNodeRectanglePairs(nodes)
    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge


    for k, v in pairs(nodes) do
        if v.x < minX then
            minX = v.x
        elseif v.x > maxX then
            maxX = v.x
        end

        if v.y < minY then
            minY = v.y
        elseif v.y > maxY then
            maxY = v.y
        end
    end
    local width = maxX - minX
    local height = maxY - minY

    return { minX = minX, minY = minY, maxX = maxX, maxY = maxY, width = width, height = height }
end

function HighlightExtents(extents, duration, color)
    duration = duration or 0.06
    color = color or White()
    local topLeft = Vec3(extents.minX, extents.minY)
    local topRight = Vec3(extents.maxX, extents.minY)
    local bottomRight = Vec3(extents.maxX, extents.maxY)
    local bottomLeft = Vec3(extents.minX, extents.maxY)




    SpawnLine(topLeft, topRight, color, duration)
    SpawnLine(topRight, bottomRight, color, duration)
    SpawnLine(bottomRight, bottomLeft, color, duration)
    SpawnLine(bottomLeft, topLeft, color, duration)
end

function FlattenTable(input)
    local output = {}
    local index = 0
    for k, v in pairs(input) do
        index = index + 1
        output[index] = v
    end
    return output
end
--#endregion