--- forts API ---
dofile("scripts/forts.lua")
dofile(path .. "/scripts/utility/BetterLog.lua")
dofile(path .. "/scripts/math/math.lua")
dofile(path .. "/scripts/math/vector.lua")
dofile(path .. "/scripts/gameplay-objects/items.lua")
dofile(path .. "/scripts/gameplay-objects/modules.lua")
dofile(path .. "/scripts/utility/physLib.lua")
debugMode = true


function Load()
    LoadPhysLib()
    gravity = GetConstant("Physics.Gravity")
    --ScheduleCall(30,DestroyItemViaLifespan)
    if debugMode then
        for key, value in pairs(ExistingModules) do
            value.recipe.baseTime = 0.5
        end
    end
end

function Update()
    UpdatePhysLib()
    UpdatePhysicsObjects()

    UpdateModules()

end
