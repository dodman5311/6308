local BadgeService = game:GetService("BadgeService")
local CollectionService = game:GetService("CollectionService")
local AnalyticsService = game:GetService("AnalyticsService")
local rng = Random.new()

local HttpService = game:GetService("HttpService")
funnelSessionId = HttpService:GenerateGUID()

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local spawners = require(Globals.Server.Services.Spawners)
local net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)
local timer = require(Globals.Vendor.Timer)

local vfx = net:RemoteEvent("ReplicateEffect")
local createProjectileRemote = net:RemoteEvent("CreateProjectile")
local doUiAction = net:RemoteEvent("DoUiAction")

local moveChances = {
	{ "Acid", 10 },

	{ "Sacrifice", 20 },
	{ "Geysers", 25 },

	{ "Grenades", 30 },
	{ "Fire", 45 },
	{ "Rockets", 100 },
}

local patterns = {
	{ -- straight bars
		Vector2.new(0, 1),
		Vector2.new(0, -1),
		Vector2.new(1, 0),
		Vector2.new(-1, 0),

		Vector2.new(0, 0.75),
		Vector2.new(0, -0.75),
		Vector2.new(0.75, 0),
		Vector2.new(-0.75, 0),

		Vector2.new(0, 0.5),
		Vector2.new(0, -0.5),
		Vector2.new(0.5, 0),
		Vector2.new(-0.5, 0),

		Vector2.new(0, 0.25),
		Vector2.new(0, -0.25),
		Vector2.new(0.25, 0),
		Vector2.new(-0.25, 0),
	},

	{ -- diagonal bars
		Vector2.new(0.25, 0.25),
		Vector2.new(0.5, 0.5),
		Vector2.new(0.75, 0.75),

		Vector2.new(-0.25, -0.25),
		Vector2.new(-0.5, -0.5),
		Vector2.new(-0.75, -0.75),

		Vector2.new(0.25, -0.25),
		Vector2.new(0.5, -0.5),
		Vector2.new(0.75, -0.75),

		Vector2.new(-0.25, 0.25),
		Vector2.new(-0.5, 0.5),
		Vector2.new(-0.75, 0.75),
	},

	{ -- circle
		Vector2.new(1, 0.75),
		Vector2.new(1, 0.25),
		Vector2.new(1, 0),
		Vector2.new(1, -0.25),
		Vector2.new(1, -0.75),

		Vector2.new(-1, 0.75),
		Vector2.new(-1, 0.25),
		Vector2.new(-1, 0),
		Vector2.new(-1, -0.25),
		Vector2.new(-1, -0.75),

		Vector2.new(0.75, 1),
		Vector2.new(0.25, 1),
		Vector2.new(0, 1),
		Vector2.new(-0.25, 1),
		Vector2.new(-0.75, 1),

		Vector2.new(0.75, -1),
		Vector2.new(0.25, -1),
		Vector2.new(0, 1),
		Vector2.new(-0.25, -1),
		Vector2.new(-0.75, -1),

		Vector2.new(0.75, 0.75),
		Vector2.new(-0.75, 0.75),
		Vector2.new(0.75, -0.75),
		Vector2.new(-0.75, -0.75),
	},

	{ -- close circle... kinda
		Vector2.new(1, 0.5),
		Vector2.new(1, 0.15),
		Vector2.new(1, 0),
		Vector2.new(1, -0.15),
		Vector2.new(1, -0.5),

		Vector2.new(-1, 0.5),
		Vector2.new(-1, 0.15),
		Vector2.new(-1, 0),
		Vector2.new(-1, -0.15),
		Vector2.new(-1, -0.5),

		Vector2.new(0.5, 1),
		Vector2.new(0.15, 1),
		Vector2.new(0, 1),
		Vector2.new(-0.15, 1),
		Vector2.new(-0.5, 1),

		Vector2.new(0.15, -1),
		Vector2.new(0.25, -1),
		Vector2.new(0, 1),
		Vector2.new(-0.15, -1),
		Vector2.new(-0.5, -1),

		Vector2.new(0.5, 0.5),
		Vector2.new(-0.5, 0.5),
		Vector2.new(0.5, -0.5),
		Vector2.new(-0.5, -0.5),
	},
}

