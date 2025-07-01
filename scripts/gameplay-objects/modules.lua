-- Global state
GlobalModuleIterator = 0
ExistingFloatingModules = {}
ExistingDeviceModules = {}
ExistingInserters = {}

-- Active/Sleeping state tables
ActiveDeviceModules = {}
SleepingDeviceModules = {}
ActiveInserters = {}
SleepingInserters = {}

-- Index maps for efficient removal
DeviceModuleIndexMap = {} -- deviceId -> module lookup
ModuleActiveIndexMap = {} -- module -> index in ActiveDeviceModules
ModuleSleepingIndexMap = {} -- module -> index in SleepingDeviceModules
InserterActiveIndexMap = {} -- inserter -> index in ActiveInserters
InserterSleepingIndexMap = {} -- inserter -> index in SleepingInserters

-- Constants
local DEFAULT_BUFFER_SIZE = 2
local DEFAULT_CRAFTING_TIME = 250 --10s TODO: Multi by 25 done not at recipe set
local DEFAULT_INSERTER_SPEED = 10
local DEFAULT_ITEM_SPACING = 0.2
local DEFAULT_PICKUP_RADIUS = 50 -- Radius for automatic item pickup

ModuleCreationDefinitions = {
    ["derrick"] = function (newModule)
        newModule:AddOutputBuffer(12,"Oil",Vec3(-40,-250))
        newModule:SetRecipe(Recipes.derrick.oil)
    end,
    ["mine"] = function (newModule)
        newModule:AddOutputBuffer(2,"IronOre",Vec3(-25,-110))
        newModule:SetRecipe(Recipes.mine.ore)
    end,
    ["mine2"] = function (newModule)
        newModule:AddOutputBuffer(2,"IronOre",Vec3(-25,-110))
        newModule:SetRecipe(Recipes.mine2.ore)
    end,
    ["furnace"] = function (newModule, deviceId)
        local basePos = GetDevicePosition(deviceId)
        newModule:AddInputBuffer(4, {"IronOre"}, Hitbox:New(basePos + Vec3(0, -1000), Vec3(100, 100)), {x = 0, y = -70})
        newModule:AddOutputBuffer(2, "IronPlate", {x = -30, y = 20})
        newModule:AddOutputBuffer(0, "", {x = 30, y = 20})
        newModule:SetRecipe(Recipes.furnace.ironPlate)
    end,
    ["steelfurnace"] = function (newModule, deviceId)
        local basePos = GetDevicePosition(deviceId)
        newModule:AddInputBuffer(4, {"IronOre"}, Hitbox:New(basePos + Vec3(1, 0), Vec3(100, 100)), {x = 0, y = -70})
        newModule:AddOutputBuffer(2, "IronPlate", {x = -30, y = 20})
        newModule:AddOutputBuffer(0, "", {x = 30, y = 20})
        newModule:SetRecipe(Recipes.steelfurnace.ironPlate)
    end,
    ["chemicalplant"] = function (newModule, deviceId)
        local basePos = GetDevicePosition(deviceId)
        newModule:AddInputBuffer(4, {"IronPlate"}, Hitbox:New(basePos + Vec3(1, 0), Vec3(100, 100)), {x = 0, y = 50})
        newModule:AddOutputBuffer(2, "SulfuricAcid", {x = 30, y = 0})
        newModule:AddOutputBuffer(0, "", {x = -30, y = 0})
        newModule:SetRecipe(Recipes.chemicalplant.sulfuricAcid)
    end,
    ["constructor"] = function (newModule, deviceId)
        local basePos = GetDevicePosition(deviceId)
        newModule:AddInputBuffer(4, {"IronPlate"}, Hitbox:New(basePos + Vec3(1, 0), Vec3(100, 100)), {x = 0, y = -100}) --{["IronPlate"] = true} 
        newModule:AddOutputBuffer(2, "Ammo", {x = 30, y = 0})
        newModule:AddOutputBuffer(0, "", {x = -30, y = 0})
        newModule:SetRecipe(Recipes.constructor.ammo)
    end,
    ["inserter"] = { -- Not going to be a module, different system entirely, normal modules are not going to support 2x device/link connections NOTE: May be fine to make conveyors have a module for connecting too lol

    },
}

