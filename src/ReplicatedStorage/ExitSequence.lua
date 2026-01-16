local module = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local MapService = require(ServerScriptService.Server.Services.MapService)
local dataStore = require(Globals.Server.Services.DataStore)
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

	local stageNumber = MapService.CurrentStage == 0 and workspace:GetAttribute("SaveStage") or MapService.CurrentStage
	local stageFolder = ServerStorage:FindFirstChild("Stage_" .. stageNumber)

	local boss_name = stageFolder:GetAttribute("MainBoss")
	local miniboss_name = stageFolder:GetAttribute("MiniBoss")

	for _, arena in ipairs(workspace.Map:GetChildren()) do
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
	local spawnedArenas = #arenas
	local arenaCount = #arenasCompleted
	local enemyCount = #enemies

	for _, enemy in ipairs(enemies) do
		enemy:Destroy()
	end

	local title = "The Suburbs"

	if stage_number == 2 then
		title = "The Sewers"
	end

	if not bossBeaten or bossBeaten == "A prayer is spoken" then
		comboCount = net:RemoteFunction("GetMaxCombo"):InvokeClient(player)
	end

	if spawnedArenas == 0 then
		spawnedArenas = 1
		arenaCount = 1
	end

	if level_number ~= 2 and level_number ~= 5 then
		local upgradesList = {}

		for _, category in pairs(upgrades) do
			for upgradeName, _ in pairs(category) do
				upgradesList[upgradeName] = workspace:GetAttribute(upgradeName)
			end
		end

		dataStore.SaveData(player, "ShopUpgrades", upgradesList)
	end

	if stage_number == 0 then
		bossBeaten = "The Requiem"

		comboCount = workspace:GetAttribute("TotalScore")
		spawnedArenas = 1
		arenaCount = 0
		spawnedEnemies = 1
		enemyCount = 0
		workspace:SetAttribute("TotalScore", 0)
	end

	local levelData = {
		Name = bossBeaten or title .. " : " .. level_number,
		TimeTaken = math.round(os.clock() - start_time),
		EnemiesKilled = reverse(enemyCount, spawnedEnemies) * 100,
		ArenasCompleted = arenaCount / spawnedArenas * 100,
		MaxCombo = comboCount,
	}

	if stage_number ~= 0 then
		local maxScore = levelData.EnemiesKilled + levelData.ArenasCompleted + (levelData.MaxCombo * 10)
		workspace:SetAttribute("TotalScore", workspace:GetAttribute("TotalScore") + math.floor(maxScore))
	end

	if bossBeaten == "A prayer is spoken" then
		workspace:SetAttribute("IsInReq", true)
	end

	net:RemoteEvent("StartExitSequence")
		:FireAllClients(
			levelData,
			level_number,
			boss_name,
			miniboss_name,
			stage_number,
			bossBeaten == "A prayer is spoken"
		)
end

return module
