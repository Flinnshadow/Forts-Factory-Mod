function Merge(t1, t2) for k, v in pairs(t2) do t1[k] = v end end

--Merge(Weapon,
--{
--	CannonDoubleShot = L"Chemical Ammunition", --WHAT DO??
--})

Merge(Device,
{
    furnace = L"Furnace",
    furnaceTip2 = L"Basic metal processing facility, swap recipes via the context menu",
    furnaceTip3 = L"Each craft requires some amount of energy additional to the passive consumption",
})
