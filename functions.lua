require "calls"
require "__DragonIndustries__.registration"
require "__DragonIndustries__.entities"

---@class (exact) CombinatorTypeDef
---@field id string
---@field validation fun(LuaEntity) : boolean
---@field callback fun(LuaEntity, table, LuaEntity) : int|{string:int}
---@field tickRate int
---@field rampRate? int
---@field inputCount int
---@field isActuator? boolean
---@field emptySignal {string: int}

---@class (exact) CombinatorConnection
---@field wire LuaWireConnector
---@field entity LuaEntity

---@class (exact) CombinatorEntry
---@field id string
---@field entity LuaEntity
---@field tick_rate int
---@field tick_offset int
---@field base_tick_rate? int
---@field ramp_rate? int
---@field data? table
---@field connection? CombinatorConnection

---@type {string: CombinatorTypeDef}
COMBINATORS = {}

maximumTickRate = 9999999

---@param entity LuaEntity
---@return boolean
function isTrainStop(entity)
	return entity.type == "train-stop"
end

---@param entity LuaEntity
---@return boolean
function isInserterOrLoader(entity)
	return entity.type == "loader" or entity.type == "inserter"
end

---@param entity LuaEntity
---@return boolean
function entityHasPower(entity)
	return entity.electric_buffer_size and entity.electric_buffer_size > 0 or false
end

---@param entity LuaEntity
---@return boolean
function isElectricPole(entity)
	return entity.type == "electric-pole"
end

---@param entity LuaEntity
---@return boolean
function hasLogiConnection(entity)
	return entity.type == "logistic-container" or entity.type == "roboport"
end

---@param entity LuaEntity
---@return boolean
function isTank(entity)
	return entity.type == "storage-tank"
end

---@param entity LuaEntity
---@return boolean
function isChest(entity)
	return (entity.type == "container" or entity.type == "logistic-container")-- and entity.get_inventory(defines.inventory.chest)
end

---@param id string
---@return number
function getTickRate(id)
	return COMBINATORS[id].tickRate
end

---@param id string
---@return number
function getRampRate(id)
	return COMBINATORS[id].rampRate
end

---@param entry CombinatorEntry
---@return boolean
local function testIfEntityIsStillConnected(entry)
	if not entry.connection then return false end
	return testIfEntityIsConnectedToWire(entry.connection.wire, entry.connection.entity)
end

---@param entry CombinatorEntry
local function tryFindConnection(entry)
	local connectValid = COMBINATORS[entry.id].validation
	if not connectValid then return false end
	forEachWireConnection(entry.entity, function(conn, point)
		if connectValid and connectValid(conn.target) then
			--game.print("Found " .. val.name)
			entry.connection = {entity = conn.target, wire = point}
			return true
		else
			return false
		end
	end)
end

---@param entry CombinatorEntry
---@param val {string:int}
local function setValue(entry, val)
	if (not entry.entity.valid) then return end
	local def = COMBINATORS[entry.id]
	if def.isActuator then return end
	
	setConstantCombinatorSignals(entry.entity, val)
end

---@param id string
---@param val int
---@return int
local function checkValueLimits(id, val)
	if val > 2^31-1 then
		game.print("Sensor " .. id .. " outputted a value of " .. val .. ", far more than is plausible or displayable!")
		val = 2^31-1
	elseif val < -(2^31-1) then
		game.print("Sensor " .. id .. " outputted a value of " .. val .. ", far less than is plausible or displayable!")
		val = -(2^31-1)
	end
	return val
end

---@param entry CombinatorEntry
---@return {string:int}?
local function runCallback(entry)
	local def = COMBINATORS[entry.id]
	if def then
		--game.print("Running callback for combinator " .. id)
		local ret = def.callback(entry.entity, entry.data, entry.connection.entity)
		if ret == nil then return nil end
		return type(ret) == "number" and {[entry.id]=ret} or ret
	else
		entry.entity.force.print({"", "Could not find combinator definition for entity ", {"entity-name" .. entry.entity.name}, ", ID = " .. entry.id .. "!"})
		return nil
	end
end

