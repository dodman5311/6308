local stats = {
	ViewDistance = 200,
	AttackDelay = { Min = 2, Max = 6 },
	AltAttackDelay = { Min = 6, Max = 8 },
	MoveDelay = { Min = 4, Max = 9 },
	AttackCooldown = 0,
	ProjectileSpeed = 400,
	AltProjectileSpeed = 300,
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { true, 400, 0 } },

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				1,
				stats.ProjectileSpeed,
				1,
			},
		},

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AltAttackDelay,
				stats.AttackCooldown,
				1,
				stats.AltProjectileSpeed,
				3,
				{},
				"Projectile",
				"SpecialAttack",
			},
		},

		{ Function = "GetToDistance", Parameters = { 30, true } },
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
		{ Function = "RemoveWithDelay", Parameters = { 1 } },
	},
}

return module
