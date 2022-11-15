local callbacks = {}

---AVOID FUNCTION NAME CONFLICTS, WHICH WILL CONFUSE THE DECLARATIONS IN COMBINATORS
---ALSO IF ANY CALLS OR THEIR NAMES CHANGE, GAME NEEDS RESTART THEN COMBINATORS NEED TO BE BROKEN AND REPLACED

local function moveBox(area, dx, dy)
	--printTable(area)
	area.left_top.x = area.left_top.x+dx
	area.left_top.y = area.left_top.y+dy
	area.right_bottom.x = area.right_bottom.x+dx
	area.right_bottom.y = area.right_bottom.y+dy
	return area
end

local function moveBoxDirection(area, dir, dist)
	if dir == defines.direction.north then
		area = moveBox(area, 0, dist)
	end
	if dir == defines.direction.south then
		area = moveBox(area, 0, -dist)
	end
	if dir == defines.direction.east then
		area = moveBox(area, -dist, 0)
	end
	if dir == defines.direction.west then
		area = moveBox(area, dist, 0)
	end
	return area
end

local function getBox(entity)
	return moveBox(entity.prototype.collision_box, entity.position.x, entity.position.y)	
end

local function getFacingEntity(entity, types)
	local box = getBox(entity)
	box = moveBoxDirection(box, entity.direction, 1)
	local seek = {area = box, force = entity.force, limit = 1}
	if types then seek.type = types end
	--game.print(serpent.block(seek))
	return entity.surface.find_entities_filtered(seek)
end

local function getDesiredBeltDirection(entity)
	local network = entity.get_circuit_network(defines.wire_type.red)
	if not network then network = entity.get_circuit_network(defines.wire_type.green) end
	if network then
		local signals = network.signals
		if signals and #signals > 0 then
			for _,signal in pairs(signals) do
				if signal.count > 0 and signal.signal.type == "virtual" then
					if signal.signal.name == "signal-N" then return defines.direction.north end
					if signal.signal.name == "signal-S" then return defines.direction.south end
					if signal.signal.name == "signal-E" then return defines.direction.east end
					if signal.signal.name == "signal-W" then return defines.direction.west end
				end
			end
		end
	end
	return nil
end

function setBeltDirection(entity, data, connection)
	local tgt = getFacingEntity(entity, "transport-belt")
	if tgt and table_size(tgt) > 0 and tgt[1].valid then
		local dir = getDesiredBeltDirection(entity)
		--game.print(tgt[1].name .. " and " .. serpent.block(dir))
		if dir then
			tgt[1].direction = dir
		end
	end
	return 0
end

local function getDesiredItemFilter(entity)
	local network = entity.get_circuit_network(defines.wire_type.red)
	if not network then network = entity.get_circuit_network(defines.wire_type.green) end
	if network then
		local signals = network.signals
		if signals and #signals > 0 then
			for _,signal in pairs(signals) do
				if signal.count > 0 and signal.signal.type == "item" then
					return signal.signal.name
				end
			end
		end
	end
end

function setInserterFilter(entity, data, connection)
	local tgt = getFacingEntity(entity, {"loader", "inserter"})
	if tgt and table_size(tgt) > 0 and tgt[1].valid and tgt[1].filter_slot_count > 0 then
		local item = getDesiredItemFilter(entity)
		--game.print(tgt[1].name)
		if item then
			tgt[1].set_filter(1, item)
		end
	end
	return 0
end

function checkSignalDuration(entity, data, connection)
	return 0
end

local function countTrainSize(train)
	local ret = {locomotivesFront = 0, locomotivesBack = 0, wagons = 0, fluidWagons = 0}
	if not train then return ret end
	ret.wagons = table_size(train.cargo_wagons)
	ret.fluidWagons = table_size(train.fluid_wagons)
	ret.locomotivesFront = table_size(train.locomotives["front_movers"])
	ret.locomotivesBack = table_size(train.locomotives["back_movers"])
	return ret
end

function trainSize(entity, data, connection)
	local check = connection.get_stopped_train()
	local counts = countTrainSize(check)
	--game.print(serpent.block(counts))
	return {
		{id = "train-locos-front", value = counts.locomotivesFront},
		{id = "train-locos-back", value = counts.locomotivesBack},
		{id = "train-wagons", value = counts.wagons},
		{id = "train-fluid-wagons", value = counts.fluidWagons},
	}
end

local function countTrainTotals(train)
	local ret = {items = 0, fluids = 0}
	if not train then return ret end
	for _,wagon in pairs(train.cargo_wagons) do
		local inv = wagon.get_inventory(defines.inventory.cargo_wagon);
		ret.items = ret.items+inv.get_item_count()
	end
	for _,wagon in pairs(train.fluid_wagons) do
		local fb = wagon.fluidbox[1]
		if fb then
			ret.fluids = ret.fluids+fb.amount
		end
	end
	return ret
