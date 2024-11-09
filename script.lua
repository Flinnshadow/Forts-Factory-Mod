--- forts API ---
dofile(path .. "/scripts/utility/BetterLog.lua")
dofile(path .. "/scripts/math/math.lua")
dofile(path .. "/scripts/math/vector.lua")
dofile(path .. "/scripts/gameplay-objects/items.lua")

dofile("scripts/forts.lua")

function Load()
    gravity = GetConstant("Physics.Gravity")
    --ScheduleCall(30,DestroyItemViaLifespan)
end

function Update(frame)

    UpdatePhysicsObjects()

    for key, value in pairs(Devices) do
        Device:Update()
    end
end
