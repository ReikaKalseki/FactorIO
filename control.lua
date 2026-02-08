require "prototypes.combinators"
require "functions"

---@return {int: CombinatorEntry}
local function getCombinatorStorage()
	return storage.signals.combinators
end

function initGlobal(markDirty)
	if not storage.signals then
		storage.signals = {}
	end
	local signals = storage.signals
	if not signals.combinators then
		signals.combinators = {}
	end
	
	for _,entry in pairs(signals.combinators) do
		if not entry.data then entry.data = {} end
	end
	
	signals.dirty = markDirty
end

script.on_configuration_changed(function(data)
	initGlobal(true)
end)

script.on_init(function()
	initGlobal(true)
end)

---@param entry CombinatorEntry
---@param tick int
---@return boolean
function shouldTick(entry, tick)
	if not entry.tick_rate then fmterror("Stored nil tick rate for combinator %s > %s", entry.entity.name, entry.id) end
	--game.print("Checking " .. entry.id .. " @ " .. entry.tick_rate .. " + " .. entry.tick_offset .. " #" .. (game.tick%entry.tick_rate))
	return entry and tick%entry.tick_rate == entry.tick_offset
end

script.on_event(defines.events.on_tick, function(event)
	if event.tick%maximumTickRate == 0 then
		local signals = getCombinatorStorage()
		for unit,entry in pairs(signals) do
			if shouldTick(entry, event.tick) then
				if not tickCombinator(entry, event.tick) then
					signals[unit] = nil
				end
			end
		end		
	end
end)

---@param entity LuaEntity
local function onEntityRemoved(entity)
	if entity.unit_number then
		getCombinatorStorage()[entity.unit_number] = nil
	end
end

---@param entity LuaEntity
local function onEntityAdded(entity)
	if entity.type == "constant-combinator" then
		local id = string.sub(entity.name, 12) --trim leading "combinator-"
		if COMBINATORS[id] then
			local rate = getTickRate(id)
			if not rate then fmterror("Got nil tick rate for combinator %s > %s", entity.name, id) end
			local ramp = getRampRate(id)
			local offset = maximumTickRate*math.random(0, math.floor(rate/maximumTickRate)-1)
			local entry = {entity = entity, id = id, tick_rate = rate, tick_offset = offset}
			if ramp then
				entry.base_tick_rate = rate
				entry.ramp_rate = ramp
				entry.tick_rate = ramp
			end
			getCombinatorStorage()[entity.unit_number] = entry
			--[[
			game.print("Added combinator of type " .. getCombinatorStorage()[entity.unit_number].id .. ", tick rate of " .. rate .. " with offset of " .. getCombinatorStorage()[entity.unit_number].tick_offset)
			if ramp then
				game.print("Ramping from " .. entry.base_tick_rate .. " to " .. entry.ramp_rate)
			end
			--]]
		end
	end
end

script.on_event(defines.events.on_entity_died, function(event)
	onEntityRemoved(event.entity)
end)

script.on_event(defines.events.on_pre_player_mined_item, function(event)
	onEntityRemoved(event.entity)
end)

script.on_event(defines.events.on_robot_pre_mined, function(event)
	onEntityRemoved(event.entity)
end)

script.on_event(defines.events.on_built_entity, function(event)
	onEntityAdded(event.entity)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
	onEntityAdded(event.entity)
end)