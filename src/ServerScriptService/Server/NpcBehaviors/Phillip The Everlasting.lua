local stats = {
	ViewDistance = 200,
}

local WALKSPEED = 12
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local assets = ReplicatedStorage.Assets
local globalSounds = assets.Sounds.EverlastingBoss

local Globals = require(ReplicatedStorage.Shared.Globals)
local util = require(Globals.Vendor.Util)
local animationService = require(Globals.Vendor.AnimationService)
local timer = require(Globals.Vendor.Timer)
local weakspotService = require(Globals.Vendor.WeakspotService)

local net = require(Globals.Packages.Net)

local rng = Random.new()

local moveChances = {
	{ "addArmor", 25 },
	{ "throwAttack", 90 },
	{ "shootAttack", 100 },
}

local moves = {}

local function getTimer(npc, timerName, defaultTime)
	local foundTimer = npc.Timers[timerName]

	if not foundTimer then
		npc.Timers[timerName] = npc.Timer:new(timerName, defaultTime)
		return npc.Timers[timerName]
	end

	return foundTimer
end

local function indicateAttack(npc, color)
	net:RemoteEvent("ReplicateEffect"):FireAllClients("IndicateAttack", "Server", true, npc.Instance, color)
	timer.wait(0.5)
end

local function checkHitbox(subject: Model, Pos, Size)
	local hitboxResult = workspace:GetPartBoundsInBox(Pos, Size)
	local humanoidsHit = {}

	for _, part in ipairs(hitboxResult) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model or model == subject then
			continue
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		if table.find(humanoidsHit, humanoid) then
			continue
		end
		table.insert(humanoidsHit, humanoid)
	end
	return humanoidsHit
end

local function createImpulse(subject: Model, power: number, direction: Vector3, velocityTime)
	local primaryPart = subject.PrimaryPart
	if not primaryPart then
		return
	end

	local newVelocity = Instance.new("LinearVelocity")
	Debris:AddItem(newVelocity, velocityTime)

	newVelocity.Parent = primaryPart
	newVelocity.Attachment0 = primaryPart:FindFirstChildOfClass("Attachment")
	newVelocity.MaxForce = math.huge
	newVelocity.VectorVelocity = direction * power
end

local function showGunFire(subject, sound)
	sound:Play()
	local firePart = subject.FirePart

	for _, v in ipairs(firePart:GetChildren()) do
		if v.Name ~= "FireEffect" then
			continue
		end
		v.Enabled = true
		task.delay(0.075, function()
			v.Enabled = false
		end)
	end
	firePart.HeatEffect.Enabled = true
	task.delay(2, function()
		firePart.HeatEffect.Enabled = false
	end)
end

local function showHitBlood(subject, sound)
	sound:Play()
	local hitPart = subject.MeleeHitPart
	for _, v in ipairs(hitPart:GetChildren()) do
		if v.Name ~= "BloodEffect" then
			continue
		end
		v.Enabled = true
		task.delay(0.1, function()
			v.Enabled = false
		end)
	end
end

local function stunEnemy(npc)
	local humanoid = npc.Instance.Humanoid

	humanoid.WalkSpeed = 0.05
	animationService:playAnimation(npc.Instance, "Stun", Enum.AnimationPriority.Action4.Value, false, 0, 1, 1.25)
	globalSounds.Stun:Play()
	timer.wait(2.8)
	humanoid.WalkSpeed = WALKSPEED
end

function moves.addArmor(npc)
	npc.Acts:createAct("inAction", "inHeal")
	local subject = npc.Instance

	local humanoid = subject.Humanoid
	local logHealth = humanoid.Health
	local damageIndicator = subject.PrimaryPart.DamageBoard
	local maxDamage = humanoid.MaxHealth / math.random(20, 23)
	local damageAccumulated = 0

	humanoid.WalkSpeed = 0.05

	local healthChanged
	healthChanged = humanoid.HealthChanged:Connect(function(health)
		if health < logHealth then
			damageAccumulated += logHealth - health
		end

		damageIndicator.Enabled = true
		damageIndicator.Damage.Stroke.Color = Color3.new(1, 0, 0)

		local percent = damageAccumulated / maxDamage
		damageIndicator.Damage.Size = UDim2.new(percent, 0, percent, 0)
		damageIndicator.DamageNumber.Text = math.round(damageAccumulated)

		logHealth = health

		if damageAccumulated < maxDamage then
			return
		end
		damageIndicator.Damage.Stroke.Color = Color3.new(0, 1, 0)
	end)

	globalSounds.ArmorBuild:Play()
	subject.PrimaryPart.RootAttachment.ArmorRing:Emit(1)
	timer.wait(2)

	healthChanged:Disconnect()
	damageIndicator.Enabled = false

	if damageAccumulated >= maxDamage then
		npc.Acts:createTempAct("inStun", stunEnemy, nil, npc)
	else
		globalSounds.ArmorGain:Play()
		humanoid.Health += 10
	end

	humanoid.WalkSpeed = WALKSPEED

	npc.Acts:removeAct("inAction", "inHeal")
