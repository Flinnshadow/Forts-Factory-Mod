GlobalModuleIterator = 0
ExistingModules = {}

GlobalInputHitboxIterator = 0
ModuleInputHitboxes = {}


ModuleCreationDefinitions = {
    ["pumpjack"] = {
    },
    ["mine"] = {
        Id = 0,
        DeviceId = 0,
        Created = function(deviceId) Id = GlobalModuleIterator; DeviceId = deviceId; ScheduleCall(5, SpawnMetal, deviceId) end,
        Update = function() --[[process Items]] end,
        Destroyed = function() UnLinkAllModules = function() end end,
        LinkModule = function() end,
        UnLinkModule = function() end,
    },
    ["mine2"] = {
    },
    ["furnace"] = {
        Id = 0,
        DeviceId = 0,
        InputItem = function() --[[DestroyItem]]end,
        Inputs = {{InputBuffer = {size = 1,"IronOre"}, Connections = { }, requests = {"IronOre"},--[[position = Vec3(0,0),]]}},
        Outputs = {{OutputBuffer = {size = 1,"IronOre"}, Connections = { }, requests = {"IronPlate"},--[[position = Vec3(0,0),]]}},
        Created = function(deviceId)
            self.Id = GlobalModuleIterator; DeviceId = deviceId
            AddModuleInputHitbox(self.Id,GetDevicePosition(deviceId),100,GetDevicePosition,deviceId)

        end,
    },
    ["steelfurnace"] = {
    },
    ["chemicalplant"] = {
    },
    ["constructor"] = {
    },
    ["inserter"] = {
        InputModule = module1,
        OutputModule = module2,
        Length = 100,
        Speed = 10,
        Contents = {["IronOre"] = 10},
        Update = function() --[[move items]] end,
    },
}

function AddModuleInputHitbox(id,pos,bounds,checkFunction,variable)
    GlobalInputHitboxIterator = GlobalInputHitboxIterator + 1
    ModuleInputHitboxes[GlobalInputHitboxIterator]={
        MaxX = pos.x+bounds.x,MaxY = pos+bounds.y,MinX = pos-bounds.x,MinY = pos-bounds.y,
        MaxXB = pos.x+30,MaxYB = pos+30,MinXB = pos-30,MinYB = pos-30,
        Bounds=bounds, Pos = pos, CheckFunction = checkFunction,Variable = variable, Module = ExistingModules[id]
    }
end

function ModuleInputHitboxPositionUpdate()
    for _, HB in pairs(ModuleInputHitboxes) do
        local pos = HB.CheckFunction(HB.Variable)
        if HB.MaxXB < pos.x or HB.MinXB > pos.x or HB.MaxYB < pos.y or HB.MinYB > pos.y then
            MaxX = pos.x+HB.Bounds.x MaxY = pos+HB.Bounds.y MinX = pos-HB.Bounds.x MinY = pos-HB.Bounds.y
            HB.MaxXB = pos.x+30 HB.MaxY = pos+30 HB.MinX = pos-30 HB.MinY = pos-30 HB.Pos = pos
        end
    end
end

SpawnItems = false
--ContainItem()
function OnKey(key, down)
    if key == "u" then
        SpawnItems = down
    end
end

function SpawnMetal(deviceId)
    if DeviceExists(deviceId) then
        --Find Output
        local pos = GetDevicePosition(deviceId) - Vec3(0, 130)
        CreateItem(pos,"IronOre")
        ScheduleCall(16, SpawnMetal, deviceId) --a mine would have yielded 64 metal, each ore is 50, metal plates are 124 (64 per ore)
        -- if debug then BetterLog(GlobalItemIterator) end
    end
end

function OnDeviceCompleted(teamId, deviceId, saveName)
    if ModuleCreationDefinitions[saveName] then
        CreateModule(saveName,deviceId)
    end
end

function CreateModule(deviceName,deviceId) --Externally referred to as a device, alternative names for the virtual devices: Construct, Structure, Facility
    GlobalModuleIterator = GlobalModuleIterator + 1
    ExistingModules[GlobalModuleIterator] = DeepCopy(ModuleCreationDefinitions[deviceName])
    ExistingModules[GlobalModuleIterator]:Created(deviceId)
