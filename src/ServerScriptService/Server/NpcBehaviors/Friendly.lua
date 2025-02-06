local players = game:GetService("Players")

local stats = {
	ViewDistance = 150,
	AttackDelay = NumberRange.new(1, 5),
	MoveDelay = NumberRange.new(8, 15),
	AttackCooldown = 0.15,
	ProjectileSpeed = 180,
	AttackAmount = 1,
	NpcType = "Commrad",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { "Enemy", stats.ViewDistance } },
		{ Function = "LookAtTarget", Parameters = { true } },
		{
			Function = "ShootPlayerProjectile",
			Parameters = { stats.AttackDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed },
		},

		{ Function = "GetToDistance", Parameters = { 20, true } },
		{ Function = "PlayWalkingAnimation" },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget", Parameters = { "Attacking" } },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	OnSpawned = {
		{ Function = "SetLeader", Parameters = { players:GetPlayers()[1] } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Commrad" } },
		{ Function = "SetCollision", Parameters = { "Player" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 5 } },
	},
}

return module
