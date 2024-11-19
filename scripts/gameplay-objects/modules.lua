GlobalModuleIterator = 0

ModuleCreationDefinitions = {
    ["pumpjack"] = {
    },
    ["mine"] = function (newModule)
        newModule:AddOutputBuffer(2,"IronOre",Vec3(-50,-50))
    end,
    ["mine2"] = {
    },
    ["furnace"] = function (newModule,deviceId)
        basePos = GetDevicePosition(deviceId)
        Module:AddInputBuffer(6,"IronOre",Hitbox:New(basePos+Vec3(1,0), Vec3(100, 100)))
        Module:AddOutputBuffer(3,"IronPlate",Vec3())
        Module:AddOutputBuffer(3,"",Vec3())
    end,
    ["steelfurnace"] = {
    },
    ["chemicalplant"] = {
    },
    ["constructor"] = {
    },
    ["inserter"] = {

    },
}

function OnKey(key, down)
    if key == "u" and down then
        CreateItem(ProcessedMousePos(),"apple")
    end
    if key == "i" and down then
        CreateItem(ProcessedMousePos(),"apple")
    end
end

function SpawnMetal(deviceId)
    if DeviceExists(deviceId) then
        --Find Output
        pos = GetDevicePosition(deviceId) - Vec3(0, 130)
        CreateItem(pos,"IronOre")
        ScheduleCall(16/16, SpawnMetal, deviceId) --a mine would have yielded 64 metal, each ore is 50, metal plates are 124 (64 per ore)
        -- if debug then BetterLog(GlobalItemIterator) end
    end
end

function OnDeviceCompleted(teamId, deviceId, saveName)
    if ModuleCreationDefinitions[saveName] then
        CreateModule(saveName,deviceId)
    end
end

function UpdateModules()
    for _, module in pairs(ExistingModules) do
        module:GrabItemsAutomatically()
        module:UpdateCrafting()
        if module.deviceId then
            local pos = GetDevicePosition(module.deviceId)
            local angle = GetDeviceAngle(module.deviceId)
            for _, buffer in ipairs(module.inputBuffers) do
                if buffer.hitbox then
                    local bufferPos = RotatePosition(buffer.relativePosition, angle)
                    bufferPos.x = pos.x + bufferPos.x
                    bufferPos.y = pos.y + bufferPos.y
                    buffer.hitbox:UpdatePosition(bufferPos)
                end
            end
            for _, buffer in ipairs(module.outputBuffers) do
                if buffer.hitbox then
                    local bufferPos = RotatePosition(buffer.relativePosition, angle)
                    bufferPos.x = pos.x + bufferPos.x
                    bufferPos.y = pos.y + bufferPos.y
                    buffer.hitbox:UpdatePosition(bufferPos)
                end
            end
        end
    end

    for _, inserter in pairs(ExistingInserters) do
        inserter:Update()
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

function RotatePosition(position, angle)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)
    return {
        x = position.x * cosAngle - position.y * sinAngle,
        y = position.x * sinAngle + position.y * cosAngle
    }
end

function CreateModule(deviceName,deviceId) --Externally referred to as a device, alternative names for the virtual devices: Construct, Structure, Facility
    local newModule = Module:New(deviceId)
    ModuleCreationDefinitions[deviceName](newModule,deviceId)
    apple:AddInputBuffer(10, {["IronOre"]= true}, Hitbox:New(GetDevicePosition(deviceId), Vec3(100, 100)))
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
    baseCraftingTime = 100,
}

function Module:New(deviceId)
    local module = {}
    GlobalModuleIterator = GlobalModuleIterator + 1
    ExistingModules[GlobalModuleIterator] = module
    setmetatable(module, self)
    self.__index = self
    module.id = GlobalModuleIterator
    module.deviceId = deviceId
    module.inputBuffers = {}
    module.outputBuffers = {}
    module.recipes = {}
    return module
end

function Module:AddInputBuffer(bufferSize, itemTypes, hitbox, relativePosition)
    local buffer = {
        maxSize = bufferSize,
        items = {},
        itemTypes = itemTypes or {}, -- allowable item types
        hitbox = hitbox,
        inserterAttached = false,
        relativePosition = relativePosition or {x = 0, y = 0}
    }
    table.insert(self.inputBuffers, buffer)
