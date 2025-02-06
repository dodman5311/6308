local stats = {
	ViewDistance = 200,
	LeadCompensation = 750,
	AttackDistance = 30,
}

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local assets = ReplicatedStorage.Assets
local effects = assets.Effects

local Globals = require(ReplicatedStorage.Shared.Globals)
local util = require(Globals.Vendor.Util)
local UIAnimator = require(Globals.Vendor.UIAnimationService)
local animationService = require(Globals.Vendor.AnimationService)

local timer = require(Globals.Vendor.Timer)
local catTimer = timer:new("CatWalkTimer", 6.5)

local rockUp = assets.Sounds.RockUp
local rockHits = assets.Sounds.RockHits

local net = require(Globals.Packages.Net)

local rng = Random.new()

local vfx = net:RemoteEvent("ReplicateEffect")

local moveChances = {
	{ "GroundElectrify", 15 },
	{ "BlackHole", 25 },
	{ "ShootRocks", 45 },
	{ "GravityPattern", 100 },
}

local patterns = {
	{
		Vector2.new(1, 1),
		Vector2.new(-1, 1),
		Vector2.new(1, -1),
		Vector2.new(-1, -1),
	},

	{
		Vector2.new(0, -1),
		Vector2.new(-0.75, 0.75),
		Vector2.new(0.75, 0.75),
	},

	{
		Vector2.new(0, -1),
		Vector2.new(0, -2.25),
		Vector2.new(0, -3.5),
	},

	{
		Vector2.new(-1.25, -1),
		Vector2.new(0, -1),
		Vector2.new(1.25, -1),
	},

	{
		Vector2.new(0, -1),
		Vector2.new(0, 1),
		Vector2.new(1, 0),
		Vector2.new(-1, 0),
	},

	{
		Vector2.new(0, -1.5),
		Vector2.new(0, 1.5),
		Vector2.new(1.5, 0),
		Vector2.new(-1.5, 0),

		Vector2.new(1.25, -1.25),
		Vector2.new(-1.25, -1.25),
		Vector2.new(1.25, 1.25),
		Vector2.new(-1.25, 1.25),
	},
}

local function createImpulse(subject: Model, power: number, direction: Vector3, velocityTime: number)
	local primaryPart = subject.PrimaryPart
	if not primaryPart then
		return
	end

	local newVelocity = Instance.new("LinearVelocity")
	Debris:AddItem(newVelocity, velocityTime)

	newVelocity.Parent = subject
	newVelocity.Attachment0 = primaryPart:FindFirstChildOfClass("Attachment")
	newVelocity.MaxForce = math.huge
	newVelocity.VectorVelocity = direction * power

	return newVelocity
end

local function grabPlayer(npc)
	if npc.Acts:checkAct("inGrab", "inStun", "Blackhole") then
		return
	end

	npc.Acts:createAct("inAction", "inGrab")
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

	animationService:playAnimation(subject, "Attack", Enum.AnimationPriority.Action4.Value, false, 0, 1, 1.5)

	timer.wait(0.1)
	humanoid:TakeDamage(2)

	if not target or not target.Parent or not target.PrimaryPart then
		return
	end
	target.PrimaryPart.Anchored = false
	local impulseDirection = (subject.PrimaryPart.CFrame * CFrame.Angles(math.rad(25), 0, 0)).LookVector
	createImpulse(target, 65, impulseDirection, 0.1)
	timer.wait(0.5)

	npc.Acts:removeAct("inAction", "inGrab")
end

local function hitPlayer(character)
	character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, -200, 0)
	local humanoid = character:FindFirstChild("Humanoid")

	humanoid:TakeDamage(3)
end

