--scripts/utility/physLib/physLib.lua


--#region Includes
dofile("scripts/forts.lua")

dofile(path .. "/scripts/utility/physLib/entrypoints.lua")
dofile(path .. "/scripts/utility/physLib/structures.lua")
dofile(path .. "/scripts/utility/physLib/physicsObjects.lua")
dofile(path .. "/scripts/utility/physLib/render.lua")
--#endregion

--#region Global tables

NodesRaw = {}
Nodes = {}
NodeTree = {}

Links = {}
LinksTree = {}
--#endregion





--#region Capsule collision
function CapsuleCollisionOnStructure(posA, posB, radius)
    local results = {}
    CapsuleCollisionsOnBranch(posA, posB, radius, LinksTree, results)
    return results
end
function CapsuleCollisionOnObjects(posA, posB, radius)
    local results = {}
    CapsuleCollisionsOnBranch(posA, posB, radius, ObjectCastTree, results)
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


    --HighlightExtents(rect, 0.06, Red())
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

local reusedCandidates = {-1, -1, 1, -1, -1, 1, 0, -1, -1, 0, 0, 0, 0, 1, 1, 0, 1, 1}
local reusedFilteredList = {}
function ClosestPointsBetweenLines(A1, A2, B1, B2)

    local candidates = reusedCandidates
    local filteredList = reusedFilteredList
    local A1x, A1y, A2x, A2y, B1x, B1y, B2x, B2y = A1.x, A1.y, A2.x, A2.y, B1.x, B1.y, B2.x, B2.y

    local A1SubB1x, A1SubB1y = A1x - B1x, A1y - B1y
    local A2SubA1x, A2SubA1y = A2x - A1x, A2y - A1y
    local A2SubB1x, A2SubB1y = A2x - B1x, A2y - B1y
    local B1SubA1x, B1SubA1y = B1x - A1x, B1y - A1y
    local B2SubA1x, B2SubA1y = B2x - A1x, B2y - A1y
    local B2SubB1x, B2SubB1y = B2x - B1x, B2y - B1y
    
    local A1SubB1DotA2SubA1 = A1SubB1x * A2SubA1x + A1SubB1y * A2SubA1y
    local B2SubB1Squared = B2SubB1x * B2SubB1x + B2SubB1y * B2SubB1y
    local A1SubB1DotB2SubB1 = A1SubB1x * B2SubB1x + A1SubB1y * B2SubB1y
    local AtSubA1DotB2SubB1 = A2SubA1x * B2SubB1x + A2SubA1y * B2SubB1y
    local A2SubA1CrossB2SubB1 = A2SubA1x * B2SubB1y - A2SubA1y * B2SubB1x
    local A2SubA1Squared = A2SubA1x * A2SubA1x + A2SubA1y * A2SubA1y
    local B2SubB1DotA2SubA1 = B2SubB1x * A2SubA1x + B2SubB1y * A2SubA1y
    local A2SubB1DotB2SubB1 = A2SubB1x * B2SubB1x + A2SubB1y * B2SubB1y
    local B2SubA1DotA2SubA1 = B2SubA1x * A2SubA1x + B2SubA1y * A2SubA1y
    local B1SubA1DotA2SubA1 = B1SubA1x * A2SubA1x + B1SubA1y * A2SubA1y



    local t1 = -(A1SubB1DotA2SubA1 * B2SubB1Squared - A1SubB1DotB2SubB1 * AtSubA1DotB2SubB1) / (A2SubA1CrossB2SubB1 * A2SubA1CrossB2SubB1)
    local t2 = (A1SubB1DotA2SubA1 + A2SubA1Squared * t1) / B2SubB1DotA2SubA1
    local t3 = A2SubB1DotB2SubB1 / B2SubB1Squared
    local t4 = B2SubA1DotA2SubA1 / A2SubA1Squared
    local t5 = A1SubB1DotB2SubB1 / B2SubB1Squared
    local t6 = B1SubA1DotA2SubA1 / A2SubA1Squared
    candidates[1] = t1
    candidates[2] = t2
    candidates[4] = t3
    candidates[5] = t4
    candidates[8] = t5
    candidates[9] = t6
    
    
    local candidateCount = 18
    local filteredListCount = 1
    for i = 1, candidateCount, 2 do
        if 0 <= candidates[i] and candidates[i] <= 1 and 0 <= candidates[i + 1] and candidates[i + 1] <= 1 then
            filteredList[filteredListCount] = candidates[i]
            filteredList[filteredListCount + 1] = candidates[i + 1]
            filteredListCount = filteredListCount + 2
        end
    end


    local bestCandidate1 = filteredList[1]
    local bestCandidate2 = filteredList[2]
    local distanceX = (A1x + bestCandidate1 * A2SubA1x) - (B1x + bestCandidate2 * B2SubB1x)
    local distanceY = (A1y + bestCandidate1 * A2SubA1y) - (B1y + bestCandidate2 * B2SubB1y)
    local bestDistance = distanceX * distanceX + distanceY * distanceY

    for i = 3, filteredListCount - 1, 2 do
        local candidate1 = filteredList[i]
        local candidate2 = filteredList[i + 1]
        local distanceX = (A1x + candidate1 * A2SubA1x) - (B1x + candidate2 * B2SubB1x)
        local distanceY = (A1y + candidate1 * A2SubA1y) - (B1y + candidate2 * B2SubB1y)


        local distance = distanceX * distanceX + distanceY * distanceY 

        if distance < bestDistance then
            bestCandidate1 = candidate1
            bestCandidate2 = candidate2
            bestDistance = distance
        end
    end
    local returnPosA = {x = A1x + bestCandidate1 * A2SubA1x, y = A1y + bestCandidate1 * A2SubA1y}
    local returnPosB = {x = B1x + bestCandidate2 * B2SubB1x, y = B1y + bestCandidate2 * B2SubB1y}
    return returnPosA, bestCandidate1, returnPosB, bestCandidate2, bestDistance