local closePattern = {
	Vector2.new(0.175, 0),
	Vector2.new(0.175, 0.1),
	Vector2.new(0.175, -0.1),

	Vector2.new(-0.175, 0),
	Vector2.new(-0.175, 0.1),
	Vector2.new(-0.175, -0.1),

	Vector2.new(0, 0.175),
	Vector2.new(0.1, 0.175),
	Vector2.new(-0.1, 0.175),

	Vector2.new(0, -0.175),
	Vector2.new(0.1, -0.175),
	Vector2.new(-0.1, -0.175),

	Vector2.new(0.15, 0.15),
	Vector2.new(-0.15, -0.15),
	Vector2.new(0.15, -0.15),
	Vector2.new(-0.15, 0.15),
}

local function dealDamage(npc, humanoid, amount)
	if npc:GetState() == "Dead" then
		return
	end

	humanoid:TakeDamage(amount)
end

local function indicateAttack(npc, color)
	net:RemoteEvent("ReplicateEffect"):FireAllClients("IndicateVisageAttack", "Server", true, npc.Instance, color)
	timer.wait(0.5)
end

local function doForBarrels(npc, callback)
	for _, barrel in ipairs(npc.Instance.Apature:GetChildren()) do
		if barrel.Name ~= "Barrel" then
			continue
		end

		callback(barrel)
	end
end

local function MoveApatureTo(npc, yAlpha, rotationAngle, speed)
	local root = npc.Instance.PrimaryPart

	if speed then
		npc.Instance.Apature.AlignPosition.MaxVelocity = speed
	else
		npc.Instance.Apature.AlignPosition.MaxVelocity = 2500
	end

	if yAlpha then
		local yPos = (yAlpha * (75 * 2)) - 75
		root.ApatureRoot.Position = Vector3.new(0, yPos, 0)
	end

	if rotationAngle then
		root.ApatureRoot.Orientation = Vector3.new(0, rotationAngle, 0)
	end
end

local function shootFireHitboxes(npc)
	doForBarrels(npc, function(barrel)
		local origin = barrel.Attachment.WorldCFrame

		local newPart = game.ReplicatedStorage.FireHitbox:Clone()
		newPart.Parent = workspace

		newPart.Position = origin.Position
		local goal = origin * CFrame.new(0, 0, -170)

		Debris:AddItem(newPart, 2)

		table.insert(npc.fireHitboxes, {
			part = newPart,
			startPosition = origin.Position,
			startSize = newPart.Size,
			goal = goal.Position,
			createdAt = os.clock(),
		})
	end)
end

local function processHitboxes(npc)
	for index, hitbox in ipairs(npc.fireHitboxes) do
		local t = os.clock() - hitbox.createdAt

		hitbox.part.Position = hitbox.startPosition:Lerp(hitbox.goal, t / 1.5)
		hitbox.part.Size = hitbox.startSize:Lerp(Vector3.new(20, 50, 50), t / 1.5)

		if t >= 1.5 then
			hitbox.part:Destroy()
			table.remove(npc.fireHitboxes, index)
		end
	end
end

local function checkHitboxes(npc)
	local playersHit = {}

	for _, hitbox in ipairs(npc.fireHitboxes) do
		local part = hitbox.part

		if not part then
			continue
		end

		for _, partHit in ipairs(workspace:GetPartsInPart(part)) do
			local humanoid, model = util.checkForHumanoid(partHit)

			local playerHit = Players:GetPlayerFromCharacter(model)

			if not playerHit or table.find(playersHit, playerHit) then
				continue
			end

			dealDamage(npc, humanoid, 1)

			table.insert(playersHit, playerHit)
		end
	end
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

