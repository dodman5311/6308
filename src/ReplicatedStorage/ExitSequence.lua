local module = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local dataStore = require(Globals.Server.Services.DataStore)
local mapService = require(Globals.Server.Services.MapService)
local net = require(Globals.Packages.Net)
local spawners = require(Globals.Services.Spawners)
local upgrades = require(Globals.Shared.Upgrades)

local function reverse(number, max)
	if max == 0 then
		return 1
	end

	return math.abs((number / max) - 1)
end

module.Exit = function(player, start_time, stage_number, level_number, bossBeaten)
	local arenas = {}
	local arenasCompleted = {}
	local comboCount = 10

	local stageFolder = ServerStorage:FindFirstChild("Stage_" .. mapService.CurrentStage)
	local boss_name = stageFolder:GetAttribute("MainBoss")
	local miniboss_name = stageFolder:GetAttribute("MiniBoss")

	for _, arena in ipairs(ReplicatedStorage.Map:GetChildren()) do
		if not string.match(arena.Name, "Arena_") then
			continue
		end

		table.insert(arenas, arena)

		if arena:GetAttribute("Status") == "Completed" then
			table.insert(arenasCompleted, arena)
		end
	end

	local enemies = CollectionService:GetTagged("Enemy") or {}

	local spawnedEnemies = spawners.EnemiesSpawned
	local spawnedArenas = math.clamp(#arenas, 1, math.huge)
	local arenaCount = math.clamp(#arenasCompleted, 1, math.huge)
	local enemyCount = #enemies

	for _, enemy in ipairs(enemies) do
		enemy:Destroy()
	end

	local title = "The Suburbs"

	if stage_number == 2 then
		title = "The Sewers"
	end

	if not bossBeaten then
		comboCount = net:RemoteFunction("GetMaxCombo"):InvokeClient(player)
	end

	if stage_number == 0 then
		bossBeaten = "The Requiem"
		workspace:SetAttribute("TotalScore", 0)
		comboCount = 0
		spawnedArenas = 1
		arenaCount = 0
		spawnedEnemies = 1
		enemyCount = 0
	end

	local levelData = {
		Name = bossBeaten or title .. " : " .. level_number,
		TimeTaken = math.round(os.clock() - start_time),
		EnemiesKilled = reverse(enemyCount, spawnedEnemies) * 100,
		ArenasCompleted = arenaCount / spawnedArenas * 100,
		MaxCombo = comboCount,
	}

	local maxScore = levelData.EnemiesKilled + levelData.ArenasCompleted + (levelData.MaxCombo * 10)
	workspace:SetAttribute("TotalScore", workspace:GetAttribute("TotalScore") + math.floor(maxScore))

	local upgradesList = {}

	for _, category in pairs(upgrades) do
		for upgradeName, _ in pairs(category) do
			upgradesList[upgradeName] = workspace:GetAttribute(upgradeName)
		end
	end

	dataStore.SaveData(player, "ShopUpgrades", upgradesList)

	net:RemoteEvent("StartExitSequence"):FireAllClients(levelData, level_number, boss_name, miniboss_name, stage_number)
end

return module
