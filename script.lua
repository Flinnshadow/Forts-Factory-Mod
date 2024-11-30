--- forts API ---
dofile("scripts/forts.lua")
dofile(path .. "/scripts/utility/BetterLog.lua")
dofile(path .. "/scripts/math/math.lua")
dofile(path .. "/scripts/math/vector.lua")
dofile(path .. "/scripts/gameplay-objects/items.lua")
dofile(path .. "/scripts/gameplay-objects/modules.lua")

dofile(path .. "/scripts/utility/physLib/physLib.lua")
DebugMode = true


function Load()
    LoadPhysLib()
    Gravity = GetConstant("Physics.Gravity")
end

function Update(frame)
    UpdatePhysLib(frame)
    UpdateItemObjects()

    UpdateModules()
    if SpawnItems then

    CreateItem(ProcessedMousePos(),"IronOre")
    end

    --perf test
    -- local lineA1 = Vec3(-50, -25)
    -- local lineA2 = Vec3(-30, -75)

    -- local lineB1 = Vec3(-30, -25)
    -- local lineB2 = ProcessedMousePos()

    -- local startTime = GetRealTime()
    -- for i = 1, 10000 do
    --     ClosestPointsBetweenLines(lineA1, lineA2, lineB1, lineB2)
    -- end
    -- local endTime = GetRealTime()
    -- BetterLog("Time taken: " .. (endTime - startTime) * 1000 .. "ms")

    -- local bestA, _, bestB, _, _ = ClosestPointsBetweenLines(lineA1, lineA2, lineB1, lineB2)

    -- SpawnCircle(bestA, 5, White(), 0.06)
    -- SpawnCircle(bestB, 5, White(), 0.06)

    -- SpawnLine(lineA1, lineA2, White(), 0.06)
    -- SpawnLine(lineB1, lineB2, White(), 0.06)
end

function OnDraw()
    PhysLibRender.OnDraw()
end
