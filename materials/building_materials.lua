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





TextureTable = {
    ["conveyor-node"] = {
        frameDuration = 0.1,
        path .. "/materials/conveyorBeltNode3.png",
        path .. "/materials/conveyorBeltNode3.dds",
        path .. "/materials/conveyorBeltNode3.dds",
        path .. "/materials/conveyorBeltNode3.dds",
    },
    ["c1l"] = {
        frameDuration = 0.08,
        path .. "/materials/tier1/left/off1.png",
        path .. "/materials/tier1/left/off2.png",
        path .. "/materials/tier1/left/off3.png",
        path .. "/materials/tier1/left/off4.png",
        path .. "/materials/tier1/left/off5.png",
        path .. "/materials/tier1/left/off6.png",
        path .. "/materials/tier1/left/off7.png",
        path .. "/materials/tier1/left/off8.png",
        
    },
    ["c1r"] = {
        frameDuration = 0.08,
        path .. "/materials/tier1/right/off1.png",
        path .. "/materials/tier1/right/off2.png",
        path .. "/materials/tier1/right/off3.png",
        path .. "/materials/tier1/right/off4.png",
        path .. "/materials/tier1/right/off5.png",
        path .. "/materials/tier1/right/off6.png",
        path .. "/materials/tier1/right/off7.png",
        path .. "/materials/tier1/right/off8.png",
    },
    ["c1pl"] = {
        frameDuration = 0.04,
        path .. "/materials/tier1/left/on1.png",
        path .. "/materials/tier1/left/on2.png",
        path .. "/materials/tier1/left/on3.png",
        path .. "/materials/tier1/left/on4.png",
        path .. "/materials/tier1/left/on5.png",
        path .. "/materials/tier1/left/on6.png",
        path .. "/materials/tier1/left/on7.png",
        path .. "/materials/tier1/left/on8.png",
    },
    ["c1pr"] = {
        frameDuration = 0.04,
        path .. "/materials/tier1/right/on1.png",
        path .. "/materials/tier1/right/on2.png",
        path .. "/materials/tier1/right/on3.png",
        path .. "/materials/tier1/right/on4.png",
        path .. "/materials/tier1/right/on5.png",
        path .. "/materials/tier1/right/on6.png",
        path .. "/materials/tier1/right/on7.png",
        path .. "/materials/tier1/right/on8.png",
    },
    ["c2l"] = {
        frameDuration = 0.04,
        path .. "/materials/tier2/left/off1.png",
        path .. "/materials/tier2/left/off2.png",
        path .. "/materials/tier2/left/off3.png",
        path .. "/materials/tier2/left/off4.png",
        path .. "/materials/tier2/left/off5.png",
        path .. "/materials/tier2/left/off6.png",
        path .. "/materials/tier2/left/off7.png",
        path .. "/materials/tier2/left/off8.png",
    },
    ["c2r"] = {
        frameDuration = 0.04,
        path .. "/materials/tier2/right/off1.png",
        path .. "/materials/tier2/right/off2.png",
        path .. "/materials/tier2/right/off3.png",
        path .. "/materials/tier2/right/off4.png",
        path .. "/materials/tier2/right/off5.png",
        path .. "/materials/tier2/right/off6.png",
        path .. "/materials/tier2/right/off7.png",
        path .. "/materials/tier2/right/off8.png",

    },
    ["c2pl"] = {
        frameDuration = 0.02,
        path .. "/materials/tier2/left/on1.png",
        path .. "/materials/tier2/left/on2.png",
        path .. "/materials/tier2/left/on3.png",
        path .. "/materials/tier2/left/on4.png",
        path .. "/materials/tier2/left/on5.png",
        path .. "/materials/tier2/left/on6.png",
        path .. "/materials/tier2/left/on7.png",
        path .. "/materials/tier2/left/on8.png",
    },
    ["c2pr"] = {
        frameDuration = 0.02,
        path .. "/materials/tier2/right/on1.png",
        path .. "/materials/tier2/right/on2.png",
        path .. "/materials/tier2/right/on3.png",
        path .. "/materials/tier2/right/on4.png",
        path .. "/materials/tier2/right/on5.png",
        path .. "/materials/tier2/right/on6.png",
        path .. "/materials/tier2/right/on7.png",
        path .. "/materials/tier2/right/on8.png",
    },
    ["c3l"] = {
        frameDuration = 0.02,
        path .. "/materials/tier3/left/off1.png",
        path .. "/materials/tier3/left/off2.png",
        path .. "/materials/tier3/left/off3.png",
        path .. "/materials/tier3/left/off4.png",
        path .. "/materials/tier3/left/off5.png",
        path .. "/materials/tier3/left/off6.png",
        path .. "/materials/tier3/left/off7.png",
        path .. "/materials/tier3/left/off8.png",
    },
    ["c3r"] = {
        frameDuration = 0.02,
        path .. "/materials/tier3/right/off1.png",
        path .. "/materials/tier3/right/off2.png",
        path .. "/materials/tier3/right/off3.png",
        path .. "/materials/tier3/right/off4.png",
        path .. "/materials/tier3/right/off5.png",
        path .. "/materials/tier3/right/off6.png",
        path .. "/materials/tier3/right/off7.png",
        path .. "/materials/tier3/right/off8.png",
    },
    ["c3pl"] = {
        frameDuration = 0.01,
        path .. "/materials/tier3/left/on1.png",
        path .. "/materials/tier3/left/on2.png",
        path .. "/materials/tier3/left/on3.png",
        path .. "/materials/tier3/left/on4.png",
        path .. "/materials/tier3/left/on5.png",
        path .. "/materials/tier3/left/on6.png",
        path .. "/materials/tier3/left/on7.png",
        path .. "/materials/tier3/left/on8.png",
    },
    ["c3pr"] = {
        frameDuration = 0.01,
        path .. "/materials/tier3/right/on1.png",
        path .. "/materials/tier3/right/on2.png",
        path .. "/materials/tier3/right/on3.png",
        path .. "/materials/tier3/right/on4.png",
        path .. "/materials/tier3/right/on5.png",
        path .. "/materials/tier3/right/on6.png",
        path .. "/materials/tier3/right/on7.png",
        path .. "/materials/tier3/right/on8.png",
    }

}


