ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged_small.lua"
Scale = 1.0
SelectionWidth = 40.0
SelectionHeight = 40.0
SelectionOffset = { 0.0, -40.5 }
Mass = 80.0
HitPoints = 110.0
EnergyProductionRate = -5.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter
--[[
Sprites =
{
	{
		Name = "metalstore-base",
		States =
		{
			Normal = { Frames = { { texture = "devices/metalstore/base.dds" }, mipmap = true, }, },
		},
	},
	{
		Name = "metalstore-head",
		States =
		{
			Normal = { Frames = { { texture = "devices/metalstore/metal.dds" }, mipmap = true, }, },
		},
	},
}
]]
Root =
{
	Name = "MetalStore",
	Angle = 0,
	Pivot = { 0, -0.55 },
	PivotOffset = { 0, 0 },
	Sprite = "metalstore-base",

	ChildrenBehind =
	{
		{
			Name = "Head",
			Angle = 0,
			Pivot = { 0, 0 },
			PivotOffset = { 0, 0 },
			Offset = { 0, -0.8 },
			Sprite = "metalstore-head",
			UserData = 100,
		},
	},
	ChildrenInFront =
	{
	},
}
