local stats = {
	ViewDistance = 165,
	AttackDelay = NumberRange.new(2, 4),
	MoveDelay = NumberRange.new(5, 10),
	AttackCooldown = 0.25,
	ProjectileSpeed = 100,
	dodgeDistance = 10,
	AttackAmount = NumberRange.new(3, 5),
	NpcType = "Enemy",
}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)
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
	local chance = (currentHealth / npc.Instance.Humanoid.MaxHealth) * 100
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

local function startHealing(npc)
	local healingSound: Sound = npc.Instance.PrimaryPart.Healing

	if npc.MindData.OnHealCooldown then
		return
	end

	local target = npc:GetTarget()
	if not target then
		healingSound:Pause()
		return
	end

	local nearestEnemy =
		util.getNearestEnemy(target:GetPivot().Position, 60, CollectionService:GetTagged("Enemy"), { "Apostle" })

	if not nearestEnemy then
		healingSound:Pause()
		return
	end

	healingSound:Resume()

	npc.MindData.OnHealCooldown = true

	nearestEnemy.Humanoid.Health += 1
	npc.Instance.HealBeam.Attachment1 = nearestEnemy.PrimaryPart.RootAttachment

	net:RemoteEvent("ReplicateEffect"):FireAllClients("HealingEffect", "Server", true, nearestEnemy)

	task.delay(0.25, function()
		npc.MindData.OnHealCooldown = false
	end)
end

local function setup(npc)
	local healingSound: Sound = npc.Instance.PrimaryPart.Healing

	healingSound.Resumed:Connect(function()
		local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
		util.tween(healingSound, ti, { Volume = 0.5 })

		npc.Instance.PrimaryPart.Activate:Play()
	end)

	healingSound.Paused:Connect(function()
		healingSound.Volume = 0
		npc.Instance.PrimaryPart.Deactivate:Play()
	end)
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "LeadTarget", Parameters = { 105 } },

		{ Function = "Custom", Parameters = { startHealing }, State = "Attacking" },
		{ Function = "PlayWalkingAnimation" },
		{ Function = "MoveAwayFromDistance", Parameters = { 25, true } },
	},

	OnDamaged = {
		{ Function = "Custom", Parameters = { dodge } },
	},

	AtDistance = {

		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				stats.AttackAmount,
				stats.ProjectileSpeed,
				1,
				{ Size = 1 },
				"EnemyElectricProjectile",
				false,
				0.5,
			},
		},

		Parameters = { 40 },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
		--{ Function = "Custom", Parameters = { destroyShield } },
	},

	OnSpawned = {
		{ Function = "Custom", Parameters = { setup } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		--{ Function = "Custom", Parameters = { destroyShield } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
