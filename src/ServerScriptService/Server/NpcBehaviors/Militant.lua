local stats = {
	ViewDistance = 150,
	AttackDelay = { Min = 1, Max = 6 },
	MoveDelay = { Min = 5, Max = 10 },
	AttackCooldown = 0.15,
	ProjectileSpeed = 200,
	AttackAmount = { Min = 1, Max = 4 },
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { true, 200, 5 } },
		{
			Function = "ShootProjectile",
			Parameters = { stats.AttackDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed },
			true,
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
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
