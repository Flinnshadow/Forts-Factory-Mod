function Merge(t1, t2) for k, v in pairs(t2) do t1[k] = v end end

--Merge(Weapon,
--{
--	CannonDoubleShot = L"Chemical Ammunition", --WHAT DO??
--})

Merge(Device,
{
    derrick = L"Derrick",
    derrickTip2 = L"Produces Oil",
    derrickTip3 = L"If not placed on an oil deposit, functions at 25% speed",

    mine = L"Mine",
    mineTip2 = L"Produces metal chucks every 16 seconds",
    mineTip3 = L"Can be swapped to advanced processing if supplied with sulfuric acid ",

    mine2 = L"Super Mine",
    mine2Tip2 = L"Produces metal chucks every 11 seconds",
    mine2Tip3 = L"Can be swapped to advanced processing if supplied with sulfuric acid ",

    furnace = L"Furnace",
    furnaceTip2 = L"Basic metal processing facility, swap recipes via the context menu",
    furnaceTip3 = L"Each craft requires some amount of energy additional to the passive consumption",

    steelfurnace = L"Steel Furnace",
    steelfurnaceTip2 = L"Metal processing facility, swap recipes via the context menu",
    steelfurnaceTip3 = L"Faster then the basic furnace",

    chemicalplant = L"Chemical Plant",
    chemicalplantTip2 = L"Used to produce chemicals for manufacturing or offense",
    chemicalplantTip3 = L"Use to kickstart oil production from mines",

    constructor = L"Constructor",
    constructorTip2 = L"Creates ammo",
    constructorTip3 = L"Each craft requires some amount of energy",
})
