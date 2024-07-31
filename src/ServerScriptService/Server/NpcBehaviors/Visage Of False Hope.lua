local CollectionService = game:GetService("CollectionService")
local rng = Random.new()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local spawners = require(Globals.Server.Services.Spawners)
local net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)
local timer = require(Globals.Vendor.Timer)

local vfx = net:RemoteEvent("ReplicateEffect")

local moveChances = {
	--{ "SinkRoom", 10 },
	--{ "Sacrifice", 15 },
	--{ "SkyLasers", 25 },

	{ "Fire", 100 }, -- 40 },
	--{ "Rockets", 50 },
	--{ "Grenades", 100 },
}

local function MoveApatureTo(npc, yAlpha, rotationAngle)
	local root = npc.Instance.PrimaryPart

	if yAlpha then
		local yPos = (yAlpha * (75 * 2)) - 75
		root.ApatureRoot.Position = Vector3.new(0, yPos, 0)
	end

	if rotationAngle then
		root.ApatureRoot.Orientation = Vector3.new(0, rotationAngle, 0)
	end
end

local function shootFireHitboxes(npc)
	for _, barrel in ipairs(npc.Instance.Apature:GetChildren()) do
		if barrel.Name ~= "Barrel" then
			continue
		end

		local origin = barrel.Attachment.WorldCFrame

		local newPart = game.ReplicatedStorage.FireHitbox:Clone()
		newPart.Parent = workspace

		newPart.Position = origin.Position
		local goal = origin * CFrame.new(0, 0, -170)

		table.insert(npc.fireHitboxes, {
			part = newPart,
			startPosition = origin.Position,
			startSize = newPart.Size,
			goal = goal.Position,
			createdAt = os.clock(),
		})
	end
end

local function processHitboxes(npc)
	for index, hitbox in ipairs(npc.fireHitboxes) do
		local t = os.clock() - hitbox.createdAt

		hitbox.part.Position = hitbox.startPosition:Lerp(hitbox.goal, t / 1.5)
		hitbox.part.Size = hitbox.startSize:Lerp(Vector3.new(20, 50, 50), t / 1.5)

		if t >= 1.5 then
			hitbox.part:Destroy()
			table.remove(npc.fireHitboxes, index)
		end
	end
end

local function checkHitboxes(npc)
	local playersHit = {}

	for _, hitbox in ipairs(npc.fireHitboxes) do
		local part = hitbox.Part

		if not part then
			continue
		end

		for _, partHit in ipairs(workspace:GetPartsInPart(part)) do
			local humanoid, model = util.checkForHumanoid(partHit)

			local playerHit = Players:GetPlayerFromCharacter(model)
			if not playerHit or table.find(playersHit, playerHit) then
				continue
			end

			humanoid:TakeDamage(1)

			table.insert(playersHit, playerHit)
		end
	end
end

local function rotateForFire(npc)
	local startTime = os.clock()
	local lastStep = os.clock()
	local alpha = 0
	local hitBoxAlpha = 0

	local raiseTime = 8
	local rotateTime = 1.4

	npc.fireHitboxes = {}

	local checkHitboxTimer = npc:GetTimer("CheckHitboxes")
	checkHitboxTimer.WaitTime = 0.25
	checkHitboxTimer.Function = checkHitboxes
	checkHitboxTimer.Parameters = { npc }

	return RunService.Heartbeat:Connect(function()
		local currentTime = os.clock() - startTime
		local step = os.clock() - lastStep

		alpha += step / raiseTime
		hitBoxAlpha += step

		MoveApatureTo(npc, alpha, (currentTime * 90) / rotateTime)

		if alpha >= 0.5 then
			alpha = 0
		end

		if hitBoxAlpha >= 0.1 then
			hitBoxAlpha = 0
			shootFireHitboxes(npc)
		end

		processHitboxes(npc)
		checkHitboxTimer:Run()

		lastStep = os.clock()
	end)
end

local moves = {
	Fire = function(npc)
		npc.Acts:createAct("InAction")

		MoveApatureTo(npc, 0, 0)

		vfx:FireAllClients("VisageFire", "Server", true, npc.Instance, true)
		local rotateOnStep = rotateForFire(npc)

		timer.wait(15)

		vfx:FireAllClients("VisageFire", "Server", true, npc.Instance, false)

		rotateOnStep:Disconnect()
		npc.Acts:removeAct("InAction")
	end,
}

local function spawnEnemy(OriginCFrame)
	local spawnRange = 150
	local enemyToSpawn = rng:NextNumber(0, 100) <= 10 and "Specimen" or "Tollsman"
	local spawnCFrame = OriginCFrame
		* CFrame.new(rng:NextNumber(-spawnRange, spawnRange), -75, rng:NextNumber(-spawnRange, spawnRange))

	local enemyModel = spawners.placeNewObject(10, spawnCFrame, "Enemy", enemyToSpawn)

	if not enemyModel then
		return
	end

	net:RemoteEvent("ReplicateEffect"):FireAllClients("EnemySpawned", "Server", true, spawnCFrame.Position)
end

local function runAttackTimer(npc)
	if npc.Acts:checkAct("Run", "InAttack", "Melee") then
		return
	end

	local AttackTimer = npc:GetTimer(npc, "Special")

	AttackTimer.WaitTime = rng:NextNumber(2, 4)
	AttackTimer.Function = function()
		if npc.StatusEffects["Ice"] then
			return
		end

		for _, value in ipairs(moveChances) do
			if rng:NextNumber(0, 100) > value[2] then
				continue
			end

			if not npc.Acts:checkAct("InAction") then
				moves[value[1]](npc)
			end

			return
		end
	end
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
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

-- local function setUp(npc)

-- end

local module = {
	OnStep = {
		{ Function = "Custom", Parameters = { spawnEnemies } },
		{ Function = "Custom", Parameters = { runAttackTimer } },
	},

	OnSpawned = {
		--{ Function = "Custom", Parameters = { setUp } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 1 } },
	},
}

return module
