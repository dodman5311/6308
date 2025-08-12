local stats = {
	AttackDistance = 30,
	ViewDistance = 150,
	NpcType = "Enemy",
	MoveDelay = NumberRange.new(2, 5),
	AttackDelay = NumberRange.new(6, 10),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local animationService = require(Globals.Vendor.AnimationService)
local net = require(Globals.Packages.Net)
local timer = require(Globals.Vendor.Timer)

local function getRandomTime()
	return Random.new():NextNumber(stats.AttackDelay.Min, stats.AttackDelay.Max)
end

local function indicateAttack(npc, color)
	net:RemoteEvent("ReplicateEffect"):FireAllClients("IndicateAttack", "Server", true, npc.Instance, color)
	timer.wait(0.5)
end

local function Unaim(npc)
	if not npc.MindData.Aiming then
		return
	end
	npc.Instance.AimGui.Enabled = false

	local model = npc.Instance
	animationService:stopAnimation(model, "Attack")
	local unaimAnim = animationService:playAnimation(model, "Unaim", Enum.AnimationPriority.Action4)
	animationService:stopAnimation(model, "AimIdle")

	unaimAnim.Stopped:Once(function()
		model.Humanoid.WalkSpeed = 25
		npc.MindData.Aiming = false
		model.PrimaryPart.ChargedLaser.Enabled = false
	end)
end

local function aim(npc)
	local model = npc.Instance

	if npc.MindData.Aiming then
		local target = npc:GetTarget()
		if not target then
			return
		end

		model.PrimaryPart.ChargedAttachment.WorldCFrame = target:GetPivot()

		return
	end

	npc.MindData.Aiming = true
	npc.Instance.AimGui.Enabled = true

	model.Humanoid.WalkSpeed = 0

	local a = animationService:playAnimation(model, "Aim", Enum.AnimationPriority.Action3)
	animationService:playAnimation(model, "AimIdle", Enum.AnimationPriority.Action)

	a.Stopped:Once(function()
		model.PrimaryPart.ChargedLaser.Enabled = true
	end)
end

local function checkRaycast(subject: Model, target: Model)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { subject, target }

	local origin = subject:GetPivot().Position
	local destination = target:GetPivot().Position - origin

	local newRay = workspace:Raycast(origin, destination, rp)

	return not newRay
end

local function shoot(npc)
	if not npc.MindData.Aiming then
		return
	end

	local timer = npc.Timers["Attack"]
	timer.WaitTime = getRandomTime()

	npc.Instance.PrimaryPart.ChargedAttack:Play()

	local target = npc:GetTarget()
	if not target then
		return
	end

	indicateAttack(npc, Color3.fromRGB(255, 135, 135))

	if checkRaycast(npc.Instance, target) then
		target.Humanoid:TakeDamage(1)
	end
end

local function resetTarget(npc)
	npc["Target"].Value = nil
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },
		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },

		{ Function = "LookAtTarget", Parameters = { false }, State = "Attacking" },
		{ Function = "RunTimer", Parameters = { "Attack", getRandomTime(), shoot, true } },

		{ Function = "PlayWalkingAnimation" },
	},

	AtDistance = {
		{ Function = "MoveAwayFromDistance", Parameters = { 30, true } },
		Parameters = { 20 },
	},

	DistanceReached = {
		{ Function = "Custom", Parameters = { Unaim } },
		{ Function = "SwitchToState", Parameters = { "Idle" } },
	},

	DistanceLeft = {
		{ Function = "Custom", Parameters = { resetTarget } },
	},

	TargetFound = {
		{ Function = "Custom", Parameters = { aim } },
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		{ Function = "Custom", Parameters = { Unaim } },
		{ Function = "MoveTowardsTarget" },
	},

	OnSpawned = {
		{ Function = "AssignGender" },
		{ Function = "AssignVoice" },
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
