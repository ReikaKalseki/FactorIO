local callbacks = {}

function runTimer(entity)
	return game.tick%60
end

function getNearEnemies(entity) --stagger calls to this one
	local near = entity.surface.find_entities_filtered({type = "unit", area = {{entity.position.x-24, entity.position.y-24}, {entity.position.x+24, entity.position.y+24}}, force = game.forces.enemy})
	return #near
end

function getDayTime(entity)
	return (math.floor(entity.surface.daytime*24000+0.5)+6000)%24000 --MC time
end

function getResearchProgress(entity)
	local force = entity.force
	return math.floor(force.research_progress*100 + 0.5)
end

function countLogiBots(entity, connection)
	local network = connection.logistic_network
	if network then
		return network.all_logistic_robots
	end
	return 0
end

function countConstrBots(entity, connection)
	local network = connection.logistic_network
	if network then
		return network.all_construction_robots
	end
	return 0
end

function getPowerProduction(entity, connection) --in kW
	local stats = connection.electric_network_statistics
	local gen = 0
	for k,amt in pairs(stats.input_counts) do
		gen = gen+amt
	end
	return gen/1000
end

function getPowerConsumption(entity, connection) --in kW
	local stats = connection.electric_network_statistics
	local con = 0
	for k,amt in pairs(stats.output_counts) do
	--game.print(k .. ": " .. amt)
		con = con+amt
	end
	return con/1000
end

function getFluidTemp(entity, connection)
	local fluid = connection.fluidbox[1]
	return fluid and fluid.temperature or 0
end

function countEmptySlots(entity, connection)
	local inv = connection.get_inventory(defines.inventory.chest)
	local ret = 0
	for i = 1,#inv do
		if not (inv[i] and inv[i].valid_for_read) then
			ret = ret+1
		end
	end
	return ret
end

function runCallback(id, entity, connection)
	local func = callbacks[id]
	if func then
		--game.print("Running callback for combinator " .. id)
		return func(entity, connection)
	else
		game.print("Could not find callback for entity " .. entity.name .. ", ID = " .. id .. "!")
		return 0
	end
end

function registerCall(id, callback)
	callbacks[id] = callback
end

function typeExists(id)
	return callbacks[id] ~= nil
end