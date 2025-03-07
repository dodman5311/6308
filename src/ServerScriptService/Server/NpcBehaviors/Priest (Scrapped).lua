local stats = {
	ViewDistance = 200,

	AttackDistance = 6,
	AttackDelay = 1,

	NpcType = "Enemy",
}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)
local animationService = require(Globals.Vendor.AnimationService)

local function healSurrounding(npc)
	net:RemoteEvent("ReplicateEffect")
		:FireAllClients("emitObject", "Server", true, npc.Instance.PrimaryPart.RootAttachment.MassHeal)

	for _, enemyModel: Model in ipairs(CollectionService:GetTagged("Enemy")) do
		if enemyModel == npc.Instance then
			continue
		end

		local distance = (npc.Instance:GetPivot().Position - enemyModel:GetPivot().Position).Magnitude

		if distance > 30 then
			continue
		end

		local humanoid = enemyModel:FindFirstChild("Humanoid")
		if not humanoid then
			continue
		end

		humanoid.Health += math.ceil(humanoid.MaxHealth / 3)
		-- healing effect
		net:RemoteEvent("ReplicateEffect"):FireAllClients("HealingEffect", "Server", true, enemyModel)
	end
end

local function attack(npc)
	npc.Instance.PrimaryPart.Attack:Play()

	npc.Instance.Trail.Enabled = true
	task.delay(0.2, function()
		npc.Instance.Trail.Enabled = false
	end)

	local animation = animationService:playAnimation(npc.Instance, "Attack", Enum.AnimationPriority.Action3)
	npc.Instance.Humanoid.WalkSpeed = 0
	animation.Stopped:Once(function()
		npc.Instance.Humanoid.WalkSpeed = 35
	end)

	local cframe = npc.Instance:GetPivot()

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { npc }
	raycastParams.CollisionGroup = "NpcBullet"

	local shapecast =
		workspace:Spherecast(cframe.Position, 2, cframe.LookVector * (stats.AttackDistance + 2), raycastParams)

	if not shapecast then
		return
	end

	local hitHumanoid = util.checkForHumanoid(shapecast.Instance)

	if not hitHumanoid then
		return
	end
	hitHumanoid:TakeDamage(5)
	healSurrounding(npc)
end

local module = {
	OnStep = {
		{ Function = "MoveToRandomUnit", State = "Idle" },

		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "LookAtTarget", Parameters = { true } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance - 2, true } },
		{ Function = "PlayWalkingAnimation" },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	AtDistance = {
		{
			Function = "RunTimer",
			Parameters = { "MeleeAttack", 1, attack, true },
		},

		Parameters = { stats.AttackDistance },
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
