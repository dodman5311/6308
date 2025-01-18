local stats = {
	ViewDistance = 200,
	ReactionDelay = 0,
	AttackDelay = 0,
	MoveDelay = { Min = 4, Max = 10 },
	AttackCooldown = 0.2,
	ProjectileSpeed = 200,
	AttackAmount = { Min = 4, Max = 5 },
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
			Function = "ShootWithoutTimer",
			Parameters = { stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed, 5 },
			ReturnFunction = function(npc, result)
				if not result then
					return
				end

				local reloadSound: Sound = npc.Instance.PrimaryPart.Reloading
				reloadSound:Play()
				reloadSound.Ended:Wait()
				npc.MindData.CantShoot = false
			end,
		},

		Parameters = { stats.AttackDistance },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },

		-- {
		-- 	Function = "ShootProjectile",
		-- 	Parameters = { stats.ReactionDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed, 5 },
		-- 	IgnoreEventParams = true,
		-- },
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
