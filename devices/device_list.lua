
local mine = FindDevice("mine")
if mine then
    mine.MetalCost = mine.MetalCost - 50 --Reduced cost due to the requirement of belts and the reduced income before smelting
    mine.EnergyCost = mine.EnergyCost - 500
    mine.MetalRepairCost = mine.MetalRepairCost * 0.8
    mine.EnergyRepairCost = mine.EnergyRepairCost * 0.8
end

table.insert(Devices,
{
    SaveName = "furnace",
    FileName = path.."/devices/furnace.lua",
    Icon = "hud-metalstore-icon",
    Detail = "hud-detail-metalstore",
    BuildTimeComplete = 16.0,
    ScrapPeriod = 8,
    MetalCost = 175,
    EnergyCost = 1000,
    MetalRepairCost = 20,
    EnergyRepairCost = 400,
    MaxUpAngle = StandardMaxUpAngle,
    BuildOnGroundOnly = false,
    ValidityFlags = VALIDITYFLAG_REQUIRES_ABOVE_WATER,
    SelectEffect = "ui/hud/devices/ui_devices",
})
table.insert(Devices,
{
    SaveName = "steelfurnace",
    FileName = path.."/devices/steelfurnace.lua",
    Icon = "hud-metalstore-icon",
    Detail = "hud-detail-metalstore",
    BuildTimeComplete = 16.0,
    ScrapPeriod = 8,
    MetalCost = 175,
    EnergyCost = 1000,
    MetalRepairCost = 20,
    EnergyRepairCost = 400,
    MaxUpAngle = StandardMaxUpAngle,
    BuildOnGroundOnly = false,
    ValidityFlags = VALIDITYFLAG_REQUIRES_ABOVE_WATER,
    SelectEffect = "ui/hud/devices/ui_devices",
})