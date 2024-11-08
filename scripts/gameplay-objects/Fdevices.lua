--[[Device = {
   IsPhysical = true,
   Id = 0,
   PassiveMatChange = Value(0,0),
   EnergyGridChange = 0,
   LinkedDevices =   {{id = 0, consumer = true,producer = false,belt=false,displaysSideBySide = false}},
   InputRequests =   {"IronOre"},
   InputHitBox =     {position = Vec3(0,0), Size = Vec3(100,100)},
   Inputs =          {position = Vec3(0,0), Requests = {"IronOre"}, Inputs = {id = 0}},
   Outputs =         {position = Vec3(0,0), Outputs = {id = 0}},
   OverFlowOutput =  {position = Vec3(0,0), Outputs = {id = 0}},
}]]

--[[function CreateFurnace(obj)
    furn = Device.new
    furn:HitboxInput(Vec3(0,0))
    furn:Input(Vec3(0,0))
    furn:Output(Vec3(0,0))
    furn:OverflowOutput(Vec3(0,0))
    furn:Processer(
        FindInput,FindOutput
    )
end]]

for key, value in pairs(Devices) do
    Device:Update()
end

GlobalDeviceIterator = 0

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
function DeviceEMPed(id)
    if Devices[id].EMPed then
        Devices[id]:EMPed()
    end
end]]

Device = {
    [deviceId] = {
    Id = 0,
    Update = function() --[[process Items]] end,
    Destroyed = function() UnLinkAllDevices = function() end end,
    LinkDevice = function() end,
    UnLinkDevice = function() end,
    --[[EMPed = function () end,
    EMPEnd = function () end,
    Repairing = function () end,
    RepairEnd = function () end,
    Scrapping = function () end,
    ScrappingEnd = function () end,
    Disabled = function () end,
    DisableEnd = function () end,]]
    }
}

Device = {

    Id = 0,
    EnergyGridChange = 0,
    PassiveMaterialChange = Value(0,0),
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
        GlobalDeviceIterator = GlobalDeviceIterator + 1
        obj.Id = GlobalDeviceIterator
        obj.InputRate = inputRate
        obj.ProcessTime = processTime
        obj.InputRequests = inputRequests or {}
        obj.Inputs = {}
        obj.Outputs = {}
        obj.LinkedInserters = {}
        return obj
    end,

}

Inserter = {
    InputDevice = Device1,
    OutputDevice = Device2,
    Length = 100,
    Speed = 10,
    Contents = {["IronOre"] = 10},
}

function LinkDevice(device1,device2)
   if device1.id == device2.id then return end
   for i=1,2 do
      apple = _G["device"..i]
      apple2 = _G["device".. 3-i]
      for key, value in pairs(apple.LinkedDevices) do
         if value.id == apple2.id then return end
      end
   end
end

--[[
-- Device Class with Initialization
Device = {
   Id = 0,
   InputRate = 1, -- Items per second
   ProcessTime = 5, -- Seconds needed to process an item
   InputRequests = {"IronOre"}, -- Items it can take in
   Inputs = {}, -- Current input storage
   Outputs = {}, -- Processed items ready for output
   LinkedInserters = {}, -- Connected inserters

   -- Constructor for new device instance
   new = function(self, id, inputRate, processTime, inputRequests)
      local obj = setmetatable({}, { __index = self })
      obj.Id = id
      obj.InputRate = inputRate
      obj.ProcessTime = processTime
      obj.InputRequests = inputRequests or {}
      obj.Inputs = {}
      obj.Outputs = {}
      obj.LinkedInserters = {}
      return obj
   end,

   -- Process input items after ProcessTime
   processItems = function(self, deltaTime)
      for _, item in pairs(self.Inputs) do
         item.time = (item.time or 0) + deltaTime
         if item.time >= self.ProcessTime then
            table.insert(self.Outputs, item.name)
            item.time = 0
         end
      end
   end,

   -- Request items from inserters
   requestItems = function(self)
      for _, inserter in pairs(self.LinkedInserters) do
         inserter:attemptTransfer(self)
      end
   end
}
]]