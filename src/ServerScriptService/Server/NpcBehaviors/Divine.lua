local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Vendor.Util)
local stats = {
	ViewDistance = 100,
	AttackDelay = NumberRange.new(1.5, 5),
	MoveDelay = NumberRange.new(3, 6),
	AttackCooldown = 0.15,
	ProjectileSpeed = 400,
	AttackAmount = 3,
	NpcType = "Enemy",
}

local function specialIndication(npc, indicateTime: number)
	local weakspot = npc.Instance:FindFirstChild("NonWeakspot")
	if not weakspot then
		return
	end

	local ti_0 = TweenInfo.new(indicateTime, Enum.EasingStyle.Quint)
	local ti_1 = TweenInfo.new(0.1)

	local lleft = weakspot.SkullLowerLeft
	local lright = weakspot.SkullLowerRight
	local uleft = weakspot.SkullUpperLeft
	local uright = weakspot.SkullUpperRight

	weakspot.Name = "Weakspot"

	local beamTweenNumber = Instance.new("NumberValue")

	local distance = 0.5

	Util.tween(lleft, ti_0, { C1 = CFrame.new(-distance, distance, 0) })
	Util.tween(lright, ti_0, { C1 = CFrame.new(distance, distance, 0) })
	Util.tween(uleft, ti_0, { C1 = CFrame.new(-distance, -distance, 0) })
	Util.tween(uright, ti_0, { C1 = CFrame.new(distance, -distance, 0) })

	beamTweenNumber.Changed:Connect(function(a0: number)
		for i = 0, 3 do
			local halo = weakspot:FindFirstChild("Halo")
			if not halo then
				continue
			end
			local beam = halo:FindFirstChild("Beam_" .. i)
			if not beam then
				continue
			end
			beam.Transparency = NumberSequence.new(a0)
		end
	end)

	Util.tween(beamTweenNumber, ti_1, { Value = 1 })

	task.delay(indicateTime, function()
		if not weakspot or not weakspot.Parent then
			return
		end

		weakspot.Name = "NonWeakspot"

		Util.tween(lleft, ti_1, { C1 = CFrame.new() })
		Util.tween(lright, ti_1, { C1 = CFrame.new() })
		Util.tween(uleft, ti_1, { C1 = CFrame.new() })
		Util.tween(uright, ti_1, { C1 = CFrame.new() })

		Util.tween(beamTweenNumber, ti_1, { Value = 0 }, true)
		beamTweenNumber:Destroy()
	end)
end

local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget" },
		{ Function = "LeadTarget", Parameters = { 400 } },
		{
			Function = "ShootProjectile",
			Parameters = {
				stats.AttackDelay,
				stats.AttackCooldown,
				stats.AttackAmount,
				stats.ProjectileSpeed,
				1,
				{},
				"EnemyPlasmaProjectile",
				false,
				1,
				specialIndication,
			},
			State = "Attacking",
		},

		{ Function = "MoveRandom", Parameters = { 20, stats.MoveDelay } },
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
