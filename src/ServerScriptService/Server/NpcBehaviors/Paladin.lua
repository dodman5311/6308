local stats = {
	ViewDistance = 200,
	ReactionDelay = 0.1,
	AttackDelay = 3,
	MoveDelay = { Min = 4, Max = 10 },
	AttackCooldown = 0.15,
	ProjectileSpeed = 200,
	AttackAmount = { Min = 5, Max = 6 },
	AttackDistance = 60,

	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 100, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { true, stats.ProjectileSpeed, 1 } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },
		{ Function = "MoveAwayFromDistance", Parameters = { 25, true } },

		{ Function = "PlayWalkingAnimation" },
	},

	InCloseRange = {

		{
			Function = "ShootProjectile",
			Parameters = { stats.AttackDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed, 5 },
		},

		Parameters = { stats.AttackDistance },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },

		{
			Function = "ShootProjectile",
			Parameters = { stats.ReactionDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed, 5 },
			IgnoreEventParams = true,
		},
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
