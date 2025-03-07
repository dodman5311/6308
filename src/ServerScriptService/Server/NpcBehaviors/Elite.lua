local CollectionService = game:GetService("CollectionService")
local stats = {
	ViewDistance = 85,
	AttackDelay = NumberRange.new(1, 5),
	MoveDelay = NumberRange.new(5, 10),
	AttackCooldown = 0.075,
	ProjectileSpeed = 400,
	AttackAmount = NumberRange.new(6, 8),
	ShieldingChance = 50,
	NpcType = "Enemy",
}

local rng = Random.new()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)
local AnimationService = require(Globals.Vendor.AnimationService)

local function searchForHarbinger(npc)
	if not npc.Instance:GetAttribute("CanShield") then
		return
	end
	local selectedHarbinger

	for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
		if enemy.Name ~= "Harbinger" or enemy == npc.Instance then
			continue
		end

		local distance = (npc.Instance:GetPivot().Position - enemy:GetPivot().Position).Magnitude

		if distance > 60 then
			continue
		end

		if enemy:GetAttribute("Protected") then
			continue
		end

		selectedHarbinger = enemy
	end

	if not selectedHarbinger then
		return
	end

	npc.Instance:SetAttribute("State", "Shielding")
	selectedHarbinger:SetAttribute("Protected", true)
	npc.MindData.HarbingerToProtect = selectedHarbinger
end

local function checkHarbingerStatus(npc)
	return npc.Instance:GetAttribute("CanShield")
		and npc.MindData.HarbingerToProtect
		and npc.MindData.HarbingerToProtect.Parent
		and npc.MindData.HarbingerToProtect.Humanoid.Health > 0
end

local function closeShield(npc)
	if not npc.Instance.Shield.ShieldPart.CanQuery then
		return
	end
	AnimationService:stopAnimation(npc.Instance, "Shield", 0)

	npc.Instance.Shield.ShieldPart.CanQuery = false
	net:RemoteEvent("ReplicateEffect"):FireAllClients("CloseShieldEffect", "Server", true, npc.Instance.Shield)
	npc.Instance.Shield.ShieldPart.Transparency = 1
end

local function loseHarbinger(npc)
	if not npc.MindData.HarbingerToProtect then
		return
	end

	if npc.MindData.HarbingerToProtect.Parent then
		npc.MindData.HarbingerToProtect:SetAttribute("Protected", false)
	end

	npc.Instance:SetAttribute("State", "Idle")
	npc.MindData.HarbingerToProtect = nil
	closeShield(npc)
end

local function openShield(npc)
	if npc.Instance.Shield.ShieldPart.CanQuery then
		return
	end
	AnimationService:playAnimation(npc.Instance, "Shield", Enum.AnimationPriority.Action2, false, 0)

	npc.Instance.Shield.ShieldPart.CanQuery = true

	npc.Instance.Shield.ShieldPart.Transparency = 0
	net:RemoteEvent("ReplicateEffect"):FireAllClients("OpenShieldEffect", "Server", true, npc.Instance.Shield)
end

local function checkDistance(npc)
	if not npc.MindData.HarbingerToProtect then
		return
	end

	local distance = (npc.Instance:GetPivot().Position - npc.MindData.HarbingerToProtect:GetPivot().Position).Magnitude

	if distance > 12 then
		return
	end

	openShield(npc)
end

local function setup(npc)
	local model = npc.Instance
	if rng:NextNumber(0, 100) > stats.ShieldingChance then
		model:SetAttribute("CanShield", false)
		model.Gauntlet:Destroy()
		model.Shield:Destroy()
	end
end

local module = {
	OnStep = {

		{ Function = "MoveRandom", Parameters = { 60, stats.MoveDelay }, NotState = "Shielding" },
		{ Function = "MoveInfrontOfHarbinger", State = "Shielding" },
		{ Function = "Custom", Parameters = { checkDistance }, State = "Shielding" },
		{
			Function = "Custom",
			Parameters = { checkHarbingerStatus },
			State = "Shielding",
			ReturnFunction = function(npc, result)
				if not result then
					loseHarbinger(npc)
				end
			end,
		},

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },

		{ Function = "LeadTarget", Parameters = { 800 }, NotState = "Shielding" },
		{ Function = "LookAtTarget", NotState = "Shielding" },
		{ Function = "LookAtTarget", Parameters = { true }, State = "Shielding" },

		{
			Function = "ShootProjectile",
			Parameters = { stats.AttackDelay, stats.AttackCooldown, stats.AttackAmount, stats.ProjectileSpeed },
			NotState = "Shielding",
		},

		{ Function = "GetToDistance", Parameters = { 30, true }, NotState = "Shielding" },
		{ Function = "PlayWalkingAnimation" },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" }, NotState = "Shielding" },
		{ Function = "MoveTowardsTarget", NotState = "Shielding" },
		{ Function = "Custom", Parameters = { searchForHarbinger } },
	},

	TargetLost = {
		{ Function = "Custom", Parameters = { loseHarbinger } },
		{ Function = "SwitchToState", Parameters = { "Chasing" }, NotState = "Shielding" },
		{ Function = "MoveTowardsTarget" },
		NotState = "Shielding",
	},

	OnSpawned = {
		{ Function = "Custom", Parameters = { setup } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { loseHarbinger } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
