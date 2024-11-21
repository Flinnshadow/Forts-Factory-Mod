--- forts API ---
dofile("scripts/forts.lua")
dofile(path .. "/scripts/utility/BetterLog.lua")
dofile(path .. "/scripts/math/math.lua")
dofile(path .. "/scripts/math/vector.lua")
dofile(path .. "/scripts/gameplay-objects/items.lua")
dofile(path .. "/scripts/gameplay-objects/modules.lua")
dofile(path .. "/scripts/utility/physLib.lua")



function Load()
    LoadPhysLib()
    gravity = GetConstant("Physics.Gravity")
    --ScheduleCall(30,DestroyItemViaLifespan)

end

function Update()
    UpdatePhysLib()
    UpdatePhysicsObjects()

    UpdateModules()

end
