local stats = {
	ViewDistance = 200,
	AttackDelay = { Min = 6, Max = 12 },
	MoveDelay = { Min = 2, Max = 7 },
	AttackCooldown = 0.1,
	ProjectileSpeed = 250,
	AttackAmount = { Min = 20, Max = 30 },
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { true, 300, 1 } },
		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				stats.AttackAmount,
				stats.ProjectileSpeed,
				1,
				{ SplashRange = 6, SplashDamage = 1 },
				false,
				false,
				0.5,
			},
		},

		{ Function = "GetToDistance", Parameters = { 50, true } },
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
