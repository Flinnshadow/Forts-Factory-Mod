GlobalModuleIterator = 0
function OnKey(key, down)
    if key == "u" and down then
        CreateItem(ProcessedMousePos(),"apple")
    end
end

function SpawnMetal(deviceId)
    if DeviceExists(deviceId) then
        --Find Output
        pos = GetDevicePosition(deviceId) - Vec3(0, 130)
        CreateItem(pos,"IronOre")
        ScheduleCall(16, SpawnMetal, deviceId) --a mine would have yielded 64 metal, each ore is 50, metal plates are 124 (64 per ore)
        -- if debug then BetterLog(GlobalItemIterator) end
    end
end

function OnDeviceCompleted(teamId, deviceId, saveName)
    --if ModuleCreationDefinitions[saveName] then
        CreateModule(saveName,deviceId)
    --end
end

function CreateModule(deviceName,deviceId) --Externally referred to as a device, alternative names for the virtual devices: Construct, Structure, Facility
    GlobalModuleIterator = GlobalModuleIterator + 1
    Log("1")
    apple = Module:new()
    ExistingModules[GlobalModuleIterator] = apple
    apple:AddInputBuffer(10, {["IronOre"]= true}, Hitbox:new(GetDevicePosition(deviceId), Vec3(100, 100)))
    ScheduleCall(5, SpawnMetal, deviceId)
    BetterLog(apple)
end

ExistingModules = {}

-- Module Class with Dynamic Input, Output Management, and Speed Adjustment
Module = {
    id = 0,
    deviceId = 0,
    inputBuffers = {},
    outputBuffers = {},
    recipes = {},
    craftingTime = 0,
    currentRecipe = nil,
    baseCraftingTime = 100, -- default crafting time (modifiable)
}

function Module:new(deviceId)
    local module = {}
    setmetatable(module, self)
    self.__index = self
    module.id = GlobalModuleIterator
    module.deviceId = deviceId
    module.inputBuffers = {}
    module.outputBuffers = {}
    module.recipes = {}
    return module
end

function Module:AddInputBuffer(bufferSize, itemTypes, hitbox)
    local buffer = {
        maxSize = bufferSize,
        items = {},
        itemTypes = itemTypes or {}, -- allowable item types
        hitbox = hitbox,
        inserterAttached = false
    }
    table.insert(self.inputBuffers, buffer)
end

function Module:AddOutputBuffer(bufferSize, itemType)
    local buffer = {
        maxSize = bufferSize,
        items = {},
        itemType = itemType
    }
    table.insert(self.outputBuffers, buffer)
end

function Module:SetRecipe(recipe)
    self.currentRecipe = recipe
    self.baseCraftingTime = recipe.baseTime
end

function Module:UpdateCrafting()
    if not self.currentRecipe then return end

    -- Check if output buffers have space for the recipe outputs
    for output, quantity in pairs(self.currentRecipe.outputs) do
        if #self:FindBuffer("output", output).items + quantity > self:FindBuffer("output", output).maxSize then
            return -- Halt crafting due to full output buffer
        end
    end

    -- Calculate crafting time reduction based on surplus items
    local surplusFactor = 1
    for input, required in pairs(self.currentRecipe.inputs) do
        local buffer = self:FindBuffer("input", input)
        local surplus = #buffer.items - required
        if surplus > 0 then
            surplusFactor = surplusFactor + (surplus * 0.1) -- each extra item reduces time by 10%
        end
    end

    self.craftingTime = self.baseCraftingTime / surplusFactor
    self.craftingTime = self.craftingTime - 1
    if self.craftingTime <= 0 then
        self:CompleteCrafting()
    end
end

function Module:CompleteCrafting()
    for input, quantity in pairs(self.currentRecipe.inputs) do
        for i = 1, quantity do
            table.remove(self:FindBuffer("input", input).items, 1)
        end
    end

    for output, quantity in pairs(self.currentRecipe.outputs) do
        for i = 1, quantity do
            table.insert(self:FindBuffer("output", output).items, output)
        end
    end

    self.craftingTime = self.baseCraftingTime
end

function Module:FindBuffer(bufferType, itemType)
    local buffers = bufferType == "input" and self.inputBuffers or self.outputBuffers
    for _, buffer in ipairs(buffers) do
        if bufferType == "input" and buffer.itemTypes[itemType] then
            return buffer
        elseif bufferType == "output" and buffer.itemType == itemType then
            return buffer
        end
    end
end

-- Handle Item Grabbing if No Inserter Attached
function Module:GrabItemsAutomatically()
    for _, buffer in ipairs(self.inputBuffers) do
        if not buffer.inserterAttached then
            for key, Object in pairs(PhysicsObjects) do
                local pos = Object.position
                if buffer.hitbox:CheckCollision(pos) then
                    if buffer.itemTypes[Object.itemType] and #buffer.items < buffer.maxSize then
                        table.insert(buffer.items, Object.itemType)
                        BetterLog("Item " .. Object.itemType .. " grabbed by module buffer")
                        DestroyItem(Object, key) -- removes the item from the world
                    end
                end
            end
        end
    end
end


-- Define a Hitbox with Collision Checking
Hitbox = {
    maxX = 0,
    maxY = 0,
    minX = 0,
    minY = 0
}

function Hitbox:new(pos, size)
    local hb = {}
    setmetatable(hb, self)
    self.__index = self
    hb.maxX = pos.x + size.x
    hb.maxY = pos.y + size.y
    hb.minX = pos.x - size.x
    hb.minY = pos.y - size.y
    return hb
end

function Hitbox:CheckCollision(pos)
    return pos.x < self.maxX and pos.x > self.minX and pos.y < self.maxY and pos.y > self.minY
end

-- Inserter Class with Connection Logic
Inserter = {
    inputModule = nil,
    outputModule = nil,
    speed = 10,
    contents = {}
}

function Inserter:ConnectModules(inputModule, outputModule)
    self.inputModule = inputModule
    self.outputModule = outputModule
end

function Inserter:TransferItem(itemType)
    if self.outputModule and self.inputModule then
        local targetBuffer = self.outputModule:FindBuffer("input", itemType)
        if targetBuffer and #targetBuffer.items < targetBuffer.maxSize then
            table.insert(targetBuffer.items, itemType)
            BetterLog("Transferring item: " .. itemType .. " to output module")
        end
    end
end

function Inserter:Update()
    -- Insert logic to handle collision and transfer animation/effects
    for _, item in pairs(self.contents) do
        self:TransferItem(item)
    end
end
