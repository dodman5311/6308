local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Packages.Net)

local stats = {
	ViewDistance = 100,

	AttackDistance = 5,
	AttackDelay = 0.4,

	NpcType = "Enemy",
}

local function awardBadge()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			if BadgeService:AwardBadge(player.UserId, 510580664798171) then
				Net:RemoteEvent("DoUiAction"):FireAllClients("Notify", "AchievementUnlocked", 510580664798171)
			end
		end)
	end
end

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
		{ Function = "PlaySound", Parameters = { "Notice", 10 } },
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
	},

	TargetLost = {
		{ Function = "PlaySound", Parameters = { "LostTarget", 5 } },
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

	OnDied = {
		{ Function = "Custom", Parameters = { awardBadge } },
		{ Function = "PlaySound", Parameters = { "Death", 50 } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "DropSoul", Parameters = { 3 } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