end

local function checkRaycast(subject: Model, origin, destination)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { subject }

	local newRay = workspace:Raycast(origin, destination, rp)

	if not newRay then
		return
	end
	local part = newRay.Instance
	local model = part:FindFirstAncestorOfClass("Model")
	if not model or model == subject then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	return humanoid, part
end

function moves.shootAttack(npc)
	npc.Acts:createAct("leading_shot", "inAction")

	local subject = npc.Instance

	subject.Humanoid.WalkSpeed = 0.05

	local rootPart = subject.PrimaryPart

	local shootAnim = animationService:getAnimation(subject, "ChargedAttack")
	animationService:playAnimation(subject, "ChargedAttack", Enum.AnimationPriority.Action3)
	timer.wait(0.5)
	shootAnim:AdjustSpeed(0)

	local firePart = subject.FirePart
	local beam = firePart.Shotbeam

	firePart.A1.WorldCFrame = subject.PrimaryPart.CFrame * CFrame.new(0, 0, -500)
	beam.Enabled = true

	--utility.indicateAttack(subject, 1, firePart)
	timer.wait(0.5)
	indicateAttack(npc, Color3.fromRGB(255, 135, 135))

	shootAnim:AdjustSpeed(1)

	beam.Enabled = false
	timer.wait(0.1)
	showGunFire(subject, rootPart.GunFire)
	local hitHumanoid, part =
		checkRaycast(subject, subject.PrimaryPart.CFrame.Position, subject.PrimaryPart.CFrame.LookVector * 500)
	if hitHumanoid and npc:GetState() ~= "Dead" then
		hitHumanoid:TakeDamage(1 + weakspotService.doWeakspotHit(part))
	end
	npc.Acts:removeAct("leading_shot", "inAction")
	timer.wait(0.125)

	subject.Humanoid.WalkSpeed = WALKSPEED
end

local function diedExit()
	--mapService.exitMiniBoss()
end

function moves.throwAttack(npc)
	local subject = npc.Instance
	npc.Acts:createAct("leading_shot_wdistance", "inAction")

	subject.Humanoid.WalkSpeed = 0.05

	animationService:playAnimation(subject, "Throw", Enum.AnimationPriority.Action3)
	timer.wait(0.23)
	globalSounds.AxeToGround:Play()

	timer.wait(1.04)
	subject.PrimaryPart.AxeThrow:Play()

	local delta = 0
	local axeSpeed = 0.5
	local throwDistance = 200
	local startCFrame = subject.PrimaryPart.CFrame * CFrame.new(0, 0, -7) * CFrame.Angles(0, 0, math.rad(-70))
	local endCFrame = subject.PrimaryPart.CFrame * CFrame.new(0, 0, -throwDistance)

	local newProjectile = subject.ThrownAxe:Clone()
	newProjectile.Parent = workspace
	newProjectile.Transparency = 0.75
	newProjectile.Anchored = true
	newProjectile.CFrame = startCFrame
	newProjectile.Sound:Play()

	for _, v in ipairs(newProjectile:GetDescendants()) do
		if not v:IsA("ParticleEmitter") then
			continue
		end
		v.Enabled = true
	end

	local hitHumanoids = {}

	local beat
	beat = RunService.Heartbeat:Connect(function(dt)
		delta += (dt * axeSpeed)
		newProjectile.CFrame = startCFrame:Lerp(endCFrame, delta)

		local hitboxHits = checkHitbox(subject, newProjectile.CFrame, newProjectile.Size)
		for _, humanoid in ipairs(hitboxHits) do
			if table.find(hitHumanoids, humanoid) or npc:GetState() == "Dead" then
				continue
			end

			local exDmg = weakspotService.doWeakspotHit(humanoid.Parent:FindFirstChild("Weakspot"))

			humanoid:TakeDamage(2 + exDmg)
			table.insert(hitHumanoids, humanoid)
		end

		if delta < 1 then
			return
		end
		beat:Disconnect()
		newProjectile:Destroy()
	end)
	npc.Acts:removeAct("leading_shot_wdistance", "inAction")
	timer.wait(1)

	subject.Humanoid.WalkSpeed = WALKSPEED
end

