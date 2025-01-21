local stats = {
	ViewDistance = 200,
	AttackDelay = { Min = 3, Max = 8 },
	MoveDelay = { Min = 4, Max = 10 },
	AttackCharge = 0.6,
	LeadCompensation = 750,
	AttackDistance = 30,

	MeleeDistance = 15,
	MeleeDelay = { Min = 0.75, Max = 1 },

	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 100, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { true, stats.LeadCompensation, 0, true } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },

		{
			Function = "ShootCharge",
			Parameters = { stats.AttackDelay, 2, stats.AttackCharge, 250 },
		},

		{ Function = "PlayWalkingAnimation" },
	},

	AtDistance = {
		{
			Function = "AttackInMelee",
			Parameters = { stats.MeleeDistance, stats.MeleeDelay, true },
		},

		Parameters = { stats.MeleeDistance },
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
