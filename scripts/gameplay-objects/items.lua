-- Constants and Globals
Gravity = 0
GlobalItemIterator = 0
MaterialArtSet = "DA_" -- "DA_": Dev art, "MRA_": Main Release Art, "TRA": Test Release Art, "SBA": SamsterBirdies Art,

-- Item Definitions
ItemDefinitions = {
    [""] =              {VariantCount=1,                                    },
    ["IronOre"] =       {VariantCount=3,            CoreValue = Value(50,0) }, --ivy
    ["DirtyOre"] =      {VariantCount=1,            CoreValue = Value(128,0)},
    ["IronPlate"] =     {VariantCount=1,            CoreValue = Value(128,0)},
    ["Steel"] =         {VariantCount=1,            CoreValue = Value(128,0)},
    ["Oil"] =           {VariantCount=1,            CoreValue = Value(0,100)},
    ["SulfuricAcid"] =  {VariantCount=1,            CoreValue = Value(0,100)},
    ["Ammo"] =          {VariantCount=1,            CoreValue = Value(128,0)},
    ["Ammo2"] =         {VariantCount=1,            CoreValue = Value(128,0)},
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
    ["c1l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -60,        Conveyor = true}, -- left
    ["c1r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  60,        Conveyor = true}, -- right
    ["c1pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -120,       Conveyor = true}, -- left powered
    ["c1pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  120,       Conveyor = true}, -- right powered
    
    --conveyor 2
    ["c2l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -120,       Conveyor = true}, -- left
    ["c2r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  120,       Conveyor = true},
    ["c2pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -240,       Conveyor = true},
    ["c2pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  240,       Conveyor = true},

    -- conveyor 3
    ["c3l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -240,       Conveyor = true},
    ["c3r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  240,       Conveyor = true},
    ["c3pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -480,       Conveyor = true},
    ["c3pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  480,       Conveyor = true},
}

-- Global Storage
ItemObjects = {}
ItemObjectLifeSpans = {}

-- Item Creation and Destruction
function CreateItem(pos, iType, effectId)
    GlobalItemIterator = GlobalItemIterator + 1

    local iType = (iType and ItemDefinitions[iType]) and iType or ""


    -- Use existing effect or create new one
    local effectId = effectId or SpawnEffectEx(path .. "/effects/" ..MaterialArtSet..iType.. GetRandomInteger(1, ItemDefinitions[iType].VariantCount or 1, "") ..".lua", pos, Vec3(GetRandomFloat(-1, 1, ""), GetRandomFloat(-1, 1, "")))

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