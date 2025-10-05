local stats = {
	ViewDistance = 100,

	AttackDistance = 5,
	AttackDelay = 1,

	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveToRandomUnit", State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "AimAtTarget" },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance - 2, true } },
		{ Function = "PlayWalkingAnimation" },
		{ Function = "PlaySound", Parameters = { "Idle", 0.1 } },
	},

	TargetFound = {
		{ Function = "PlaySound", Parameters = { "Notice", 1 } },
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
		{ Function = "AssignGender" },
		{ Function = "AssignVoice" },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDamaged = {
		{ Function = "PlaySound", Parameters = { "Hurt" } },
	},

	OnDied = {
		{ Function = "PlaySound", Parameters = { "Death", 50 } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
