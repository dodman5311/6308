local module = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local spawners = require(Globals.Services.Spawners)
local net = require(Globals.Packages.Net)
local mapService = require(Globals.Server.Services.MapService)

local function reverse(number, max)
	if max == 0 then
		return 1
	end

	return math.abs((number / max) - 1)
end

module.Exit = function(player, start_time, stage_number, level_number, bossBeaten)
	local arenas = {}
	local arenasCompleted = {}

	local stageFolder = ServerStorage:FindFirstChild("Stage_" .. mapService.CurrentStage)
	local boss_name = stageFolder:GetAttribute("MainBoss")
	local miniboss_name = stageFolder:GetAttribute("MiniBoss")

	for _, arena in ipairs(workspace.Map:GetChildren()) do
		if not string.match(arena.Name, "Arena_") then
			continue
		end

		table.insert(arenas, arena)

		if arena:FindFirstChild("ArenaHitbox") then
			table.insert(arenasCompleted, arena)
		end
	end

	local enemies = CollectionService:GetTagged("Enemy") or {}

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

	local levelData = {
		Name = bossBeaten or title .. " : " .. level_number,
		TimeTaken = math.round(os.clock() - start_time),
		EnemiesKilled = reverse(enemyCount, spawners.EnemiesSpawned) * 100,
		ArenasCompleted = reverse(arenaCount, spawnedArenas) * 100,
		MaxCombo = bossBeaten and 10 or net:RemoteFunction("GetMaxCombo"):InvokeClient(player),
	}

	net:RemoteEvent("StartExitSequence"):FireAllClients(levelData, level_number, boss_name, miniboss_name, stage_number)
end

return module
