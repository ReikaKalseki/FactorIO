require "config"
require "prototypes.combinators"
require "functions"

function initGlobal(markDirty)
	if not global.signals then
		global.signals = {}
	end
	local signals = global.signals
	if not signals.combinators then
		signals.combinators = {}
	end
	signals.dirty = markDirty
end

script.on_configuration_changed(function()
	initGlobal(true)
end)

script.on_init(function()
	initGlobal(true)
end)

function shouldTick(entry)
	--game.print("Checking " .. entry.id .. " @ " .. entry.tick_rate .. " + " .. entry.tick_offset .. " #" .. (game.tick%entry.tick_rate))
	return game.tick%entry.tick_rate == entry.tick_offset
end

script.on_event(defines.events.on_tick, function(event)
	if event.tick%maximumTickRate == 0 then
		local signals = global.signals
		for unit,entry in pairs(signals.combinators) do
			if shouldTick(entry) then
				tickCombinator(entry, event.tick)
			end
		end		
	end
end)

local function onEntityRemoved(entity)
	if entity.unit_number then
		global.signals.combinators[entity.unit_number] = nil
	end
end

local function onEntityAdded(entity)
	if entity.type == "constant-combinator" then
		local id = string.sub(entity.name, 12)
		if typeExists(id) then
			local rate = getTickRate(id)
			local ramp = getRampRate(id)
			local offset = maximumTickRate*math.random(0, math.floor(rate/maximumTickRate)-1)
			local entry = {entity = entity, id = id, tick_rate = rate, tick_offset = offset}
			if ramp then
				entry.base_tick_rate = rate
				entry.ramp_rate = ramp
				entry.tick_rate = ramp
			end
			global.signals.combinators[entity.unit_number] = entry
			--[[
			game.print("Added combinator of type " .. global.signals.combinators[entity.unit_number].id .. ", tick rate of " .. rate .. " with offset of " .. global.signals.combinators[entity.unit_number].tick_offset)
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
	onEntityAdded(event.created_entity)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
	onEntityAdded(event.created_entity)
end)