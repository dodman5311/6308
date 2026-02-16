local stats = {
	ViewDistance = 100,

	AttackDistance = 4,
	AttackDelay = 0.4,

	NpcType = "Enemy",
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local effects = ReplicatedStorage.Assets.Effects

local Globals = require(ReplicatedStorage.Shared.Globals)
local animationService = require(Globals.Vendor.AnimationService)
local net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)

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
	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
		return
	end

	npc.Instance.Parent = workspace
	vfx:FireAllClients("GhoulTeleport", "Server", true, npc.Instance:GetPivot().Position)

	npc.Instance.PrimaryPart.Anchored = true
	animationService:playAnimation(npc.Instance, "Attack", Enum.AnimationPriority.Action3).Stopped:Once(function()
		if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
			return
		end
		npc.Instance.PrimaryPart.Anchored = false
	end)

	util.PlaySound(npc.Instance.PrimaryPart.Attack, npc.Instance.PrimaryPart, 0.1)

	task.wait(0.3)

	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
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

		model.Humanoid:TakeDamage(5)
	end

	npc.Instance.PrimaryPart.Swing:Play()
end

local function attackPlayer(npc)
	local target = npc:GetTarget()
	if not target then
		return
	end

	npc.Instance.Parent = game
	vfx:FireAllClients("GhoulTeleport", "Server", true, npc.Instance:GetPivot().Position)

	task.wait(1)

	local npcModel = npc.Instance
	npcModel.Parent = workspace

	local targetPosition = target:GetPivot()
	local distance = stats.AttackDistance
	local pos = targetPosition
		* CFrame.new(
			rng:NextInteger(-3, 3),
			rng:NextInteger(-1, 2),
			rng:NextInteger(-distance * 2, -distance) --rng:NextInteger(-distance, distance)
		)

	npcModel:PivotTo(CFrame.lookAt(pos.Position, targetPosition.Position))

	swing(npc, distance + 2)
end

local function runAttackTimer(npc)
	if not npc:GetTarget() then
		return
	end

	local AttackTimer = getTimer(npc, "Attack")

	AttackTimer.WaitTime = rng:NextNumber(3, 5)
	AttackTimer.Function = attackPlayer
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local function die(npc)
	npc.Instance.PrimaryPart.Anchored = false
end

local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget", Parameters = { true } },
		{ Function = "Custom", Parameters = { runAttackTimer } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance - 4, true } },
		{ Function = "PlayWalkingAnimation" },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
		--{ Function = "Custom", Parameters = { hide } },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
		{ Function = "Custom", Parameters = { die } },
	},
}

return module
