--#region Includes
dofile("scripts/forts.lua")

dofile(path .. "/scripts/utility/physLib/entrypoints.lua")
dofile(path .. "/scripts/utility/physLib/structures.lua")
dofile(path .. "/scripts/utility/physLib/physicsObjects.lua")
--#endregion

--#region Global tables

NodesRaw = {}
Nodes = {}
NodeTree = {}

--#endregion





--#region Capsule collision
function CapsuleCollisionOnStructure(posA, posB, radius)
    local results = {}
    CapsuleCollisionsOnBranch(posA, posB, radius, NodeTree, results)
    return results
end
function CapsuleCollisionsOnBranch(posA, posB, radius, branch, results)
    if not branch then return end
    if branch.deepest then
        -- Deepest level: Test if within the bounding squares of individual nodes
        local nodes = branch.children

        for i = 1, #nodes do
            local node = nodes[i]
            CapsuleCollisionOnLinks(posA, posB, radius, node, results)
        end
        return
    end

    local ax = posA.x
    local ay = posA.y
    local bx = posB.x
    local by = posB.y

    local rect = branch.rect
    HighlightExtents(rect, 0.06, Red())
    local children = branch.children
    for i = 1, #children do
        local child = children[i]
        if not child then continue end
        local childRect = child.rect

        if LineCollidesWithRect(posA, posB, radius, childRect) then
            CapsuleCollisionsOnBranch(posA, posB, radius, child, results)
        end
    end
end



local INSIDE = 0
local LEFT = 1
local RIGHT = 2
local BOTTOM = 4
local TOP = 8

function ComputeCode(x, y, rect, radius)
    local minX, minY = rect.minX - radius, rect.minY - radius
    local maxX, maxY = rect.maxX + radius, rect.maxY + radius
    
    local code = INSIDE

    if x < minX then
        code = code | LEFT
    elseif x > maxX then
        code = code | RIGHT
    end
    if y < minY then
        code = code | BOTTOM
    elseif y > maxY then
        code = code | TOP
    end

    return code
end

function LineCollidesWithRect(posA, posB, radius, rect)
    local x1, y1 = posA.x, posA.y
    local x2, y2 = posB.x, posB.y

    local minX, minY = rect.minX - radius, rect.minY - radius
    local maxX, maxY = rect.maxX + radius, rect.maxY + radius

    local codeA = ComputeCode(x1, y1, rect, radius)
    local codeB = ComputeCode(x2, y2, rect, radius)

    local accept = false

    while true do
        if codeA == 0 and codeB == 0 then
            -- Both are inside
            accept = true
            break
        elseif codeA & codeB ~= 0 then
            -- Both are outside
            break
        else
            -- Some segment of the line is inside

            local codeOut
            local x, y

            if codeA ~= 0 then
                codeOut = codeA
            else
                codeOut = codeB
            end

            if codeOut & TOP ~= 0 then
                x = x1 + (x2 - x1) * (maxY - y1) / (y2 - y1);
                y = maxY;
            elseif codeOut & BOTTOM ~= 0 then
                x = x1 + (x2 - x1) * (minY - y1) / (y2 - y1);
                y = minY;
            elseif codeOut & RIGHT ~= 0 then
                y = y1 + (y2 - y1) * (maxX - x1) / (x2 - x1);
                x = maxX;
            elseif codeOut & LEFT ~= 0 then
                y = y1 + (y2 - y1) * (minX - x1) / (x2 - x1);
                x = minX;
            end

            -- intersection point found

            if codeOut == codeA then
                x1 = x
                y1 = y
                codeA = ComputeCode(x1, y1, rect, radius)
            else
                x2 = x
                y2 = y
                codeB = ComputeCode(x2, y2, rect, radius)
            end
        end

    end
   
    if accept then 
        return true 
    else 
        return false 

    end
end


