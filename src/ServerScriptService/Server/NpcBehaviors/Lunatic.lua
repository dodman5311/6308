local stats = {
	ViewDistance = 100,

	AttackDistance = 5,
	AttackDelay = 0.4,

	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveToRandomUnit", State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget", Parameters = { true } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance - 2, true } },
		{ Function = "PlayWalkingAnimation" },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	AtDistance = {
		{
			Function = "AttackInMelee",
			Parameters = { stats.AttackDistance, stats.AttackDelay, true },
		},

		Parameters = { stats.AttackDistance },
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