local function checkGeyserHitboxes(npc)
	local modelsHit = {}

	for _, hitbox in ipairs(CollectionService:GetTagged("GeyserHitbox")) do
		for _, partHit in ipairs(workspace:GetPartsInPart(hitbox)) do
			local humanoid, model = util.checkForHumanoid(partHit)

			-- local playerHit = Players:GetPlayerFromCharacter(model)

			-- if not playerHit or table.find(playersHit, playerHit) then
			-- 	continue
			-- end

			if hitbox:HasTag("Launching") then
				local modPos = model:GetPivot().Position
				local subPos = npc.Instance:GetPivot().Position
				local posNy = Vector3.new(subPos.X, modPos.Y, subPos.Z)

				local impulseDirection = (CFrame.lookAt(posNy, modPos + Vector3.new(0, 20, 0))).LookVector -- (subject.PrimaryPart.CFrame * CFrame.Angles(math.rad(25), 0, 0)).LookVector
				createImpulse(model, 100, impulseDirection, 0.1)
			end

			dealDamage(npc, humanoid, 1)

			table.insert(modelsHit, model)
		end
	end
end

local function RunGeyserCheck(npc)
	local geyserTimer = npc:GetTimer("GeyserTimer")

	geyserTimer.WaitTime = 0.25
	geyserTimer.Function = checkGeyserHitboxes
	geyserTimer.Parameters = { npc }
	geyserTimer:Run()
end

local function rotateForFire(npc)
	local startTime = os.clock()
	local lastStep = os.clock()
	local alpha = 0
	local hitBoxAlpha = 0

	local raiseTime = 10
	local rotateTime = 2.75

	npc.fireHitboxes = {}

	return RunService.Heartbeat:Connect(function()
		if npc:GetState() == "Dead" then
			timer:getTimer("VisageFireWaiting"):Destroy()
			return
		end

		local currentTime = os.clock() - startTime
		local step = os.clock() - lastStep

		alpha += step / raiseTime
		hitBoxAlpha += step

		MoveApatureTo(npc, alpha, (currentTime * 90) / rotateTime)

		if alpha >= 0.5 then
			alpha = -0.05
		end

		processHitboxes(npc)

		if hitBoxAlpha >= 0.075 then
			hitBoxAlpha = 0
			shootFireHitboxes(npc)
			checkHitboxes(npc)
		end

		lastStep = os.clock()
	end)
end

local function aimYAxisAtPlayer(npc)
	return RunService.Heartbeat:Connect(function()
		local target = npc:GetTarget()
		if not target then
			return
		end

		local root = npc.Instance.PrimaryPart

		local xyP = root.ApatureRoot.WorldPosition * Vector3.new(1, 0, 1)
		local npcPos2 = npc.Instance:GetPivot().Position * Vector3.new(1, 0, 1)
		local targetPos2 = target:GetPivot().Position * Vector3.new(1, 0, 1)

		local targetDistance = (npcPos2 - targetPos2).Magnitude

		root.ApatureRoot.WorldPosition = xyP
			+ Vector3.new(0, (target:GetPivot().Position.Y - 5) + (targetDistance / 3), 0)
	end)
end

local function createGeyserAt(npc, indicateTime, Position, launchTarget)
	--local target = npc:GetTarget()
	local model = npc.Instance

	local ti = TweenInfo.new(indicateTime, Enum.EasingStyle.Linear)

	-- if not target then
	-- 	return
	-- end

	local newGeyser = ReplicatedStorage.Assets.Effects.GeyserAttack:Clone()
	newGeyser.Parent = workspace

	local targetPosition = Position * Vector3.new(1, 0, 1)

	newGeyser:PivotTo(CFrame.new(targetPosition + Vector3.new(0, model:GetPivot().Position.Y - 5, 0)))

	util.tween(newGeyser.Area, ti, { Size = Vector3.new(305.65, 0, 0) })
	timer.wait(ti.Time)

	newGeyser.GeyserPart.Explosion:Play()
	newGeyser.GeyserPart.Water:Play()

	newGeyser.Area.Transparency = 1

	newGeyser.Hitbox:AddTag("GeyserHitbox")

	if launchTarget then
		newGeyser.Hitbox:AddTag("Launching")
	end

	vfx:FireAllClients("ShowParticleFor", "Server", true, newGeyser.GeyserPart, 5)
	timer.wait(5)

	newGeyser.GeyserPart.Water:Stop()
	newGeyser.Hitbox:Destroy()
	Debris:AddItem(newGeyser, 5)
