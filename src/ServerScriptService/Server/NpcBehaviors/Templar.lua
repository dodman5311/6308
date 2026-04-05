local stats = {
	ViewDistance = 200,
	ReactionDelay = 0,
	AttackDelay = 0,
	MoveDelay = NumberRange.new(2, 8),
	AttackCooldown = 0.2,
	ProjectileSpeed = 200,
	AttackAmount = 5,
	AttackDistance = 65,
	dodgeDistance = 10,

	NpcType = "Enemy",
}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)
local rng = Random.new()

local function checkDashDirection(npc, direction)
	local npcCFrame = npc.Instance:GetPivot()

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { workspace.Map }
	params.FilterType = Enum.RaycastFilterType.Include

	local rightRay =
		workspace:Raycast(npcCFrame.Position, npcCFrame.RightVector * ((stats.dodgeDistance + 1) * direction), params)
	if rightRay then
		return
	end

	local downOrigin = npcCFrame * CFrame.new(stats.dodgeDistance * direction, 0, 0)
	local downRay = workspace:Raycast(downOrigin.Position, downOrigin.UpVector * -(stats.dodgeDistance + 1), params)

	if not downRay then
		return
	end

	return downOrigin
end

local function dodge(npc, currentHealth)
	if npc.Instance:FindFirstChild("Shield") then
		return
	end

	local chance = 15
	if currentHealth == 0 or rng:NextNumber(0, 100) < chance then
		return
	end

	local direction = math.random(0, 1)
	if direction == 0 then
		direction = -1
	end

	local endCFrame = checkDashDirection(npc, direction)

	if not endCFrame then
		endCFrame = checkDashDirection(npc, -direction)
	end

	if not endCFrame then
		return
	end

	util.PlaySound(npc.Instance.PrimaryPart.Dash, npc.Instance.PrimaryPart, 0.1)

	local originalCFrame = npc.Instance:GetPivot()
	net:RemoteEvent("ReplicateEffect")
		:FireAllClients("DashEffect", "Server", true, npc.Instance, originalCFrame, endCFrame)

	for i = 0, 1, 0.25 do
		if not npc.Instance.Parent then
			return
		end

		npc.Instance:PivotTo(originalCFrame:Lerp(endCFrame, i))

		RunService.Heartbeat:Wait()
	end
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 100, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "LeadTarget", Parameters = { stats.ProjectileSpeed } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },
		{ Function = "MoveAwayFromDistance", Parameters = { 25, true } },

		{ Function = "PlayWalkingAnimation" },
		{ Function = "PlayIdleSound" },
	},

	AtDistance = {

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
		{ Function = "PlaySound", Parameters = { "Notice", 30 } },
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
	},

	TargetLost = {
		{ Function = "PlaySound", Parameters = { "LostTarget", 15 } },
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	OnSpawned = {
		{ Function = "AssignGender" },
		{ Function = "AssignVoice" },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDamaged = {
		{ Function = "Custom", Parameters = { dodge } },
		{ Function = "PlaySound", Parameters = { "Hurt", 10 } },
	},

	OnDied = {
		{ Function = "PlaySound", Parameters = { "Death", 100 } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
