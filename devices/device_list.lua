mine = FindDevice("mine")
mine.MetalCost = mine.MetalCost - 100 --Reduced cost due to the requirement of belts and the reduced income before smelting
mine.EnergyCost = mine.EnergyCost - 500
mine.MetalRepairCost = mine.MetalRepairCost * 0.8
mine.EnergyRepairCost = mine.EnergyRepairCost * 0.8
