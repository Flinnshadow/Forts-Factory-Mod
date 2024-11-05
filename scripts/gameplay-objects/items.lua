local gravity = 0
GlobalId = 1

PhysicsObjects = {}
function Load()
    gravity = GetConstant("Physics.Gravity")
end

function OnDeviceCompleted(teamId, deviceId, saveName)
    if saveName == "mine" or saveName == "mine2" then
        ScheduleCall(2, SpawnMetal, deviceId)
    end
end

function SpawnMetal(deviceId)
    if DeviceExists(deviceId) then
        --Find Output
        pos = GetDevicePosition(deviceId) - Vec3(0, 130)
        local id = SpawnEffectEx(path .. "/effects/DefaultMaterial.lua", pos, Vec3(0, -1))
        Obj = {
            effectId = id,
            id = GlobalId,
            position = pos,
            velocity = Vec3(0, 0, 0),
            radius = 50 / 2,
            springConst = GetRandomInteger(200, 600, "springRand") * 10,
            dampening = GetRandomInteger(5, 15, "dampeningRand") * 5,
            friction = 5,
            staticFriction = 15,

        }
        table.insert(PhysicsObjects, Obj)
        GlobalId = GlobalId + 1
        ScheduleCall(5, SpawnMetal, deviceId)
    end
end

function OnKey(key, down)
    if key == "u" and down then
        local id = SpawnEffectEx(path .. "/effects/DefaultMaterial.lua", ProcessedMousePos(), Vec3(0, -1))
        Obj = {
            effectId = id,
            id = GlobalId,
            position = ProcessedMousePos(),
            velocity = Vec3(0, 0, 0),
            radius = 50 / 2,
            springConst = GetRandomInteger(200, 600, "springRand") * 10,
            dampening = GetRandomInteger(5, 15, "dampeningRand") * 5,
            friction = 5,
            staticFriction = 15,

        }
        table.insert(PhysicsObjects, Obj)
        GlobalId = GlobalId + 1
    end
end

local lastUpdateTime = 0
function OnUpdate(frame)
    if lastUpdateTime == 0 then
        lastUpdateTime = GetRealTime()
    end
    local updateTime = GetRealTime()

    local delta = (updateTime - lastUpdateTime) * 0.5
    lastUpdateTime = updateTime
    for i = 1, 2 do
        for key, Object in pairs(PhysicsObjects) do
            -- Euler integration
            Object.position = Object.position + (delta * 0.5 * Object.velocity)
            Object.velocity.y = Object.velocity.y + gravity * delta
            Object.position = Object.position + (delta * 0.5 * Object.velocity)


            local velocity = Object.velocity

            SetEffectPosition(Object.effectId, Object.position)

            local snapResult = SnapToWorld(Object.position, Object.radius, SNAP_LINKS_FORE, -1, -1, "")
            local normal = snapResult.Normal

            local platformVelocity = Vec2Average({ NodeVelocity(snapResult.NodeIdA), NodeVelocity(snapResult.NodeIdB) })
            local materialSaveName = GetLinkMaterialSaveName(snapResult.NodeIdA, snapResult.NodeIdB)



            -- Perform collision in the frame of reference of the object that it is colliding with
            velocity = velocity - platformVelocity


            -- Helper vectors
            local error = Object.position - snapResult.Position
            local length = error.length
            if (length == 0) then
                continue
            end
            local errorNormalized = Vec3(error.x / length, error.y / length, error.z / length)
            error = (Object.radius - length) * errorNormalized
            local parallel = Vec3(normal.y, -normal.x, 0)
            if materialSaveName == "Conveyor" then
                velocity = velocity - 5 * parallel
            end


            local velocityPerpToSurface = Vec2Dot(velocity, normal)
            local velocityParallelToSurface = Vec2Dot(velocity, parallel)



            -- Spring force
            local force = Object.springConst * error - Object.dampening * velocityPerpToSurface * normal

            -- Dynamic friction
            force = force - Object.friction * velocityParallelToSurface * parallel
            velocity = velocity + delta * force


            velocity = velocity + platformVelocity


            Object.velocity = velocity

            -- Static friction
            if (math.abs(velocityParallelToSurface) < Object.staticFriction) then
                Object.velocity = velocity - velocityParallelToSurface * parallel

                if materialSaveName == "Conveyor" then
                    Object.velocity = velocity - (velocityParallelToSurface + 5) * parallel
                end
            end
        end
    end
end
