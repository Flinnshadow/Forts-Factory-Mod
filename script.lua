--- forts API ---
dofile(path .. "/math.lua")
dofile(path .. "/vector.lua")
dofile(path .. "/BetterLog.lua")

dofile("scripts/forts.lua")

local gravity = 0
GlobalId = 1

PhysicsObjects = {}
function Load()
    gravity = GetConstant("Physics.Gravity")
end

function OnDeviceCompleted(teamId, deviceId, saveName)
    Log(saveName)
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
            staticFriction = 20,

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
            staticFriction = 20,

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

            --local id = SpawnCircle(Object.position, Object.radius, White(), 0.04)
            SetEffectPosition(Object.effectId, Object.position)
            --SetEffectDirection(id, direction)

            local snapResult = SnapToWorld(Object.position, Object.radius, SNAP_LINKS_FORE + SNAP_NODES, -1, -1, "")
            --[[snapResult.Distance = math.huge
      for key, Object2 in pairs(PhysicsObjects) do
         if Object.id == Object2.id then continue end
         Distance = Vec2Dist(Object.position, Object2.position) - Object.radius -Object2.radius
         if 0 > Distance and snapResult.Distance > Distance then --TODO: apply some force to Object2, in case 3x hit eachother at once
            snapResult.Position = Object2.position
            snapResult.Normal = Vec2Normalize(Object.position - Object2.position)
            snapResult.Distance = Distance
         end
      end]]
            local normal = snapResult.Normal

            -- Helper vectors
            local error = Object.position - snapResult.Position
            local length = error.length
            if (length == 0) then
                continue
            end
            local errorNormalized = Vec3(error.x / length, error.y / length, error.z / length)
            error = (Object.radius - length) * errorNormalized
            local parallel = Vec3(normal.y, -normal.x, 0)
            local velocityPerpToSurface = Vec2Dot(Object.velocity, normal)
            local velocityParallelToSurface = Vec2Dot(Object.velocity, parallel)

            -- Spring force
            local force = Object.springConst * error - Object.dampening * velocityPerpToSurface * normal

            -- Dynamic friction
            force = force - Object.friction * velocityParallelToSurface * parallel
            Object.velocity = Object.velocity + delta * force

            -- Static friction
            if (math.abs(velocityParallelToSurface) < Object.staticFriction) then
                Object.velocity = Object.velocity - velocityParallelToSurface * parallel
            end
            
        end
    end
end

function SpringDampenedForce(springConst, displacement, dampening, velocity)
    local force = springConst * displacement - dampening * velocity
    return force
end
