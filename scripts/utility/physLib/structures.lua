--scripts/utility/physLib/structures.lua

--#region Enumeration callback
---@diagnostic disable-next-line: lowercase-global
function c(idA, idB, linkPos, saveName)
    -- TODO: Optimize this to not get the savename in enumerate links as this is slow and most of the time not useful, instead the savename should be collected and then cached by the next thing
    -- to say it is colliding with the link
    --local saveName = GetLinkMaterialSaveName(nodeA, nodeB)
    local nodesRaw = NodesRaw
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
    local links = Links
    local nodesRaw = NodesRaw
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
-- function UpdateLinkPosition(link)
--     local nodeA = link.nodeA
--     local nodeB = link.nodeB
--     local linksRaw = LinksRaw
--     local nodeAx, nodeAy, nodeBx, nodeBy = nodeA.x, nodeA.y, nodeB.x, nodeB.y


--     local minX, minY, maxX, maxY
--     if nodeAx < nodeBx then
--         minX = nodeAx
--         maxX = nodeBx
--     else
--         minX = nodeBx
--         maxX = nodeAx
--     end
--     if nodeAy < nodeBy then
--         minY = nodeAy
--         maxY = nodeBy
--     else
--         minY = nodeBy
--         maxY = nodeAy
--     end

--     link.minX = minX
--     link.minY = minY
--     link.maxX = maxX
--     link.maxY = maxY
--     local linkPos = link.pos
--     pos.x = (minX + maxX) / 2
--     pos.y = (minY + maxY) / 2



--     local link = {nodeA = nodeA, nodeB = nodeB, material = material, minX = minX, minY = minY, maxX = maxX, maxY = maxY, pos = linkPos}
--     linksRaw[#linksRaw + 1] = link
-- end

--#endregion

--#region Subdivision

function SubdivideStructures()
    --for i = 1, 50 do
   --NodeTree = SubdivideNodeGroup(Nodes, 0)
   LinksTree = SubdivideLinkGroup(Links, 0)
    --end
end
SDTYPE_BOTH_THRESHOLD_MAX = 1.1
SDTYPE_BOTH_THRESHOLD_MIN = 1/SDTYPE_BOTH_THRESHOLD_MAX


function SubdivideLinkGroup(nodes, depth)
    local rect = GetLinkRectangle(nodes) -- Warning: extents are a ROUGH estimate!
    local count = rect.count
    --Degenerate case: two nodes positioned mathematically perfectly on top of each other (this occurs when nodes rotate too far and split)
    if count <= 1 or (rect.width * rect.height == 0) then
        rect = nodes[1]
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
        children[#children + 1] = SubdivideLinkGroup(group, depth + 1)
    end

    -- Call back the minimum quad extent
    for i = 1, #children do
        local child = children[i]
        local childRect = child.rect
        rect.minX = (rect.minX < childRect.minX) and rect.minX or childRect.minX
        rect.maxX = (rect.maxX > childRect.maxX) and rect.maxX or childRect.maxX
        rect.minY = (rect.minY < childRect.minY) and rect.minY or childRect.minY
        rect.maxY = (rect.maxY > childRect.maxY) and rect.maxY or childRect.maxY
        -- Spawn lines from each child corner to the parent corner


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

        -- Draw a line from child corners to parent corners
        
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
        CircleCollisionOnLink(position, radius, node, link.node, link, results)
    end
end

function CircleCollisionOnLink(position, radius, nodeA, nodeB, link, results, time)
    -- --SpawnLine(node, link.node, White(), 0.06)



    local positionX = position.x
    local positionY = position.y
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
        if posToNodeASquaredX + posToNodeASquaredY > radius * radius then return end
        local dist = math.sqrt(posToNodeASquaredX + posToNodeASquaredY)
        local linkNormalX = posToNodeAX / dist
        local linkNormalY = posToNodeAY / dist
        results[#results + 1] = { nodeA = nodeA, nodeB = nodeB, normal = { x = linkNormalX, y = linkNormalY }, pos = { x = nodeA.x, y = nodeA.y }, distance =
        dist, material = link.material, type = 2, t = 0, testPos = position, time = time }
        return
    end
    if (crossDistToNodeB < 0) then
        local posToNodeBSquaredX = posToNodeBX * posToNodeBX
        local posToNodeBSquaredY = posToNodeBY * posToNodeBY
        if posToNodeBSquaredX + posToNodeBSquaredY > radius * radius then return end
        local dist = math.sqrt(posToNodeBSquaredX + posToNodeBSquaredY)
        local linkNormalX = posToNodeBX / dist
        local linkNormalY = posToNodeBY / dist
        results[#results + 1] = { nodeA = nodeA, nodeB = nodeB, normal = { x = linkNormalX, y = linkNormalY }, pos = { x = nodeB.x, y = nodeB.y }, distance =
        dist, material = link.material, type = 2, t = 1, testPos = position, time = time }
        return
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

        results[#results + 1] = { 
            nodeA = nodeA, 
            nodeB = nodeB, 
            normal = { x = linkNormalX, y = linkNormalY }, 
            pos = { x = posX, y = posY }, 
            distance = dist, 
            material = link.material, 
            type = 1,
            t = t, 
            testPos = position, 
            time = time }
        return
    end
end
--#endregion