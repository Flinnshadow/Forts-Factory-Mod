local maxPhysicsStep = 8


local defaultObjectDefinition = {

    springConst = 400,
    dampening = 20,
    DynamicFriction = 4,
    StaticFriction = 4,
}


PhysicsObjects = {}
PhysicsObjectsTree = {}

function UpdatePhysicsObjects()

    local worldExtents = GetWorldExtents()
    local extents = {minX = worldExtents.MinX, minY = worldExtents.MinY, maxX = worldExtents.MaxX, maxY = worldExtents.MaxY}
    PhysicsObjectsTree = SubdividePoses(PhysicsObjects, extents)
    UpdateObjects()

end


function RegisterPhysicsObject(pos, radius, velocity, objectDefinition, effectId)
    pos = pos or Vec3(0, 0, 0)
    radius = radius or 50 / 2
    velocity = velocity or Vec3(0, 0, 0)
    objectDefinition = objectDefinition or defaultObjectDefinition
    local Object = {
        pos = pos,
        radius = radius,
        velocity = velocity,
        objectDefinition = objectDefinition,
        lastPos = pos,
        effectId = effectId
    }
    PhysicsObjects[#PhysicsObjects + 1] = Object
    return Object
end
function UnregisterPhysicsObject(Object)
    for i = 1, #PhysicsObjects do
        if PhysicsObjects[i] == Object then
            table.remove(PhysicsObjects, i)
            return
        end
    end
end



function UpdateObjects()
    for i = 1, #PhysicsObjects do
        local Object = PhysicsObjects[i]
        Object.lastPos = Object.pos
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
            Object.velocity.y = Object.velocity.y + gravity * delta
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


            -- Structure
            local snapResults = CircleCollisionOnStructure(Object.pos, Object.radius)


            local noBackgroundResults = {}
            for j = 1, #snapResults do
                local snapResult = snapResults[j]
                if snapResult.material == "backbracing" then
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

            for j = 1, #filteredResults do
                local snapResult = filteredResults[j]
                local materialSaveName = snapResult.material

                local linkDefinition = LinkDefinitions[materialSaveName]
                local normal = Vec3(snapResult.normal.x, snapResult.normal.y, 0)
                local platformVelocity = Vec2Average({ NodeVelocity(snapResult.nodeA.id), NodeVelocity(snapResult.nodeB
                    .id) })
                -- Perform collision in the frame of reference of the object that it is colliding with
                local parallel = Vec3(normal.y, -normal.x, 0)
                velocity = velocity - platformVelocity + linkDefinition.ConveyorSpeed * parallel



                -- Helper vectors
                local objPos = Object.pos
                local error = Vec3(objPos.x - snapResult.pos.x, objPos.y - snapResult.pos.y)
                local length = error.length
                if (length == 0) then
                    continue
                end
                local errorNormalized = Vec3(error.x / length, error.y / length)
                error = (Object.radius - length) * errorNormalized



                local velocityPerpToSurface = Vec2Dot(velocity, normal)
                local velocityParallelToSurface = Vec2Dot(velocity, parallel)

                -- Rigid force
                Object.pos = Object.pos + error
                Object.velocity = velocity - velocityPerpToSurface * normal
                velocity = Object.velocity

                local gravityFriction = -gravity * normal.y / 1000
                -- Dynamic friction
                local force = -
                defaultObjectDefinition.DynamicFriction * linkDefinition.DynamicFriction * gravityFriction * velocityParallelToSurface *
                parallel
                velocity = velocity + delta * force
                -- Return back to world frame
                velocity = velocity + platformVelocity - linkDefinition.ConveyorSpeed * parallel
                -- Set velocity
                Object.velocity = velocity

                -- Static friction
                if (math.abs(velocityParallelToSurface) < (defaultObjectDefinition.StaticFriction * linkDefinition.StaticFriction * gravityFriction)) then
                    Object.velocity = velocity - velocityParallelToSurface * parallel
                end
            end

            
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

            local posAtoPosB = other.pos - object.pos
            local distSquared = posAtoPosB.x * posAtoPosB.x + posAtoPosB.y * posAtoPosB.y
            local combinedRadius = object.radius + other.radius
            combinedRadius = combinedRadius * combinedRadius
            if distSquared < combinedRadius then
                results[#results + 1] = other
            end
        end
        return
    end
    local x = object.pos.x
    local y = object.pos.y
    local radius = object.radius

    local center = branch.rect.center

    local subTrees = branch.children
    if x < center.x + radius + MaxRadius then
        if y < center.y + radius + MaxRadius then
            TestObjectOnObjectCollision(subTrees[1], object, results)
        end
        if y > center.y - radius - MaxRadius then
            TestObjectOnObjectCollision(subTrees[2], object, results)
        end
    end
    if x > center.x - radius - MaxRadius then
        if y < center.y + radius + MaxRadius then
            TestObjectOnObjectCollision(subTrees[3], object, results)
        end
        if y > center.y - radius - MaxRadius then
            TestObjectOnObjectCollision(subTrees[4], object, results)
        end
    end

end