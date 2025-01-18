local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)

local stats = {
	ViewDistance = 200,
	AttackDelay = { Min = 2, Max = 10 },
	AltAttackDelay = { Min = 7, Max = 13 },
	MoveDelay = { Min = 2, Max = 7 },
	AttackCooldown = 0.125,
	ProjectileSpeed = 300,
	AltProjectileSpeed = 75,
	AttackAmount = 3,
	MoveSpeed = 8,
	NpcType = "Enemy",
}

local function flyTowardsTarget(npc)
	local PrimaryPart = npc.Instance.PrimaryPart
	if not PrimaryPart then
		return
	end

	local moveForce: LinearVelocity = PrimaryPart.MoveForce
	moveForce.VectorVelocity = Vector3.new(0, 0, -stats.MoveSpeed)
end

local function stopMotion(npc)
	local PrimaryPart = npc.Instance.PrimaryPart
	if not PrimaryPart then
		return
	end

	local moveForce: LinearVelocity = PrimaryPart.MoveForce
	moveForce.VectorVelocity = Vector3.zero
end

local function explode(npc)
	local model = npc.Instance

	local PrimaryPart = model.PrimaryPart
	if not PrimaryPart then
		return
	end

	model.Body.Transparency = 1
	model.Body.CanCollide = false
	model.Body.CanQuery = false

	PrimaryPart.BackBeam1.Enabled = false
	PrimaryPart.BackBeam.Enabled = false
	PrimaryPart.FrontBeam1.Enabled = false
	PrimaryPart.FrontBeam.Enabled = false

	local explosionPosition = model:GetPivot().Position

	net:RemoteEvent("CreateExplosion"):FireAllClients(explosionPosition, 15, 2)
end

local function setPlatform(npc)
	task.wait(1)
	local humanoid = npc.Instance:WaitForChild("Humanoid")
	humanoid.PlatformStand = true
end

local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { true, 300, 0 } },

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				stats.AttackAmount,
				stats.ProjectileSpeed,
				1,
				{ SplashRange = 8, SplashDamage = 1 },
				"RocketProjectile",
			},
		},

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AltAttackDelay,
				stats.AttackCooldown,
				1,
				stats.AltProjectileSpeed,
				1,
				{ SplashRange = 6, SplashDamage = 1, Seeking = 0.12, Size = 1.5, SeekProgression = -0.001 },
				"SmartRocketProjectile",
				"SpecialAttack",
			},
		},
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "Custom", Parameters = { flyTowardsTarget } },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		{ Function = "Custom", Parameters = { stopMotion } },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
		{ Function = "Custom", Parameters = { setPlatform } },
		{ Function = "SetCollision", Parameters = { "Dreadful" } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { explode } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 1 } },
	},
}

return module
