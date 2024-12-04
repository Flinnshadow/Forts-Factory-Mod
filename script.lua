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
    PhysLib:Load()
    Gravity = GetConstant("Physics.Gravity")
end

local frameRan = true
function Update(frame)
    if not frameRan then 
        BetterLog("Update Error detected")
        _G["Update"] = function() end
    end
    frameRan = false
    local startTime = GetRealTime()
    
    PhysLib:Update(frame)
    UpdateItemObjects()

    UpdateModules()
    if SpawnItems then

    CreateItem(ProcessedMousePos(),"IronOre")
    end

    local endTime = GetRealTime()
    if (endTime - startTime) * 1000 > 35 then 
        -- BetterLog("Error: Runtime limit exceeded, destroying Update for your own sanity")
        -- _G["Update"] = function() end 

    end
    frameRan = true
end

function OnUpdate()
    local startTime = GetRealTime()
    PhysLib:OnUpdate()
    local endTime = GetRealTime()
    if (endTime - startTime) * 1000 > 40 then 
        BetterLog("Error: Runtime limit exceeded, destroying OnUpdate for your own sanity")
        _G["OnUpdate"] = function() end 

    end
end



function OnDeviceCreated(teamId, deviceId, saveName, nodeA, nodeB, t, upgradedId)
    PhysLib:OnDeviceCreated(teamId, deviceId, saveName, nodeA, nodeB, t, upgradedId)
end

function OnGroundDeviceCreated(teamId, deviceId, saveName, pos, upgradedId)
    PhysLib:OnGroundDeviceCreated(teamId, deviceId, saveName, pos, upgradedId)
end

function OnNodeCreated(nodeId, teamId, pos, foundation, selectable, extrusion)
    PhysLib:OnNodeCreated(nodeId, teamId, pos, foundation, selectable, extrusion)
end

function OnNodeDestroyed(nodeId, selectable)
    PhysLib:OnNodeDestroyed(nodeId, selectable)
end

function OnNodeBroken(thisNodeId, nodeIdNew)
    PhysLib:OnNodeBroken(thisNodeId, nodeIdNew)
end

function OnLinkCreated(teamId, saveName, nodeIdA, nodeIdB, pos1, pos2, extrusion)
    PhysLib:OnLinkCreated(teamId, saveName, nodeIdA, nodeIdB, pos1, pos2, extrusion)

    ClearStructureAroundConveyors(teamId, saveName, nodeIdA, nodeIdB)
    
end

function ClearStructureAroundConveyors(teamId, saveName, nodeIdA, nodeIdB)
    if LinkDefinitions[saveName] and LinkDefinitions[saveName].Conveyor then
        local nodeA = PhysLib.NodesRaw[nodeIdA]
        local nodeB = PhysLib.NodesRaw[nodeIdB]
        local nodeBToNodeA = nodeB - nodeA
        local length = math.sqrt(nodeBToNodeA.x * nodeBToNodeA.x + nodeBToNodeA.y * nodeBToNodeA.y)
        local normal = Vec3(nodeBToNodeA.y, -nodeBToNodeA.x)
        if normal.y < 0 then normal = -normal end
        normal = normal / length
        ConvertLinksAboveNode(nodeA, normal, nodeIdA, teamId)
        ConvertLinksAboveNode(nodeB, normal, nodeIdB, teamId)
    end
end

function ConvertLinksAboveNode(node, normal, nodeId, teamId)
    for _, link in pairs(node.links) do
        if link.material ~= "bracing" then continue end
        local dir = node - link.node
        local length = math.sqrt(dir.x * dir.x + dir.y * dir.y)
        dir = dir / length

        local dot = dir.x * normal.x + dir.y * normal.y
        if dot > 0.5 then
            CreateLink(teamId, "backbracing", nodeId, link.node.id)
        end
    end
end


function OnLinkDestroyed(teamId, saveName, nodeIdA, nodeIdB, breakType)
    PhysLib:OnLinkDestroyed(teamId, saveName, nodeIdA, nodeIdB, breakType)
end