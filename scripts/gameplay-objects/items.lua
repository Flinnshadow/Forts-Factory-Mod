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

-- TODO: move to it's own file
LinkDefinitions = {
    [""] = {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = 0},
    ["bracing"] = {DynamicFriction = 1, StaticFriction = 8, ConveyorSpeed = 0},
    ["armour"] = {DynamicFriction = 0.05, StaticFriction = 0, ConveyorSpeed = 0},
    ["door"] = {DynamicFriction = 0.05, StaticFriction = 8, ConveyorSpeed = 0},
    ["rope"] = {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = 0},
    ["fuse"] = {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = 0},
    ["shield"] = {DynamicFriction = 0, StaticFriction = 0, ConveyorSpeed = 0},
    ["portal"] = {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = 0},
    ["solarpanel"] = {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = 0},
    --conveyor 1
    ["c1l"]  =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = -120}, -- left
    ["c1r"]  =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed =  120}, -- right
    ["c1pl"] =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = -240}, -- left powered
    ["c1pr"] =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed =  240}, -- right powered
    
    --conveyor 2
    ["c2l"]  =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = -240},
    ["c2r"]  =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed =  240},
    ["c2pl"] =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = -480},
    ["c2pr"] =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed =  480},

    -- conveyor 3
    ["c3l"]  =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = -480},
    ["c3r"]  =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed =  480},
    ["c3pl"] =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed = -960},
    ["c3pr"] =  {DynamicFriction = 4, StaticFriction = 8, ConveyorSpeed =  960},
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
        springConst = 400,
        dampening = 20,
        DynamicFriction = 4,
        StaticFriction = 4,
    }
    PhysicsObjects[GlobalItemIterator] = Obj
    ScheduleCall(300, DestroyItem, Obj, GlobalItemIterator)
    return Obj
end



function DestroyItem(item, itemKey, preserveEffect)
    if not preserveEffect then
        CancelEffect(item.effectId)
    end
    PhysicsObjects[itemKey] = nil
end
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


            local noBackgroundResults = {}
            for i = 1, #snapResults do
                local snapResult = snapResults[i]
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

            for i = 1, #filteredResults do
                local snapResult = filteredResults[i]
                local materialSaveName = snapResult.material

                local linkDefinition = LinkDefinitions[materialSaveName]
                local normal = Vec3(snapResult.normal.x, snapResult.normal.y, 0)
                local platformVelocity = Vec2Average({ NodeVelocity(snapResult.nodeA.id), NodeVelocity(snapResult.nodeB
                .id) })
                -- Perform collision in the frame of reference of the object that it is colliding with
                local parallel = Vec3(normal.y, -normal.x, 0)
                velocity = velocity - platformVelocity + linkDefinition.ConveyorSpeed * parallel
                


                -- Helper vectors
                local objPos = Object.position
                local error = Vec3(objPos.x - snapResult.pos.x, objPos.y - snapResult.pos.y)
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

                local gravityFriction = -gravity * normal.y / 1000
                -- Dynamic friction
                force = force - Object.DynamicFriction * linkDefinition.DynamicFriction * gravityFriction * velocityParallelToSurface * parallel  
                velocity = velocity + delta * force
                -- Return back to world frame
                velocity = velocity + platformVelocity - linkDefinition.ConveyorSpeed * parallel
                -- Set velocity
                Object.velocity = velocity

                -- Static friction
                if (math.abs(velocityParallelToSurface) < (Object.StaticFriction * linkDefinition.StaticFriction * gravityFriction)) then
                    Object.velocity = velocity - velocityParallelToSurface * parallel
                end
            end
        end


        SetEffectPosition(Object.effectId, Object.position)
    end
end