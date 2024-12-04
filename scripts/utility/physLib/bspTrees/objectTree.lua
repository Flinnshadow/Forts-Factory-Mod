--scripts/utility/physLib/bspTrees/objectTree.lua
local Helper = PhysLib.BspTrees.Helper

PhysLib.BspTrees.ObjectsTree = {}
--#region Generation
function GenerateObjectTree(objects)
    if #objects == 0 then return end
    -- TODO: move SubdivideGroup to it's own file
    return SubdivideObjects(objects, 0)
end


local minCellSize = 5
function SubdivideObjects(objects, depth)

    local rect = GetObjectRectangle(objects)
    -- if depth < 15 then -- Do additional checks because we might have a problem

    --     rect = objects[1].extents
    --     return {children = objects, rect = rect, deepest = true}
    -- end
    local count = rect.count
    --Degenerate case: two nodes positioned mathematically perfectly on top of each other (this occurs when nodes rotate too far and split)
    if count <= 1 or rect.width + rect.height < minCellSize then

        rect = objects[1].extents
        for i = 1, #objects do
            local object = objects[i]
            local objectExtents = object.extents
            rect.minX = (rect.minX < objectExtents.minX) and rect.minX or objectExtents.minX
            rect.maxX = (rect.maxX > objectExtents.maxX) and rect.maxX or objectExtents.maxX
            rect.minY = (rect.minY < objectExtents.minY) and rect.minY or objectExtents.minY
            rect.maxY = (rect.maxY > objectExtents.maxY) and rect.maxY or objectExtents.maxY
        end
        return {children = objects, rect = rect, deepest = true}
    end

    local widthHeightRatio = rect.width / rect.height

    local subTree
    
    if (widthHeightRatio > SDTYPE_BOTH_THRESHOLD_MAX) then
        --Divide vertically
        subTree = DivideObjectsV(objects, rect.x)
    elseif (widthHeightRatio < SDTYPE_BOTH_THRESHOLD_MIN) then
        --Divide horizontally
        subTree = DivideObjectsH(objects, rect.y)
    else
        --Divide both
        subTree = DivideObjectsVH(objects, rect)
    end
    local children = {}
    for i = 1, #subTree do
        local group = subTree[i]

        if group == 0 or #group == 0 then continue end
        children[i] = SubdivideObjects(group, depth + 1)
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
    --HighlightExtents(rect, 0.06, Blue())
    children.type = subTree.type
    return {children = children, rect = rect, deepest = false}
end


function DivideObjectsV(nodes, center)
    local subTree1, subTree2 = {}, {}
    local count1, count2 = 0, 0


    for i = 1, #nodes do
        local v = nodes[i]
        local pos = v.pos
        if pos.x < center then
            count1 = count1 + 1
            subTree1[count1] = v
        else
            count2 = count2 + 1
            subTree2[count2] = v
        end
    end

    return { subTree1, subTree2, type = 1 }
end

function DivideObjectsH(nodes, center)
    local subTree1, subTree2 = {}, {}
    local count1, count2 = 0, 0

    for i = 1, #nodes do
        local v = nodes[i]
        local pos = v.pos
        if pos.y < center then
            count1 = count1 + 1
            subTree1[count1] = v
        else
            count2 = count2 + 1
            subTree2[count2] = v
        end
    end

    return { subTree1, subTree2, type = 2 }
end

function DivideObjectsVH(nodes, center)
    local subTree1, subTree2, subTree3, subTree4 = {}, {}, {}, {}
    local count1, count2, count3, count4 = 0, 0, 0, 0

    local centerY = center.y

    for i = 1, #nodes do
        local v = nodes[i]
        local pos = v.pos
        local y = pos.y
        local pos = v.pos
        if pos.x < center.x then
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




function GetObjectRectangle(objects)
    local huge = math.huge
    local count = #objects
    local minX, minY, maxX, maxY = huge, huge, -huge, -huge
    local averageX, averageY = 0, 0


    for i = 1, count do
        local v = objects[i]
        local pos = v.pos
        local x, y = pos.x, pos.y

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