local function grabPlayer(npc)
	if npc.Acts:checkAct("inGrab", "inStun", "inHeal") then
		return
	end

	local target = npc:GetTarget()
	local subject = npc.Instance

	local size = target:GetExtentsSize().Magnitude
	if size > 15 then
		return
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local rootPart = subject.PrimaryPart

	npc.Acts:createAct("inAction", "inGrab")
	subject.Humanoid.WalkSpeed = 0.05
	animationService:playAnimation(subject, "Grab", Enum.AnimationPriority.Action4.Value, false, 0, 1, 1.5)

	local beat
	beat = RunService.Heartbeat:Connect(function()
		if npc:GetState() == "Dead" or not npc.Instance.Parent or not target or not target.PrimaryPart then
			npc.Acts:removeAct("inAction", "inGrab")
			beat:Disconnect()
			return
		end

		target.PrimaryPart.Anchored = true
		local grabPosition = subject:GetPivot() * CFrame.new(0, 0, -6) * CFrame.Angles(0, math.rad(-180), 0)
		target:PivotTo(grabPosition)
	end)

	timer.wait(0.1)
	showHitBlood(subject, rootPart.AxeHit)

	if npc:GetState() ~= "Dead" then
		local exDmg = weakspotService.doWeakspotHit(humanoid.Parent:FindFirstChild("Weakspot"))
		humanoid:TakeDamage(2 + exDmg)
	end

	timer.wait(0.515)
	showGunFire(subject, rootPart.GunFire)

	if npc:GetState() ~= "Dead" then
		local exDmg = weakspotService.doWeakspotHit(humanoid.Parent:FindFirstChild("Weakspot"))
		humanoid:TakeDamage(2 + exDmg)
	end

	beat:Disconnect()

	if not target or not target.Parent or not target.PrimaryPart then
		return
	end
	target.PrimaryPart.Anchored = false
	local impulseDirection = (subject.PrimaryPart.CFrame * CFrame.Angles(math.rad(25), 0, 0)).LookVector
	createImpulse(target, 65, impulseDirection, 0.1)
	timer.wait(1)

	subject.Humanoid.WalkSpeed = WALKSPEED
	npc.Acts:removeAct("inAction", "inGrab")
end

local function runAttackTimer(npc)
	if npc.Acts:checkAct("Run", "InAttack", "Melee") then
		return
	end

	local AttackTimer = getTimer(npc, "Special", 3)

	AttackTimer.Function = function()
		AttackTimer.WaitTime = rng:NextNumber(2, 4)

		for _, value in ipairs(util.ShuffleTable(moveChances)) do
			if rng:NextNumber(0, 100) > value[2] then
				continue
			end

			if not npc.Acts:checkAct("inAction") then
				moves[value[1]](npc)
			end

			return
		end
	end
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local function moveTowardsPosition(subject: Model, position: Vector3)
	local getHumanoid = subject:FindFirstChildOfClass("Humanoid")

	local distanceToPos = (subject:GetPivot().Position - position).Magnitude

	if distanceToPos <= 5 then
		subject:PivotTo(CFrame.lookAt(subject:GetPivot().Position, position) * CFrame.new(0, 0, 0.01))
		return
	end
	getHumanoid:MoveTo(position)
end

local function onDied(npc)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			if BadgeService:AwardBadge(player.UserId, 982889213750283) then
				net:RemoteEvent("DoUiAction"):FireAllClients("Notify", "AchievementUnlocked", 982889213750283)
			end
		end)
	end

	net:RemoteEvent("StopMusic"):FireAllClients("Phillip The Everlasting")
	timer.wait(1)
	net:RemoteEvent("DoUiAction"):FireAllClients("BossIntro", "ShowCompleted", npc.Instance.Name)
	net:RemoteEvent("DoUiAction"):FireAllClients("HUD", "HideBossBar")
end

local function lead(npc)
	local target = npc:GetTarget()
	if not target then
		return
	end

	local targetPosition = target:GetPivot().Position
	local targetVelocity = target.PrimaryPart.Velocity

	local distance = (targetPosition - npc.Instance:GetPivot().Position).Magnitude

	if npc.Acts:checkAct(false, "leading_shot") then
		local positionToLookAt = targetPosition + targetVelocity / 3 --2.25
		moveTowardsPosition(npc.Instance, positionToLookAt)
	elseif npc.Acts:checkAct(false, "leading_shot_wdistance") then
		local positionToLookAt = targetPosition
			+ (
				(targetVelocity + Vector3.new(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-2.5, 2.5)))
				* (distance / 50)
			)
		moveTowardsPosition(npc.Instance, positionToLookAt)
	else
		moveTowardsPosition(npc.Instance, targetPosition)
	end
end

local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { stats.ViewDistance } },
		{ Function = "Custom", Parameters = { runAttackTimer } },
		{ Function = "Custom", Parameters = { lead } },

		{ Function = "PlayWalkingAnimation" },
	},

	AtDistance = {
		{
			Function = "Custom",
			Parameters = { grabPlayer },
		},

		Parameters = { 10 },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		--{ Function = "MoveTowardsTarget" },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 6, true } },
		{ Function = "Custom", Parameters = { onDied } },
		{ Function = "Custom", Parameters = { diedExit } },
	},
}

return module
