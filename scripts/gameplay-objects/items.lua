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
            springConst = 800,
            dampening = 30,
            friction = 15,
            staticFriction = 15,

        }
        table.insert(PhysicsObjects, Obj)
        GlobalId = GlobalId + 1
        ScheduleCall(10, SpawnMetal, deviceId)
        BetterLog(GlobalId)
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
            springConst = 800,
            dampening = 30,
            friction = 15,
            staticFriction = 15,
        }
        table.insert(PhysicsObjects, Obj)
        GlobalId = GlobalId + 1
    end
end

local conveyorSpeed = 120


local maxPhysicsStep = 8

function Update(frame)
    for key, Object in pairs(PhysicsObjects) do
        
        local deviceCheckSnapResult = SnapToWorld(Object.position, Object.radius * 3, SNAP_DEVICES, -1, -1, "")
        if GetDeviceType(deviceCheckSnapResult.DeviceId) == "reactor" then
            CancelEffect(Object.effectId)

            continue
        end


        local velocity = Object.velocity
        local radius = Object.radius
        local physicsStep = math.clamp(math.ceil((velocity.length * data.updateDelta) / (radius)), 1, maxPhysicsStep)

        local delta = data.updateDelta / physicsStep


        -- Physics steps
        for i = 1, physicsStep do   

            -- Euler integration
            Object.position = Object.position + (delta * 0.5 * Object.velocity)
            Object.velocity.y = Object.velocity.y + gravity * delta
            Object.position = Object.position + (delta * 0.5 * Object.velocity)



            local velocity = Object.velocity

            

            local snapResult = SnapToWorld(Object.position, Object.radius, SNAP_LINKS_FORE, -1, -1, "")


            local normal = snapResult.Normal



            local platformVelocity
            if snapResult.Type == SNAP_TYPE_LINK then
                platformVelocity= Vec2Average({ NodeVelocity(snapResult.NodeIdA), NodeVelocity(snapResult.NodeIdB) })
            elseif snapResult.Type == SNAP_TYPE_NODE then
                platformVelocity = NodeVelocity(snapResult.NodeIdA)

            elseif snapResult.Type == SNAP_TYPE_NOTHING then continue end
            
            local materialSaveName = GetLinkMaterialSaveName(snapResult.NodeIdA, snapResult.NodeIdB)


            -- Perform collision in the frame of reference of the object that it is colliding with
            velocity = velocity - platformVelocity
            local parallel = Vec3(normal.y, -normal.x, 0)


            if materialSaveName == "Conveyor" then
                velocity = velocity + conveyorSpeed * parallel
            end
            if materialSaveName == "ConveyorInverted" then
                velocity = velocity - conveyorSpeed * parallel
            end



            -- Helper vectors
            local error = Object.position - snapResult.Position
            local length = error.length
            if (length == 0) then
                continue
            end
            local errorNormalized = Vec3(error.x / length, error.y / length, error.z / length)
            error = (Object.radius - length) * errorNormalized



            local velocityPerpToSurface = Vec2Dot(velocity, normal)
            local velocityParallelToSurface = Vec2Dot(velocity, parallel)


            -- Spring force
            local force = Object.springConst * (physicsStep ^ 2) * error - Object.dampening * velocityPerpToSurface * normal

            -- Dynamic friction
            force = force - Object.friction * velocityParallelToSurface * parallel
            velocity = velocity + delta * force

            -- Return back to world frame
            velocity = velocity + platformVelocity
            if materialSaveName == "Conveyor" then
                velocity = velocity - conveyorSpeed * parallel
            end
            if materialSaveName == "ConveyorInverted" then
                velocity = velocity + conveyorSpeed * parallel
            end


            -- Set velocity
            Object.velocity = velocity

            -- Static friction
            if (math.abs(velocityParallelToSurface) < Object.staticFriction) then
                Object.velocity = velocity - velocityParallelToSurface * parallel
            end
        end



        SetEffectPosition(Object.effectId, Object.position)
    end
end