end

function trainTotals(entity, data, connection)
	local check = connection.get_stopped_train()
	local counts = countTrainTotals(check)
	--game.print(serpent.block(counts))
	return {
		{id = "train-total-items", value = counts.items},
		{id = "train-total-fluid", value = counts.fluids},
	}
end

local function isFull(wagon)
	local inv = wagon.get_inventory(defines.inventory.cargo_wagon)
	local filter = inv.get_filter(1)
	local item = filter and filter or "blueprint"
	return not inv.can_insert({name=item, count=1})
end

local function isEmpty(wagon)
	return wagon.get_inventory(defines.inventory.cargo_wagon).is_empty()
end

local function isTrainEmpty(train)
	for _,wagon in pairs(train.carriages) do
		if wagon.type == "cargo-wagon" then
			if not isEmpty(wagon) then
				return false
			end
		end
	end
	return true
end

local function isTrainFull(train)
	for _,wagon in pairs(train.carriages) do
		if wagon.type == "cargo-wagon" then
			if not isFull(wagon) then
				return false
			end
		end
	end
	return true
end

function trainFill(entity, data, connection)
	local check = connection.get_stopped_train()
	local empty = check ~= nil and isTrainEmpty(check)
	local full = check ~= nil and isTrainFull(check)
	return {
		{id = "train-empty", value = empty and 1 or 0},
		{id = "train-full", value = full and 1 or 0},
	}
end

function trainStatus(entity, data, connection)
	local trains = entity.force.get_trains(entity.surface)
	local status = {}
	for _,val in pairs(defines.train_state) do
		status[val] = 0
	end
	for _,train in pairs(trains) do
		status[train.state] = status[train.state]+1
	end
	return {
		{id = "moving-trains", value = status[defines.train_state.on_the_path]},
		{id = "parked-trains", value = status[defines.train_state.wait_station]},
		{id = "waiting-trains", value = status[defines.train_state.wait_signal]},
		{id = "lost-trains", value = status[defines.train_state.no_path]},
	}
end

function powerSatisfaction(entity, data, connection)
	return math.floor((100*connection.energy/connection.electric_buffer_size)+0.5)
end

function runTimer(entity)
	return game.tick%60
end

function getNearEnemies(entity) --stagger calls to this one
	local forces = {game.forces.enemy}
	if game.forces.wisp_attack then
		table.insert(forces, game.forces.wisp_attack)
	end
	if game.forces["biter_faction_1"] then
		for i = 1,5 do
			table.insert(forces, game.forces["biter_faction_" .. i])
		end
	end
	return #entity.surface.find_entities_filtered({type = "unit", area = {{entity.position.x-24, entity.position.y-24}, {entity.position.x+24, entity.position.y+24}}, force = forces})
end

function getDayTime(entity)
	return (math.floor(entity.surface.daytime*24000+0.5)+6000)%24000 --MC time
end

function getResearchProgress(entity)
	local force = entity.force
	return math.floor(force.research_progress*100 + 0.5)
end

function countLogiBots(entity, data, connection)
	local network = connection.logistic_network
	if network then
		return network.all_logistic_robots
	end
	return 0
end

function countConstrBots(entity, data, connection)
	local network = connection.logistic_network
	if network then
		return network.all_construction_robots
	end
	return 0
end

function getPowerProduction(entity, data, connection) --in kW
	local last = data.last_value and data.last_value or -1
	local stats = connection.electric_network_statistics
	local gen = 0
	for k,amt in pairs(stats.input_counts) do
		gen = gen+amt
	end
	local diff = gen-last
	data.last_value = gen
	return last == -1 and 0 or diff/500
end

function getPowerConsumption(entity, data, connection) --in kW
	local last = data.last_value and data.last_value or -1
	local stats = connection.electric_network_statistics
	local con = 0
	for k,amt in pairs(stats.output_counts) do
		con = con+amt
	end
	local diff = con-last
	data.last_value = con
	return last == -1 and 0 or diff/500
end

function getFluidTemp(entity, data, connection)
	local fluid = connection.fluidbox[1]
	return fluid and fluid.temperature or 0
end

function countEmptySlots(entity, data, connection)
	local inv = connection.get_inventory(defines.inventory.chest)
	local ret = 0
	for i = 1,#inv do
		if not (inv[i] and inv[i].valid_for_read) then
			ret = ret+1
		end
	end
	return ret
end

function runCallback(id, entity, data, connection)
	local func = callbacks[id]
	if func then
		--game.print("Running callback for combinator " .. id)
		return func(entity, data, connection)
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