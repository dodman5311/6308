local stats = {
	ViewDistance = 100,

	AttackDistance = 5,
	AttackDelay = 0.4,

	NpcType = "Enemy",
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local effects = ReplicatedStorage.Assets.Effects

local Globals = require(ReplicatedStorage.Shared.Globals)
local animationService = require(Globals.Vendor.AnimationService)
local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)

local vfx = net:RemoteEvent("ReplicateEffect")

local function getTimer(npc, timerName)
	local foundTimer = npc.Timers[timerName]

	if not foundTimer then
		npc.Timers[timerName] = npc.Timer:new(timerName)
		return npc.Timers[timerName]
	end

	return foundTimer
end

local rng = Random.new()

local function swing(npc, distance)
	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] then
		return
	end

	npc.Instance.Parent = workspace
	vfx:FireAllClients("GhoulTeleport", "Server", true, npc.Instance:GetPivot().Position)

	animationService:playAnimation(npc.Instance, "Attack", Enum.AnimationPriority.Action3).Ended:Once(function()
		if npc:GetState() == "Dead" then
			return
		end

		vfx:FireAllClients("GhoulTeleport", "Server", true, npc.Instance:GetPivot().Position)
		npc.Instance.Parent = game
	end)

	util.PlaySound(npc.Instance.PrimaryPart.Attack, npc.Instance.PrimaryPart, 0.1)

	task.wait(0.3)

	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] then
		return
	end

	local cframe = npc.Instance:GetPivot()

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { npc }
	raycastParams.CollisionGroup = "Npcs"

	local playersHit = {}
	for _, part in
		ipairs(
			workspace:GetPartBoundsInBox(
				cframe * CFrame.new(0, 0, -(distance / 2)),
				Vector3.new(distance, distance, distance)
			)
		)
	do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model then
			continue
		end

		local player = Players:GetPlayerFromCharacter(model)

		if not player or table.find(playersHit, player) then
			continue
		end

		table.insert(playersHit, player)

		model.Humanoid:TakeDamage(3)
	end

	npc.Instance.PrimaryPart.Swing:Play()
end

local function attackPlayer(npc)
	local target = npc:GetTarget()
	if not target then
		return
	end

	local npcModel = npc.Instance
	npcModel.Parent = workspace

	local targetPosition = target:GetPivot()
	local distance = 6
	local pos = targetPosition
		* CFrame.new(
			rng:NextInteger(-3, 3),
			rng:NextInteger(-1, 2),
			rng:NextInteger(-distance * 2, -distance) --rng:NextInteger(-distance, distance)
		)
	npcModel:PivotTo(CFrame.lookAt(pos.Position, targetPosition.Position))

	swing(npc, distance + 1)
end

local function runAttackTimer(npc)
	if not npc:GetTarget() then
		return
	end

	local AttackTimer = getTimer(npc, "Attack")

	AttackTimer.WaitTime = rng:NextNumber(2, 5)
	AttackTimer.Function = attackPlayer
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local function hide(npc)
	task.delay(0.5, function()
		npc.Instance.Parent = game
		vfx:FireAllClients("GhoulTeleport", "Server", true, npc.Instance:GetPivot().Position)
	end)
end

local function die(npc)
	npc.Instance.PrimaryPart.Anchored = false
end

local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LookAtTarget", Parameters = { true } },
		{ Function = "Custom", Parameters = { runAttackTimer } },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "Custom", Parameters = { hide } },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 1 } },
		{ Function = "Custom", Parameters = { die } },
	},
}

return module
