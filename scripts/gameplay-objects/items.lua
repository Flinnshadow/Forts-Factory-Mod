gravity = 0
GlobalItemIterator = 0
PhysicsObjectLifeSpans = {}

function OnKey(key, down)
    if key == "u" and down then
        CreateItem(ProcessedMousePos(),"apple")
    end
end

function SpawnMetal(deviceId)
    if DeviceExists(deviceId) then
        --Find Output
        pos = GetDevicePosition(deviceId) - Vec3(0, 130)
        CreateItem(pos,"IronOre")
        ScheduleCall(16, SpawnMetal, deviceId) --a mine would have yielded 64 metal, each ore is 50, metal plates are 124 (64 per ore)
        -- if debug then BetterLog(GlobalItemIterator) end
    end
end

function OnDeviceCompleted(teamId, deviceId, saveName)
        SpawnMetal(deviceId)
end

ItemDefinitions = {
    [""] = {MaterialType = "Dynamo"},
    ["IronOre"] = {MaterialType = "DefaultMaterial",CoreValue = Value(50,0)},
    ["IronPlate"] = {MaterialType = "Bebop",CoreValue = Value(128,0)},
}

PhysicsObjects = {}

function CreateItem(pos,iType,extras)

    GlobalItemIterator = GlobalItemIterator + 1
    --if not pos then return end
    --extras == {velocity,inDevice,Direction}
    local iType = (iType and ItemDefinitions[iType] and ItemDefinitions[iType].MaterialType) and iType or ""
    local id = SpawnEffectEx(path .. "/effects/".. ItemDefinitions[iType].MaterialType ..".lua", pos, Vec3(0, -1))
    local Obj = { --TODO: move any static variables to a item definition (ie the core insertion value)
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
    ScheduleCall(30,DestroyItem,Obj,GlobalItemIterator)
   -- table.insert(PhysicsObjectLifeSpans,-1,{Id = GlobalItemIterator,LifeSpan = 30}) --insert the PhysicsObjects sub table directly so I don't have to search for it when I want to remove it

end

function DestroyItemViaLifespan()
    --SC to the next lowest lifespan in the list, if everything has 30s lifespan then the list can just go linearly
    --else ScheduleCall(30,DestroyItemViaLifespan)
end

function ContainItem(itemKey)
    PhysicsObjects[itemKey] = nil
end

function ReleaseItem(item,itemKey)
    PhysicsObjects[itemKey] = item
end

function DestroyItem(item,itemKey)
    CancelEffect(item.effectId)
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
                DestroyItem(Object,key)

                continue
            end
        end



        local velocity = Object.velocity
        local radius = Object.radius
        local physicsStep = math.clamp(math.ceil((velocity.length() * data.updateDelta) / (radius)), 1, maxPhysicsStep)

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
            local length = error.length()
            if (length == 0) then
                continue
            end
            local errorNormalized = Vec3(error.x / length, error.y / length, error.z / length)
            error = (Object.radius - length) * errorNormalized



            local velocityPerpToSurface = Vec2Dot(velocity, normal)
            local velocityParallelToSurface = Vec2Dot(velocity, parallel)


            -- Spring force
            local force = Object.springConst * (physicsStep ^ 2) * error - (Object.dampening * velocityPerpToSurface * normal)

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