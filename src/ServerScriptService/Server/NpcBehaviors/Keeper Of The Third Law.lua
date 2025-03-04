local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local assets = ReplicatedStorage.Assets

local Globals = require(ReplicatedStorage.Shared.Globals)

local animationService = require(Globals.Vendor.AnimationService)

--local stats = {}
local rng = Random.new()

local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)

local mapService = require(Globals.Server.Services.MapService)
local globalSounds = assets.Sounds.EverlastingBoss

local timer = require(Globals.Vendor.Timer)

local enemiesHitWithChain = {}
local chainConnect
local runRing
local soulsLeft = 0
local logHealth = 0

local function getTimer(npc, timerName)
	local foundTimer = npc.Timers[timerName]

	if not foundTimer then
		npc.Timers[timerName] = npc.Timer:new(timerName)
		return npc.Timers[timerName]
	end

	return foundTimer
end

-- local function showHitbox(cframe, size)
-- 	local hitbox = Instance.new("Part")
-- 	hitbox.Parent = workspace

-- 	hitbox.Anchored = true
-- 	hitbox.CFrame = cframe
-- 	hitbox.Size = size

-- 	hitbox.Color = Color3.new(1, 0, 0)
-- 	hitbox.Transparency = 0.8

-- 	hitbox.CanCollide = false
-- 	hitbox.CanTouch = false
-- 	hitbox.CanQuery = false

-- 	task.delay(3.5, function()
-- 		hitbox:Destroy()
-- 	end)

-- 	return hitbox
-- end

local function createHitbox(npc, size, offset, damage, blacklist)
	if not blacklist then
		blacklist = {}
	end

	local op = OverlapParams.new()
	op.FilterDescendantsInstances = { npc.Instance }

	local newHitbox = workspace:GetPartBoundsInBox(npc.Instance:GetPivot() * offset, size, op)

	--showHitbox(npc.Instance:GetPivot() * offset, size)

	local hasHit = {}

	for _, hitPart in ipairs(newHitbox) do
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if not model or table.find(hasHit, model) or table.find(blacklist, model) then
			continue
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		humanoid:TakeDamage(damage)

		table.insert(hasHit, model)
	end

	return hasHit
end

local function AttackMelee(npc)
	if npc.Acts:checkAct("InAttack") then
		return
	end

	npc.Acts:createTempAct("Melee", function()
		local primaryPart = npc.Instance.PrimaryPart

		npc.Instance.Humanoid.WalkSpeed = 0
		primaryPart.Anchored = true

		local attackIndex = math.random(1, 3)

		util.PlaySound(primaryPart.SwordSwipe, primaryPart, 0.15)

		animationService:playAnimation(npc.Instance, "Swing_" .. attackIndex, Enum.AnimationPriority.Action4, false, 0)
		animationService:stopAnimation(npc.Instance, "Run", 0)
		timer.wait(1)
		if not npc.Instance.Parent then
			return
		end
		primaryPart.Anchored = false
		timer.wait(1)
		if not npc.Instance.Parent then
			return
		end
		npc.Instance.Humanoid.WalkSpeed = 12

		npc.Acts:removeAct("Run")
	end)
end

local function doDashEffect(npc)
	local newDashEffect = assets.Effects.DashEffect:Clone()
	newDashEffect.Parent = workspace

	local leftDust = newDashEffect:FindFirstChild("LeftDust", true)
	local rightDust = newDashEffect:FindFirstChild("RightDust", true)
	local trail = npc.Instance:FindFirstChild("DashTrail", true)

	newDashEffect:PivotTo(npc.Instance:GetPivot())

	leftDust:Emit(25)
	rightDust:Emit(25)
	trail.Enabled = true
	task.delay(0.15, function()
		if not trail then
			return
		end

		trail.Enabled = false
	end)

	Debris:AddItem(newDashEffect, 2)
end

local function DashTowardsPlayer(npc)
	if npc.Acts:checkAct("Melee", "InAttack", "Run") then
		return
	end

	local startCFrame: CFrame = npc.Instance:GetPivot()

	local target = npc:GetTarget()
	if not target then
		return
	end

	local distanceToTarget = (startCFrame.Position - target:GetPivot().Position).Magnitude
	local distance = math.clamp(distanceToTarget, 0, 30)

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace:FindFirstChild("Map") }

	local castCheckRay = workspace:Raycast(startCFrame.Position, startCFrame.LookVector * (distance + 1), rp)

	if castCheckRay then
		return
	end

	local endCFrame = startCFrame * CFrame.new(0, 0, -distance)

	doDashEffect(npc)

	for i = 0, 1, 0.25 do
		if not npc.Instance.Parent then
			return
		end

		npc.Instance:PivotTo(startCFrame:Lerp(endCFrame, i))
		RunService.Heartbeat:Wait()
	end
