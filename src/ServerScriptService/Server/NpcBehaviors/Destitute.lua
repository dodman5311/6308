local stats = {
	ViewDistance = 150,
	AttackDelay = NumberRange.new(1, 2),
	MoveDelay = NumberRange.new(0, 2),
	AttackCooldown = 0.05,
	ProjectileSpeed = 100,
	AttackAmount = NumberRange.new(3, 6),
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 120, stats.MoveDelay } },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "LeadTarget", Parameters = { 200 } },
		{
			Function = "ShootProjectile",
			Parameters = { stats.AttackDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed },
			true,
		},

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
