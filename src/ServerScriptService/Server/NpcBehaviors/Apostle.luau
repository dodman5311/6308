local stats = {
	ViewDistance = 150,
	AttackDelay = NumberRange.new(1, 6),
	MoveDelay = NumberRange.new(5, 10),
	AttackCooldown = 0.15,
	ProjectileSpeed = 200,
	dodgeDistance = 10,
	AttackAmount = NumberRange.new(1, 4),
	NpcType = "Enemy",
}

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Globals = require(ReplicatedStorage.Shared.Globals)

local assets = ReplicatedStorage.Assets
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

local function destroyShield(npc)
	local shield = npc.MindData.shield

	if shield then
		net:RemoteEvent("ReplicateEffect"):FireAllClients("CloseShieldEffect", "Server", true, shield)
		Debris:AddItem(shield, 1)
	end
	npc.MindData.shield = nil
end

local function createShield(npc, position)
	if npc.MindData.shield then
		return
	end

	npc.MindData.shield = assets.Models.ApostleShield:Clone()

	local newShield = npc.MindData.shield

	npc.Janitor:Add(newShield, "Destroy")
	newShield.Parent = workspace
	newShield:PivotTo(CFrame.new(position))

	newShield:AddTag("ApostleShield")

	npc.Instance.ShieldBeam.Attachment1 = newShield.Root.Connection

	return newShield
end

local function castShield(npc)
	if npc.MindData.ShieldOnCooldown then
		return
	end

	local target = npc:GetTarget()
	if not target then
		destroyShield(npc)
		return
	end

	local nearestEnemy, _, enemyPosition =
		util.getNearestEnemy(target:GetPivot().Position, 60, CollectionService:GetTagged("Enemy"), { npc.Instance })

	if not nearestEnemy then
		destroyShield(npc)
		return
	end

	local shield = npc.MindData.shield
	if not shield then
		shield = createShield(npc, enemyPosition)
	end

	local alignPos: AlignPosition = shield.AlignPosition
	local alignOr: AlignOrientation = shield.AlignOrientation

	alignPos.Position = enemyPosition
	alignOr.CFrame = CFrame.lookAt(enemyPosition, target:GetPivot().Position)

	task.delay(5, function()
		destroyShield(npc)
		npc.MindData.ShieldOnCooldown = true
		task.wait(4)
		npc.MindData.ShieldOnCooldown = false
	end)
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LeadTarget", Parameters = { false, 200, 0 } },

		{ Function = "Custom", Parameters = { castShield }, State = "Attacking" },
		{ Function = "PlayWalkingAnimation" },
	},

	OnDamaged = {
		{ Function = "Custom", Parameters = { dodge } },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
		{ Function = "Custom", Parameters = { destroyShield } },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { destroyShield } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
