local stats = {
	ViewDistance = 150,
	AltAttackDelay = NumberRange.new(1.5, 4),
	MoveDelay = NumberRange.new(3, 8),
	AttackCooldown = 0,
	AltProjectileSpeed = 300,
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "AimAtTarget" },

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AltAttackDelay,
				stats.AttackCooldown,
				1,
				stats.AltProjectileSpeed,
				3,
				{},
				false,
				"SpecialAttack",
				0.5,
			},
			State = "Attacking",
		},

		{ Function = "GetToDistance", Parameters = { 20, true } },
		{ Function = "PlayWalkingAnimation" },
		{ Function = "PlayIdleSound" },
	},

	TargetFound = {
		{ Function = "PlaySound", Parameters = { "Notice", 10 } },
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
	},

	TargetLost = {
		{ Function = "PlaySound", Parameters = { "LostTarget", 5 } },
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	OnDamaged = {
		{ Function = "PlaySound", Parameters = { "Hurt", 100 } },
	},

	OnSpawned = {
		{ Function = "AssignGender" },
		{ Function = "AssignVoice" },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
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
