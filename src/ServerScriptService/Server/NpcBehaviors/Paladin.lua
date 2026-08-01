local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationService = require(ReplicatedStorage.Vendor.AnimationService)
local Timer = require(ReplicatedStorage.Vendor.Timer)
local Util = require(ReplicatedStorage.Vendor.Util)
local stats = {
	ViewDistance = 200,
	ReactionDelay = 0,
	AttackDelay = NumberRange.new(1.25, 1.75),
	MoveDelay = NumberRange.new(2, 8),
	AttackCooldown = 4,
	ProjectileSpeed = 200,
	AttackAmount = 1,
	AttackDistance = 75,
	PelletCount = 6,
	PunchDistance = 18,

	NpcType = "Enemy",
}

local function createImpulse(subject: Model, power: number, direction: Vector3, velocityTime: number)
	local primaryPart = subject.PrimaryPart
	if not primaryPart then
		return
	end

	local newVelocity = Instance.new("LinearVelocity")
	Debris:AddItem(newVelocity, velocityTime)

	newVelocity.Parent = subject
	newVelocity.Attachment0 = primaryPart:FindFirstChildOfClass("Attachment")
	newVelocity.MaxForce = math.huge
	newVelocity.VectorVelocity = direction * power

	return newVelocity
end

local function Punch(npc)
	local target = npc:GetTarget()

	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
		return
	end

	if not target or npc.MindData.PunchCooldown then
		return
	end

	local instance = npc.Instance

	local targetPosition = target:GetPivot().Position
	local npcPosition = instance:GetPivot().Position
	local distance = (targetPosition - npcPosition).Magnitude

	if distance > stats.PunchDistance then
		return
	end

	npc.MindData.PunchCooldown = true
	instance.Humanoid.WalkSpeed = 0

	AnimationService:playAnimation(npc.Instance, "Punch", Enum.AnimationPriority.Action4)
	Timer.delay(0.8, function()
		npc.MindData.PunchCooldown = false
	end)

	Timer.wait(0.2)

	if npc:GetState() == "Dead" or npc.StatusEffects["Ice"] or npc.StatusEffects["Stun"] then
		return
	end

	instance.PrimaryPart.Punch:Play()

	local sound = Util.getRandomChild(instance.Voice.Punch)
	if sound then
		Util.PlaySound(sound, instance.PrimaryPart, 0.025)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { npc }
	raycastParams.CollisionGroup = "Npcs"

	local playersHit = {}
	for _, part in
		ipairs(
			workspace:GetPartBoundsInBox(
				npc.MindData.AimCFrame * CFrame.new(0, 0, -stats.PunchDistance),
				Vector3.new(10, 10, stats.PunchDistance)
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

		model.Humanoid:TakeDamage(1)
		local impulseDirection = (instance:GetPivot() * CFrame.Angles(math.rad(25), 0, 0)).LookVector
		createImpulse(target, 50, impulseDirection, 0.1)
	end

	instance.Humanoid.WalkSpeed = 26
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 100, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "LeadTarget", Parameters = { stats.ProjectileSpeed - 25 } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },
		{ Function = "MoveAwayFromDistance", Parameters = { 25, true } },

		{ Function = "PlayWalkingAnimation" },
		{ Function = "PlayIdleSound" },
		{ Function = "Custom", Parameters = { Punch } },
	},

	AtDistance = {

		-- 	{
		-- 		Function = "ShootWithoutTimer",
		-- 		Parameters = { stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed, 6 },
		-- 		ReturnFunction = function(npc, result)
		-- 			if not result then
		-- 				return
		-- 			end

		-- 			local reloadSound: Sound = npc.Instance.PrimaryPart.Reloading
		-- 			reloadSound:Play()
		-- 			reloadSound.Ended:Wait()
		-- 			npc.MindData.CantShoot = false
		-- 		end,
		-- 	},

		-- 	Parameters = { stats.AttackDistance },

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				stats.AttackAmount,
				stats.ProjectileSpeed,
				stats.PelletCount,
				{},
				"Projectile",
				false,
				0.5,
			},
			State = "Attacking",
		},

		Parameters = { stats.AttackDistance },
	},

	TargetFound = {
		{ Function = "PlaySound", Parameters = { "Notice", 15 } },
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
	},

	TargetLost = {
		{ Function = "PlaySound", Parameters = { "LostTarget", 5 } },
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	OnSpawned = {
		{ Function = "AssignGender" },
		{ Function = "AssignVoice" },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDamaged = {
		{ Function = "PlaySound", Parameters = { "Hurt", 50 } },
	},

	OnDied = {
		{ Function = "PlaySound", Parameters = { "Death", 100 } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
