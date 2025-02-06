local stats = {
	ViewDistance = 200,
	AttackDelay = NumberRange.new(1.5, 5),
	MoveDelay = NumberRange.new(2, 5),
	AttackCooldown = 0.1,
	ProjectileSpeed = 400,
	AttackAmount = 3,
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { true, 400, 0 } },
		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				stats.AttackAmount,
				stats.ProjectileSpeed,
				1,
				{},
				false,
				false,
				0.5,
			},
		},

		{ Function = "MoveRandom", Parameters = { 20, stats.MoveDelay } },
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
