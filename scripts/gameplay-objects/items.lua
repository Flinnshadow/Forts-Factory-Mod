-- Constants and Globals
Gravity = 0
GlobalItemIterator = 0

-- Item Definitions
ItemDefinitions = {
    [""] = {MaterialType = "Dynamo"},
    ["IronOre"] = {MaterialType = "IronOre",CoreValue = Value(50,0)}, --ivy
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
    [""] =              {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["bracing"] =       {DynamicFriction = 1,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["armour"] =        {DynamicFriction = 0.2,     StaticFriction = 8,         ConveyorSpeed = 0},
    ["door"] =          {DynamicFriction = 0.2,     StaticFriction = 8,         ConveyorSpeed = 0},
    ["rope"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["fuse"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["shield"] =        {DynamicFriction = 0,       StaticFriction = 0,         ConveyorSpeed = 0},
    ["portal"] =        {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["solarpanel"] =    {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    --conveyor 1
    ["c1l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -30}, -- left
    ["c1r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  30}, -- right
    ["c1pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -60}, -- left powered
    ["c1pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  60}, -- right powered
    
    --conveyor 2
    ["c2l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -60},
    ["c2r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  60},
    ["c2pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -120},
    ["c2pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  120},

    -- conveyor 3
    ["c3l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -120},
    ["c3r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  120},
    ["c3pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -240},
    ["c3pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  240},
}

-- Global Storage
ItemObjects = {}
ItemObjectLifeSpans = {}

-- Item Creation and Destruction
function CreateItem(pos, iType, effectId)
    GlobalItemIterator = GlobalItemIterator + 1
    local iType = (iType and ItemDefinitions[iType] and ItemDefinitions[iType].MaterialType) and iType or ""

    -- Use existing effect or create new one
    local effectId = effectId or SpawnEffectEx(path .. "/effects/".. ItemDefinitions[iType].MaterialType.. GetRandomInteger(1, 3, "") ..".lua", pos, Vec3(GetRandomFloat(-1, 1, ""), GetRandomFloat(-1, 1, "")))

    local radius = 50/2

    Obj = RegisterPhysicsObject(pos, radius, Vec3(0, 0, 0), _, effectId)
    Obj.itemType = iType
    Obj.id = GlobalItemIterator
    ItemObjects[GlobalItemIterator] = Obj
    ScheduleCall(300, DestroyItem, Obj, GlobalItemIterator)
    return Obj
end



function DestroyItem(item, itemKey, preserveEffect)
    if not preserveEffect then
        CancelEffect(item.effectId)
    end
    ItemObjects[itemKey] = nil
    UnregisterPhysicsObject(item)
end
local maxPhysicsStep = 8

function UpdateItemObjects()
    local extents = GetWorldExtents()
    for key, Object in pairs(ItemObjects) do
        if Object.pos.x < extents.MinX or Object.pos.x > extents.MaxX or Object.pos.y < extents.MinY or Object.pos.y > extents.MaxY then
            DestroyItem(Object, key)
            continue
        end

        local deviceCheckSnapResult = SnapToWorld(Object.pos, Object.radius * 3, SNAP_DEVICES, -1, -1, "")
        if GetDeviceType(deviceCheckSnapResult.DeviceId) == "reactor" then
            if ItemDefinitions[Object.itemType].CoreValue then
                AddResourcesContinuous(GetDeviceTeamIdActual(deviceCheckSnapResult.DeviceId), ItemDefinitions[Object.itemType].CoreValue)
                DestroyItem(Object, key)
                continue
            end
        end

    end
end