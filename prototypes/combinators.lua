require "functions"

addCombinator("empty-slots", countEmptySlots, isChest, 30)
addCombinator("fluid-temp", getFluidTemp, isTank, 30)
addCombinator("research-progress", getResearchProgress, nil, 60)
addCombinator("daytime", getDayTime, nil, 30)
addCombinator("timer", runTimer, nil, 30)
addCombinator("near-enemies", getNearEnemies, nil, 30, 150)
addCombinator("power-production", getPowerProduction, isElectricPole, 30)
addCombinator("power-consumption", getPowerConsumption, isElectricPole, 30)
addCombinator("logi-bots", countLogiBots, isLogiChest, 30)
addCombinator("constr-bots", countConstrBots, isLogiChest, 30)
addCombinator("power-supply", powerSatisfaction, entityHasPower, 15)
addMultiCombinator("train-status", {"moving-trains", "parked-trains", "waiting-trains", "lost-trains"}, trainStatus, nil, 90)

addCombinator("inserter-filter", setInserterFilter, nil--[[isInserterOrLoader--]], 30, nil, true)

log("Registered combinators; maximum tick rate is " .. maximumTickRate)