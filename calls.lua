---AVOID FUNCTION NAME CONFLICTS, WHICH WILL CONFUSE THE DECLARATIONS IN COMBINATORS
---ALSO IF ANY CALLS OR THEIR NAMES CHANGE, GAME NEEDS RESTART THEN COMBINATORS NEED TO BE BROKEN AND REPLACED

--require "__DragonIndustries__.boxes"

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function checkSignalDuration(entity, data, connection)
	return 0
end

---@param train LuaTrain
---@return {string:int}
local function countTrainSize(train)
	local ret = {locomotivesFront = 0, locomotivesBack = 0, wagons = 0, fluidWagons = 0}
	if not train then return ret end
	ret.wagons = table_size(train.cargo_wagons)
	ret.fluidWagons = table_size(train.fluid_wagons)
	ret.locomotivesFront = table_size(train.locomotives["front_movers"])
	ret.locomotivesBack = table_size(train.locomotives["back_movers"])
	return ret
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return {string:int}
function trainSize(entity, data, connection)
	local check = connection.get_stopped_train()
	local counts = countTrainSize(check)
	--game.print(serpent.block(counts))
	return {
		["train-locos-front"] = counts.locomotivesFront,
		["train-locos-back"] = counts.locomotivesBack,
		["train-wagons"] = counts.wagons,
		["train-fluid-wagons"] = counts.fluidWagons,
	}
end

---@param train LuaTrain
---@return {string:int}
local function countTrainTotals(train)
	local ret = {items = 0, fluids = 0}
	if not train then return ret end
	for _,wagon in pairs(train.cargo_wagons) do
		local inv = wagon.get_inventory(defines.inventory.cargo_wagon)
		if inv then ret.items = ret.items+inv.get_item_count() end
	end
	for _,wagon in pairs(train.fluid_wagons) do
		local fb = wagon.fluidbox[1]
		if fb then
			ret.fluids = ret.fluids+fb.amount
		end
	end
	return ret
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return {string:int}
function trainTotals(entity, data, connection)
	local check = connection.get_stopped_train()
	local counts = countTrainTotals(check)
	--game.print(serpent.block(counts))
	return {
		["train-total-items"] = counts.items,
		["train-total-fluid"] = counts.fluids,
	}
end

---@param wagon LuaEntity
---@return boolean
local function isFull(wagon)
	local inv = wagon.get_inventory(defines.inventory.cargo_wagon)
	local filter = inv.get_filter(1)
	local item = filter and filter or "blueprint"
	return not inv.can_insert({name=item, count=1})
end

---@param wagon LuaEntity
---@return boolean
local function isEmpty(wagon)
	return wagon.get_inventory(defines.inventory.cargo_wagon).is_empty()
end

---@param train LuaTrain
---@return boolean
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

---@param train LuaTrain
---@return boolean
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

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return {string:int}
function trainFill(entity, data, connection)
	local check = connection.get_stopped_train()
	local empty = check ~= nil and isTrainEmpty(check)
	local full = check ~= nil and isTrainFull(check)
	return {
		["train-empty"] = empty and 1 or 0,
		["train-full"] = full and 1 or 0,
	}
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return {string:int}
function trainStatus(entity, data, connection)
	local trains = game.train_manager.get_trains({force=entity.force, surface=entity.surface})
	local status = {}
	for _,val in pairs(defines.train_state) do
		status[val] = 0
	end
	for _,train in pairs(trains) do
		status[train.state] = status[train.state]+1
	end
	return {
		["moving-trains"]=status[defines.train_state.on_the_path],
		["parked-trains"]=status[defines.train_state.wait_station],
		["waiting-trains"]=status[defines.train_state.wait_signal],
		["lost-trains"]=status[defines.train_state.no_path],
	}
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function powerSatisfaction(entity, data, connection)
	return math.floor((100*connection.energy/connection.electric_buffer_size)+0.5)
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function runTimer(entity)
	return game.tick%60
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
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
	return entity.surface.count_entities_filtered({type = "unit", area = {{entity.position.x-24, entity.position.y-24}, {entity.position.x+24, entity.position.y+24}}, force = forces})
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function getDayTime(entity)
	return (math.floor(entity.surface.daytime*24000+0.5)+6000)%24000 --MC time
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function getResearchProgress(entity)
	local force = entity.force
	return math.floor(force.research_progress*100 + 0.5)
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function countLogiBots(entity, data, connection)
	local network = connection.logistic_network
	if network then
		return network.all_logistic_robots
	end
	return 0
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function countConstrBots(entity, data, connection)
	local network = connection.logistic_network
	if network then
		return network.all_construction_robots
	end
	return 0
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
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

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
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

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function getFluidTemp(entity, data, connection)
	local fluid = connection.fluidbox[1]
	return fluid and fluid.temperature or 0
end

---@param entity LuaEntity
---@param data table
---@param connection LuaEntity
---@return int
function countEmptySlots(entity, data, connection)
	local inv = connection.get_inventory(defines.inventory.chest)
	if not inv then return 0 end
	local ret = 0
	for i = 1,#inv do
		if not (inv[i] and inv[i].valid_for_read) then
			ret = ret+1
		end
	end
	return ret
end