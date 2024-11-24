-- Constants and Globals
gravity = 0
GlobalItemIterator = 0
local CONVEYOR_SPEED = 120
local MAX_PHYSICS_STEP = 8

-- Item Definitions
ItemDefinitions = {
    [""] = {MaterialType = "Dynamo"},
    ["IronOre"] = {MaterialType = "DefaultMaterial",CoreValue = Value(50,0)}, --ivy
    ["DirtyOre"] = {MaterialType = "Haze",CoreValue = Value(128,0)},
    ["IronPlate"] = {MaterialType = "Abrams",CoreValue = Value(128,0)},
    ["Steel"] = {MaterialType = "Bebop",CoreValue = Value(128,0)},
    ["Oil"] = {MaterialType = "Viscous",CoreValue = Value(0,100)},
    ["SulfuricAcid"] = {MaterialType = "Viscous",CoreValue = Value(0,100)},
    ["Ammo"] = {MaterialType = "meowginnis",CoreValue = Value(128,0)},
    ["Ammo2"] = {MaterialType = "MoAndKrill",CoreValue = Value(128,0)},
}

-- Global Storage
PhysicsObjects = {}
PhysicsObjectLifeSpans = {}

-- Item Creation and Destruction
function CreateItem(pos, iType, effectId)
    GlobalItemIterator = GlobalItemIterator + 1
    local iType = (iType and ItemDefinitions[iType] and ItemDefinitions[iType].MaterialType) and iType or ""

    -- Use existing effect or create new one
    local id = effectId or SpawnEffectEx(path .. "/effects/".. ItemDefinitions[iType].MaterialType ..".lua", pos, Vec3(0, -1))

    local Obj = {
        itemType = iType,
        effectId = id,
        id = GlobalItemIterator,
        position = pos,
        velocity = Vec3(0, 0, 0),
        radius = 50 / 2,
        springConst = 800,
        dampening = 30,
        friction = 15,
        staticFriction = 15,
    }
    PhysicsObjects[GlobalItemIterator] = Obj
    ScheduleCall(30, DestroyItem, Obj, GlobalItemIterator)
    return Obj
end

function DestroyItem(item, itemKey, preserveEffect)
    if not preserveEffect then
        CancelEffect(item.effectId)
    end
    PhysicsObjects[itemKey] = nil
end

local conveyorSpeed = 120


local maxPhysicsStep = 8

function UpdatePhysicsObjects()
    for key, Object in pairs(PhysicsObjects) do

        local deviceCheckSnapResult = SnapToWorld(Object.position, Object.radius * 3, SNAP_DEVICES, -1, -1, "")
        if GetDeviceType(deviceCheckSnapResult.DeviceId) == "reactor" then
            if ItemDefinitions[Object.itemType].CoreValue then
                AddResourcesContinuous(GetDeviceTeamIdActual(deviceCheckSnapResult.DeviceId), ItemDefinitions[Object.itemType].CoreValue)
                DestroyItem(Object, key)
                continue
            end
        end



        local velocity = Object.velocity
        local radius = Object.radius
        local physicsStep = math.clamp(math.ceil((Vec2Mag(velocity) * data.updateDelta) / (radius)), 1, maxPhysicsStep)

        local delta = data.updateDelta / physicsStep
        -- Physics steps
        for i = 1, physicsStep do
            -- Euler integration
            Object.position = Object.position + (delta * 0.5 * Object.velocity)
            Object.velocity.y = Object.velocity.y + gravity * delta
            Object.position = Object.position + (delta * 0.5 * Object.velocity)



            local velocity = Object.velocity



            local snapResults = CircleCollisionOnStructure(Object.position, Object.radius)


            for i = 1, #snapResults do
                local snapResult = snapResults[i]
                local materialSaveName = snapResult.material
                if materialSaveName == "backbracing" then
                    continue
                end
                local normal = snapResult.normal
                local platformVelocity = Vec2Average({ NodeVelocity(snapResult.nodeA.id), NodeVelocity(snapResult.nodeB
                .id) })
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
                local error = Object.position - snapResult.pos
                local length = error.length
                if (length == 0) then
                    continue
                end
                local errorNormalized = Vec3(error.x / length, error.y / length)
                error = (Object.radius - length) * errorNormalized



                local velocityPerpToSurface = Vec2Dot(velocity, normal)
                local velocityParallelToSurface = Vec2Dot(velocity, parallel)


                -- Spring force
                local force = Object.springConst * (physicsStep ^ 2) * error -
                (Object.dampening * velocityPerpToSurface * normal)

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
        end


        SetEffectPosition(Object.effectId, Object.position)
    end
end