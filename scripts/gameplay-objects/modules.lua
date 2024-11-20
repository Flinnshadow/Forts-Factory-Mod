-- Global state
GlobalModuleIterator = 0
ExistingModules = {}
ExistingInserters = {}

-- Constants
local DEFAULT_BUFFER_SIZE = 10
local DEFAULT_CRAFTING_TIME = 100
local DEFAULT_INSERTER_SPEED = 10
local DEFAULT_ITEM_SPACING = 0.2

ModuleCreationDefinitions = {
    ["pumpjack"] = {
    },
    ["mine"] = function (newModule)
        newModule:AddOutputBuffer(2,"IronOre",Vec3(-50,-50))
        newModule:SetRecipe({
            baseTime = 16,
            inputs = {},
            outputs = {["IronOre"] = 1}
        })
    end,
    ["mine2"] = {
    },
    ["furnace"] = function (newModule, deviceId)
        local basePos = GetDevicePosition(deviceId)
        newModule:AddInputBuffer(4, {["IronOre"] = true}, Hitbox:New(basePos + Vec3(1, 0), Vec3(100, 100)), {x = 0, y = 0})
        newModule:AddOutputBuffer(2, "IronPlate", {x = 0, y = 0})
        newModule:AddOutputBuffer(0, "", {x = 0, y = 0})
        newModule:SetRecipe({
            baseTime = 22, --27.7 == 1.5 & 21.3 == 1.5 * max surplus
            inputs = {["IronOre"] = 2},
            outputs = {["IronPlate"] = 1},
            consumption = Value(0,-10/25),
        })
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

function OnDeviceCompleted(teamId, deviceId, saveName)
    if ModuleCreationDefinitions[saveName] then
        CreateModule(saveName,deviceId)
    end
end

function OnDeviceDestroyed(teamId, deviceId, saveName)
    DestroyModule(deviceId)
end

function CreateModule(deviceName,deviceId) --Externally referred to as a device, alternative names for the virtual devices: Construct, Structure, Facility
    local newModule = Module:New(deviceId)
    ModuleCreationDefinitions[deviceName](newModule,deviceId)
    table.insert(ExistingModules, newModule)
    BetterLog(newModule)
end

function DestroyModule(deviceId)
    for i, module in ipairs(ExistingModules) do
        if module.deviceId == deviceId then
            local pos = GetDevicePosition(deviceId)
            local angle = GetDeviceAngle(deviceId)

            -- Handle input buffers
            for _, buffer in ipairs(module.inputBuffers) do
                local bufferPos = RotatePosition(buffer.relativePosition, angle)
                bufferPos.x = pos.x + bufferPos.x
                bufferPos.y = pos.y + bufferPos.y

                for _, item in ipairs(buffer.items) do
                    CreateItem(bufferPos, item)
                end
            end

            -- Handle output buffers
            for _, buffer in ipairs(module.outputBuffers) do
                local bufferPos = RotatePosition(buffer.relativePosition, angle)
                bufferPos.x = pos.x + bufferPos.x
                bufferPos.y = pos.y + bufferPos.y

                for _, item in ipairs(buffer.items) do
                    CreateItem(bufferPos, item)
                end
            end

            -- Handle connected inserters
            for _, inserter in ipairs(module.connectedInserters) do
                -- Drop inserter contents at its current position
                for _, item in ipairs(inserter.contents) do
                    CreateItem(inserter.currentPosition, item)
                end

                -- Remove inserter from ExistingInserters
                for j, existingInserter in ipairs(ExistingInserters) do
                    if existingInserter == inserter then
                        table.remove(ExistingInserters, j)
                        break
                    end
                end
            end

            -- Remove module from ExistingModules
            table.remove(ExistingModules, i)
            break
        end
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

-- Module Class Definition
Module = {
    id = 0,
    deviceId = 0,
    teamId = 0,
    inputBuffers = {},
    outputBuffers = {},
    connectedInserters = {},
    craftingTime = 0,
    currentRecipe = nil,
    baseCraftingTime = DEFAULT_CRAFTING_TIME,
}

-- Module Core Functions
function Module:New(deviceId)
    local module = {}
    GlobalModuleIterator = GlobalModuleIterator + 1
    setmetatable(module, self)
    self.__index = self
    
    module.id = GlobalModuleIterator
    module.deviceId = deviceId
    module.teamId = GetDeviceTeamIdActual(deviceId)
    module.inputBuffers = {}
    module.outputBuffers = {}
    module.connectedInserters = {}
    
    return module
end

function Module:AddInputBuffer(bufferSize, itemTypes, hitbox, relativePosition)
    local buffer = {
        maxSize = bufferSize or DEFAULT_BUFFER_SIZE,
        items = {},
        itemTypes = itemTypes or {},
        hitbox = hitbox or Hitbox:New(GetDevicePosition(self.deviceId), Vec3(100, 100)),
        inserterAttached = false,
        relativePosition = relativePosition or {x = 0, y = 0}
    }
    table.insert(self.inputBuffers, buffer)
end

function Module:AddOutputBuffer(bufferSize, itemType, relativePosition)
    local buffer = {
        maxSize = bufferSize or DEFAULT_BUFFER_SIZE,
        items = {},
        itemType = itemType,
        relativePosition = relativePosition or {x = 0, y = 0}
    }
    table.insert(self.outputBuffers, buffer)
end

-- Module Recipe Management
function Module:SetRecipe(recipe)
    self.currentRecipe = recipe
    self.baseCraftingTime = recipe.baseTime*25
    self.craftingTime = recipe.baseTime

    -- Configure input buffers
    local i = 1
    for inputItem, _ in pairs(recipe.inputs) do
        local buffer = self.inputBuffers[i]
        if buffer then
            buffer.itemTypes[inputItem] = true
            for j = #buffer.items, 1, -1 do
                if not buffer.itemTypes[buffer.items[j]] then
                    table.remove(buffer.items, j)
                end
            end
        else
            Notice("Recipe has too many inputs for module")
        end
        i = i + 1
    end

    -- Configure output buffers
    local k = 1
    for outputItem, _ in pairs(recipe.outputs) do
        local buffer = self.outputBuffers[k]
        if buffer then
            buffer.itemType = outputItem
            for l = #buffer.items, 1, -1 do
                if buffer.items[l] ~= outputItem then
                    table.remove(buffer.items, l)
                end
            end
        else
            Notice("Recipe has too many outputs for module")
        end
        k = k + 1
    end
end
--[[
Module input buffers must be able to contain multiple item types at once, make inserters check for each type that the connected module wants and the recipe to properly set the input buffers item types
]]
function Module:UpdateCrafting()
    if not self.currentRecipe then return end

    -- Check if there are enough inputs to consume
    for input, required in pairs(self.currentRecipe.inputs) do
        local inputBuffer = self:FindBuffer("input", input)
        if #inputBuffer.items < required then
            return -- Halt crafting due to insufficient input items
        end
    end

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

    if self.currentRecipe.consumption then
        AddResourcesContinuous(self.teamId, self.currentRecipe.consumption)
    end

    self.craftingTime = (self.craftingTime) - 1 * surplusFactor
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
            for _=1, quantity do
                if outputBuffer.inserterAttached then
                    table.insert(outputBuffer.items, output)
                else
                    -- Calculate spawn position based on buffer's relative position and module rotation
                    local pos = GetDevicePosition(self.deviceId)
                    local angle = GetDeviceAngle(self.deviceId)
                    local spawnPos = RotatePosition(outputBuffer.relativePosition, angle)
                    spawnPos.x = pos.x + spawnPos.x
                    spawnPos.y = pos.y + spawnPos.y
                    CreateItem(spawnPos, output)
                end
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

-- Update physics object grabbing
function Module:GrabItemsAutomatically()
    for _, buffer in ipairs(self.inputBuffers) do
        if not buffer.inserterAttached then
            for key, Object in pairs(PhysicsObjects) do
                local pos = Object.position
                if buffer.hitbox:CheckCollision(pos) then
                    if buffer.itemTypes[Object.itemType] and #buffer.items < buffer.maxSize then
                        -- Find connected inserter
                        for _, inserter in ipairs(self.connectedInserters) do
                            if inserter.inputModule == self then
                                inserter:TakeOverEffect(Object)
                                break
                            end
                        end
                        table.insert(buffer.items, Object.itemType)
                        DestroyItem(Object, key)
                    end
                end
            end
        end
    end
end

ExistingInserters = {}

-- Inserter Class Definition
Inserter = {
    inputModule = nil,
    outputModule = nil,
    inputNode = nil,
    outputNode = nil,
    speed = DEFAULT_INSERTER_SPEED,
    contents = {},
    itemsInTransit = {},
    currentPosition = {x = 0, y = 0},
    startPosition = {x = 0, y = 0},
    endPosition = {x = 0, y = 0},
    itemSpacing = DEFAULT_ITEM_SPACING,
    inputHitbox = nil,
}

function Inserter:New(o, speed)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    o.speed = speed or DEFAULT_INSERTER_SPEED
    o.contents = {}
    o.itemsInTransit = {}
    o.currentPosition = {x = 0, y = 0}
    o.startPosition = {x = 0, y = 0}
    o.endPosition = {x = 0, y = 0}
    o.itemSpacing = DEFAULT_ITEM_SPACING
    
    return o
end

function Inserter:CanGrabNewItem()
    if #self.itemsInTransit == 0 then return true end
    -- Check if the last grabbed item has moved far enough
    local lastItem = self.itemsInTransit[#self.itemsInTransit]
    return lastItem.progress >= self.itemSpacing
end

function Inserter:GetItemPosition(progress)
    return {
        x = self.startPosition.x + (self.endPosition.x - self.startPosition.x) * progress,
        y = self.startPosition.y + (self.endPosition.y - self.startPosition.y) * progress,
        z = 0
    }
end

function Inserter:TakeOverEffect(physicsObject)
    local effectId = physicsObject.effectId
    DestroyItem(physicsObject, physicsObject.id, true)
    return effectId
end

function Inserter:CreateItemEffect(itemType, position)
    return SpawnEffectEx(path .. "/effects/".. ItemDefinitions[itemType].MaterialType ..".lua", position, Vec3(0, -1))
end

function Inserter:ConnectToModule(module)
    if module then
        table.insert(module.connectedInserters, self)
    end
end

function Inserter:DisconnectFromModule(module)
    if module then
        for i, inserter in ipairs(module.connectedInserters) do
            if inserter == self then
                table.remove(module.connectedInserters, i)
                break
            end
        end
    end
end

function Inserter:ConnectModules(input, output)
    -- Disconnect from previous modules if any
    self:DisconnectFromModule(self.inputModule)
    self:DisconnectFromModule(self.outputModule)

    if input.position then
        self.inputModule = input
        self.inputNode = nil
        local angle = GetDeviceAngle(input.deviceId)
        self.startPosition = RotatePosition(input.relativePosition, angle)
        self.startPosition.x = input.position.x + self.startPosition.x
        self.startPosition.y = input.position.y + self.startPosition.y
        self:ConnectToModule(input)
    else
        self.inputNode = input
        self.inputModule = nil
        self.startPosition = input.position
        self.inputHitbox = Hitbox:New(input.position, {x = 1, y = 1})
    end

    if output.position then
        self.outputModule = output
        self.outputNode = nil
        local angle = GetDeviceAngle(output.deviceId)
        self.endPosition = RotatePosition(output.relativePosition, angle)
        self.endPosition.x = output.position.x + self.endPosition.x
        self.endPosition.y = output.position.y + self.endPosition.y
        self:ConnectToModule(output)
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

function Inserter:TransferItems()
    for i = #self.itemsInTransit, 1, -1 do
        local item = self.itemsInTransit[i]
        if item.progress >= 1.0 then
            if self.outputModule then
                local targetBuffer = self.outputModule:FindBuffer("input", item.itemType)
                if targetBuffer and #targetBuffer.items < targetBuffer.maxSize then
                    table.insert(targetBuffer.items, item.itemType)
                    CancelEffect(item.effectId)
                    table.remove(self.itemsInTransit, i)
                end
            elseif self.outputNode then
                -- Transfer effect to new physics object
                CreateItem(self.endPosition, item.itemType, nil, item.effectId)
                table.remove(self.itemsInTransit, i)
            end
        end
    end
end

function Inserter:Update(dt)
    -- Update positions of items in transit
    for _, item in ipairs(self.itemsInTransit) do
        item.progress = item.progress + (dt * self.speed / self.transferDuration)
        -- Update effect position
        local pos = self:GetItemPosition(item.progress)
        SetEffectPosition(item.effectId, pos)
    end

    -- Transfer completed items
    for i = #self.itemsInTransit, 1, -1 do
        local item = self.itemsInTransit[i]
        if item.progress >= 1.0 then
            if self.outputModule then
                local targetBuffer = self.outputModule:FindBuffer("input", item.itemType)
                if targetBuffer and #targetBuffer.items < targetBuffer.maxSize then
                    table.insert(targetBuffer.items, item.itemType)
                    CancelEffect(item.effectId) -- Clean up effect
                    table.remove(self.itemsInTransit, i)
                end
            elseif self.outputNode then
                CreateItem(self.endPosition, item.itemType)
                CancelEffect(item.effectId) -- Clean up effect
                table.remove(self.itemsInTransit, i)
            end
        end
    end

    -- Try to grab new items if there's space
    if self:CanGrabNewItem() then
        if #self.contents > 0 then
            local itemType = table.remove(self.contents, 1)
            local effectId = self:CreateItemEffect(itemType, self.startPosition)
            table.insert(self.itemsInTransit, {
                itemType = itemType,
                progress = 0,
                effectId = effectId
            })
        end
    end
end


-- Helper function to get all item positions for rendering
function Inserter:GetAllItemPositions()
    local positions = {}
    for _, item in ipairs(self.itemsInTransit) do
        table.insert(positions, {
            position = self:GetItemPosition(item.progress),
            itemType = item.itemType
        })
    end
    return positions
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
    hb.size = size
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

function RotatePosition(position, angle)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)
    return {
        x = position.x * cosAngle - position.y * sinAngle,
        y = position.x * sinAngle + position.y * cosAngle,
        z = 0
    }
end

function OnKey(key, down)
    if key == "u" and down then
        CreateItem(ProcessedMousePos(),"IronOre")
    end
    if key == "i" and down then
        CreateItem(ProcessedMousePos(),"apple")
    end
    if key == "o" and down then
        BetterLog(ExistingModules)
    end
end

--[[
ModuleIndexMap = {} -- deviceId -> index lookup

function CreateModule(deviceName, deviceId)
    local newModule = Module:New(deviceId)
    ModuleCreationDefinitions[deviceName](newModule, deviceId)
    table.insert(ExistingModules, newModule)
    ModuleIndexMap[deviceId] = #ExistingModules
    BetterLog(newModule)
end

function DestroyModule(deviceId)
    local index = ModuleIndexMap[deviceId]
    if index then
        local module = ExistingModules[index]
        -- ... existing drop items code ...
        
        -- Update index map for shifted modules
        for i = index + 1, #ExistingModules do
            ModuleIndexMap[ExistingModules[i].deviceId] = i - 1
        end
        
        table.remove(ExistingModules, index)
        ModuleIndexMap[deviceId] = nil
    end
end
]]