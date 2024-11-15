--- forts API ---
dofile("scripts/forts.lua")
dofile(path .. "/scripts/utility/BetterLog.lua")
dofile(path .. "/scripts/math/math.lua")
dofile(path .. "/scripts/math/vector.lua")
dofile(path .. "/scripts/gameplay-objects/items.lua")
dofile(path .. "/scripts/gameplay-objects/modules.lua")



function Load()

    gravity = GetConstant("Physics.Gravity")
    --ScheduleCall(30,DestroyItemViaLifespan)
end

function Update(frame)

    UpdatePhysicsObjects()

    for key, apple in pairs(ExistingModules) do
        apple:GrabItemsAutomatically()
        apple:UpdateCrafting()
    end
    --[[for key, Device in pairs(Devices) do
        Device:Update()
    end]]
end
