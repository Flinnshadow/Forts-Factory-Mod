--- forts API ---
dofile("scripts/forts.lua")
dofile(path .. "/scripts/utility/BetterLog.lua")
dofile(path .. "/scripts/math/math.lua")
dofile(path .. "/scripts/math/vector.lua")
dofile(path .. "/scripts/gameplay-objects/items.lua")
dofile(path .. "/scripts/gameplay-objects/modules.lua")

dofile(path .. "/scripts/utility/physLib/physLib.lua")
dofile(path .. "/scripts/utility/physLib/entrypoints.lua")
dofile(path .. "/scripts/utility/physLib/structure.lua")
debugMode = true


function Load()
    LoadPhysLib()
    gravity = GetConstant("Physics.Gravity")
end

function Update(frame)
    UpdatePhysLib(frame)
    UpdateItemObjects()

    UpdateModules()
    if SpawnItems then

    CreateItem(ProcessedMousePos(),"IronOre")
    end
end

function OnDraw()
    PhysLibRender.OnDraw()
end