end

function CapsuleCollisionOnLinks(posA, posB, radius, link, results)
    local nodeA = link.nodeA
    local nodeB = link.nodeB

    local closestPointCapsule, closestPointCapsuleTime,
    closestPointLink, closestPointLinkTime,
    closestDistance = ClosestPointsBetweenLines(posA, posB, nodeA, nodeB)
    if closestDistance > radius * radius then return end
    CircleCollisionOnLink(closestPointCapsule, radius, nodeA, nodeB, link, results, closestPointCapsuleTime)
end
--#endregion

--#region Utility
function GetLinkRectangle(nodes)
    local huge = math.huge
    local count = #nodes
    local minX, minY, maxX, maxY = huge, huge, -huge, -huge
    local averageX, averageY = 0, 0

    local boundCheckInterval = 10
    local boundCheckCounter = 9

    for i = 1, count do
        local v = nodes[i]
        local x, y = v.x, v.y

        -- Update sums for average
        averageX = averageX + x
        averageY = averageY + y

        boundCheckCounter = boundCheckCounter + 1
        if boundCheckCounter == boundCheckInterval then
            boundCheckCounter = 0
            -- Update bounds
            minX = (x < minX) and x or minX
            maxX = (x > maxX) and x or maxX

            minY = (y < minY) and y or minY
            maxY = (y > maxY) and y or maxY
        end
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
    local lineUnit = Vec2Normalize({ x = posB.x - posA.x, y = posB.y - posA.y})
    local linePerp = Vec2Perp(lineUnit)
    linePerp = Vec3(linePerp.x, linePerp.y, 0)

    
    SpawnLine({x = posA.x + radius * linePerp.x, y = posA.y + radius * linePerp.y}, {x = posB.x + radius * linePerp.x, y = posB.y + radius * linePerp.y}, White(), 0.06)
    SpawnLine({x = posA.x - radius * linePerp.x, y = posA.y - radius * linePerp.y}, {x = posB.x - radius * linePerp.x, y = posB.y - radius * linePerp.y}, White(), 0.06)

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



