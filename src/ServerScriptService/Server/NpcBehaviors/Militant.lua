local stats = {
	ViewDistance = 150,
	AttackDelay = NumberRange.new(1, 6),
	MoveDelay = NumberRange.new(5, 10),
	AttackCooldown = 0.15,
	ProjectileSpeed = 200,
	AttackAmount = NumberRange.new(1, 4),
	NpcType = "Enemy",
}

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "LeadTarget", Parameters = { 200, 1 } },
		{
			Function = "ShootProjectile",
			Parameters = { stats.AttackDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed },
			true,
		},

		-- {
		-- 	Function = "ShootProjectile",
		-- 	Parameters = {
		-- 		math.random(8, 15),
		-- 		1,
		-- 		1,
		-- 		75,
		-- 		1,
		-- 		{
		-- 			Dropping = 0.35,
		-- 			Bouncing = true,
		-- 			SplashRange = 30,
		-- 			SplashDamage = 2,
		-- 			Slowing = 0.65,
		-- 		},
		-- 		"EnemyGrenadeProjectile",
		-- 		"ThrowGrenade",
		-- 		1,
		-- 	},
		--},

		{ Function = "GetToDistance", Parameters = { 30, true } },
		{ Function = "PlayWalkingAnimation" },
		{ Function = "PlayIdleSound" },
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
		{ Function = "AssignGender" },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDamaged = {
		{ Function = "PlaySound", Parameters = { "Hurt" } },
	},

	OnDied = {
		{ Function = "PlaySound", Parameters = { "Death" } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