--#endregion
--#region CircleCast
function PhysLib.BspTrees.ObjectTree:ObjectCast(object)
    local results = {}
    self:GetObjectsCollidingWithObjectBranch(object, self.ObjectsTree, results)
    local finalResults = {}
    for i = 1, #results do
        local result = results[i]
        local otherObject = result.object
        local timeObject = result.timeObject
        local timeOther = result.timeOther
        local requiredDistance = result.requiredDistance

        local objectAStart = object.lastFramePos
        local objectAStartX = objectAStart.x
        local objectAStartY = objectAStart.y
        local objectAEnd = object.pos
        local objectAEndX = objectAEnd.x
        local objectAEndY = objectAEnd.y
        local objectBStart = otherObject.lastFramePos
        local objectBStartX = objectBStart.x
        local objectBStartY = objectBStart.y
        local objectBEnd = otherObject.pos
        local objectBEndX = objectBEnd.x
        local objectBEndY = objectBEnd.y
        

        local objectAPositionATimeX = objectAStartX + (objectAEndX - objectAStartX) * timeObject
        local objectAPositionATimeY = objectAStartY + (objectAEndY - objectAStartY) * timeObject

        local objectBPositionATimeX = objectBStartX + (objectBEndX - objectBStartX) * timeObject
        local objectBPositionATimeY = objectBStartY + (objectBEndY - objectBStartY) * timeObject

        local APosATimeToBPosATimeX = objectBPositionATimeX - objectAPositionATimeX
        local APosATimeToBPosATimeY = objectBPositionATimeY - objectAPositionATimeY

        local AToBATime = APosATimeToBPosATimeX * APosATimeToBPosATimeX + APosATimeToBPosATimeY * APosATimeToBPosATimeY
        

        if AToBATime < requiredDistance then
            local distance = math.sqrt(AToBATime)
            local normal = {x = -APosATimeToBPosATimeX / distance, y = -APosATimeToBPosATimeY / distance}

            finalResults[#finalResults + 1] = {object = otherObject, normal = normal, distance = distance, objectAPos = {x = objectAPositionATimeX, y = objectAPositionATimeY}, objectBPos = {x = objectBPositionATimeX, y = objectBPositionATimeY}}
            continue
        end
        local objectAPositionBTimeX = objectAStartX + (objectAEndX - objectAStartX) * timeOther
        local objectAPositionBTimeY = objectAStartY + (objectAEndY - objectAStartY) * timeOther

        local objectBPositionBTimeX = objectBStartX + (objectBEndX - objectBStartX) * timeOther
        local objectBPositionBTimeY = objectBStartY + (objectBEndY - objectBStartY) * timeOther

        local APosBTimeToBPosBTimeX = objectBPositionBTimeX - objectAPositionBTimeX
        local APosBTimeToBPosBTimeY = objectBPositionBTimeY - objectAPositionBTimeY

        local AToBBTime = APosBTimeToBPosBTimeX * APosBTimeToBPosBTimeX + APosBTimeToBPosBTimeY * APosBTimeToBPosBTimeY
        if AToBBTime < requiredDistance then
            local distance = math.sqrt(AToBBTime)
            local normal = {x = -APosBTimeToBPosBTimeX / distance, y = -APosBTimeToBPosBTimeY / distance}

            finalResults[#finalResults + 1] = {object = otherObject, normal = normal, distance = distance, objectAPos = {x = objectAPositionBTimeX, y = objectAPositionBTimeY}, objectBPos = {x = objectBPositionBTimeX, y = objectBPositionBTimeY}}
            continue
        end


    end

    return finalResults
end


function PhysLib.BspTrees.ObjectTree:GetObjectsCollidingWithObjectBranch(object, branch, results)
    if not branch then return end
    if branch.deepest then
        -- Deepest level: Test if within the bounding squares of individual nodes
        local objects = branch.children
        self:GetObjectsCollidingWithObject(object, objects, results)
        return
    end


    --HighlightExtents(rect, 0.06, Red())
    local children = branch.children
    for i = 1, #children do
        local childBranch = children[i]
        if not childBranch then continue end
        local childRect = childBranch.rect
        if Helper:LineCollidesWithRect(object.lastFramePos, object.pos, object.radius, childRect) then
            self:GetObjectsCollidingWithObjectBranch(object, childBranch, results)
        end
    end
end

function PhysLib.BspTrees.ObjectTree:GetObjectsCollidingWithObject(object, objects, results)
    for i = 1, #objects do
        local otherObject = objects[i]
        if otherObject == object then continue end

        local objectA1 = object.lastFramePos
        local objectA2 = object.pos
        local objectB1 = otherObject.lastFramePos
        local objectB2 = otherObject.pos
        local combinedRadius = object.radius + otherObject.radius
        local requiredDistance = combinedRadius * combinedRadius
        local timeObject, timeOther, closestDistance = Helper:ClosestPointsBetweenLines(objectA1, objectA2, objectB1, objectB2)
        
        if closestDistance < requiredDistance then
            results[#results + 1] = { object = otherObject, timeObject = timeObject, timeOther = timeOther, requiredDistance = requiredDistance}
        end
    end
end
--#endregion

