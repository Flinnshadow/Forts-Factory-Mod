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

    for _, module in pairs(ExistingModules) do
        module:GrabItemsAutomatically()
        module:UpdateCrafting()
        if module.deviceId then
            local pos = GetDevicePosition(module.deviceId)
            if module.inputHitbox then
                module.inputHitbox:UpdatePosition(pos)
            end
            if module.outputHitbox then
                module.outputHitbox:UpdatePosition(pos)
            end
        end
    end

    for _, inserter in pairs(ExistingInserters) do
        inserter:Update(frame)
        if inserter.inputNode then
            local pos = NodePosition(inserter.inputNode)
            if inserter.inputHitbox then
                inserter.inputHitbox:UpdatePosition(pos)
            end
        end
        if inserter.outputNode then
            local pos = NodePosition(inserter.outputNode)
            if inserter.outputHitbox then
                inserter.outputHitbox:UpdatePosition(pos)
            end
        end
    end
end
