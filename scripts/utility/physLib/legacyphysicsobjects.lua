local maxPhysicsStep = 8
local minimumVelocityPerSecond = 1


local defaultObjectDefinition = {

    springConst = 400,
    dampening = 20,
    DynamicFriction = 4,
    StaticFriction = 4,
}



function UpdatePhysicsObjects()

    local worldExtents = GetWorldExtents()
    local extents = {minX = worldExtents.MinX, minY = worldExtents.MinY, maxX = worldExtents.MaxX, maxY = worldExtents.MaxY}
    PhysicsObjectsTree = SubdividePoses(PhysicsObjects, extents)
    ProcessPhysicsObjects()

end


function RegisterPhysicsObject(pos, radius, velocity, objectDefinition, effectId)
    pos = pos or Vec3(0, 0, 0)
    radius = radius or (50 / 2)
    velocity = velocity or Vec3(0, 0, 0)
    objectDefinition = objectDefinition or defaultObjectDefinition
    local Object = {
        pos = pos,
        radius = radius,
        velocity = velocity,
        objectDefinition = objectDefinition,
        lastFramePos = pos,
        effectId = effectId
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



function ProcessPhysicsObjects()
    for i = 1, #PhysicsObjects do
        local Object = PhysicsObjects[i]
        Object.lastFramePos = Object.pos
    end

    for i = 1, #PhysicsObjects do
        local Object = PhysicsObjects[i]
        local velocity = Object.velocity
        local radius = Object.radius
        local physicsStep = math.clamp(math.ceil((Vec2Mag(velocity) * data.updateDelta) / (radius)), 1, maxPhysicsStep)
        local delta = data.updateDelta / physicsStep
        -- Physics steps
        for k = 1, physicsStep do
            -- Euler integration
            Object.pos = Object.pos + (delta * 0.5 * Object.velocity)
            Object.velocity.y = Object.velocity.y + Gravity * delta
            Object.pos = Object.pos + (delta * 0.5 * Object.velocity)
            --SpawnCircle(Object.pos, Object.radius, Red(), 0.06)


            local velocity = Object.velocity

            -- Other objects
            local collidingObjects = GetOtherCollidingObjects(Object)

            for j = 1, #collidingObjects do
                local collidingObject = collidingObjects[j]

                local velocity = Object.velocity
                local collidingVelocity = collidingObject.velocity
                local relativeVelocity = velocity - collidingVelocity

                local objectToCollidingObject = collidingObject.pos - Object.pos
                local distance = objectToCollidingObject.length
                local normal = Vec3(objectToCollidingObject.x / distance, objectToCollidingObject.y / distance, 0)

                local displacement = Object.radius + collidingObject.radius - distance

                local displacementVector = displacement * normal

                Object.pos = Object.pos - {x = displacementVector.x / 2, y = displacementVector.y / 2, z = 0}
                collidingObject.pos = {x = collidingObject.pos.x + displacementVector.x / 2, y = collidingObject.pos.y + displacementVector.y / 2, z = 0}

                Object.velocity = velocity - Vec2Dot(relativeVelocity, normal) / 2 * normal
                collidingObject.velocity = collidingVelocity + Vec2Dot(relativeVelocity, normal) / 2 * normal

            end


            -- Structure filtering
            local snapResults = StructureCircleCollision(Object.pos, Object.radius)


            local noBackgroundResults = {}
            local portalResults = {}
            for j = 1, #snapResults do
                local snapResult = snapResults[j]
                if snapResult.material == "backbracing" then
                    continue
                end
                if snapResult.material == "portal" and snapResult.type == 1 then
                    portalResults[#portalResults + 1] = snapResult
                    continue
                end
                noBackgroundResults[#noBackgroundResults + 1] = snapResult
            end
            local filteredResults = {}
            for j = 1, #noBackgroundResults do
                local snapResult = noBackgroundResults[j]
                if snapResult.type == 1 then
                    
                    filteredResults[#filteredResults + 1] = snapResult
                end
            end
            if #filteredResults == 0 then
                filteredResults = noBackgroundResults
            end
            local lastFramePos = Object.lastFramePos








            -- Structure
            for j = 1, #filteredResults do
                
                -- Snap result
                local snapResult = filteredResults[j]

                local materialSaveName = snapResult.material
                local snapResultPos = snapResult.pos
                local snapResultNormal = snapResult.normal
                local snapResultDistance = snapResult.distance
                local nodeA = snapResult.nodeA
                local nodeB = snapResult.nodeB
                local t = snapResult.t

                -- object
                local objectPos = Object.pos
                local objectRadius = Object.radius

                -- Definitions
                local linkDefinition = LinkDefinitions[materialSaveName]
                local objectDefinition = Object.objectDefinition


                local normal = Vec3(snapResultNormal.x, snapResultNormal.y, 0)
                
                -- Keep the normal from the previous frame to help reduce clipping
                local lastFramePosToSnapPos = {x = snapResultPos.x - lastFramePos.x, y = snapResultPos.y - lastFramePos.y}
                local platformVelocity = Vec2Lerp(NodeVelocity(nodeA.id), NodeVelocity(nodeB.id), t)
                local parallel = Vec3(normal.y, -normal.x, 0)
                normal = Vec2Dot(lastFramePosToSnapPos, normal) > 0 and -normal or normal

                -- Apply conveyor frame of reference shift
                velocity = velocity - platformVelocity + linkDefinition.ConveyorSpeed * parallel



                local velocityPerpToSurface = Vec2Dot(velocity, normal)
                local velocityParallelToSurface = Vec2Dot(velocity, parallel)
                
                
                local error = objectRadius - snapResultDistance


                -- Rigid force
                objectPos.x = objectPos.x + error * normal.x
                objectPos.y = objectPos.y + error * normal.y
                velocity = velocity - velocityPerpToSurface * normal

                local gravityFriction = -Gravity * normal.y / 1000
                -- Dynamic friction
                local force = -
                objectDefinition.DynamicFriction * linkDefinition.DynamicFriction * gravityFriction * velocityParallelToSurface *
                parallel
                velocity = velocity + delta * force
                -- Return back to world frame
                velocity = velocity + platformVelocity - linkDefinition.ConveyorSpeed * parallel
                -- Set velocity
                Object.velocity = velocity

                -- Static friction
                if (math.abs(velocityParallelToSurface) < (objectDefinition.StaticFriction * linkDefinition.StaticFriction * gravityFriction)) then
                    Object.velocity = velocity - velocityParallelToSurface * parallel
                end
            end






            -- Portals
            for j = 1, #portalResults do
                Object.InterpolateThisFrame = false
                local snapResult = portalResults[j]
                
                local nodeA = snapResult.nodeA
                local nodeB = snapResult.nodeB

                local nodeIdA = nodeA.id
                local nodeIdB = nodeB.id
                
                local destinationA = GetPortalDestinationA(nodeIdA, nodeIdB)
                local destinationB = GetPortalDestinationB(nodeIdA, nodeIdB)


                if destinationA == 0 then continue end
                local destinationANode = NodesRaw[destinationA]
                local destinationBNode = NodesRaw[destinationB]

                local destinationLink = destinationBNode - destinationANode
                local destinationLinkLength = destinationLink.length
                local destinationLinkPerp = Vec3(destinationLink.y / destinationLinkLength, -destinationLink.x / destinationLinkLength, 0)
                local destinationLinkParallel = Vec3(destinationLink.x / destinationLinkLength, destinationLink.y / destinationLinkLength, 0)

                local originalPortalLink = nodeB - nodeA
                local originalPortalLinkLength = originalPortalLink.length
                local originalPortalLinkParallel = Vec3(originalPortalLink.x / originalPortalLinkLength, originalPortalLink.y / originalPortalLinkLength, 0)
                local originalPortalLinkPerp = Vec3(originalPortalLinkParallel.y, -originalPortalLinkParallel.x, 0)

                local portalSideSign = Vec2Dot(originalPortalLinkPerp, Object.pos - nodeA) > 0 and 1 or -1



                local destinationPos = Vec2Lerp(destinationANode, destinationBNode, snapResult.t)
                destinationPos = {x = destinationPos.x - destinationLinkPerp.x * (Object.radius + 0.01) * portalSideSign, y = destinationPos.y - destinationLinkPerp.y * (Object.radius + 0.01) * portalSideSign, z = 0}
                Object.pos = destinationPos



                local velocityParallel = Vec2Dot(velocity, originalPortalLinkParallel)
                local velocityPerp = Vec2Dot(velocity, originalPortalLinkPerp)

                local destinationVelocity = velocityParallel * destinationLinkParallel + velocityPerp * destinationLinkPerp
                Object.velocity = destinationVelocity
                break -- only do one portal per frame
            end

            -- local objectVelocity = Object.velocity
            -- if objectVelocity.x * objectVelocity.x + objectVelocity.y * objectVelocity.y * delta < minimumVelocityPerSecond * minimumVelocityPerSecond then
            --     Object.velocity = Vec3(0, 0, 0)
            -- end
        end
        --SpawnCircle(Object.pos, Object.radius, White(), 0.06)
    end
end



function SubdividePoses(objects, extents)
    if #objects <= 2 or extents.maxY - extents.minY < MaxRadius or extents.maxX - extents.minX < MaxRadius then return {children = objects, leaf = true} end

    local subA = {}
    local subB = {}
    local subC = {}
    local subD = {}

    local center = Vec3((extents.minX + extents.maxX) / 2, (extents.minY + extents.maxY) / 2)
    extents.center = center

    for i = 1, #objects do
        local object = objects[i]
        local pos = object.pos
        if pos.x < center.x then
            if pos.y < center.y then
                subA[#subA + 1] = object
            else
                subB[#subB + 1] = object
            end
        else
            if pos.y < center.y then
                subC[#subC + 1] = object
            else
                subD[#subD + 1] = object
            end
        end
    end

    subA = SubdividePoses(subA, {minX = extents.minX, minY = extents.minY, maxX = center.x, maxY = center.y})
    subB = SubdividePoses(subB, {minX = extents.minX, minY = center.y, maxX = center.x, maxY = extents.maxY})
    subC = SubdividePoses(subC, {minX = center.x, minY = extents.minY, maxX = extents.maxX, maxY = center.y})
    subD = SubdividePoses(subD, {minX = center.x, minY = center.y, maxX = extents.maxX, maxY = extents.maxY})

    return {children = {subA, subB, subC, subD}, rect = extents, leaf = false}
end


function GetOtherCollidingObjects(collider)
    local results = {}
    TestObjectOnObjectCollision(PhysicsObjectsTree, collider, results)
    return results
end

MaxRadius = 50 -- Placeholder
function TestObjectOnObjectCollision(branch, object, results)
    if branch.leaf then
        for i = 1, #branch.children do
            local other = branch.children[i]

            if other == object then continue end
            local otherObjectPos = other.pos
            local objectPos = object.pos
            local otherPosX = otherObjectPos.x
            local otherPosY = otherObjectPos.y
            local objectPosX = objectPos.x
            local objectPosY = objectPos.y

            local objectRadius = object.radius
            local otherRadius = other.radius

            local posAToPosBX, posAToPosBY = otherPosX - objectPosX, otherPosY - objectPosY
            local distSquared = posAToPosBX * posAToPosBX + posAToPosBY * posAToPosBY
            local combinedRadius = objectRadius + otherRadius
            combinedRadius = combinedRadius * combinedRadius
            if distSquared < combinedRadius then
                results[#results + 1] = other
            end
        end
        return
    end
    local pos = object.pos
    local x = pos.x
    local y = pos.y
    local radius = object.radius

    local center = branch.rect.center
    local centerX = center.x
    local centerY = center.y
    local subTrees = branch.children
    if x < centerX + radius + MaxRadius then
        if y < centerY + radius + MaxRadius then
            TestObjectOnObjectCollision(subTrees[1], object, results)
        end
        if y > centerY - radius - MaxRadius then
            TestObjectOnObjectCollision(subTrees[2], object, results)
        end
    end
    if x > centerX - radius - MaxRadius then
        if y < centerY + radius + MaxRadius then
            TestObjectOnObjectCollision(subTrees[3], object, results)
        end
        if y > centerY - radius - MaxRadius then
            TestObjectOnObjectCollision(subTrees[4], object, results)
        end
    end

end