local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local effects = ReplicatedStorage.Assets.Effects

local Globals = require(ReplicatedStorage.Shared.Globals)
local UIAnimator = require(Globals.Vendor.UIAnimationService)
local animationService = require(Globals.Vendor.AnimationService)
local util = require(Globals.Vendor.Util)

local stats = {
	ViewDistance = 200,
	AttackDelay = { Min = 3, Max = 8 },
	MoveDelay = { Min = 4, Max = 10 },
	AttackCharge = 0.6,
	LeadCompensation = 750,
	AttackDistance = 30,

	MeleeDistance = 15,
	MeleeDelay = { Min = 0.75, Max = 1 },

	NpcType = "Enemy",
}

local rng = Random.new()

local function getTimer(npc, timerName)
	local foundTimer = npc.Timers[timerName]

	if not foundTimer then
		npc.Timers[timerName] = npc.Timer:new(timerName)
		return npc.Timers[timerName]
	end

	return foundTimer
end

local function hitPlayer(character)
	character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, -200, 0)
	local humanoid = character:FindFirstChild("Humanoid")
	humanoid:TakeDamage(3)
end

local function createAttackAt(position, hasSound)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }
	local raycast = workspace:Raycast(position, CFrame.new().UpVector * -300, rp)
	if not raycast then
		return
	end

	local effect = effects.GravityAttack:Clone()
	effect.Parent = workspace
	effect:PivotTo(CFrame.new(raycast.Position) * CFrame.Angles(0, 0, math.rad(90)))

	if hasSound then
		local sound = effect.Notice.Activate
		sound:Play()
		local ti = TweenInfo.new(1)

		task.delay(0.5, function()
			util.tween(sound, ti, { Volume = 0 })
		end)
	end

	UIAnimator.PlayAnimation(effect.Notice.SurfaceGui.Frame, 0.03, false, true).OnEnded:Wait()
	task.wait(0.2)

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end

		local playerPosition = character:GetPivot().Position * Vector3.new(1, 0, 1)
		local distance = (playerPosition - (position * Vector3.new(1, 0, 1))).Magnitude

		if distance > effect.Area.Size.Z / 2 then
			continue
		end

		hitPlayer(character)
	end

	if hasSound then
		local soundPart = Instance.new("Part")
		soundPart.Parent = workspace
		soundPart.CanCollide = false
		soundPart.CanQuery = false
		soundPart.Transparency = 1
		soundPart.Anchored = true
		soundPart.Position = effect.Notice.Position

		Debris:AddItem(soundPart, 10)

		util.PlaySound(effect.Notice.AirBoom, soundPart)
		util.PlaySound(effect.Notice.Boom, soundPart)
	end

	task.wait(0.1)
	effect:Destroy()
end

local function attackPlayer(npc)
	local target = npc:GetTarget()
	if not target or npc.StatusEffects["Ice"] then
		return
	end

	--local humanoid = npc.Instance.Humanoid

	--humanoid.WalkSpeed = 0.01

	animationService:playAnimation(npc.Instance, "SlamAttack", Enum.AnimationPriority.Action3)

	local targetLocation = target:GetPivot().Position
	local targetVelocity = target.PrimaryPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	task.spawn(function()
		createAttackAt(targetLocation, true)

		--humanoid.WalkSpeed = 6
	end)

	if targetVelocity.Magnitude == 0 or npc.StatusEffects["Electricity"] then
		return
	end

	createAttackAt(targetLocation + (targetVelocity * 1.65))
end

local function runAttackTimer(npc)
	if not npc:GetTarget() then
		return
	end

	local AttackTimer = getTimer(npc, "Special")

	AttackTimer.WaitTime = rng:NextNumber(5, 8)
	AttackTimer.Function = attackPlayer
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 100, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },

		{ Function = "PlayWalkingAnimation" },
		{ Function = "Custom", Parameters = { runAttackTimer } },
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
		{ Function = "RemoveWithDelay", Parameters = { 1 } },
	},
}

return module