end

function Module:AddOutputBuffer(bufferSize, itemType, relativePosition)
    local buffer = {
        maxSize = bufferSize,
        items = {},
        itemType = itemType,
        relativePosition = relativePosition or {x = 0, y = 0}
    }
    table.insert(self.outputBuffers, buffer)
end

function Module:SetRecipe(recipe)
    self.currentRecipe = recipe
    self.baseCraftingTime = recipe.baseTime

    -- Configure input buffers based on the recipe
    local i = 1
    for inputItem, _ in pairs(recipe.inputs) do
        local buffer = self.inputBuffers[i]
        if buffer then
            if type(inputItem) == "table" then
                for key, inputItem in pairs() do
                    buffer.itemTypes = {[inputItem] = true}
                end
            else
                buffer.itemTypes = {[inputItem] = true}
            end
            buffer.items = {}
            buffer.inserterAttached = false
        else
            Notice("Recipe has too many inputs for module")
            self:AddInputBuffer(10, {[inputItem] = true}, nil, {x = 0, y = 0}) -- Example size and position
        end
        i = i + 1
    end

    -- Configure output buffers based on the recipe
    local k = 1
    for outputItem, _ in pairs(recipe.outputs) do
        local buffer = self.outputBuffers[k]
        if buffer then
            buffer.itemType = outputItem
            buffer.items = {}
            buffer.inserterAttached = false
        else
            Notice("Recipe has too many outputs for module")
            self:AddOutputBuffer(10, outputItem, {x = 0, y = 0}) -- Example size and position
        end
        k = k + 1
    end

end
--[[
Module input buffers must be able to contain multiple item types at once, make inserters check for each type that the connected module wants and the recipe to properly set the input buffers item types
]]
function Module:UpdateCrafting()
    if not self.currentRecipe then return end

    -- Check if output buffers have space for the recipe outputs
    for output, quantity in pairs(self.currentRecipe.outputs) do
        local outputBuffer = self:FindBuffer("output", output)
        if #outputBuffer.items + quantity > outputBuffer.maxSize then
            return -- Halt crafting due to full output buffer
        end
    end

    -- Calculate crafting time reduction based on surplus items
    local surplusFactor = 1
    for input, required in pairs(self.currentRecipe.inputs) do
        local inputBuffer = self:FindBuffer("input", input)
        local surplus = #inputBuffer.items - required
        if surplus > 0 then
            surplusFactor = surplusFactor + (surplus * 0.1) -- each extra item reduces time by 10%
        end
    end

    self.craftingTime = self.baseCraftingTime / surplusFactor
    self.craftingTime = self.craftingTime - 1
    if self.craftingTime <= 0 then
        -- Move items from input buffers to output buffers
        for input, required in pairs(self.currentRecipe.inputs) do
            local inputBuffer = self:FindBuffer("input", input)
            for i = 1, required do
                table.remove(inputBuffer.items)
            end
        end

        for output, quantity in pairs(self.currentRecipe.outputs) do
            local outputBuffer = self:FindBuffer("output", output)
            for i = 1, quantity do
                table.insert(outputBuffer.items, output)
            end
        end

        -- Reset crafting time
        self.craftingTime = self.baseCraftingTime
    end
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

ExistingInserters = {}

-- Inserter Class with Connection Logic
Inserter = {
    inputModule = nil,
    outputModule = nil,
    inputNode = nil,
    outputNode = nil,
    speed = 10,
    contents = {},
    transferTime = 0,
    transferDuration = 0, -- duration in seconds for a transfer
    currentPosition = {x = 0, y = 0},
    startPosition = {x = 0, y = 0},
    endPosition = {x = 0, y = 0},
    itemSpacing = 0.1, -- minimum distance between items
    inputHitbox = nil
}

