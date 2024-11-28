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
end

function Update(frame)
    UpdatePhysLib(frame)
    UpdatePhysicsObjects()

    UpdateModules()

end