function ClosestPointOnLineSegment(A, B, point)


    
    local ABX, ABY = B.x - A.x, B.y - A.y
    local t = ((point.x - A.x) * ABX + (point.y - A.y) * ABY) / (ABX * ABX + ABY * ABY)

    t = math.min(math.max(t, 0), 1)
    return {x = A.x + t * ABX, y = A.y + t * ABY}
end

function ClosestPointsBetweenLines(A1, A2, B1, B2)
    local t1 = -(Vec3Dot(A1-B1, A2-A1) * Vec3Dot(B2-B1, B2-B1) - Vec3Dot(A1-B1, B2-B1) * Vec3Dot(A2-A1, B2-B1)) / (Vec2Cross(A2-A1, B2-B1) * Vec2Cross(A2-A1, B2-B1))
    local t2 = (Vec3Dot(A1-B1, A2-A1) + Vec3Dot(A2-A1, A2-A1) * t1) / Vec3Dot(B2-B1, A2-A1)
    local t3 = Vec3Dot(A2-B1, B2-B1) / Vec3Dot(B2-B1, B2-B1)
    local t4 = Vec3Dot(B2-A1, A2-A1) / Vec3Dot(A2-A1, A2-A1)
    local t5 = Vec3Dot(A1-B1, B2-B1) / Vec3Dot(B2-B1, B2-B1)
    local t6 = Vec3Dot(B1-A1, A2-A1) / Vec3Dot(A2-A1, A2-A1)
    
    local candidates = {{t1, t2}, {1, t3}, {t4, 1}, {0, t5}, {t6, 0}, {0, 0}, {0, 1}, {1, 0}, {1, 1}}
    local filteredList = {}

    for i = 1, #candidates do
        if 0 <= candidates[i][1] and candidates[i][1] <= 1 and 0 <= candidates[i][2] and candidates[i][2] <= 1 then
            filteredList[#filteredList + 1] = candidates[i]
        end
    end

    local LineA = function(t)
        return A1 + t * (A2-A1)
    end

    local LineB = function(t)
        return B1 + t * (B2-B1)
    end

    local DistanceSquared = function(s)
        local distance = LineA(s[1]) - LineB(s[2])
        return Vec3Dot(distance, distance)
    end 

    local bestCandidate = filteredList[1]
    local bestDistance = DistanceSquared(bestCandidate)

    for i = 2, #filteredList do
        local candidate = filteredList[i]
        local distance = DistanceSquared(candidate)

        if distance < bestDistance then
            bestCandidate = candidate
            bestDistance = distance
        end
    end
    return LineA(bestCandidate[1]), LineB(bestCandidate[2]), bestDistance
end

function CapsuleCollisionOnLinks(posA, posB, radius, node, results)
    for _, link in pairs(node.links) do
        local nodeA = node
        local nodeB = link.node
        
        local linkX, linkY = nodeB.x - nodeA.x, nodeB.y - nodeA.y

        local capsuleX, capsuleY = posB.x - posA.x, posB.y - posA.y

        local closestPointLink, closestPointCapsule = ClosestPointsBetweenLines(posA, posB, nodeA, nodeB)

        SpawnCircle(closestPointCapsule, radius, Red(), 0.06)
        SpawnCircle(closestPointLink, radius, Blue(), 0.06)
        SpawnLine(closestPointCapsule, closestPointLink, White(), 0.06)
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

function HighlightCapsule(posA, posB, radius)
    SpawnCircle(posA, radius, White(), 0.06)
    SpawnCircle(posB, radius, White(), 0.06)
    local lineUnit = Vec2Normalize(posB - posA)
    local linePerp = Vec2Perp(lineUnit)
    linePerp = Vec3(linePerp.x, linePerp.y, 0)
    SpawnLine(posA + radius * linePerp, posB + radius * linePerp, White(), 0.06)
    SpawnLine(posA - radius * linePerp, posB - radius * linePerp, White(), 0.06)

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



