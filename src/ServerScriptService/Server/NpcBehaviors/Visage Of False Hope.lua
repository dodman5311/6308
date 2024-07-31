local CollectionService = game:GetService("CollectionService")
local rng = Random.new()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local spawners = require(Globals.Server.Services.Spawners)
local net = require(Globals.Packages.Net)

local function spawnEnemy(OriginCFrame)
	local spawnRange = 100
	local enemyToSpawn = rng:NextNumber(0, 100) <= 10 and "Specimen" or "Tollsman"
	local spawnCFrame = OriginCFrame
		* CFrame.new(rng:NextNumber(-spawnRange, spawnRange), -10, rng:NextNumber(-spawnRange, spawnRange))

	local enemyModel = spawners.placeNewObject(10, spawnCFrame, "Enemy", enemyToSpawn)

	if not enemyModel then
		return
	end

	net:RemoteEvent("ReplicateEffect"):FireAllClients("EnemySpawned", "Server", true, spawnCFrame.Position)
end

local function spawnEnemies(npc) -- 250 studs
	local origin = npc.Instance:GetPivot()

	local spawnTimer = npc:GetTimer("SpawnEnemies")

	spawnTimer.WaitTime = 5
	spawnTimer.Function = function()
		if #CollectionService:GetTagged("Enemy") > 6 then
			return
		end

		spawnEnemy(origin)
	end

	spawnTimer.Parameters = { npc }

	spawnTimer:Run()
end

local module = {
	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnStep = {
		{ Function = "Custom", Parameters = { spawnEnemies } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 1 } },
	},
}

return module