--[[{
    baseTime = 35,
    inputs = {["IronPlate"] = 3}, 
    outputs = {["Steel"] = 2,["Slag"] = 1},
    consumption = Value(0,-15/25),
}
-- advanced = {input = SulfuricAcid, 
--baseTime = 22 iron, baseTime2 = 30 = dirtyIron, baseTime3 = 40, slag}
]]


--ModuleIndexMap = {} -- deviceId -> index lookup

function CreateModule(deviceName,deviceId) --Externally referred to as a device; alternative names for the virtual devices: Construct, Structure, Facility
    local newModule = Module:New(deviceId)
    ModuleCreationDefinitions[deviceName](newModule,deviceId)
    table.insert(ExistingDeviceModules, newModule)
    -- Start modules in sleeping state by default
    table.insert(SleepingDeviceModules, newModule)
    DeviceModuleIndexMap[deviceId] = newModule
    ModuleSleepingIndexMap[newModule] = #SleepingDeviceModules
    newModule:CheckAndUpdateState() -- Initial state check
end

function DestroyModule(deviceId)
    local module = DeviceModuleIndexMap[deviceId]
    if not module then return end
    
    local pos = GetDevicePosition(deviceId)
    local angle = GetDeviceAngle(deviceId) - 1.57079633

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

        -- Remove inserter from all tables using index maps
        for j, existingInserter in ipairs(ExistingInserters) do
            if existingInserter == inserter then
                table.remove(ExistingInserters, j)
                break
            end
        end
        
        local activeIndex = InserterActiveIndexMap[inserter]
        if activeIndex then
            local lastInserter = ActiveInserters[#ActiveInserters]
            ActiveInserters[activeIndex] = lastInserter
            InserterActiveIndexMap[lastInserter] = activeIndex
            ActiveInserters[#ActiveInserters] = nil
            InserterActiveIndexMap[inserter] = nil
        end
        
        local sleepingIndex = InserterSleepingIndexMap[inserter]
        if sleepingIndex then
            local lastInserter = SleepingInserters[#SleepingInserters]
            SleepingInserters[sleepingIndex] = lastInserter
            InserterSleepingIndexMap[lastInserter] = sleepingIndex
            SleepingInserters[#SleepingInserters] = nil
            InserterSleepingIndexMap[inserter] = nil
        end
    end

    -- Remove module from all tables using index maps
    for i, existingModule in ipairs(ExistingDeviceModules) do
        if existingModule == module then
            table.remove(ExistingDeviceModules, i)
            break
        end
    end
    
    local activeIndex = ModuleActiveIndexMap[module]
    if activeIndex then
        local lastModule = ActiveDeviceModules[#ActiveDeviceModules]
        ActiveDeviceModules[activeIndex] = lastModule
        ModuleActiveIndexMap[lastModule] = activeIndex
        ActiveDeviceModules[#ActiveDeviceModules] = nil
        ModuleActiveIndexMap[module] = nil
    end
    
    local sleepingIndex = ModuleSleepingIndexMap[module]
    if sleepingIndex then
        local lastModule = SleepingDeviceModules[#SleepingDeviceModules]
        SleepingDeviceModules[sleepingIndex] = lastModule
        ModuleSleepingIndexMap[lastModule] = sleepingIndex
        SleepingDeviceModules[#SleepingDeviceModules] = nil
        ModuleSleepingIndexMap[module] = nil
    end
    
    DeviceModuleIndexMap[deviceId] = nil
end
--[[
function UpdateModules()
    -- Update Modules
    for _, module in pairs(ExistingModules) do
        module:GrabItemsAutomatically()
        module:UpdateCrafting()

        if module.deviceId and not module.isGroundDevice then
            local pos = GetDevicePosition(module.deviceId)
            local angle = GetDeviceAngle(module.deviceId)

            -- Precompute cosine and sine of the angle
            local cosAngle = math.cos(angle)
            local sinAngle = math.sin(angle)

            -- Helper function to update buffer positions
            local function UpdateBufferPositions(buffers)
                for _, buffer in ipairs(buffers) do
                    if buffer.hitbox then
                        -- Rotate the relative position using precomputed cosAngle and sinAngle
                        local relPos = buffer.relativePosition
                        local bufferPos = {
                            x = relPos.x * cosAngle - relPos.y * sinAngle,
                            y = relPos.x * sinAngle + relPos.y * cosAngle
                        }
                        bufferPos.x = pos.x + bufferPos.x
                        bufferPos.y = pos.y + bufferPos.y
                        buffer.hitbox:UpdatePosition(bufferPos)
                    end
                end
            end

            -- Update input and output buffer positions
            UpdateBufferPositions(module.inputBuffers)
            UpdateBufferPositions(module.outputBuffers)
        end
        -- No need to update positions for ground devices
    end

    -- Update Inserters
    for _, inserter in pairs(ExistingInserters) do
        inserter:Update()
        if inserter.inputNode and inserter.inputHitbox then
            local pos = NodePosition(inserter.inputNode)
            inserter.inputHitbox:UpdatePosition(pos)
        end
        if inserter.outputNode and inserter.outputHitbox then
            local pos = NodePosition(inserter.outputNode)
            inserter.outputHitbox:UpdatePosition(pos)
        end
    end
end]]
function UpdateModules()
    -- Update positions and states for all modules once per frame (including sleeping ones)
    for _, module in pairs(ExistingDeviceModules) do
        module:UpdateState()
    end

    -- Only process crafting for active modules
    for _, module in pairs(ActiveDeviceModules) do
        module:GrabItemsAutomatically()
        module:UpdateCrafting()
        
        -- Check if module should go to sleep after processing
        if not module:CanCraft() then
            module:GoToSleep()
        end

        -- Debug visuals only for active modules
        if DebugMode then
            local pos = module.position
            SpawnCircle(pos, 15, Colour(0, 0, 255, 255), 0.1)
        end
    end

    -- Only update active inserters
    for _, inserter in pairs(ActiveInserters) do
        inserter:Update()
        
        -- Check if inserter should go to sleep
        if #inserter.itemsInTransit == 0 and #inserter.contents == 0 and not inserter:CanGrabNewItem() then
            inserter:GoToSleep()
        end

        -- Debug visuals only for active inserters
        if DebugMode then
            SpawnLine(inserter.startPosition, inserter.endPosition, Colour(255, 0, 0, 255), 0.1)
            SpawnCircle(inserter.currentPosition, 5, Colour(255, 255, 0, 255), 0.1)
        end
    end
end

-- Module Class Definition
Module = {
    id = 0,
    deviceId = 0,
    teamId = 0,
    position = Vec3(250), -- if default is ever used somehow I would like to know
    angle = 0,
    inputBuffers = {},
    outputBuffers = {},
    craftingTime = 0,
    baseCraftingTime = DEFAULT_CRAFTING_TIME,
    currentRecipe = nil,
    isGroundDevice = false,
    isActive = false,
    isEMPed = false,
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
    module.isGroundDevice = IsGroundDevice(deviceId)
    module.position = GetDevicePosition(deviceId)
    module.angle = GetDeviceAngle(deviceId) - 1.57079633
    module.inputBuffers = {}
    module.outputBuffers = {}
    module.isActive = false
    module.isEMPed = false

    return module
end

-- Wake/Sleep System
function Module:WakeUp()
    if not self.isActive and not self.isEMPed then
        self.isActive = true
        -- Move from sleeping to active table using index maps
        local sleepingIndex = ModuleSleepingIndexMap[self]
        if sleepingIndex then
            local lastModule = SleepingDeviceModules[#SleepingDeviceModules]
            SleepingDeviceModules[sleepingIndex] = lastModule
            ModuleSleepingIndexMap[lastModule] = sleepingIndex
            SleepingDeviceModules[#SleepingDeviceModules] = nil
            ModuleSleepingIndexMap[self] = nil
        end
        table.insert(ActiveDeviceModules, self)
        ModuleActiveIndexMap[self] = #ActiveDeviceModules

        -- Wake up all connected inserters through buffers
        for _, buffer in ipairs(self.inputBuffers) do
            for _, inserter in ipairs(buffer.connectedInserters) do
                inserter:WakeUp()
            end
        end
        for _, buffer in ipairs(self.outputBuffers) do
            for _, inserter in ipairs(buffer.connectedInserters) do
                inserter:WakeUp()
            end
        end
    end
end

function Module:GoToSleep()
    if self.isActive then
        self.isActive = false
        -- Move from active to sleeping table using index maps
        local activeIndex = ModuleActiveIndexMap[self]
        if activeIndex then
            local lastModule = ActiveDeviceModules[#ActiveDeviceModules]
            ActiveDeviceModules[activeIndex] = lastModule
            ModuleActiveIndexMap[lastModule] = activeIndex
            ActiveDeviceModules[#ActiveDeviceModules] = nil
            ModuleActiveIndexMap[self] = nil
        end
        table.insert(SleepingDeviceModules, self)
        ModuleSleepingIndexMap[self] = #SleepingDeviceModules

        -- Put all connected inserters to sleep through buffers
        for _, buffer in ipairs(self.inputBuffers) do
            for _, inserter in ipairs(buffer.connectedInserters) do
                inserter:GoToSleep()
            end
        end
        for _, buffer in ipairs(self.outputBuffers) do
            for _, inserter in ipairs(buffer.connectedInserters) do
                inserter:GoToSleep()
            end
        end
    end
end

function Module:SetEMPed(emped)
    if self.isEMPed ~= emped then
        self.isEMPed = emped
        if emped then
            -- EMP puts module to sleep and propagates to buffers
            self:GoToSleep()
            self:UpdateBufferEMPStatus(true)
        else
            -- When EMP wears off, update buffers then check if module can wake up
            self:UpdateBufferEMPStatus(false)
            self:CheckAndUpdateState()
        end
    end
end

function Module:UpdateBufferEMPStatus(emped)
    -- Update all buffers and their connected inserters
    for _, buffer in ipairs(self.inputBuffers) do
        buffer.isEMPed = emped
        for _, inserter in ipairs(buffer.connectedInserters) do
            if emped then
                inserter:GoToSleep()
            else
                -- Only wake up if both connected modules are not EMPed
                if not inserter:IsConnectedToEMPedModule() then
                    inserter:WakeUp()
                end
            end
        end
    end
    for _, buffer in ipairs(self.outputBuffers) do
        buffer.isEMPed = emped
        for _, inserter in ipairs(buffer.connectedInserters) do
            if emped then
                inserter:GoToSleep()
            else
                -- Only wake up if both connected modules are not EMPed
                if not inserter:IsConnectedToEMPedModule() then
                    inserter:WakeUp()
                end
            end
        end
    end
end

function Module:CanCraft()
    local currentRecipe = self.currentRecipe
    if not currentRecipe or self.isEMPed then return false end
    
    -- Check inputs
    for input, required in pairs(currentRecipe.inputs) do
        local inputBuffer = self:FindBuffer("input", input)
        if not inputBuffer or #inputBuffer.items < required then
            return false
        end
    end
    
    -- Check outputs have space
    for output, quantity in pairs(currentRecipe.outputs) do
        local outputBuffer = self:FindBuffer("output", output)
        if not outputBuffer or #outputBuffer.items + quantity > outputBuffer.maxSize then
            return false
        end
    end
    
    return true
end

function Module:CheckAndUpdateState()
    if self:CanCraft() and not self.isActive then
        self:WakeUp()
    elseif not self:CanCraft() and self.isActive then
        self:GoToSleep()
    end
end

function Module:OnInputAdded()
    -- Called when inserter adds item to input buffer
    self:CheckAndUpdateState()
end

function Module:OnOutputRemoved()
    -- Called when inserter removes item from output buffer
    self:CheckAndUpdateState()
end

function Module:AddInputBuffer(bufferSize, itemType, hitbox, relativePosition)
    local buffer = {
        maxSize = bufferSize or DEFAULT_BUFFER_SIZE,
        items = {},
        itemType = itemType or "",
        inserterAttached = false,
        relativePosition = relativePosition or {x = 0, y = 0},
        position = {x=0,y=0,z=0},
        pickupRadius = DEFAULT_PICKUP_RADIUS,
        connectedInserters = {},
        isEMPed = false,
    }
    table.insert(self.inputBuffers, buffer)
end

function Module:AddOutputBuffer(bufferSize, itemType, relativePosition)
    local buffer = {
        maxSize = bufferSize or DEFAULT_BUFFER_SIZE,
        items = {},
        itemType = itemType or "",
        relativePosition = relativePosition or {x = 0, y = 0},
        position = {x=0,y=0,z=0},
        connectedInserters = {},
        isEMPed = false,
    }
    table.insert(self.outputBuffers, buffer)
end

-- Module Recipe Management
function Module:SetRecipe(recipe)
    self.currentRecipe = recipe
    self.baseCraftingTime = recipe.baseTime*25
    self.craftingTime = self.baseCraftingTime

    -- Configure input buffers
    local i = 1
    for inputItem, _ in pairs(recipe.inputs) do
        local buffer = self.inputBuffers[i]
        if not buffer then Notice("Recipe has too many inputs for module; Setting to empty") self:SetRecipe(Recipes.empty) return end
        if buffer.itemType ~= inputItem then buffer.itemType = inputItem
        --Tell Inserter That its Output Has changed
        for j = #buffer.items, 1, -1 do
            for _, item in ipairs(buffer.items) do
                table.remove(buffer.items, j)
                CreateItem(buffer.position, item)
            end

            end
        end
        i = i + 1
    end

    -- Configure output buffers
    local k = 1
    for outputItem, _ in pairs(recipe.outputs) do
        local buffer = self.outputBuffers[k]
        if not buffer then Notice("Recipe has too many outputs for module; Setting to empty") self:SetRecipe(Recipes.empty) return end

        buffer.itemType = outputItem
        for l = #buffer.items, 1, -1 do
            if buffer.items[l] ~= outputItem then
                table.remove(buffer.items, l)
            end
        end

        k = k + 1
    end

    self:CheckAndUpdateState() -- Check if new recipe allows crafting
end

--TODO: Pipes, likely just set priority per output and then full. Surplus: recipue based Per item surpluss, per all overload surpluss, Active Modules table? (if no output, if no input)
--

--[[
Module input buffers must be able to contain multiple item types at once, make inserters check for each type that the connected module wants and the recipe to properly set the input buffers item types
WHY??? I DON'T UNDERSTAND, WHY
]]
function Module:UpdateCrafting()
    local currentRecipe = self.currentRecipe
    if not currentRecipe then return end

    -- Only update if we can actually craft (should always be true for active modules)
    if not self:CanCraft() then
        self:GoToSleep()
        return
    end

    local surplusFactor = 1
    -- Check if there are enough inputs to consume then find surplus factor
    for input, required in pairs(currentRecipe.inputs) do
        local inputBuffer = self:FindBuffer("input", input)
        local itemCount = #inputBuffer.items
        if itemCount < required then
            return -- Halt crafting due to insufficient input items
        elseif currentRecipe.surplusFactors[input] then
            surplusFactor = surplusFactor + currentRecipe.surplusFactors[input] * itemCount-required / required
        end

    end

    -- Check if output buffers have space for the recipe outputs
    for output, quantity in pairs(currentRecipe.outputs) do
        local outputBuffer = self:FindBuffer("output", output)
        if #outputBuffer.items + quantity > outputBuffer.maxSize then
            return -- Halt crafting due to full output buffer
        end
    end

    if currentRecipe.consumption then
        AddResourcesContinuous(self.teamId, currentRecipe.consumption)
    end

    self.craftingTime = (self.craftingTime) - 1 * surplusFactor
    if self.craftingTime <= 0 then

        for input, required in pairs(currentRecipe.inputs) do
            local inputBuffer = self:FindBuffer("input", input)
            for _=1, required do
                table.remove(inputBuffer.items)
            end
        end
        local pos = self.position -- not required if all outputs go to inserters
        local angle = self.angle
        for output, quantity in pairs(currentRecipe.outputs) do --Output Items to world at output buffer position or store in buffer if waiting for a inserter
            local outputBuffer = self:FindBuffer("output", output)
            for _=1, quantity do
                if outputBuffer.inserterAttached then
                    table.insert(outputBuffer.items, output)
                else
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
        if buffer.itemType == itemType then
            return buffer
        end
    end
end

-- Update physics object grabbing
function Module:GrabItemsAutomatically()
    for _, buffer in ipairs(self.inputBuffers) do
        if not buffer.inserterAttached and #buffer.items < buffer.maxSize then
            for key, Object in pairs(ItemObjects) do
                local pos = Object.pos
                local bufferPos = buffer.position
                
                -- Calculate distance using circular detection
                local dx = pos.x - bufferPos.x
                local dy = pos.y - bufferPos.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance <= buffer.pickupRadius and Object.itemType == buffer.itemType then
                    -- Check if any connected inserter wants to take over this item
                    local inserterTookOver = false
                    for _, inserter in ipairs(buffer.connectedInserters) do
                        if inserter.outputModule == self then
                            inserter:TakeOverEffect(Object)
                            inserterTookOver = true
                            break
                        end
                    end
                    
                    if not inserterTookOver then
                        table.insert(buffer.items, Object.itemType)
                        DestroyItem(Object, key)
                        self:OnInputAdded() -- Wake up module if it can now craft
                    end
                end
            end
        end
    end
end

function RemoveItemsFromBuffer(buffer)
    
end

function Module:UpdateState()
    local deviceId = self.deviceId
    local angle = GetDeviceAngle(deviceId) - 1.57079633
    local pos = GetDevicePosition(deviceId)
    
    -- Check for EMP status (this should be event-based in real implementation)
    -- self:SetEMPed(IsDeviceEMPed(deviceId))
    
    -- Update all buffer positions once per frame
    local function UpdateBufferPositions(buffers)
        for _, buffer in ipairs(buffers) do
            local relPos = buffer.relativePosition
            local rotated = RotatePoint(relPos.x, relPos.y, -angle)
            
            local bufferPos = {
                x = pos.x + rotated.x,
                y = pos.y + rotated.y,
                z = -101
            }
            
            buffer.position = bufferPos
            
            -- Debug visuals for buffers
            if DebugMode then
                -- Draw buffer center
                SpawnCircle(bufferPos, 5, Colour(255, 0, 255, 255), 0.1)
                
                -- Draw pickup radius for input buffers without inserters
                if buffer.pickupRadius and not buffer.inserterAttached then
                    SpawnCircle(bufferPos, buffer.pickupRadius, Colour(0, 255, 0, 100), 0.1)
                end
            end
        end
    end
    
    UpdateBufferPositions(self.inputBuffers)
    UpdateBufferPositions(self.outputBuffers)
    
    -- Update module position and angle
    self.position = pos
    self.angle = angle
    
    -- Update connected inserter positions
    for _, inserter in ipairs(self.connectedInserters) do
        inserter:UpdatePositions()
    end
end

function InserterLogic() --example
    --[[
    Why was I woken?

    Output inserters: 
    Items to grab; Positions:
    Inserter slot is full, outputbuffer does not need to loop wake, call wake on outputbuffer when inserter has space or just take from the buffer
    Inserter is empty, inserter will handle output if more then 1 item
    Item overload?; Module checks buffers every frame, when items are taken they will start working again
    --Result: CheckInput function for inserters, WakeInserter for output buffers
    Input inserters: 
    Items to grab; Positions:
    Inserter output slot is full, insert will update
    ]]
end

ExistingInserters = {}

-- Inserter Class Definition
Inserter = {
    inputModule = nil,
    outputModule = nil,
    inputBuffer = nil,
    outputBuffer = nil,
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
    isActive = false,
    needsPositionUpdate = false,
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
    o.isActive = false
    o.needsPositionUpdate = false
    -- Start in sleeping state
    table.insert(SleepingInserters, o)
    InserterSleepingIndexMap[o] = #SleepingInserters
    
    return o
end

function Inserter:WakeUp()
    if not self.isActive then
        self.isActive = true
        -- Check if connected modules/buffers allow waking up
        if self:IsConnectedToEMPedModule() then
            return -- Don't wake up if connected to EMPed modules
        end
        
        -- Move from sleeping to active table using index maps
        local sleepingIndex = InserterSleepingIndexMap[self]
        if sleepingIndex then
            local lastInserter = SleepingInserters[#SleepingInserters]
            SleepingInserters[sleepingIndex] = lastInserter
            InserterSleepingIndexMap[lastInserter] = sleepingIndex
            SleepingInserters[#SleepingInserters] = nil
            InserterSleepingIndexMap[self] = nil
        end
        table.insert(ActiveInserters, self)
        InserterActiveIndexMap[self] = #ActiveInserters
    end
end

function Inserter:GoToSleep()
    if self.isActive then
        self.isActive = false
        -- Move from active to sleeping table using index maps
        local activeIndex = InserterActiveIndexMap[self]
        if activeIndex then
            local lastInserter = ActiveInserters[#ActiveInserters]
            ActiveInserters[activeIndex] = lastInserter
            InserterActiveIndexMap[lastInserter] = activeIndex
            ActiveInserters[#ActiveInserters] = nil
            InserterActiveIndexMap[self] = nil
        end
        table.insert(SleepingInserters, self)
        InserterSleepingIndexMap[self] = #SleepingInserters
    end
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
    return SpawnEffectEx(path .. "/effects/" ..MaterialArtSet..itemType .. GetRandomInteger(1, ItemDefinitions[itemType].VariantCount or 1,"")..".lua", position, Vec3(0, -1))
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

function Inserter:ConnectToBuffer(buffer)
    if buffer then
        table.insert(buffer.connectedInserters, self)
        buffer.inserterAttached = true
    end
end

function Inserter:DisconnectFromBuffer(buffer)
    if buffer then
        for i, inserter in ipairs(buffer.connectedInserters) do
            if inserter == self then
                table.remove(buffer.connectedInserters, i)
                break
            end
        end
        buffer.inserterAttached = #buffer.connectedInserters > 0
    end
end

function Inserter:ConnectModules(input, output)
    -- Disconnect from previous connections
    self:DisconnectFromBuffer(self.inputBuffer)
    self:DisconnectFromBuffer(self.outputBuffer)

    if input.position then
        self.inputModule = input
        self.inputBuffer = input -- input is actually a buffer
        self.inputNode = nil
        local angle = GetDeviceAngle(input.deviceId) - 1.57079633
        self.startPosition = RotatePosition(input.relativePosition, angle)
        self.startPosition.x = input.position.x + self.startPosition.x
        self.startPosition.y = input.position.y + self.startPosition.y
        self:ConnectToBuffer(input)
    else
        self.inputNode = input
        self.inputModule = nil
        self.inputBuffer = nil
        self.startPosition = input.position
        self.inputHitbox = Hitbox:New(input.position, 25)
    end

    if output.position then
        self.outputModule = output
        self.outputBuffer = output -- output is actually a buffer
        self.outputNode = nil
        local angle = GetDeviceAngle(output.deviceId) - 1.57079633
        self.endPosition = RotatePosition(output.relativePosition, angle)
        self.endPosition.x = output.position.x + self.endPosition.x
        self.endPosition.y = output.position.y + self.endPosition.y
        self:ConnectToBuffer(output)
    else
        self.outputNode = output
        self.outputModule = nil
        self.outputBuffer = nil
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

-- Simplified Hitbox for inserters only
Hitbox = {
    centerX = 0,
    centerY = 0,
    radius = 0
}

function Hitbox:New(pos, radius)
    local hb = {}
    setmetatable(hb, self)
    self.__index = self
    hb.radius = radius or 25
    hb:UpdatePosition(pos)
    return hb
end

function Hitbox:UpdatePosition(pos)
    self.centerX = pos.x
    self.centerY = pos.y
end

function Hitbox:CheckCollision(pos)
    local dx = pos.x - self.centerX
    local dy = pos.y - self.centerY
    return math.sqrt(dx * dx + dy * dy) <= self.radius
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
function RotatePosition(position, angle)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)
    return {
        x = position.x * cosAngle - position.y * sinAngle,
        y = position.x * sinAngle + position.y * cosAngle,
        z = 0
    }
end

function RotatePoint(x, y, angle)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)
    return {
        x = x * cosAngle - y * sinAngle,
        y = x * sinAngle + y * cosAngle
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
        if DebugMode then
            for key, value in pairs(ExistingDeviceModules) do
                value.craftingTime = 0
                value.baseCraftingTime = 1
            end
        end
        BetterLog(ExistingDeviceModules)
    end
    if key == "y" and down then
        PhysLib:Load()
    end
end

function ModuleReset() -- If a recipe gets changed a buffer may swap to not existing or a fluid buffer so either update visuals activly or otherwise check, If the recipe changes while a 
--inserter is being placed "frame perfect" it may be plausable for a wrong inserter type to be attached

end

Recipes = { -- Don't use an input count of 0, it will cause a divide by 0
    empty = {
        baseTime = 99999,
        inputs = {},
        outputs = {},
        surplusFactors = {}, -- 1x-2x input 0%-100% Added speed per update
    },
    derrick = {
        oil = {
            baseTime = 10,
            inputs = {},
            outputs = {["Oil"] = 6},
            surplusFactors = {},
        },
    },
    mine = {
        ore = {
            baseTime = 16,
            inputs = {},
            outputs = {["IronOre"] = 1},
            surplusFactors = {},
        },
    },
    mine2 = {
        ore = {
            baseTime = 11, --12 == ~1.333x
            inputs = {},
            outputs = {["IronOre"] = 1},
            surplusFactors = {},
        },
    },
    furnace = {
        ironPlate = { --Furnace may swap recipe based on inputs?
            baseTime = 22, --27.7 == 1.5 & 21.3 == 1.5 * max surplus
            surplusFactors = {["IronOre"] = 0.05},
            inputs = {["IronOre"] = 2},
            outputs = {["IronPlate"] = 1},
            consumption = Value(0,-10/25),
        },
    },
    steelfurnace = {
        ironPlate = {
            baseTime = 18,
            inputs = {["IronOre"] = 2},
            outputs = {["IronPlate"] = 1},
            consumption = Value(0,-12/25),
            surplusFactors = {},
        },
    },
    chemicalplant = {
        sulfuricAcid = {
            baseTime = 15,
            inputs = {["IronPlate"] = 1},
            outputs = {["SulfuricAcid"] = 10},
            surplusFactors = {},
        },
    },
    constructor = {
        ammo = {
            baseTime = 20,
            inputs = {["IronPlate"] = 1},
            outputs = {["Ammo"] = 2},
            surplusFactors = {},
        },
    },
}