local function createAttackAt(npc, position, hasSound)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }
	local raycast = workspace:Raycast(position, CFrame.new().UpVector * -300, rp)
	if not raycast then
		return
	end

	local effect = effects.GravityAttack:Clone()
	effect.Parent = workspace
	effect:PivotTo(CFrame.new(raycast.Position) * CFrame.Angles(0, 0, math.rad(90)))

	if hasSound then
		local sound = effect.Notice.Activate
		sound:Play()
		local ti = TweenInfo.new(1)

		task.delay(0.5, function()
			util.tween(sound, ti, { Volume = 0 })
		end)
	end

	UIAnimator.PlayAnimation(effect.Notice.SurfaceGui.Frame, 0.03, false, true).OnEnded:Wait()
	timer.wait(0.2)

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end

		local playerPosition = character:GetPivot().Position * Vector3.new(1, 0, 1)
		local distance = (playerPosition - (position * Vector3.new(1, 0, 1))).Magnitude

		if distance > effect.Area.Size.Z / 2 then
			continue
		end

		if npc:GetState() == "Dead" then
			return
		end

		hitPlayer(character, npc)
	end

	if hasSound then
		local soundPart = Instance.new("Part")
		soundPart.Parent = workspace
		soundPart.CanCollide = false
		soundPart.CanQuery = false
		soundPart.Transparency = 1
		soundPart.Anchored = true
		soundPart.Position = effect.Notice.Position

		Debris:AddItem(soundPart, 10)

		util.PlaySound(effect.Notice.AirBoom, soundPart)
		util.PlaySound(effect.Notice.Boom, soundPart)
	end

	timer.wait(0.1)
	effect:Destroy()
end

