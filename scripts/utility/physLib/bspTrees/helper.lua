--scripts/utility/physLib/bspTrees/helper.lua




local INSIDE = 0
local LEFT = 1
local RIGHT = 2
local BOTTOM = 4
local TOP = 8

local function ComputeCode(x, y, rect, radius)
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
function PhysLib.BspTrees.Helper:LineCollidesWithRect(posA, posB, radius, rect)
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


function PhysLib.BspTrees.Helper:ClosestPointOnLineSegment(A, B, point)
    local ABX, ABY = B.x - A.x, B.y - A.y
    local t = ((point.x - A.x) * ABX + (point.y - A.y) * ABY) / (ABX * ABX + ABY * ABY)

    t = math.min(math.max(t, 0), 1)
    return {x = A.x + t * ABX, y = A.y + t * ABY}
end



local reusedCandidates = {-1, -1, 1, -1, -1, 1, 0, -1, -1, 0, 0, 0, 0, 1, 1, 0, 1, 1}
local reusedFilteredList = {}
function PhysLib.BspTrees.Helper:ClosestPointsBetweenLines(A1, A2, B1, B2)

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

    return bestCandidate1, bestCandidate2, bestDistance
end