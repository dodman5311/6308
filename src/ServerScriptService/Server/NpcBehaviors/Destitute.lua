local CollectionService = game:GetService("CollectionService")
local stats = {
	ViewDistance = 150,
	AttackDelay = NumberRange.new(1, 2),
	MoveDelay = NumberRange.new(0, 2),
	AttackCooldown = 0.05,
	ProjectileSpeed = 100,
	AttackAmount = NumberRange.new(3, 6),
	NpcType = "Enemy",
}

local function searchForAbomination(npc)
	-- if not npc.Instance:GetAttribute("CanShield") then
	-- 	return
	-- end
	local selectedAbomination

	for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
		if enemy.Name ~= "Abomination" or enemy == npc.Instance then
			continue
		end

		local distance = (npc.Instance:GetPivot().Position - enemy:GetPivot().Position).Magnitude

		if distance > 60 then
			continue
		end

		if enemy:GetAttribute("Mounted") then
			continue
		end

		selectedAbomination = enemy
	end

	if not selectedAbomination then
		return
	end

	npc.Instance:SetAttribute("State", "Riding")
	selectedAbomination:SetAttribute("Mounted", true)
	npc.MindData.AbominationToRide = selectedAbomination
end

local function checkAbominationStatus(npc)
	return npc.MindData.AbominationToRide
		and npc.MindData.AbominationToRide.Parent
		and npc.MindData.AbominationToRide.Humanoid.Health > 0
end

local function loseAbomination(npc)
	if not npc.MindData.AbominationToRide then
		return
	end

	if npc.MindData.AbominationToRide.Parent then
		npc.MindData.AbominationToRide:SetAttribute("Mounted", false)
	end

	npc.Instance:SetAttribute("State", "Idle")
	npc.MindData.AbominationToRide = nil
end

local function rideAbomination(npc)
	local newWeld = Instance.new("Weld")
	newWeld.Parent = npc.Instance
	newWeld.Part0 = npc.MindData.AbominationToRide.PrimaryPart.MountPoint
	newWeld.Part1 = npc.Instance.PrimaryPart
end

local function checkDistance(npc)
	if not npc.MindData.AbominationToRide then
		return
	end

	local distance = (npc.Instance:GetPivot().Position - npc.MindData.AbominationToRide:GetPivot().Position).Magnitude

	if distance > 12 then
		return
	end

	rideAbomination(npc)
end

local module = {
	OnStep = {
		{ Function = "MoveRandom", Parameters = { 120, stats.MoveDelay }, NotState = "Riding" },
		{ Function = "MoveToAbomination", State = "Riding" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget", NotState = "Riding" },
		{ Function = "LeadTarget", Parameters = { 200 } },
		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				stats.AttackAmount,
				stats.ProjectileSpeed,
				1,
				{},
				"Projectile",
				false,
				0.5,
			},
			true,
			State = "Attacking",
		},

		{
			Function = "ShootProjectile",
			Parameters = {
				AttackDelay = NumberRange.new(2, 4),
				0.02,
				50,
				75,
				1,
				{},
				"Projectile",
				false,
				0.5,
			},
			true,
			State = "Riding",
		},

		{ Function = "Custom", Parameters = { checkDistance }, State = "Riding" },
		{
			Function = "Custom",
			Parameters = { checkAbominationStatus },
			State = "Riding",
			ReturnFunction = function(npc, result)
				if not result then
					loseAbomination(npc)
				end
			end,
		},

		{ Function = "PlayWalkingAnimation" },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" }, NotState = "Riding" },
		{ Function = "MoveTowardsTarget", NotState = "Riding" },
		{ Function = "Custom", Parameters = { searchForAbomination } },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" }, NotState = "Riding" },
		{ Function = "MoveTowardsTarget", NotState = "Riding" },
	},

	OnSpawned = {
		{ Function = "AssignGender" },
		{ Function = "AssignVoice" },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { loseAbomination } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