local function attackPlayer(npc)
	npc.Acts:createAct("InAttack", "inAction")

	local humanoid = npc.Instance.Humanoid

	humanoid.WalkSpeed = 0.01

	animationService:playAnimation(npc.Instance, "SlamAttack", Enum.AnimationPriority.Action3)

	local pattern = patterns[math.random(1, #patterns)]
	local npcCframne = npc.Instance:GetPivot()

	for i, offset in ipairs(pattern) do
		local cframe = npcCframne * CFrame.new(offset.X * 40, 0, offset.Y * 40)

		task.spawn(createAttackAt, npc, cframe.Position, i == 1)
	end

	timer.wait(0.3)
	humanoid.WalkSpeed = 6

	npc.Acts:removeAct("InAttack", "inAction")
end

local function removeBlackHole(npc, hole)
	if not hole or not hole.Parent or not npc["B_Beat"] then
		return
	end

	local ti_0 = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	npc.B_Beat:Disconnect()

	assets.Sounds.BlackHole.TimePosition = 7
	assets.Sounds.BlackHole:Play()

	util.tween(hole.Weakspot, ti_0, { Size = Vector3.zero })
	util.tween(hole.EventHorizon, ti_0, { Size = Vector3.zero })
	util.tween(hole.PhotonSphere, ti_0, { Size = Vector3.zero })
	util.tween(hole.AccretionDisk, ti_0, { Size = Vector3.zero }, true)

	hole:Destroy()

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character or not character:FindFirstChild("BlackholePull") then
			continue
		end

		character.BlackholePull:Destroy()
	end

	timer.wait(1)
	npc.Acts:removeAct("InAttack", "inAction", "Blackhole")
end

local function shootRock(npc, i)
	local npcCFrame = npc.Instance:GetPivot()
	local newRock = effects.RockProjectile:Clone()
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Back)

	newRock.Parent = workspace
	util.PlaySound(util.getRandomChild(rockUp), newRock)

	local origin = npcCFrame * CFrame.Angles(0, math.rad(25 * -i), 0)

	newRock:PivotTo(origin * CFrame.new(0, -8, -8))

	util.tween(newRock, ti, { CFrame = newRock.CFrame * CFrame.new(0, 8, 0) }, true)

	newRock.ChargedLaser.Enabled = true

	timer.wait(0.8)
	Debris:AddItem(newRock, 3)

	newRock.ChargedLaser.Enabled = false

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { npc.Instance }

	local newRay = workspace:Spherecast(newRock.Position, 2, newRock.CFrame.LookVector * 300, rp)

	if not newRay then
		return
	end

	newRock.Position = newRay.Position
	newRock.ParticleEmitter.Enabled = false
	newRock.Transparency = 1
	newRock.Explode:Emit(100)

	util.PlaySound(util.getRandomChild(rockHits), newRock)

	local part = newRay.Instance
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	humanoid:TakeDamage(4)
end

local function ShowCatwalks(_, bossRoom)
	local ti = TweenInfo.new(0.3)

	if not bossRoom:GetAttribute("CatsOut") then
		for _, catwalk in ipairs(bossRoom.CatWalks:GetChildren()) do
			util.tween(catwalk.PrimaryPart, ti, { CFrame = catwalk.PrimaryPart.CFrame * CFrame.new(0, -70, 0) })
		end
	end

	bossRoom:SetAttribute("CatsOut", true)
	catTimer.Function = function()
		for _, catwalk in ipairs(bossRoom.CatWalks:GetChildren()) do
			util.tween(
				catwalk.PrimaryPart,
				ti,
				{ CFrame = catwalk.PrimaryPart.CFrame * CFrame.new(0, 70, 0) },
				false,
				function()
					bossRoom:SetAttribute("CatsOut", false)
				end
			)
		end
	end

	catTimer:Cancel()
	catTimer:Run()
end

local function createPillars(npc)
	local ti = TweenInfo.new(0.3)

	for _ = 1, 6 do
		local newPillar = effects.RockPillar:Clone()
		newPillar.Parent = workspace
		newPillar.Position = npc.Instance:GetPivot().Position
			+ Vector3.new(math.random(-50, 50), -15, math.random(-50, 50))

		util.tween(newPillar, ti, { Position = newPillar.Position + Vector3.new(0, 20, 0) })
		util.PlaySound(util.getRandomChild(rockUp), newPillar)

		task.delay(6.5, function()
			newPillar.CanCollide = false
			newPillar.CanQuery = false
			newPillar.CanTouch = false
			newPillar.Transparency = 1
			newPillar.Explode:Emit(100)

			Debris:AddItem(newPillar, 2)
			util.PlaySound(util.getRandomChild(rockHits), newPillar)
		end)
	end
end

local moves = {
	BlackHole = function(npc)
		npc.Acts:createAct("InAttack", "inAction", "Blackhole")

		local newBlackHole: Model = assets.Effects["Black Hole"]:Clone()

		newBlackHole:AddTag("Enemy")
		newBlackHole:PivotTo(npc.Instance:GetPivot() * CFrame.new(0, 15, 0))

		local size = 0.9

		newBlackHole.Weakspot.Size = Vector3.zero
		newBlackHole.EventHorizon.Size = Vector3.zero
		newBlackHole.PhotonSphere.Size = Vector3.zero
		newBlackHole.AccretionDisk.Size = Vector3.zero

		assets.Sounds.BlackHole.TimePosition = 0
		assets.Sounds.BlackHole:Play()

		timer.wait(1)

		local pullPower = 0.4

		local lastDamage = os.clock()

		npc.B_Beat = RunService.Heartbeat:Connect(function()
			for _, player in ipairs(Players:GetPlayers()) do -- pull enemies
				local character = player.Character
				if not character then
					continue
				end

				local distance = (character:GetPivot().Position - newBlackHole:GetPivot().Position).Magnitude
				if distance < 15 and os.clock() - lastDamage >= 0.5 then
					local humanoid = character:FindFirstChild("Humanoid")

					if humanoid and npc:GetState() ~= "Dead" then
						humanoid:TakeDamage(1)
						lastDamage = os.clock()
					end
				end

				local direction = newBlackHole:GetPivot().Position - character:GetPivot().Position

				if character:FindFirstChild("BlackholePull") then
					character.BlackholePull.VectorVelocity = direction * pullPower
					continue
				end

				local velocityObject = createImpulse(character, pullPower, direction, 5.75)
				velocityObject.Name = "BlackholePull"
			end
		end)

		npc.Janitor:Add(npc.B_Beat)

		newBlackHole.Parent = workspace

		local ti = TweenInfo.new(2, Enum.EasingStyle.Quint)

		util.tween(newBlackHole.Weakspot, ti, { Size = Vector3.one * (13.427 * size) })
		util.tween(newBlackHole.EventHorizon, ti, { Size = Vector3.one * (11.682 * size) })
		util.tween(newBlackHole.PhotonSphere, ti, { Size = Vector3.one * (11.888 * size) })
		util.tween(newBlackHole.AccretionDisk, ti, { Size = Vector3.new(43.248, 19.212, 43.248) * size })

		newBlackHole.Humanoid.HealthChanged:Connect(function(health)
			if health > 0 then
				return
			end
			removeBlackHole(npc, newBlackHole)
		end)

		timer.wait(5.5)

		removeBlackHole(npc, newBlackHole)
	end,

	GravityPattern = function(npc)
		attackPlayer(npc)
	end,

	ShootRocks = function(npc)
		npc.Acts:createAct("InAttack", "inAction")

		for i = -6, 6, 1 do
			task.spawn(shootRock, npc, i)
		end

		npc.Instance.Humanoid.WalkSpeed = 6

		local animation =
			animationService:playAnimation(npc.Instance, "PullAttack", Enum.AnimationPriority.Action4.Value)
		animation.Ended:Once(function()
			npc.Acts:removeAct("InAttack", "inAction")
			npc.Instance.Humanoid.WalkSpeed = 0.1
		end)
	end,

	GroundElectrify = function(npc)
		if npc.Acts:checkAct("InElectrify") then
			return
		end

		npc.Acts:createAct("InAttack", "inAction", "InElectrify")

		animationService:playAnimation(npc.Instance, "SlamAttack", Enum.AnimationPriority.Action3)

		local newGround = effects.ElectricSmoke:Clone()
		newGround.Parent = workspace
		newGround.Position = npc.Instance:GetPivot().Position + Vector3.new(0, -4, 0)

		vfx:FireAllClients("ElectrifyPart", "Server", true, newGround)

		timer.wait(0.25)

		-- pillars

		local bossRoom = workspace.Map:FindFirstChild("MiniBossRoom_2")

		if bossRoom then
			ShowCatwalks(npc, bossRoom)
		else
			createPillars(npc)
		end

		timer.wait(0.85)

		local lastDamage = os.clock()

		local electricSound = util.PlaySound(assets.Sounds.Electricity, ReplicatedStorage)

		local connection = RunService.Heartbeat:Connect(function()
			local getPartsHit = workspace:GetPartBoundsInBox(newGround.CFrame, newGround.Size)

			for _, part in ipairs(getPartsHit) do
				local model = part:FindFirstAncestorOfClass("Model")
				if not model or not Players:GetPlayerFromCharacter(model) then
					continue
				end

				if os.clock() - lastDamage < 0.25 or npc:GetState() == "Dead" then
					continue
				end
				model.Humanoid:TakeDamage(1)

				lastDamage = os.clock()
			end
		end)
		npc.Janitor:Add(connection)

		npc.Acts:removeAct("InAttack", "inAction")

		timer.wait(5)

		npc.Acts:removeAct("InElectrify")

		if connection and connection.Connected then
			connection:Disconnect()
		end

		util.tween(electricSound, TweenInfo.new(1), { Volume = 0 }, false, function()
			electricSound:Stop()
		end)

		Debris:AddItem(newGround, 5)
	end,
}

local function getTimer(npc, timerName)
	local foundTimer = npc.Timers[timerName]

	if not foundTimer then
		npc.Timers[timerName] = npc.Timer:new(timerName)
		return npc.Timers[timerName]
	end

	return foundTimer
end

local function diedExit()
	--mapService.exitMiniBoss()
end

local function runAttackTimer(npc)
	if npc.Acts:checkAct("Run", "InAttack", "Melee") then
		return
	end

	local AttackTimer = getTimer(npc, "Special")

	AttackTimer.WaitTime = rng:NextNumber(2, 4)
	AttackTimer.Function = function()
		if npc.StatusEffects["Ice"] then
			return
		end

		for _, value in ipairs(moveChances) do
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
	getHumanoid:MoveTo(position)
end

local function onDied(npc)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			if BadgeService:AwardBadge(player.UserId, 2888864866950727) then
				net:RemoteEvent("DoUiAction"):FireAllClients("Notify", "AchievementUnlocked", true, 2888864866950727)
			end
		end)
	end

	removeBlackHole(npc)
	net:RemoteEvent("StopMusic"):FireAllClients("Specimen #09")
	timer.wait(1)
	net:RemoteEvent("DoUiAction"):FireAllClients("BossIntro", "ShowCompleted", true, npc.Instance.Name)
	net:RemoteEvent("DoUiAction"):FireAllClients("HUD", "HideBossBar", true)
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
		local positionToLookAt = targetPosition + targetVelocity / 2.5
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
		--{ Function = "LeadTarget", Parameters = { true, stats.LeadCompensation, 0, true } },
		{ Function = "Custom", Parameters = { runAttackTimer } },
		{ Function = "Custom", Parameters = { lead } },

		{ Function = "GetToDistance", Parameters = { stats.AttackDistance, true } },

		{ Function = "PlayWalkingAnimation" },
	},

	AtDistance = {
		{
			Function = "Custom",
			Parameters = { grabPlayer },
		},

		Parameters = { 15 },
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
