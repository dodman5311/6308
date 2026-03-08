local stats = {
	ViewDistance = 150,
	AttackDelay = NumberRange.new(3, 7),
	MoveDelay = NumberRange.new(4, 10),
	AttackCharge = 0.5,
	LeadCompensation = 500,
	AttackDistance = 50,

	MeleeDistance = 15,
	MeleeDelay = NumberRange.new(0.75, 1),

	NpcType = "Enemy",
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local effects = ReplicatedStorage.Assets.Effects

local Globals = require(ReplicatedStorage.Shared.Globals)
local Timer = require(ReplicatedStorage.Vendor.Timer)
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

local function shoot(npc)
	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
		return
	end

	local headAttachment = npc.Instance.Head.FaceCenterAttachment

	local target = npc:GetTarget()
	local characterPos = target:GetPivot().Position
	local startCF = CFrame.lookAt(headAttachment.WorldPosition, characterPos)

	npc.Instance.Humanoid.WalkSpeed = 0

	vfx:FireAllClients("SentinelAttack", "Server", true, startCF, npc.Instance.Humanoid)

	Timer.wait(1)
	task.delay(1, function()
		if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
			return
		end
		npc.Instance.Humanoid.WalkSpeed = 16
	end)
	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
		return
	end

	npc.Instance.PrimaryPart.ChargedAttack:Play()

	characterPos = target:GetPivot().Position
	local characterPos2D = Vector3.new(characterPos.X, startCF.Position.Y, characterPos.Z)

	local distance = (characterPos - startCF.Position).Magnitude

	local lookAtTarget = CFrame.lookAt(startCF.Position, characterPos2D)
	local characterYDiff = math.abs(characterPos.Y - (startCF * CFrame.new(0, 0, -distance)).Position.Y)
	local charYAngle = startCF.LookVector:Dot(lookAtTarget.LookVector)

	if charYAngle > 0.9 and characterYDiff < 4 and distance < stats.ViewDistance then
		target.Humanoid:TakeDamage(2)
	end
end

local function attackPlayer(npc)
	local target = npc:GetTarget()
	if not target then
		return
	end

	shoot(npc) --, distance + 2)
end

local function runAttackTimer(npc)
	if not npc:GetTarget() then
		return
	end

	local AttackTimer = getTimer(npc, "Attack")

	AttackTimer.WaitTime = rng:NextNumber(stats.AttackDelay.Min, stats.AttackDelay.Max)
	AttackTimer.Function = attackPlayer
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 100, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },

		{ Function = "Custom", Parameters = { runAttackTimer } },

		{ Function = "PlayWalkingAnimation" },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
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
	},
}

return module