end

local function parryEffect(position, endPosition)
	local distance = (position - endPosition).Magnitude

	local partClone = assets.Effects.BossParry:Clone()
	partClone.Parent = workspace.Ignore
	partClone.CFrame = CFrame.lookAt(position, endPosition)
	partClone.Hit.Position = Vector3.new(0, 0, -distance)
	partClone.Beam.Enabled = true

	task.spawn(function()
		for i = 0.5, 1, 0.05 do
			timer.wait(0.05)
			partClone.Beam.Transparency = NumberSequence.new(i)
		end
		partClone:Destroy()
	end)
end

local function parryAttack(npc, health)
	local humanoid = npc.Instance.Humanoid

	local healthChange = logHealth - health

	humanoid.Health = logHealth

	util.PlaySound(assets.Sounds.Blocked, ReplicatedStorage, 0.1)
	util.PlaySound(assets.Sounds.BlockedMetal, ReplicatedStorage, 0.1)

	animationService:playAnimation(
		npc.Instance,
		"Parry_" .. math.random(1, 4),
		Enum.AnimationPriority.Action4,
		false,
		0
	)

	local npcPos = npc.Instance:GetPivot().Position

	local target = npc:GetTarget()
	if not target then
		return
	end

	local targetPos = target:GetPivot().Position

	parryEffect(npcPos, targetPos)

	local enemyHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not enemyHumanoid or enemyHumanoid.Health <= 0 then
		return
	end

	enemyHumanoid:TakeDamage(healthChange)
end

local function addArmor(npc)
	npc.Acts:createAct("InAttack")
	local subject = npc.Instance

	local humanoid = subject.Humanoid

	humanoid.WalkSpeed = 0.05

	globalSounds.ArmorBuild:Play()
	subject.PrimaryPart.RootAttachment.ArmorRing:Emit(1)
	timer.wait(2)

	globalSounds.ArmorGain:Play()
	humanoid.Health += 15

	humanoid.WalkSpeed = 12

	npc.Acts:removeAct("InAttack")
end

local attacks = {
	function(npc) -- Pull chain to player
		npc.Acts:createAct("InAttack")
		animationService:playAnimation(npc.Instance, "ChainAttack", Enum.AnimationPriority.Action4, false, 0)
	end,

	function(npc) -- chain swipe
		util.PlaySound(assets.Sounds.Chain, npc.Instance.PrimaryPart, 0.05)

		npc.Acts:createAct("InAttack")
		animationService:playAnimation(npc.Instance, "ChainStrike", Enum.AnimationPriority.Action4, false, 0)
	end,

	function(npc) -- Run to player
		npc.Acts:createAct("Run")
		npc.Instance.Humanoid.WalkSpeed = 50

		animationService:playAnimation(npc.Instance, "Run", Enum.AnimationPriority.Action, false, 0)

		local runTimer = npc:GetTimer("RunTimer")
		runTimer.WaitTime = 5
		runTimer.Function = function()
			npc.Instance.Humanoid.WalkSpeed = 12
			animationService:stopAnimation(npc.Instance, "Run", 0)
			npc.Acts:removeAct("Run")
			npc.Acts:removeAct("InAttack")
		end

		runTimer:Cancel()
		runTimer:Run()

		repeat
			timer.wait()

			if not npc.Instance.Parent then
				break
			end

			npc.Instance.Humanoid.WalkSpeed = 50
		until not npc.Acts:checkAct("InAttack")
	end,

	function(npc) -- Bell hit
		if rng:NextNumber(0, 100) > 30 then
			return
		end

		local model = npc.Instance
		local runTo = workspace:FindFirstChild("JumpPoint", true)

		if not runTo or not model.Parent then
			addArmor(npc)
			return
		end

		npc.Acts:createAct("InAttack")

		model.Shell.Shell.CanQuery = true -- immortal

		model:SetAttribute("State", "NoAi")

		animationService:playAnimation(npc.Instance, "Run", Enum.AnimationPriority.Action, false, 0)

		local distanceToPoint = (model:GetPivot().Position - runTo.Position).Magnitude

		local runTime = os.clock()

		repeat
			timer.wait()

			if not model.Parent then
				break
			end

			model.Humanoid.WalkSpeed = 50
			npc.Target.Value = runTo

			distanceToPoint = (model:GetPivot().Position - runTo.Position).Magnitude
		until distanceToPoint <= 6 or (os.clock() - runTime > 5)

		if not model.Parent then
			return
		end

		model:SetAttribute("State", "Attacking")

		model.Humanoid.WalkSpeed = 12
		model.PrimaryPart.Anchored = true
		model:PivotTo(runTo.CFrame)

		animationService:stopAnimation(npc.Instance, "Run", 0)
		animationService
			:playAnimation(npc.Instance, "StrikeBell", Enum.AnimationPriority.Action4, false, 0).Stopped
			:Wait()

		if not model.Parent then
			return
		end

		model.PrimaryPart.Anchored = false
		model.Shell.Shell.CanQuery = false
		npc.Acts:removeAct("InAttack")
	end,

	function(npc) -- Parry attacks
		npc.Acts:createAct("InAttack")
		local animation =
			animationService:playAnimation(npc.Instance, "ParryStance", Enum.AnimationPriority.Action3, false, 0)

		repeat
			timer.wait()
		until animation.Length > 0

		if not npc.Instance.Parent then
			return
		end

		local primaryPart = npc.Instance.PrimaryPart
		local humanoid = npc.Instance.Humanoid

		humanoid.WalkSpeed = 0

		primaryPart.SwordGrab:Play()

		task.delay(0.6, function()
			animation:AdjustSpeed(0)
		end)

		npc.Acts:createAct("Parrying")

		task.delay(3, function()
			animation:AdjustSpeed(1)
			humanoid.WalkSpeed = 12
			npc.Acts:removeAct("InAttack")
			npc.Acts:removeAct("Parrying")
		end)
	end,
}

