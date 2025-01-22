local stats = {
	AttackDistance = 30,
	ViewDistance = 400,
	NpcType = "Enemy",
	MoveDelay = { Min = 2, Max = 5 },
	AttackDelay = { Min = 5, Max = 10 },
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local animationService = require(Globals.Vendor.AnimationService)

local function getRandomTime()
	return Random.new():NextNumber(stats.AttackDelay.Min, stats.AttackDelay.Max)
end

local function Unaim(npc)
	if not npc.MindData.Aiming then
		return
	end

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

	model.Humanoid.WalkSpeed = 0

	local a = animationService:playAnimation(model, "Aim", Enum.AnimationPriority.Action3)
	animationService:playAnimation(model, "AimIdle", Enum.AnimationPriority.Action)

	a.Stopped:Once(function()
		model.PrimaryPart.ChargedLaser.Enabled = true
	end)
end

local function lookAtTarget(npc)
	local target = npc.Target.Value
	if not target then
		return
	end

	local subject = npc.Instance
	local position = target:GetPivot().Position
	local subjectPos = subject:GetPivot().Position

	subject:PivotTo(CFrame.lookAt(subjectPos, position))
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
		{ Function = "SearchForTarget", Parameters = { "Player", 500 } },

		{ Function = "Custom", Parameters = { lookAtTarget }, State = "Attacking" },
		{ Function = "RunTimer", Parameters = { "Attack", true, getRandomTime(), shoot } },

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
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
