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
					{ texture = path .. "/materials/conveyorBlueOn1.png", duration = 0.02},
					{ texture = path .. "/materials/conveyorBlueOn2.png", duration = 0.02},
                    { texture = path .. "/materials/conveyorBlueOn3.png", duration = 0.02},
					{ texture = path .. "/materials/conveyorBlueOn4.png", duration = 0.02},
                    { texture = path .. "/materials/conveyorBlueOn5.png", duration = 0.02},
					{ texture = path .. "/materials/conveyorBlueOn6.png", duration = 0.02},
                    { texture = path .. "/materials/conveyorBlueOn7.png", duration = 0.02},
					{ texture = path .. "/materials/conveyorBlueOn8.png", duration = 0.02},
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
   conveyor.RenderOrder = 5
   conveyor.EndCap = "conveyor-node"
   conveyor.EndLinkOffset = -1
   conveyor.KeySpriteByDamage = false
   conveyor.MinLength = 62
   conveyor.MaxLength = 160
   conveyor.MaxLinkLength = 180
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
end