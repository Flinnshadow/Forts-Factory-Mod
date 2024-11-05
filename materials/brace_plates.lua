
--[[
Sprites =
{
	NodeSprite("foundation0", "materials/foundation_standard_team", 0, -0.13),
	NodeSprite("foundation1", "materials/foundation_standard_team", 1, -0.13),
	NodeSprite("foundation2", "materials/foundation_standard_team", 2, -0.13),
	NodeSprite("foundationBG", "materials/foundation_standard_background", "", -0.13),
	NodeSprite("node0", "materials/node_team", 0, 0),
	NodeSprite("node1", "materials/node_team", 1, 0),
	NodeSprite("node2", "materials/node_team", 2, 0),
	NodeSprite("nodeBG", "materials/node_background", "", 0),
	{
		Name = "peg",
		States =
		{
			Normal = { Frames = { { texture = "materials/peg.dds", offsetY = -0.5 }, mipmap = true, }, },
		},
	}
}]]

table.insert(Sprites,
{
   Name = "CVnode0",
   States =
   {
      Normal = { Frames = { { texture = path.."/materials/conveyorBeltNode.png", offsetY = 0 }, mipmap = true, }, },
   },
}
)
table.insert(Sprites,
{
   Name = "CVnode1",
   States =
   {
      Normal = { Frames = { { texture = path.."/materials/conveyorBeltNode.png", offsetY = 0 }, mipmap = true, }, },
   },
}
)
table.insert(Sprites,
{
   Name = "CVnode2",
   States =
   {
      Normal = { Frames = { { texture = path.."/materials/conveyorBeltNode.png", offsetY = 0 }, mipmap = true, }, },
   },
}
)
table.insert(Sprites,
{
   Name = "CVnodeBG",
   States =
   {
      Normal = { Frames = { { texture = path.."/materials/conveyorBeltNode.png", offsetY = 0 }, mipmap = true, }, },
   },
}
)

table.insert(BracingPlates,
{
   DisplayName = "Conveyor Bracing Plate",
   SaveName = "core-cbp",
   Sprite = "CVnode0",
   Sprite1 = "CVnode1",
   Sprite2 = "CVnode2",
   SpriteBG = "CVnodeBG",
})



--[[
isVerAlpha = false
--functions
function sboldNodeSprite(name, filename, team, yoffset)
    return
    {
        Name = name,
        States =
        {
            Normal = { Frames = { { texture = path .. "/" .. filename .. team .. ".tga", offsetY = yoffset }, mipmap = true, }, },
        },
    }
end
function TableContains(t, element)
    for k, v in pairs(t) do
        if v == element then
            return true
        end
    end
    return false
end
function RemoveSprite(name)
    for k, v in ipairs(Sprites) do
        if v.Name == name then
            table.remove(Sprites, k)
        end
    end
end
--remove new sprites
local spritesToRemove = 
{
    "foundation0",
    "foundation1",
    "foundation2",
    "foundationBG",
    "node0", 
    "node1", 
    "node2", 
    "nodeBG",
}
for k, v in pairs(spritesToRemove) do
    RemoveSprite(v)
end
--add old sprites
if isVerAlpha then
    
else
    table.insert(Sprites, sboldNodeSprite("foundation0", "materials/foundation_standard_team", 0, -0.13))
    table.insert(Sprites, sboldNodeSprite("foundation1", "materials/foundation_standard_team", 1, -0.13))
    table.insert(Sprites, sboldNodeSprite("foundation2", "materials/foundation_standard_team", 2, -0.13))
    table.insert(Sprites, sboldNodeSprite("foundationBG", "materials/foundation_standard_background", "", -0.13))
    table.insert(Sprites, sboldNodeSprite("node0", "materials/node_team", 0, 0))
    table.insert(Sprites, sboldNodeSprite("node1", "materials/node_team", 1, 0))
    table.insert(Sprites, sboldNodeSprite("node2", "materials/node_team", 2, 0))
    table.insert(Sprites, sboldNodeSprite("nodeBG", "materials/node_background", "", 0))
end]]