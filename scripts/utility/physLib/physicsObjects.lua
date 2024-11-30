--scripts/utility/physLib/physicsObjects.lua
PhysicsObjects = {}
PhysicsObjectsTree = {}

function UpdatePhysicsObjects()
    CalculateObjectsExtents(PhysicsObjects)
    --PhysicsObjectsTree = GenerateObjectTree(PhysicsObjects)


    local delta = data.updateDelta
    for i = 1, #PhysicsObjects do
        local Object = PhysicsObjects[i]
        ProcessPhysicsObject(Object, delta)
    end
end


function ProcessPhysicsObject(object, delta)

    local objectPos = object.pos
    object.lastFramePos = object.pos
    objectPos.x = objectPos.x + (delta* 0.5 * object.velocity.x)
    objectPos.y = objectPos.y + (delta* 0.5 * object.velocity.y)
    object.velocity.y = object.velocity.y + Gravity * delta
    objectPos.x = objectPos.x + (delta* 0.5 * object.velocity.x)
    objectPos.y = objectPos.y + (delta* 0.5 * object.velocity.y)

    object.nextPos = {x = object.pos.x + object.velocity.x * delta, y = object.pos.y + object.velocity.y * delta}

    HighlightCapsule(object.pos, object.nextPos, object.radius)

    local structureCollisionResults = CapsuleCollisionOnStructure(object.pos, object.nextPos, object.radius)

    local noBackgroundResults = {}
    local portalResults = {}
    local filteredResults = {}
    for j = 1, #structureCollisionResults do
        local snapResult = structureCollisionResults[j]
        if snapResult.material == "backbracing" then
            continue
        end
        if snapResult.material == "portal" and snapResult.type == 1 then
            portalResults[#portalResults + 1] = snapResult
            continue
        end
        noBackgroundResults[#noBackgroundResults + 1] = snapResult
    end
    
    for j = 1, #noBackgroundResults do
        local snapResult = noBackgroundResults[j]
        if snapResult.type == 1 then
            
            filteredResults[#filteredResults + 1] = snapResult
        end
    end
    if #filteredResults == 0 then
        filteredResults = noBackgroundResults
    end

    local posResolution = {}
    local velResolution = {}
    local earliestResult = GetEarliestResult(filteredResults)
    if not earliestResult then return end
    for i = 1, #filteredResults do
        BreakStructureCollisionResult(object, filteredResults[i], earliestResult.time, posResolution, velResolution)
    end
    local averagePosResolution = Vec2Average(posResolution)
    local averageVelResolution = Vec2Average(velResolution)

    object.pos.x = object.pos.x + averagePosResolution.x
    object.pos.y = object.pos.y + averagePosResolution.y
    object.velocity.x = object.velocity.x + averageVelResolution.x
    object.velocity.y = object.velocity.y + averageVelResolution.y
end

function GetEarliestResult(results)
    local earliestResult = nil
    local earliestTime = math.huge

    for i = 1, #results do
        local result = results[i]
        if result.time < earliestTime then
            earliestTime = result.time
            earliestResult = result
        end
    end
    return earliestResult
end


local maxTimeWindow = 0.1
function BreakStructureCollisionResult(object, result, earliestTime, posResolution, velResolution)

    if result.time > earliestTime + maxTimeWindow then return end
    local objectPos = object.pos
    local objectNextPos = object.nextPos
    local velocity = object.velocity
    local radius = object.radius
    local normal = result.normal
    local resultPos = result.pos
    local testPos = result.testPos
    local dist = result.distance

    local velocityPerpToSurface = Vec2Dot(velocity, normal)
    local error = radius - dist

    posResolution[#posResolution+1] = {x = error * normal.x, y = error * normal.y}
    velResolution[#velResolution+1] = {x = -velocityPerpToSurface * normal.x, y = -velocityPerpToSurface * normal.y}

    -- objectNextPos.x = objectNextPos.x + error * normal.x
    -- objectNextPos.y = objectNextPos.y + error * normal.y
    -- velocity.x = velocity.x - velocityPerpToSurface * normal.x
    -- velocity.y = velocity.y - velocityPerpToSurface * normal.y
                
end

local defaultObjectDefinition = {

    springConst = 400,
    dampening = 20,
    DynamicFriction = 4,
    StaticFriction = 4,
}

function RegisterPhysicsObject(pos, radius, velocity, objectDefinition, effectId)
    pos = pos or Vec3(0, 0, 0)
    radius = radius or (50 / 2)
    velocity = velocity or Vec3(0, 0, 0)
    objectDefinition = objectDefinition or defaultObjectDefinition
    local Object = {
        pos = pos,
        nextPos = pos,
        prevPos = pos,
        radius = radius,
        velocity = velocity,
        objectDefinition = objectDefinition,
        lastFramePos = pos,
        effectId = effectId,
        extents = {}
    }
    PhysicsObjects[#PhysicsObjects + 1] = Object
    BetterLog(#PhysicsObjects)
    return Object
end
function UnregisterPhysicsObject(Object)
    for i = 1, #PhysicsObjects do
        if PhysicsObjects[i] == Object then
            table.remove(PhysicsObjects, i)
            BetterLog(#PhysicsObjects)
            return
        end
    end
end


TestObject = {
    x = 0,
    y = 0,
    nextX = 0,
    nextY = 0,
    radius = 50 / 2,
    velocity = Vec3(0, 0, 0),
    effectId = 0,
    extents = {minX = -1000, minY = -1000, maxX = 1000, maxY = 1000}


}

function CalculateObjectsExtents(Objects)
    for i = 1, #Objects do
        CalculateObjectExtents(Objects[i])
    end
end

function CalculateObjectExtents(object)
    local radius = object.radius
    local pos = object.pos
    local nextPos = object.nextPos
    local posX = pos.x
    local posY = pos.y
    local nextPosX = nextPos.x
    local nextPosY = nextPos.y

    local minX = (posX < nextPosX and posX or nextPosX) - radius
    local minY = (posY < nextPosY and posY or nextPosY) - radius
    local maxX = (posX > nextPosX and posX or nextPosX) + radius
    local maxY = (posY > nextPosY and posY or nextPosY) + radius

    object.extents = {minX = minX, minY = minY, maxX = maxX, maxY = maxY, center = {x = (minX + maxX) / 2, y = (minY + maxY) / 2}}

end


function GenerateObjectTree(objects)
    if #objects == 0 then return end
    -- TODO: move SubdivideGroup to it's own file
    return SubdivideObjects(objects, 0)
end






function SubdivideObjects(objects, depth)
    local rect = GetObjectRectangle(objects)
    local count = rect.count
    --Degenerate case: two nodes positioned mathematically perfectly on top of each other (this occurs when nodes rotate too far and split)
    if count <= 1 or rect.width + rect.height == 0 then

        rect = objects[1].extents
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
