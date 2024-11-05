Device = {
   IsPhysical = true,
   Id = 0,
   PassiveMatChange = Value(0,0),
   EnergyGridChange = 0,
   LinkedDevices =   {{id = 0, consumer = true,producer = false,belt=false,displaysSideBySide = false}},
   InputHitBox =     {position = Vec3(0,0), Size = Vec3(100,100)},
   Inputs =          {position = Vec3(0,0), Request = "IronOre", Inputs = {id = 0}},
   Outputs =         {position = Vec3(0,0), Outputs = {id = 0}},
   OverFlowOutput =  {position = Vec3(0,0), Outputs = {id = 0}},
}

Spliter = {inputParent = Device}


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