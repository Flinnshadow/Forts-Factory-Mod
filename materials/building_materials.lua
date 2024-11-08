---@diagnostic disable: param-type-mismatch
dofile("scripts/forts.lua")
dofile(path .. "/scripts/BetterLog.lua")

ConveyorNode =
{
	Priority = 1,
	Foundations =
	{
		{ angle = 145, material = "core-fndstd" },
		{ material = "core-fndhvyroof" },
	},
	Plates =
	{
		--{ material = "core-cbp" },
	},
}


table.insert(Sprites,
    {
		Name = "conveyor",
		States =
		{
			Normal =
			{
				Frames =
				{
					{ texture = path .. "/materials/tier1/normal/off1.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/normal/off2.png", duration = 0.02},
                    { texture = path .. "/materials/tier1/normal/off3.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/normal/off4.png", duration = 0.02},
                    { texture = path .. "/materials/tier1/normal/off5.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/normal/off6.png", duration = 0.02},
                    { texture = path .. "/materials/tier1/normal/off7.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/normal/off8.png", duration = 0.02},
					mipmap = true,
					repeatS = true,
				},
			},
		},
	}
)
table.insert(Sprites,
    {
		Name = "conveyor-inverted",
		States =
		{
			Normal =
			{
				Frames =
				{
					{ texture = path .. "/materials/tier1/inverted/off1.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/inverted/off2.png", duration = 0.02},
                    { texture = path .. "/materials/tier1/inverted/off3.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/inverted/off4.png", duration = 0.02},
                    { texture = path .. "/materials/tier1/inverted/off5.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/inverted/off6.png", duration = 0.02},
                    { texture = path .. "/materials/tier1/inverted/off7.png", duration = 0.02},
					{ texture = path .. "/materials/tier1/inverted/off8.png", duration = 0.02},
					mipmap = true,
					repeatS = true,
				},
			},
		},
	}
)
table.insert(Sprites,
   {
      Name = "conveyor-node",
      States =
      {
         Normal =
         {
            Frames =
            {
               -- durations must add up to 1 for the damage keying to work properly
               -- anything beyond 1 will never show
               { texture = path.."/materials/conveyorBeltNode3.png", duration = 0.1 },
               { texture = path.."/materials/conveyorBeltNode3.dds", duration = 0.3 },
               { texture = path.."/materials/conveyorBeltNode3.dds", duration = 0.3 },
               { texture = path.."/materials/conveyorBeltNode3.dds", duration = 0.301 },
               mipmap = true,
            },
         },
      },
   }
)

local conveyor = DeepCopy(FindMaterial("armour"))
if conveyor then
   conveyor.SaveName = "Conveyor"
   conveyor.Sprite = "conveyor"
   conveyor.Node = ConveyorNode
   conveyor.RenderOrder = 7
   conveyor.EndCap = "conveyor-node"
   conveyor.EndLinkOffset = -1
   conveyor.KeySpriteByDamage = false
   conveyor.MinLength = 62
   conveyor.MaxLinkLength = 185
   conveyor.MetalBuildCost = 0.8 --40
   conveyor.MetalRepairCost = 0.5
   conveyor.MetalReclaim = 0.7
   conveyor.EnergyBuildCost = 2.5
   conveyor.EnergyRepairCost = 4.5
   conveyor.BuildTime = 6
   conveyor.ScrapTime = 3
   conveyor.RepairRateMultiplier = 1.5
   conveyor.Mass = 0.35
   conveyor.HitPoints = 200

   PostCreateMaterialAlways = true -- usually only want to place one door at a time, can drag if not
   PostCreateTargetSaveName = "bracing"
   RecessionTargetSaveName = "backbracing"

   -- this is needed so that doors are reported to the weapon recession call,
   -- so the door is recognised and to avoid making some other structure into a door
   DoorTargetSaveName = "door"
   WeaponRecession = true -- only recess the armor into a door when in the way of a weapon

   ArmorRemovalTargetSaveName = "bracing"
   FogOfWarTargetSaveName = "bracing"
   --conveyor.CanAttachToGround = false
   conveyor.IsBehindDevices = false
   conveyor.SplashMultiplier = 0
   conveyor.MaxLinkLengthMultiplierInEditor = 4
   conveyor.MaxAngle = 50

   --WarmUpTime = 10
   --WarmUpTimeDisabled = 12
   --AttachesCladding = true
   --SupportsDevices = false
   --conveyor.KeyEndCapByDamage = true
   --Sprite = "energy_shield",
   --SpriteDeactivated = "materials/energy_shield_deactivated",


   table.insert(Materials, conveyor)

   conveyor2 = DeepCopy(conveyor)

   conveyor2.SaveName = "ConveyorInverted"
   conveyor2.Sprite = "conveyor-inverted"
   table.insert(Materials, conveyor2)
end

