require "config" 

local tech = table.deepcopy(data.raw.technology["circuit-network"])
tech.name = "more-signals"
tech.prerequisites = {"circuit-network", "advanced-electronics"}
tech.effects = {}
tech.unit.count = math.floor(tech.unit.count*1.5)

data:extend({tech})

--[[
data:extend({
	{
		type = "technology",
		name = "more-signals",
		prerequisites =
		{
			"circuit-network",
		},
		icon = "__MoreSignals__/graphics/technology/tech.png",
		effects =
		{
			
		},
		unit =
		{
		  count = 150,
		  ingredients =
		  {
			{"science-pack-1", 1},
			{"science-pack-2", 1},
		  },
		  time = 30
		},
		order = "[circuit-network]-3",
		icon_size = 128,
	}
})

--]]