end



--TODO: test: Module:Update    Update() Log(self.apple)  end

--[[Module = {
   IsPhysical = true,
   Id = 0,
   PassiveMatChange = Value(0,0),
   EnergyGridChange = 0,
   LinkedModules =   {{id = 0, consumer = true,producer = false,belt=false,displaysSideBySide = false}},
   InputRequests =   {"IronOre"},
   InputHitBox =     {position = Vec3(0,0), Size = Vec3(100,100)},
   Inputs =          {position = Vec3(0,0), Requests = {"IronOre"}, Inputs = {id = 0}},
   Outputs =         {position = Vec3(0,0), Outputs = {id = 0}},
   OverFlowOutput =  {position = Vec3(0,0), Outputs = {id = 0}},
}]]

--[[function CreateFurnace(obj)
    furn = Module.new
    furn:HitboxInput(Vec3(0,0))
    furn:Input(Vec3(0,0))
    furn:Output(Vec3(0,0))
    furn:OverflowOutput(Vec3(0,0))
    furn:Processer(
        FindInput,FindOutput
    )
end]]

function EMPLands()
    if DeviceDisabled(deviceId) then DeviceEMPed(deviceId)end
    GetDeviceState(deviceId)
end

--Idea: every device produces 0.01 metal, if the metal gen changes from last frame check if any devices have changed state

--[[
DEVICE_CONSTRUCTION
DEVICE_IDLE
DEVICE_REPAIR
DEVICE_SCRAP
DEVICE_DELETE
function ModuleEMPed(id)
    if Modules[id].EMPed then
        Modules[id]:EMPed()
    end
end]]

--[[function ModuleHitbox()
    
end]]

--Update: SC(ItemSlot1BecomesProccessed, timeRemainingForOtherEventAfterThisOne1,timeRemainingForOtherEvent2,timeRemainingForOtherEvent3)
--[[
Module = {
    [deviceId] = {
    Id = 0,
    Update = function()  end,
    Destroyed = function() UnLinkAllModules = function() end end,
    LinkModule = function() end,
    UnLinkModule = function() end,
    --[=[EMPed = function () end,
    EMPEnd = function () end,
    Repairing = function () end,
    RepairEnd = function () end,
    Scrapping = function () end,
    ScrappingEnd = function () end,
    Disabled = function () end,
    DisableEnd = function () end,]=]
    }
}]]
--[[
Module = {

    Id = 0,
    EnergyGridChange = 0,
    PassiveMaterialChange = Value(0,0), -- only for virtual devices
    ProcessingMaterialChange = Value(0,0),
    ProcessingProgress = 0, -- likely want a SC batch call rather then a constantly updating individual timer
    InputHitBox =    {position = Vec3(0,0), size = Vec3(100,100)},
    Inputs =         {Connections = { }, requests = {"IronOre"},position = Vec3(0,0),},
    Outputs =        {Connections = { }, requests = {"IronOre"},position = Vec3(0,0),},
    InputBuffer =    {size = 1,"IronOre"},
    OutputBuffer =   {size = 1,"IronPlate"},
    OverflowOutput = {position = Vec3(0,0)},

    Update = function(self, inputRate, processTime, inputRequests)
        local obj = setmetatable({}, { __index = self })
        GlobalModuleIterator = GlobalModuleIterator + 1
        obj.Id = GlobalModuleIterator
        obj.InputRate = inputRate
        obj.ProcessTime = processTime
        obj.InputRequests = inputRequests or {}
        obj.Inputs = {}
        obj.Outputs = {}
        obj.LinkedInserters = {}
        return obj
    end,

}]]

--[[
function LinkModule(module1,module2)
   if module1.id == device2.id then return end
   for i=1,2 do
      apple = _G["module"..i]
      apple2 = _G["module".. 3-i]
      for key, value in pairs(apple.LinkedModules) do
         if value.id == apple2.id then return end
      end
   end
end]]