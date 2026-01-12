local stats = {
	ViewDistance = 200,
	AttackDelay = NumberRange.new(1, 5),
	AltAttackDelay = NumberRange.new(5, 6),
	MoveDelay = NumberRange.new(4, 8),
	AttackCooldown = 0,
	ProjectileSpeed = 400,
	AltProjectileSpeed = 300,
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "LeadTarget", Parameters = { 400 } },

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				1,
				stats.ProjectileSpeed,
				1,
				{},
				"Projectile",
				false,
				0.5,
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
		{ Function = "PlayIdleSound" },
	},

	TargetFound = {
		{ Function = "PlaySound", Parameters = { "Notice", 10 } },
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
	},

	TargetLost = {
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
		{ Function = "PlaySound", Parameters = { "Death", 75 } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
