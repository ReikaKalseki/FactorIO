require "__DragonIndustries__.registration" 

local tech = addDerivative("technology", "circuit-network", {
	name = "more-signals",
	prerequisites = {"circuit-network", "steel-processing", "advanced-circuit"},
	effects = {}
})
tech.unit.count = math.floor(tech.unit.count*1.5)