end

local function togglePlatforms(direction)
	local room = workspace.Map:FindFirstChild("BossRoom_2")

	if not room then
		return
	end

	for _, platform in ipairs(room.RoomModel:GetChildren()) do
		if platform.Name ~= "Platform" then
			continue
		end

		local logPos = platform:GetPivot()

		task.spawn(function()
			for i = 0, 1, 0.05 do
				task.wait(0.025)
				platform:PivotTo(logPos:Lerp(logPos * CFrame.new(0, 11 * direction, 0), i))
			end
		end)
	end
end

local moves = {
	Fire = function(npc)
		local model = npc.Instance

		npc.Acts:createAct("InAction")

		MoveApatureTo(npc, 0, 0)

		indicateAttack(npc, Color3.fromRGB(255, 175, 100))

		util.PlaySound(model.PrimaryPart.Fire, model.PrimaryPart)

		vfx:FireAllClients("VisageFire", "Server", true, npc.Instance, true)
		local rotateOnStep = rotateForFire(npc)

		npc.Janitor:Add(rotateOnStep, "Disconnect")

		timer.wait(15, "VisageFireWaiting")

		vfx:FireAllClients("VisageFire", "Server", true, npc.Instance, false)
		rotateOnStep:Disconnect()

		timer.wait(2)

		MoveApatureTo(npc, 0, 0)

		npc.Acts:removeAct("InAction")
	end,

	Rockets = function(npc)
		local model = npc.Instance

		npc.Acts:createAct("InAction")

		indicateAttack(npc, Color3.fromRGB(255, 150, 150))

		MoveApatureTo(npc, 0.8, 0, 250)
		timer.wait(2)

		for i = 1, 5 do
			if npc:GetState() == "Dead" then
				break
			end

			util.PlaySound(model.PrimaryPart.Launch, model.PrimaryPart, 0.1)

			doForBarrels(npc, function(barrel)
				barrel.Attachment.Flash:Emit(3)
				barrel.Attachment.Smoke:Emit(3)

				createProjectileRemote:FireAllClients(200, barrel.Attachment.WorldCFrame, 0, 1, 5, 0, {
					Seeking = rng:NextNumber(0.5, 1),
					SeekProgression = -0.025,
					SplashRange = 12,
					SplashDamage = 5,
					SeekDistance = 9000,
					Size = 0,
				}, nil, "RocketProjectile")
			end)

			timer.wait(0.5)
			MoveApatureTo(npc, nil, i * 90)
			timer.wait(1)
		end

		timer.wait(2)

		MoveApatureTo(npc, 0, 0)

		npc.Acts:removeAct("InAction")
	end,

	Grenades = function(npc)
		local target = npc:GetTarget()

		if not target then
			return
		end

		local model = npc.Instance

		npc.Acts:createAct("InAction")

		local aimOnStep = aimYAxisAtPlayer(npc)

		indicateAttack(npc, Color3.fromRGB(230, 100, 255))

		npc.Janitor:Add(aimOnStep, "Disconnect")

		local offset = false
		for _ = 1, 10 do
			if npc:GetState() == "Dead" then
				break
			end

			local npcPos2 = model:GetPivot().Position * Vector3.new(1, 0, 1)
			local targetPos2 = target:GetPivot().Position * Vector3.new(1, 0, 1)

			local targetDistance = (npcPos2 - targetPos2).Magnitude

			util.PlaySound(model.PrimaryPart.Launch, model.PrimaryPart, 0.1)

			doForBarrels(npc, function(barrel)
				barrel.Attachment.Flash:Emit(3)
				barrel.Attachment.Smoke:Emit(3)

				createProjectileRemote:FireAllClients(
					targetDistance / 1.5,
					barrel.Attachment.WorldCFrame,
					0,
					0,
					1.5,
					0,
					{
						Dropping = 0.65,
						Bouncing = true,
						SplashRange = 50,
						SplashDamage = 6,
					},
					nil,
					"GrenadeProjectile"
				)
			end)

			MoveApatureTo(npc, nil, offset and 0 or 45)

			offset = not offset

			timer.wait(1.25)
		end

		timer.wait(1)

		MoveApatureTo(npc, 0, 0)
		aimOnStep:Disconnect()
		npc.Acts:removeAct("InAction")
	end,

	Geysers = function(npc)
		npc.Acts:createAct("InAction")

		net:RemoteEvent("ReplicateEffect")
			:FireAllClients("IndicateAttack", "Server", true, npc.Instance.Torso, Color3.fromRGB(183, 95, 255))
		timer.wait(0.5)

		if npc:GetState() == "Dead" then
			return
		end

		-- for i = 5, 1, -1 do
		-- 	task.spawn(createGeyserAtPlayerPosition, npc, i / 10)
		-- 	timer.wait(1)
		-- end

		local pattern = patterns[math.random(1, #patterns)]
		local npcCframe = npc.Instance:GetPivot()

		for _, offset in ipairs(pattern) do
			local cframe = npcCframe * CFrame.new(offset.X * 150, 0, offset.Y * 150)

			task.spawn(createGeyserAt, npc, 0.5, cframe.Position)
		end

		timer.wait(0.5)

		npc.Acts:removeAct("InAction")
	end,

	Sacrifice = function(npc)
		local enemies = CollectionService:GetTagged("Enemy")

		if #enemies <= 1 or workspace:GetAttribute("GamePaused") then
			return
		end

		npc.Acts:createAct("InAction")
		npc.Instance.Humanoid:SetAttribute("Invincible", true)

		npc.Instance.PrimaryPart.Shield_1.Enabled = true
		npc.Instance.PrimaryPart.Shield_2.Enabled = true

		for _, enemy in ipairs(enemies) do
			if enemy.Name == "Visage Of False Hope" or enemy.Humanoid.Health >= 60 then
				continue
			end

			local cframe = enemy:GetPivot()
			enemy:Destroy()

			local rp = RaycastParams.new()
			rp.FilterDescendantsInstances = { workspace.Map }
			rp.FilterType = Enum.RaycastFilterType.Include
			local upcast = workspace:Raycast(cframe.Position, CFrame.new(0, 0, 0).UpVector * 100, rp)

			if upcast then
				warn("upcast caught")
				continue
			end

			spawners.placeNewObject(1000, cframe, "Enemy", "Betrayed")
		end

		repeat
			timer.wait(0.5)
			npc.Instance.Humanoid.Health += 1
		until not workspace:FindFirstChild("Betrayed", true)

		timer.wait(1)

		npc.Instance.PrimaryPart.Shield_1.Enabled = false
		npc.Instance.PrimaryPart.Shield_2.Enabled = false

		npc.Instance.Humanoid:SetAttribute("Invincible", false)
		npc.Acts:removeAct("InAction")
	end,

	Acid = function(npc)
		local model = npc.Instance

		if npc.Acts:checkAct("AcidAttack") then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			doUiAction:FireClient(
				player,
				"Notify",
				"ShowTip",
				[[<font color="#FF7800">GO UP</font>, PG! Gotta avoid that acid!]],
				true,
				player:GetAttribute("furthestLevel") <= 10.5
			)
		end

		togglePlatforms(1)

		npc.Acts:createAct("AcidAttack")

		--local riseTween = TweenInfo.new(2, Enum.EasingStyle.Linear)
		local layers = model.AcidLayers

		local logPos = layers:GetPivot()

		net:RemoteEvent("ReplicateEffect")
			:FireAllClients("IndicateAttack", "Server", true, npc.Instance.Torso, Color3.fromRGB(110, 255, 105))
		timer.wait(0.5)

		ReplicatedStorage.Assets.Sounds.Alarm:Play()

		Lighting.Ambient = Color3.new(1)

		for _, v in ipairs(CollectionService:GetTagged("VisageRoomLight")) do
			v.Color = Color3.new(1)
		end

		timer.wait(2)

		local startPos = layers:GetPivot()
		local endGoal = model:FindFirstChild("AcidStage3"):GetPivot()

		layers.PartA.Bubbles:Play()

		for i = 0, 1, 0.001 do
			timer.wait(0.012)

			layers:PivotTo(startPos:Lerp(endGoal, i))

			if npc:GetState() == "Dead" or not npc.Instance.Parent then
				Lighting.Ambient = Color3.fromRGB(125, 125, 125)
				break
			end
		end

		if npc:GetState() ~= "Dead" or not npc.Instance.Parent then
			timer.wait(6)
		else
			Lighting.Ambient = Color3.fromRGB(125, 125, 125)
		end

		local startPos = layers:GetPivot()

		for i = 0, 1, 0.001 do
			timer.wait(0.001)

			layers:PivotTo(startPos:Lerp(logPos, i))

			if npc:GetState() == "Dead" or not npc.Instance.Parent then
				Lighting.Ambient = Color3.fromRGB(125, 125, 125)
				break
			end
		end

		layers.PartA.Bubbles:Stop()
		togglePlatforms(-1)

		Lighting.Ambient = Color3.fromRGB(125, 125, 125)
		for _, v in ipairs(CollectionService:GetTagged("VisageRoomLight")) do
			v.Color = Color3.fromRGB(255, 228, 121)
		end

		task.wait(1)

		npc.Acts:removeAct("AcidAttack")
	end,
}

local function spawnEnemy(OriginCFrame)
	local spawnRangeX = rng:NextInteger(100, 60)
	local spawnRangeZ = rng:NextInteger(100, 60)

	local enemyToSpawn = "Tollsman"

	if rng:NextNumber(0, 100) <= 10 then
		enemyToSpawn = "Specimen"
	elseif rng:NextNumber(0, 100) <= 50 then
		enemyToSpawn = "Sentinel"
	end

	local spawnCFrame = OriginCFrame
		* CFrame.new(rng:NextInteger(-spawnRangeX, spawnRangeX), 2, rng:NextInteger(-spawnRangeZ, spawnRangeZ))

	local enemyModel = spawners.placeNewObject(10, spawnCFrame, "Enemy", enemyToSpawn).Instance

	if not enemyModel then
		return
	end

	net:RemoteEvent("ReplicateEffect"):FireAllClients("EnemySpawned", "Server", true, spawnCFrame.Position)
end

local function runAttackTimer(npc)
	npc.Instance.PrimaryPart.Anchored = true

	if npc.Acts:checkAct("Run", "InAttack", "Melee") then
		return
	end

	local AttackTimer = npc:GetTimer(npc, "Special")

	AttackTimer.WaitTime = rng:NextNumber(2, 4)
	AttackTimer.Function = function()
		if npc.StatusEffects["Ice"] then
			return
		end

		for _, value in ipairs(moveChances) do
			if rng:NextNumber(0, 100) > value[2] then
				continue
			end

			if not npc.Acts:checkAct("InAction") then
				moves[value[1]](npc)
			end

			return
		end
	end
	AttackTimer.Parameters = { npc }

	AttackTimer:Run()
end

local function spawnEnemies(npc) -- 250 studs
	local origin = npc.Instance:GetPivot()

	local spawnTimer = npc:GetTimer("SpawnEnemies")

	spawnTimer.WaitTime = 7
	spawnTimer.Function = function()
		if #CollectionService:GetTagged("Enemy") > 8 or workspace:FindFirstChild("Betrayed", true) then
			return
		end

		spawnEnemy(origin)
	end

	spawnTimer.Parameters = { npc }

	spawnTimer:Run()
end
-- local function setUp(npc)

local function closeAttack(npc)
	local target = npc:GetTarget()
	local model = npc.Instance

	if not target or npc.Acts:checkAct("CloseAttack") then
		return
	end

	local playerPosition = target:GetPivot().Position * Vector3.new(1, 0, 1)
	local npcPosition = model:GetPivot().Position * Vector3.new(1, 0, 1)

	local distance = (playerPosition - npcPosition).Magnitude

	if distance > 35 then
		return
	end

	npc.Acts:createAct("CloseAttack")

	local npcCframe = model:GetPivot()

	for _, offset in ipairs(closePattern) do
		local cframe = npcCframe * CFrame.new(offset.X * 150, 0, offset.Y * 150)

		task.spawn(createGeyserAt, npc, 0.25, cframe.Position, true)
	end

	timer.wait(5)

	npc.Acts:removeAct("CloseAttack")
end

local function onDied(npc)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			if BadgeService:AwardBadge(player.UserId, 1970850586708568) then
				net:RemoteEvent("DoUiAction"):FireAllClients("Notify", "AchievementUnlocked", 1970850586708568)
			end
		end)

		AnalyticsService:LogFunnelStepEvent(player, "VisageFight", funnelSessionId, 2, "Fight Ended", {
			[Enum.AnalyticsCustomFieldKeys.CustomField01] = player.Character:GetAttribute("HasHaven") and "Has Haven"
				or "No Haven",
			[Enum.AnalyticsCustomFieldKeys.CustomField02] = "Won",
		})
	end

	for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
		if enemy.Name == npc.Instance.Name then
			continue
		end
		enemy:Destroy()
	end

	local primaryPart = npc.Instance.PrimaryPart

	net:RemoteEvent("StopMusic"):FireAllClients(npc.Instance.Name)

	if primaryPart and primaryPart:FindFirstChild("Death") then
		npc.Instance.PrimaryPart.Death:Play()
	end

	task.delay(24.5, function()
		npc.Instance.PrimaryPart.Thanks:Play()

		local thanks = npc.Instance.Head.ThankYou

		local ti = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local ti_0 = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
		local ti_1 = TweenInfo.new(0.75, Enum.EasingStyle.Linear)

		thanks.Enabled = true

		util.tween(thanks, ti, { SizeOffset = Vector2.new(0, 2) })
		util.tween(thanks.TextLabel.UIStroke, ti_0, { Transparency = 0 })
		util.tween(thanks.TextLabel, ti_0, { TextTransparency = 0 }, false, function()
			task.wait(0.25)
			util.tween(thanks.TextLabel.UIStroke, ti_1, { Transparency = 1 })
			util.tween(thanks.TextLabel, ti_1, { TextTransparency = 1 })
		end)

		task.wait(2.5)
		vfx:FireAllClients("emitObject", "Server", true, npc.Instance.PrimaryPart.Explode)

		npc.Instance.PrimaryPart.Crack:Play()
		npc.Instance.PrimaryPart.Transparency = 1

		task.wait(3)

		net:RemoteEvent("DoUiAction"):FireAllClients("BossIntro", "ShowCompleted", "Visage Of False Hope")
		net:RemoteEvent("DoUiAction"):FireAllClients("HUD", "HideBossBar")
	end)
end

local function setUp(npc)
	npc.Instance.Apature:PivotTo(CFrame.new(npc.Instance:GetPivot().Position))

	for _, player in ipairs(Players:GetPlayers()) do
		AnalyticsService:LogFunnelStepEvent(player, "VisageFight", funnelSessionId, 1, "Fight Began", {
			[Enum.AnalyticsCustomFieldKeys.CustomField01] = player.Character:GetAttribute("HasHaven") and "Has Haven"
				or "No Haven",
		})

		player.Character.Destroying:Connect(function()
			AnalyticsService:LogFunnelStepEvent(player, "VisageFight", funnelSessionId, 2, "Fight Ended", {
				[Enum.AnalyticsCustomFieldKeys.CustomField01] = player.Character:GetAttribute("HasHaven")
						and "Has Haven"
					or "No Haven",
				[Enum.AnalyticsCustomFieldKeys.CustomField02] = "Lost",
			})
		end)
	end
end

-- end

local module = {
	OnStep = {
		{ Function = "Custom", Parameters = { closeAttack } },
		{ Function = "Custom", Parameters = { RunGeyserCheck } },
		{ Function = "Custom", Parameters = { spawnEnemies } },
		{ Function = "Custom", Parameters = { runAttackTimer } },
		{ Function = "SearchForTarget", Parameters = { math.huge } },
	},

	OnSpawned = {
		{ Function = "Custom", Parameters = { setUp } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Custom", Parameters = { onDied } },
	},
}

return module