---@param entry CombinatorEntry
---@param tick int
---@return boolean
function tickCombinator(entry, tick)
	--game.print("Ticking " .. entry.id)
	
	if not (entry.entity and entry.entity.valid) then game.print("Could not find entity for signal ID = " .. entry.id .. "!") return false end
	
	local def = COMBINATORS[entry.id]
	if def.validation then --does it even need a connection?
		if entry.connection then
			if not entry.connection.entity.valid then
				entry.connection = nil
			elseif tick%120 == entry.tick_offset then
				if not testIfEntityIsStillConnected(entry) then
					entry.connection = nil
				end
			end
		end
	
		if not (entry.connection and entry.connection.entity.valid) and tick%120 == entry.tick_offset then
			tryFindConnection(entry)
		end
		
		if not (entry.connection and entry.connection.entity.valid) then
			--game.print("No connection for " .. entry.id)
			setValue(entry, def.emptySignal)
			return true
		end
	end
	
	if not entry.data then entry.data = {} end
	
	local val = runCallback(entry)
	
	if not val then val = def.emptySignal end
	
	for id,amt in pairs(val) do
		val[id] = math.floor(checkValueLimits(entry.id, amt)+0.5)
	end
	
	if entry.ramp_rate then
		--local old = entry.tick_rate
		if val > 0 then
			entry.tick_rate = math.max(entry.tick_rate - maximumTickRate, entry.base_tick_rate)
		else
			entry.tick_rate = math.min(entry.tick_rate + maximumTickRate, entry.ramp_rate)
		end
		--game.print("Ramped " .. entry.id .. " tick rate from " .. old .. " to " .. entry.tick_rate)
	end
	
	setValue(entry, val)
	return true
end

---@param variant string
---@param callFunc fun(LuaEntity, table, LuaEntity): int|{string:int}
---@param validFunc? fun(LuaEntity): boolean
---@param tickRate int
---@param rampedTickRate? int
---@param isActuator? boolean
---@return data.ConstantCombinatorPrototype|LuaEntityPrototype
function addCombinator(variant, callFunc, validFunc, tickRate, rampedTickRate, isActuator)
	local def = {
		id = variant,
		callback = callFunc,
		 validation = validFunc,
		 tickRate = tickRate, 
		 rampedTickRate = rampedTickRate, 
		 isActuator = isActuator and true or false, 
		 emptySignal={[variant]=0}
		}
	COMBINATORS[variant] = def
	maximumTickRate = math.min(maximumTickRate, tickRate)
	
	local name = "combinator-" .. variant
	if prototypes then
		return prototypes[name]
	elseif data and data.raw and not game then
		local ico = "__FactorIO__/graphics/icons/" .. variant .. ".png"
		local entity = createDerivative(data.raw["constant-combinator"]["constant-combinator"], {
			name = name,
			minable = {result = name},
			icons = {{icon = data.raw["constant-combinator"]["constant-combinator"].icon}, {icon = ico, icon_size = 32}},
			localised_name = {"basic-combinator-name." .. (isActuator and "actuator" or "sensor"), {"signal-type." .. variant}},
			energy_source = {type = "electric", usage_priority = "secondary-input"},
			active_energy_usage = isActuator and "20kW" or "4KW",
			item_slot_count = isActuator and 0 or 1,
		})
		local item = createDerivative(data.raw.item["constant-combinator"], {
			name = name,
			icons = entity.icons,
			place_result = name,
			localised_name = entity.localised_name,
		})

		local recipe = createDerivative(data.raw.recipe["constant-combinator"], {
			name = name,
			localised_name = entity.localised_name,
			results = {{type = "item", name = name, amount = 1}}
		})
		addItemToRecipe(recipe, "advanced-circuit", 1)
		
		local signal = {
			type = "virtual-signal",
			name = variant,
			icon = ico,
			icon_size = 32,
			icon_mipmaps = 0,
			subgroup = "virtual-signal-special",
			order = variant,
			localised_name = {"signal-type." .. variant},
		}
		
		data:extend({entity, item, recipe, signal})
		
		table.insert(data.raw.technology["more-signals"].effects, {type = "unlock-recipe", recipe = name})
		
		fmtlog("Added combinator '%s', calls '%s' @ %s/%s", variant, callFunc, tickRate, (rampedTickRate and rampedTickRate or "N/A"))
		
		return entity
	else
		fmterror("Invalid combinator lookup/registration!")
		return nil
	end
end

function addCombinatorWithInput(variant, inputCount, callFunc, validFunc, tickRate, rampedTickRate)
	local entity = addCombinator(variant, callFunc, validFunc, tickRate, rampedTickRate)
	
	if data and data.raw and not game then
		entity.item_slot_count = 1+inputCount
	end
	
	inputCounts[variant] = inputCount
end

function addMultiCombinator(variant, signals, callFunc, validFunc, tickRate, rampedTickRate, isActuator)
	local entity = addCombinator(variant, callFunc, validFunc, tickRate, rampedTickRate, isActuator)
	
	if data and data.raw and not game then
		for _,name in pairs(signals) do
			local signal = {
				type = "virtual-signal",
				name = name,
				icon = "__FactorIO__/graphics/icons/" .. name .. ".png",
				icon_size = 32,
				icon_mipmaps = 0,
				subgroup = "virtual-signal-special",
				order = variant,
				localised_name = {"signal-type." .. name},
			}
			data:extend({signal})
		end
		data.raw["virtual-signal"][variant] = nil --delete the base type
		entity.item_slot_count = #signals
	end
end