function ConstructSprites() 
    for name, textures in pairs(TextureTable) do
        local frames = {}
        for i, texture in ipairs(textures) do
            table.insert(frames, {texture = texture, duration = textures.frameDuration})
        end
        frames.mipmap = true
        frames.repeatS = true
        table.insert(Sprites, {
            Name = name,
            States = {
                Normal = {
                    Frames = frames
                }
            }
        })
    end
end

ConstructSprites()

local c1l = DeepCopy(FindMaterial("armour"))
if c1l then
   c1l.SaveName = "c1l"
   c1l.Sprite = "c1l"
   c1l.Node = ConveyorNode
   c1l.RenderOrder = 7
   c1l.EndCap = "conveyor-node"
   c1l.EndLinkOffset = -1
   c1l.KeySpriteByDamage = false
   c1l.MinLength = 62
   c1l.MaxLinkLength = 185
   c1l.MetalBuildCost = 0.8 --40
   c1l.MetalRepairCost = 0.5
   c1l.MetalReclaim = 0.7
   c1l.EnergyBuildCost = 2.5
   c1l.EnergyRepairCost = 4.5
   c1l.BuildTime = 6
   c1l.ScrapTime = 3
   c1l.RepairRateMultiplier = 1.5
   c1l.Mass = 0.35
   c1l.HitPoints = 200

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
   c1l.IsBehindDevices = false
   c1l.SplashMultiplier = 0
   c1l.MaxLinkLengthMultiplierInEditor = 4
   c1l.MaxAngle = 50

   --WarmUpTime = 10
   --WarmUpTimeDisabled = 12
   --AttachesCladding = true
   --SupportsDevices = false
   --conveyor.KeyEndCapByDamage = true
   --Sprite = "energy_shield",
   --SpriteDeactivated = "materials/energy_shield_deactivated",


   table.insert(Materials, c1l)

   local c1r = DeepCopy(c1l)

   c1r.SaveName = "c1r"
   c1r.Sprite = "c1r"
   table.insert(Materials, c1r)

    local c1pl = DeepCopy(c1l)
    c1pl.SaveName = "c1pl"
    c1pl.Sprite = "c1pl"
    table.insert(Materials, c1pl)

    local c1pr = DeepCopy(c1l)
    c1pr.SaveName = "c1pr"
    c1pr.Sprite = "c1pr"
    table.insert(Materials, c1pr)

    local c2l = DeepCopy(c1l)
    c2l.SaveName = "c2l"
    c2l.Sprite = "c2l"
    c2l.MetalBuildCost = 1.5
    c2l.MetalRepairCost = 1.5
    c2l.MetalReclaim = 1.5
    c2l.EnergyBuildCost = 3
    c2l.EnergyRepairCost = 5
    c2l.BuildTime = 8
    c2l.ScrapTime = 4
    c2l.RepairRateMultiplier = 1.5
    c2l.Mass = 0.5
    c2l.HitPoints = 300
    c2l.MaxLinkLength = 185
    table.insert(Materials, c2l)

    local c2r = DeepCopy(c2l)
    c2r.SaveName = "c2r"
    c2r.Sprite = "c2r"
    table.insert(Materials, c2r)

    local c2pl = DeepCopy(c2l)
    c2pl.SaveName = "c2pl"
    c2pl.Sprite = "c2pl"
    table.insert(Materials, c2pl)

    local c2pr = DeepCopy(c2l)
    c2pr.SaveName = "c2pr"
    c2pr.Sprite = "c2pr"
    table.insert(Materials, c2pr)

    local c3l = DeepCopy(c2l)
    c3l.SaveName = "c3l"
    c3l.Sprite = "c3l"
    c3l.MetalBuildCost = 4
    c3l.MetalRepairCost = 3
    c3l.MetalReclaim = 3
    c3l.EnergyBuildCost = 6
    c3l.EnergyRepairCost = 8
    c3l.BuildTime = 10
    c3l.ScrapTime = 5
    c3l.RepairRateMultiplier = 1.5
    c3l.Mass = 0.7
    c3l.HitPoints = 400
    c3l.MaxLinkLength = 185
    table.insert(Materials, c3l)

    local c3r = DeepCopy(c3l)
    c3r.SaveName = "c3r"
    c3r.Sprite = "c3r"
    table.insert(Materials, c3r)
    
    local c3pl = DeepCopy(c3l)
    c3pl.SaveName = "c3pl"
    c3pl.Sprite = "c3pl"
    table.insert(Materials, c3pl)

    local c3pr = DeepCopy(c3l)
    c3pr.SaveName = "c3pr"
    c3pr.Sprite = "c3pr"
    table.insert(Materials, c3pr)

end

