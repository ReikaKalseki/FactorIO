require "functions"

addCombinator("empty-slots", countEmptySlots, isChest, 30)
addCombinator("fluid-temp", getFluidTemp, isTank, 30)
addCombinator("research-progress", getResearchProgress, nil, 60)
addCombinator("daytime", getDayTime, nil, 30)
addCombinator("timer", runTimer, nil, 30)
addCombinator("near-enemies", getNearEnemies, nil, 30, 150)
addCombinator("power-production", getPowerProduction, isElectricPole, 30)
addCombinator("power-consumption", getPowerConsumption, isElectricPole, 30)
addCombinator("logi-bots", countLogiBots, hasLogiConnection, 30)
addCombinator("constr-bots", countConstrBots, hasLogiConnection, 30)
addCombinator("power-supply", powerSatisfaction, entityHasPower, 15)
addMultiCombinator("train-status", {"moving-trains", "parked-trains", "waiting-trains", "lost-trains"}, trainStatus, nil, 30)
addMultiCombinator("train-fill", {"train-empty", "train-full"}, trainFill, isTrainStop, 30)
addMultiCombinator("train-size", {"train-locos-front", "train-locos-back", "train-wagons", "train-fluid-wagons"}, trainSize, isTrainStop, 60)
addMultiCombinator("train-totals", {"train-total-items", "train-total-fluid"}, trainTotals, isTrainStop, 30)
--addCombinatorWithInput("signal-duration", 1, checkSignalDuration, nil, 15)

addCombinator("inserter-filter", setInserterFilter, nil--[[isInserterOrLoader--]], 30, nil, true)
addCombinator("belt-rotator", setBeltDirection, nil--[[isInserterOrLoader--]], 15, nil, true)

fmtlog("Registered combinators; maximum tick rate is " .. maximumTickRate)