function Inserter:New(o, speed)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.speed = speed or 10
    o.contents = {}
    o.transferTime = 0
    o.transferDuration = 0
    o.currentPosition = {x = 0, y = 0}
    o.startPosition = {x = 0, y = 0}
    o.endPosition = {x = 0, y = 0}
    o.itemSpacing = self.itemSpacing
    o.inputHitbox = nil
    return o
end

function Inserter:ConnectModules(input, output)
    if input.position then
        self.inputModule = input
        self.inputNode = nil
        local angle = GetDeviceAngle(input.deviceId)
        self.startPosition = RotatePosition(input.relativePosition, angle)
        self.startPosition.x = input.position.x + self.startPosition.x
        self.startPosition.y = input.position.y + self.startPosition.y
    else
        self.inputNode = input
        self.inputModule = nil
        self.startPosition = input.position
        self.inputHitbox = Hitbox:New(input.position, {x = 100, y = 100}) -- Example size
    end

    if output.position then
        self.outputModule = output
        self.outputNode = nil
        local angle = GetDeviceAngle(output.deviceId)
        self.endPosition = RotatePosition(output.relativePosition, angle)
        self.endPosition.x = output.position.x + self.endPosition.x
        self.endPosition.y = output.position.y + self.endPosition.y
    else
        self.outputNode = output
        self.outputModule = nil
        self.endPosition = output.position
    end

    self:CalculateTransferDuration()
end

function Inserter:CalculateTransferDuration()
    local dx = self.endPosition.x - self.startPosition.x
    local dy = self.endPosition.y - self.startPosition.y
    local distance = math.sqrt(dx * dx + dy * dy)
    self.transferDuration = distance / self.speed
end

function Inserter:TransferItems(itemTypes)
    if self.outputModule then
        for _, itemType in ipairs(itemTypes) do
            local targetBuffer = self.outputModule:FindBuffer("input", itemType)
            if targetBuffer and #targetBuffer.items < targetBuffer.maxSize then
                table.insert(targetBuffer.items, itemType)
                BetterLog("Transferring item: " .. itemType .. " to output module")
            end
        end
    elseif self.outputNode then
        CreateItem(self.endPosition)
        BetterLog("Transferring items to output node")
    end
end

function Inserter:Update()
    if self.transferTime > 0 then
        self.transferTime = self.transferTime - data.updateDelta
        local progress = 1 - (self.transferTime / self.transferDuration)
        self.currentPosition.x = self.startPosition.x + (self.endPosition.x - self.startPosition.x) * progress
        self.currentPosition.y = self.startPosition.y + (self.endPosition.y - self.startPosition.y) * progress
    else
        if #self.contents > 0 then
            local itemsToTransfer = {}
            local itemsToRemove = math.min(#self.contents, math.floor(self.speed * dt / self.itemSpacing))
            for i = 1, itemsToRemove do
                table.insert(itemsToTransfer, table.remove(self.contents, 1))
            end
            self:TransferItems(itemsToTransfer)
            self.transferTime = self.transferDuration
            self.currentPosition = self.startPosition
        end
    end
    --[[if self.inputNode then
        local pos = NodePosition(self.inputNode)
        if self.inputHitbox then
            self.inputHitbox:UpdatePosition(pos)
        end
    end
    if self.outputNode then
        local pos = NodePosition(self.outputNode)
        if self.outputHitbox then
            self.outputHitbox:UpdatePosition(pos)
        end
    end]]
end

-- Define a Hitbox with Collision Checking
Hitbox = {
    maxX = 0,
    maxY = 0,
    minX = 0,
    minY = 0
}

function Hitbox:New(pos, size)
    local hb = {}
    setmetatable(hb, self)
    self.__index = self
    hb.maxX = pos.x + size.x
    hb.maxY = pos.y + size.y
    hb.minX = pos.x - size.x
    hb.minY = pos.y - size.y
    return hb
end

function Hitbox:UpdatePosition(pos)
    self.maxX = pos.x + self.size.x
    self.maxY = pos.y + self.size.y
    self.minX = pos.x - self.size.x
    self.minY = pos.y - self.size.y
end

function Hitbox:CheckCollision(pos)
    return pos.x < self.maxX and pos.x > self.minX and pos.y < self.maxY and pos.y > self.minY
end