local function runAttackTimer(npc)
	if npc.Acts:checkAct("Run", "InAttack", "Melee") then
		return
	end

	local AttackTimer = getTimer(npc, "Special")

	local shuffledAttacks = util.ShuffleTable(attacks)

	AttackTimer.WaitTime = rng:NextNumber(3, 6)
	AttackTimer.Function = shuffledAttacks[math.random(1, #shuffledAttacks)]
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local function runDashTimer(npc)
	local AttackTimer = getTimer(npc, "DashToPlayer")

	AttackTimer.WaitTime = rng:NextNumber(1.5, 3)
	AttackTimer.Function = DashTowardsPlayer
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local function setEffectEnabled(npc, value, effect)
	local model = npc.Instance

	local vfx = model:FindFirstChild(effect, true)
	vfx.Enabled = value
end

local function throwGrapple(npc)
	local model = npc.Instance

	model.PrimaryPart.Anchored = true

	local npcCFrame: CFrame = model:GetPivot()

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace:FindFirstChild("Map") }

	local castCheckRay = workspace:Raycast(npcCFrame.Position, npcCFrame.LookVector * 1000, rp)

	if not castCheckRay then
		return
	end

	model.Torso.Base.Enabled = false
	model.Hook.Base.Anchored = true

	local startPos = model.Hook:GetPivot()
	local endPos = CFrame.new(castCheckRay.Position) * npcCFrame.Rotation

	for i = 0, 1, 0.25 do
		if not model.Parent then
			return
		end

		model.Hook:PivotTo(startPos:Lerp(endPos, i))
		RunService.Heartbeat:Wait()
	end
end

local function grabGrapple(npc)
	local model = npc.Instance

	local npcCFrame: CFrame = model:GetPivot()

	local endPos = CFrame.new(model.Hook.Base.CFrame.Position) * npcCFrame.Rotation

	model.Hook.Base.Anchored = false
	model.Torso.Base.Enabled = true

	local hitBlacklist = {}

	for i = 0, 0.8, 0.05 do
		if not npc.Instance.Parent then
			return
		end

		for _, enemyHit in ipairs(createHitbox(npc, Vector3.new(25, 1.5, 25), CFrame.new(), 3, hitBlacklist)) do
			table.insert(hitBlacklist, enemyHit)
		end

		npc.Instance:PivotTo(npcCFrame:Lerp(endPos, i))
		RunService.Heartbeat:Wait()
	end

	if not npc.Instance.Parent then
		return
	end
	model.PrimaryPart.Anchored = false

	npc.Acts:removeAct("InAttack")
end

local function damaged(npc, health)
	local subject = npc.Instance

	if health <= soulsLeft * 75 and soulsLeft >= 0 then
		soulsLeft -= 1

		if not npc.StatusEffects["Soul"] then
			net:RemoteEvent("DropSoul"):FireAllClients(subject:GetPivot().Position, 1000)
		end
	end

	local target = npc:GetTarget()
	local distance = target and (subject:GetPivot().Position - target:GetPivot().Position).Magnitude or 100

	if (distance <= 14 and rng:NextNumber(0, 100) <= 65) or npc.Acts:checkAct("Parrying") then
		parryAttack(npc, health)
	end

	logHealth = health
end

local function knockOut(npc)
	npc.Instance:SetAttribute("KnockedOut", true)

	mapService.bossExit()

	timer.wait(0.5)
	local humanoid = npc.Instance.Humanoid
	humanoid.Health = 0
end

local function setUpEnemy(npc)
	enemiesHitWithChain = {}
	soulsLeft = 2
	logHealth = npc.Instance.Humanoid.Health

	local animations = animationService:getLoadedAnimations(npc.Instance)

	for _, animationTrack in pairs(animations) do
		animationTrack:GetMarkerReachedSignal("CreateFrontalHitbox"):Connect(function(damage)
			createHitbox(npc, Vector3.new(8, 0.25, 16), CFrame.new(0, -1.5, -8), damage)
		end)
		animationTrack:GetMarkerReachedSignal("CreateRotaryHitbox"):Connect(function(damage)
			createHitbox(npc, Vector3.new(22, 0.25, 22), CFrame.new(0, -1.5, 0), damage)
		end)
		animationTrack:GetMarkerReachedSignal("EnableEffect"):Connect(function(effect)
			setEffectEnabled(npc, true, effect)
		end)
		animationTrack:GetMarkerReachedSignal("DisableEffect"):Connect(function(effect)
			setEffectEnabled(npc, false, effect)
		end)

		animationTrack:GetMarkerReachedSignal("ThrowGrapple"):Connect(function()
			util.PlaySound(assets.Sounds.Chain, npc.Instance.PrimaryPart, 0.05)
			throwGrapple(npc)
		end)

		animationTrack:GetMarkerReachedSignal("RetractGrapple"):Connect(function()
			local primaryPart = npc.Instance.PrimaryPart

			util.PlaySound(primaryPart.SwordSwipe, primaryPart, 0.15)
			grabGrapple(npc)
		end)

		animationTrack:GetMarkerReachedSignal("StrikeBell"):Connect(function()
			-- play bell sound

			local getUnit = workspace.Map:FindFirstChild("BossRoom_1")
			local bellChain = getUnit.BellChain

			if bellChain:GetAttribute("IsWeakened") then
				knockOut(npc)
				return
			end

			util.PlaySound(assets.Sounds.church_bell, workspace:FindFirstChild("BellPart", true))

			if npc.Instance.Parent then
				npc.Instance.Humanoid.Health += 15
			end

			if runRing then
				runRing:Disconnect()
			end

			local hasHit = false

			local hitRing = workspace:FindFirstChild("HitRing", true)
			if not hitRing then
				return
			end

			local startTime = os.clock()
			local ringTime = 2

			hitRing.Ring.Enabled = true
			hitRing.Size = Vector3.new(2, 1, 1)

			runRing = RunService.Heartbeat:Connect(function()
				local currentTime = os.clock() - startTime

				if currentTime >= ringTime then
					runRing:Disconnect()
					hitRing.Ring.Enabled = false
					return
				end

				hitRing.Size = Vector3.new(2, 1, 1):Lerp(Vector3.new(2, 400, 400), currentTime / ringTime)

				local target: Model = npc:GetTarget()

				if not target or hasHit then
					return
				end

				local maxDistance = hitRing.Size.Z / 2 -- get range between
				local minDisatance = maxDistance * 0.85

				local playerPosition = target:GetPivot().Position
				local ringPosition = hitRing.Position

				local playerDistance = (playerPosition - ringPosition).Magnitude

				if playerDistance < minDisatance or playerDistance > maxDistance then
					return
				end

				local yDifference = playerPosition.Y - ringPosition.Y

				if yDifference >= 4.5 or hasHit then
					return
				end

				-- hit player
				hasHit = true
				target.Humanoid.WalkSpeed -= 20
				target.Humanoid:TakeDamage(1)
				target:SetAttribute("LockSlide", true)

				task.delay(6, function()
					if not target.Parent then
						return
					end
					target.Humanoid.WalkSpeed += 20
					target:SetAttribute("LockSlide", false)
				end)
			end)
		end)

		animationTrack:GetMarkerReachedSignal("StartHitCasting"):Connect(function()
			enemiesHitWithChain = {}

			local rp = RaycastParams.new()
			rp.FilterDescendantsInstances = { npc.Instance }

			chainConnect = RunService.Heartbeat:Connect(function()
				if not npc.Instance.Parent then
					return
				end

				local armPosition = npc.Instance["Left Arm"].Position
				local hookPos = npc.Instance.Hook:GetPivot().Position
				local result = workspace:Spherecast(armPosition, 4, hookPos - armPosition, rp)

				if not result then
					return
				end

				local model = result.Instance:FindFirstAncestorOfClass("Model")
				if not model or table.find(enemiesHitWithChain, model) then
					return
				end

				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					return
				end

				humanoid:TakeDamage(3)

				table.insert(enemiesHitWithChain, model)
			end)
		end)

		animationTrack:GetMarkerReachedSignal("StopHitCasting"):Connect(function()
			chainConnect:Disconnect()

			npc.Acts:removeAct("InAttack")
		end)
	end
end

local function DeathEffect(npc)
	local model = npc.Instance

	model.PrimaryPart.Anchored = true

	local ti = TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	for _, v in ipairs(model:GetDescendants()) do
		if not v:IsA("BasePart") then
			continue
		end

		local newParticle = assets.Effects.FadeParticle:Clone()
		newParticle.Parent = v
		newParticle.Rate = 0
		newParticle.Enabled = true

		task.delay(1, function()
			util.tween(v, ti, { Transparency = 1 })
		end)

		util.tween(newParticle, ti, { Rate = 50 })
		task.delay(4, function()
			util.tween(newParticle, ti, { Rate = 0 })
		end)
	end
end

local function onDied(npc)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			if BadgeService:AwardBadge(player.UserId, 2275688768196496) then
				net:RemoteEvent("DoUiAction"):FireAllClients("Notify", "AchievementUnlocked", 2275688768196496)
			end
		end)
	end

	if npc.Instance:GetAttribute("KnockedOut") then
		for _, v in ipairs(npc.Instance:GetDescendants()) do
			if not v:IsA("BasePart") then
				continue
			end

			v.Transparency = 1
		end

		net:RemoteEvent("StopMusic"):FireAllClients("Keeper Of The Third Law")
		timer.wait(2)
		net:RemoteEvent("DoUiAction"):FireAllClients("BossIntro", "ShowCompleted", npc.Instance.Name)
		net:RemoteEvent("DoUiAction"):FireAllClients("HUD", "HideBossBar")

		return
	end

	local primaryPart = npc.Instance.PrimaryPart

	if primaryPart and primaryPart:FindFirstChild("Death") then
		npc.Instance.PrimaryPart.Death:Play()
	end

	net:RemoteEvent("StopMusic"):FireAllClients("Keeper Of The Third Law")

	local animation =
		animationService:playAnimation(npc.Instance, "Death", Enum.AnimationPriority.Action4, false, 0, 1, 0.5)

	task.delay(27, function()
		net:RemoteEvent("DoUiAction"):FireAllClients("BossIntro", "ShowCompleted", npc.Instance.Name)
		net:RemoteEvent("DoUiAction"):FireAllClients("HUD", "HideBossBar")
	end)

	repeat
		timer.wait()
	until animation.Length > 0

	task.delay(animation.Length + 5, function()
		DeathEffect(npc)
	end)
end

local module = {
	OnStep = {

		{ Function = "SearchForTarget", Parameters = { 1000 } },
		{ Function = "LookAtTarget" },

		{ Function = "GetToDistance", Parameters = { 4.9, true } },
		{ Function = "PlayWalkingAnimation" },
		{ Function = "Custom", Parameters = { runDashTimer } },
		{ Function = "Custom", Parameters = { runAttackTimer } },
	},

	AtDistance = {

		{ Function = "Custom", Parameters = { AttackMelee } },

		Parameters = { 12 },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
		{ Function = "Custom", Parameters = { setUpEnemy } },
	},

	OnDamaged = {
		{ Function = "Custom", Parameters = { damaged } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Custom", Parameters = { onDied } },
		{ Function = "RemoveWithDelay", Parameters = { 30 } },
	},
}

return module
