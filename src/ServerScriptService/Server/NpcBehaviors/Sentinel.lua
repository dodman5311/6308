local stats = {
	ViewDistance = 200,
	AttackDelay = NumberRange.new(2, 5),
	MoveDelay = NumberRange.new(4, 10),
	AttackCharge = 0.5,
	LeadCompensation = 500,
	AttackDistance = 50,

	MeleeDistance = 15,
	MeleeDelay = NumberRange.new(0.75, 1),

	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 100, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "AimAtTarget" },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },

		{
			Function = "ShootCharge",
			Parameters = { stats.AttackDelay, 2, stats.AttackCharge, 250 },
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
