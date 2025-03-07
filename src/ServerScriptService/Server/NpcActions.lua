local module = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local map = workspace.Map

--// Modules
local Util = require(Globals.Vendor.Util)
local AnimationService = require(Globals.Vendor.AnimationService)
local Net = require(Globals.Packages.Net)

--// Values

local enemiesInCombat = {}

local createProjectileRemote = Net:RemoteEvent("CreateProjectile")
local vfx = Net:RemoteEvent("ReplicateEffect")
local rng = Random.new()
local canFear = false

--// Library Functions

local function getNumber(input: number | NumberRange)
	if typeof(input) == "NumberRange" then
		return rng:NextNumber(input.Min, input.Max)
	end

	return input
end

local function unpackNpcInstance(npc)
	return npc.Instance, npc.Instance:FindFirstChild("Humanoid")
end

local function getObject(class, parent)
	local foundInstance = parent:FindFirstChildOfClass(class)
	if not foundInstance then
		foundInstance = Instance.new(class)
		foundInstance.Parent = parent
	end
	return foundInstance
end

local function lookAtPostition(npc, position: Vector3, includeY: boolean, doLerp: boolean, lerpAlpha: number)
	local subject = npc.Instance
	local subjectPos = subject:GetPivot().Position
	local newVector = Vector3.new(position.X, subjectPos.Y, position.Z)
	if includeY then
		newVector = position
	end
	local goal = CFrame.lookAt(subjectPos, newVector)

	local Align = getObject("AlignOrientation", subject.PrimaryPart)
	Align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	Align.RigidityEnabled = true
	Align.AlignType = Enum.AlignType.Parallel

	Align.Attachment0 = getObject("Attachment", subject.PrimaryPart)

	if doLerp then
		Align.CFrame = Align.CFrame:Lerp(goal, lerpAlpha)
	else
		Align.CFrame = goal
	end
end

local function getNearest(npc, maxDistance)
	local targetType = npc.Instance:GetAttribute("TargetType")

	local getList = {}
	if targetType == "Player" then
		for _, player in ipairs(Players:GetPlayers()) do
			table.insert(getList, player.Character)
		end

		for _, player in ipairs(CollectionService:GetTagged("Commrad")) do
			table.insert(getList, player)
		end
	else
		getList = CollectionService:GetTagged(targetType)
	end

	local closestDistance, closestModel = math.huge
	for _, model in ipairs(getList) do
		if model == npc.Instance then
			continue
		end
		local humanoid = model:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 or humanoid:GetAttribute("Invisible") then
			continue
		end

		local distance = (npc.Instance:GetPivot().Position - model:GetPivot().Position).Magnitude
		if distance > maxDistance or distance > closestDistance then
			continue
		end
		closestDistance = distance
		closestModel = model
	end

	return closestModel, closestDistance
end

local function checkSightLine(npc, target)
	if npc.Instance:GetAttribute("Blind") then
		return false
	end

	local rp = RaycastParams.new()

	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }

	local position = npc.Instance:GetPivot().Position
	local targetPosition = target:GetPivot().Position

	return not workspace:Raycast(position, targetPosition - position, rp)
end

local function MoveToRandomPosition(npc, MaxDistance, onStep)
	local npcPosition = npc.Instance:GetPivot().Position
	local PositonToMoveTo = npcPosition
		+ Vector3.new(rng:NextNumber(-MaxDistance, MaxDistance), 0, rng:NextNumber(-MaxDistance, MaxDistance))

	module.MoveTowardsPoint(npc, PositonToMoveTo, onStep)
end

local function getTimer(npc, timerName, waitTime, func, isAttackTimer, ...)
	local foundTimer = npc.Timers[timerName]

	if not foundTimer then
		waitTime = getNumber(waitTime)

		foundTimer = npc.Timer:new(timerName, waitTime, func, ...)
		npc.Timers[timerName] = foundTimer
		table.insert(npc.Timers[timerName].Parameters, 1, npc)

		if isAttackTimer then
			local oldFunction = foundTimer.Function

			foundTimer.Function = function()
				if module.CheckFear(npc) then
					return
				end

				oldFunction(table.unpack(foundTimer.Parameters))
			end
		end
	end

	return foundTimer
end

function module.CheckFear(npc)
	local target = npc:GetTarget()

	if not target then
		return
	end

	local player = Players:GetPlayerFromCharacter(target)
	if not player then
		return
	end

	local chance

	if canFear then
		chance = Net:RemoteFunction("CheckChance"):InvokeClient(player, 15, true)

		if chance then
			Net:RemoteEvent("DoUiAction"):FireClient(player, "Notify", "ShowFeared", npc.Instance)
		end

		return chance
	end

	if npc.StatusEffects["Electricity"] then
		chance = Net:RemoteFunction("CheckChance"):InvokeClient(player, 50, true)

		return chance
	end

	if npc.StatusEffects["Ice"] then
		return true
	end
end

--// NPC ACTIONS //--

function module.RunTimer(npc, timerName, waitTime, func, isAttackTimer, ...)
	local timer = getTimer(npc, timerName, waitTime, func, isAttackTimer, ...)
	timer:Run()
	return timer
end

function module.Ragdoll(npc)
	local character = npc.Instance

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Name ~= "Motor6D" then
			local socket = Instance.new("BallSocketConstraint")
			local a1 = Instance.new("Attachment")
			local a2 = Instance.new("Attachment")
			a1.Parent = descendant.Part0
			a2.Parent = descendant.Part1
			socket.Parent = descendant.Parent
			socket.Attachment0 = a1
			socket.Attachment1 = a2
			a1.CFrame = descendant.C0
			a2.CFrame = descendant.C1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			descendant.Enabled = false
		end
	end
end

function module.SetCollision(npc, groupName)
	for _, part in ipairs(npc.Instance:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end
		part.CollisionGroup = groupName
	end
end

function module.AddTag(npc, Tag)
	npc.Instance:AddTag(Tag)

	if Tag == "Commrad" then
		npc.Instance:SetAttribute("TargetType", "Enemy")
	else
		npc.Instance:SetAttribute("TargetType", "Player")
	end
end

function module.MoveToRandomUnit(npc)
	if npc.Path.Status == "Idle" then
		local getUnit = Util.getRandomChild(workspace.Map)
		--local point = getUnit:GetPivot().Position

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { map }

		local origin = getUnit:GetPivot()
		local raycast = workspace:Raycast(origin.Position, origin.UpVector * -200, rp)

		if raycast then
			local distanceToPoint = (npc.Instance:GetPivot().Position - raycast.Position).Magnitude

			if distanceToPoint > 6000 then
				return
			end

			npc.MovingToPoint = raycast.Position
		end
	end

	module.MoveTowardsPoint(npc, npc.MovingToPoint, true)

	-- if npc.Acts:checkAct("OnPath") then
	-- 	return
	-- end

	-- local getUnit = Util.getRandomChild(map)

	-- local rp = RaycastParams.new()
	-- rp.FilterType = Enum.RaycastFilterType.Whitelist
	-- rp.FilterDescendantsInstances = { map }

	-- local origin = getUnit:GetPivot()
	-- local raycast = workspace:Raycast(origin.Position, origin.UpVector * -200, rp)

	-- if not raycast then
	-- 	return
	-- end

	-- npc.Acts:createAct("OnPath")

	-- local point = raycast.Position

	-- module.MoveTowardsPoint(npc, point, false)
end

function module.AddStatToNpc(npc, name, value)
	npc[name] = value
end

function module.PlayWalkingAnimation(npc)
	local subject, humanoid = unpackNpcInstance(npc)
	if not subject.PrimaryPart then
		return
	end
	local primaryPart = subject.PrimaryPart
	local moving = primaryPart.AssemblyLinearVelocity.Magnitude >= 0.1 --humanoid.WalkSpeed - 1

	if moving and humanoid.FloorMaterial ~= Enum.Material.Air then
		AnimationService:playAnimation(subject, "Walk", Enum.AnimationPriority.Movement, true)
	else
		AnimationService:stopAnimation(subject, "Walk")
	end
end

function module.LogParameter(npc, paramName)
	local humanoid = npc.Instance:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	npc[paramName] = humanoid[paramName]
end

function module.PlayAnimation(npc, animationName, priority, noReplay, ...)
	AnimationService:playAnimation(npc.Instance, animationName, priority, noReplay, ...)
end

function module.IndicateAttack(npc, color)
	Net:RemoteEvent("ReplicateEffect"):FireAllClients("IndicateAttack", "Server", true, npc.Instance, color)
end

local function createProjectile(speed, cframe, spread, info, modelName, sender)
	createProjectileRemote:FireAllClients(speed, cframe, spread, nil, nil, nil, info, sender, modelName)
end

local function createHitCast(npc, damage, cframe, distance, spread, size)
	Net:RemoteEvent("CreateBeam"):FireAllClients(npc.Instance, damage, cframe, distance, spread, size)
end

function module.Shoot(npc, sender, cooldown, amount, speed, bulletCount, info, visualModel, indicateAttack, timerIndex)
	cooldown = getNumber(cooldown)
	amount = getNumber(amount)
	speed = getNumber(speed)
	bulletCount = getNumber(bulletCount)

	if npc:GetState() == "Dead" then
		return
	end

	if indicateAttack then
		AnimationService:playAnimation(npc.Instance, "Indicate", Enum.AnimationPriority.Action3)
		module.IndicateAttack(npc, indicateAttack)
		task.wait(indicateAttack)
	end

	if typeof(amount) == "table" then
		amount = math.random(amount.Min, amount.Max)
	end

	if not bulletCount then
		bulletCount = 1
	end

	for _ = 1, amount do
		if npc:GetState() == "Dead" then
			return
		end

		local castingFrame
		local endPosition
		local projectileCframe
		local soundName = "Attack"

		if timerIndex == "SpecialAttackSnd" then
			soundName = "Special"
		end

		AnimationService:playAnimation(npc.Instance, "Attack", Enum.AnimationPriority.Action3)
		if npc.Instance.PrimaryPart:FindFirstChild(soundName) then
			Util.PlaySound(npc.Instance.PrimaryPart[soundName], npc.Instance.PrimaryPart, 0.15)
		end

		local npcCframe = npc.Instance:GetPivot()
		local origin = npcCframe * CFrame.new(0, 0, -1)

		if npc.Instance.PrimaryPart:FindFirstChild("FirePoint") then
			origin = npc.Instance.PrimaryPart.FirePoint.WorldCFrame
		end

		if npc.MindData.AimCFrame then
			castingFrame = npc.MindData.AimCFrame
		else
			castingFrame = npcCframe
		end

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { npc.Instance }
		local raycast = workspace:Raycast(npcCframe.Position, castingFrame.LookVector * 500, params)

		if raycast then
			endPosition = raycast.Position
		else
			endPosition = (castingFrame * CFrame.new(0, 0, -500)).Position
		end

		projectileCframe = CFrame.lookAt(origin.Position, endPosition)

		for _ = 1, bulletCount do
			createProjectile(speed, projectileCframe, bulletCount - 1, info, visualModel, sender)
		end

		task.wait(cooldown)
	end
end

function module.ShootBeam(npc, damage, chargeTime, distance, bulletCount, size)
	chargeTime = getNumber(chargeTime)
	bulletCount = getNumber(bulletCount)
	distance = getNumber(distance)

	if npc:GetState() == "Dead" then
		return
	end

	if not bulletCount then
		bulletCount = 1
	end

	local primaryPart = npc.Instance.PrimaryPart
	local attackSound = primaryPart:FindFirstChild("ChargedAttack")
	local chargeSound = primaryPart:FindFirstChild("ChargeUp")
	local laser = primaryPart:FindFirstChild("ChargedLaser")
	local Beam = primaryPart:FindFirstChild("ChargedBeam")

	AnimationService:playAnimation(npc.Instance, "ChargedAttack", Enum.AnimationPriority.Action3)

	if laser then
		laser.Enabled = true
	end

	if chargeSound then
		chargeSound:Play()
	end

	local beamTimer = getTimer(npc, "RemoveBeam")

	beamTimer.WaitTime = 0.1
	beamTimer.Function = function()
		if not Beam then
			return
		end

		for i = 0.5, 1, 0.05 do
			task.wait(0.05)
			Beam.Transparency = NumberSequence.new(i)
		end

		Beam.Enabled = false
	end

	task.wait(chargeTime)

	if laser then
		laser.Enabled = false
	end

	if Beam then
		Beam.Enabled = true
		Beam.Transparency = NumberSequence.new(0)
		beamTimer:Run()
	end

	if attackSound then
		attackSound:Play()
	end

	local cframe

	if npc.MindData.AimCFrame then
		cframe = npc.MindData.AimCFrame
	else
		cframe = npc.Instance:GetPivot()
	end

	for _ = 1, bulletCount do
		createHitCast(npc, damage, cframe, distance, bulletCount - 1, size)
	end
end

local function swing(npc, distance, stopMovement)
	if npc:GetState() == "Dead" then
		return
	end

	distance = getNumber(distance)

	--AnimationService:stopAnimation(npc.Instance, "Attack", 0)
	local animation = AnimationService:playAnimation(npc.Instance, "Attack", Enum.AnimationPriority.Action3)
	if animation and stopMovement then
		npc.Instance.PrimaryPart.Anchored = true
		animation.Stopped:Once(function()
			npc.Instance.PrimaryPart.Anchored = false
		end)
	end

	if npc.Instance.PrimaryPart:FindFirstChild("Attack") then
		npc.Instance.PrimaryPart.Attack:Play()
	end

	local cframe

	if npc.MindData.AimCFrame then
		cframe = npc.MindData.AimCFrame
	else
		cframe = npc.Instance:GetPivot()
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { npc }
	raycastParams.CollisionGroup = "NpcBullet"

	local shapecast = workspace:Spherecast(cframe.Position, 2, cframe.LookVector * distance, raycastParams)

	if not shapecast then
		return
	end

	local hitHumanoid = Util.checkForHumanoid(shapecast.Instance)

	if not hitHumanoid then
		return
	end
	hitHumanoid:TakeDamage(1)
end

function module.ShootProjectile(
	npc,
	shotDelay,
	cooldown,
	amount,
	speed,
	bulletCount,
	info,
	visualModel,
	timerIndex,
	indicateAttack
)
	if npc.Instance:GetAttribute("State") ~= "Attacking" then
		return
	end

	local AttackTimer = getTimer(
		npc,
		timerIndex or "ShootAttack",
		shotDelay,
		module.Shoot,
		true,
		npc.Instance,
		cooldown,
		amount,
		speed,
		bulletCount,
		info,
		visualModel,
		indicateAttack,
		timerIndex
	)

	AttackTimer.OnEnded:Once(function()
		AttackTimer.WaitTime = getNumber(shotDelay)
	end)
	AttackTimer:Run()
end

function module.ShootWithoutTimer(npc, cooldown, amount, speed, bulletCount, info, visualModel, indicateAttack)
	if npc.Instance:GetAttribute("State") ~= "Attacking" or npc.MindData["CantShoot"] then
		return false
	end

	npc.MindData.CantShoot = true -- return event required
	module.Shoot(npc, npc.Instance, cooldown, amount, speed, bulletCount, info, visualModel, indicateAttack)
	return true
end

function module.ShootPlayerProjectile(
	npc,
	shotDelay,
	cooldown,
	amount,
	speed,
	bulletCount,
	info,
	visualModel,
	timerIndex
)
	if npc.Instance:GetAttribute("State") ~= "Attacking" then
		return
	end

	local AttackTimer = getTimer(
		npc,
		timerIndex or "ShootAttack",
		shotDelay,
		module.Shoot,
		true,
		Players:FindFirstChildOfClass("Player"),
		cooldown,
		amount,
		speed,
		bulletCount,
		info,
		visualModel
	)

	AttackTimer.OnEnded:Once(function()
		AttackTimer.WaitTime = getNumber(shotDelay)
	end)
	AttackTimer:Run()
end

function module.ShootCharge(npc, shotDelay, damage, chargeTime, distance, bulletCount, amount, cooldown, size)
	if npc.Instance:GetAttribute("State") ~= "Attacking" then
		return
	end

	local AttackTimer = getTimer(npc, "ChargedAttack", shotDelay, function()
		for _ = 1, amount or 1 do
			module.ShootBeam(npc, damage, chargeTime, distance, bulletCount, size)
			task.wait(cooldown or 0)
		end
	end, true)

	AttackTimer.OnEnded:Once(function()
		AttackTimer.WaitTime = getNumber(shotDelay)
	end)
	AttackTimer:Run()
end

function module.AttackInMelee(npc, distance, swingDelay, stopMovement)
	if npc.Instance:GetAttribute("State") ~= "Attacking" then
		return
	end

	local AttackTimer = getTimer(npc, "MeleeAttack", swingDelay, swing, true, distance, stopMovement)

	AttackTimer.OnEnded:Once(function()
		AttackTimer.WaitTime = getNumber(swingDelay)
	end)
	AttackTimer:Run()
end

function module.MoveRandom(npc, MaxDistance, delay)
	local MoveTimer = getTimer(npc, "MoveRandom", delay, MoveToRandomPosition, false, MaxDistance)
	MoveTimer.OnEnded:Once(function()
		MoveTimer.WaitTime = getNumber(delay)
	end)
	MoveTimer:Run()
end

function module.GetToDistance(npc, desiredDistance, onStep)
	local target = npc.Target.Value
	if not target then
		return
	end

	local targetPosition = target:GetPivot().Position

	local distance = (npc.Instance:GetPivot().Position - targetPosition).Magnitude

	if distance <= desiredDistance then
		return
	end

	module.MoveTowardsPoint(npc, targetPosition, onStep)
end

function module.MoveAwayFromDistance(npc, desiredDistance, onStep)
	local target = npc.Target.Value
	if not target then
		return
	end

	local targetPosition = target:GetPivot().Position
	local npcPosition = npc.Instance:GetPivot().Position
	local goalPosition = npcPosition + (npcPosition - targetPosition)

	local distance = (npcPosition - goalPosition).Magnitude

	if distance >= desiredDistance then
		return
	end

	module.MoveTowardsPoint(npc, goalPosition, onStep)
end

function module.MoveTowardsTarget(npc, target, onStep)
	if not target then
		target = npc.Target.Value
		if not target then
			return
		end
	end

	local goal = target:GetPivot().Position

	module.MoveTowardsPoint(npc, goal, onStep)
end

function module.MoveTowardsPoint(npc, point, onStep)
	if not npc.Instance.Parent or not npc.Instance.PrimaryPart or not point then
		return
	end

	if onStep then
		pcall(function()
			npc.Path:Run(point)
		end)
		return
	end

	local startState = npc:GetState()

	npc.Janitor:Add(
		npc.Path.Blocked:Connect(function()
			npc.Path:Run(point)
		end),
		"Disconnect",
		"Pathfinding"
	)

	npc.Janitor:Add(
		npc.Path.WaypointReached:Connect(function()
			npc.Path:Run(point)
		end),
		"Disconnect",
		"Pathfinding"
	)

	npc.Janitor:Add(
		npc.Path.Error:Connect(function()
			npc.Acts:removeAct("OnPath")
			npc.Janitor:Remove("Pathfind")

			if startState == "Chasing" and npc:IsState("Chasing") then
				module.SwitchToState(npc, "Idle")
			end
		end),
		"Disconnect",
		"Pathfinding"
	)

	npc.Janitor:Add(
		npc.Path.Reached:Connect(function()
			npc.Acts:removeAct("OnPath")
			npc.Janitor:Remove("Pathfind")

			if startState == "Chasing" and npc:IsState("Chasing") then
				module.SwitchToState(npc, "Idle")
			end
		end),
		"Disconnect",
		"Pathfinding"
	)

	pcall(function()
		npc.Path:Run(point)
	end)
end

function module.MoveInfrontOfHarbinger(npc)
	if not npc.MindData.HarbingerToProtect then
		return
	end

	local point = (npc.MindData.HarbingerToProtect:GetPivot() * CFrame.new(0, 0, -10)).Position

	module.MoveTowardsPoint(npc, point, true)
end

function module.SwitchToState(npc, state)
	npc.Instance:SetAttribute("State", state)

	if state ~= "Idle" and state ~= "Dead" and not table.find(enemiesInCombat, npc) then
		table.insert(enemiesInCombat, npc)
		workspace:SetAttribute("EnemiesInCombat", #enemiesInCombat)

		return
	end

	local getEnemyIndex = table.find(enemiesInCombat, npc)
	if getEnemyIndex then
		table.remove(enemiesInCombat, getEnemyIndex)
		workspace:SetAttribute("EnemiesInCombat", #enemiesInCombat)
	end
end

function module.SearchForTarget(npc, maxDistance)
	local target, distance = getNearest(npc, maxDistance)
	if not target or not checkSightLine(npc, target) then
		target = nil
	end

	npc["Target"].Value = target

	if target ~= nil then
		npc["LastTarget"] = target
	end

	return target, distance
end

function module.LookAtTarget(npc, includeY, doLerp, lerpAlpha)
	local target = npc.Target.Value
	if not target then
		return
	end

	local position = target:GetPivot().Position

	lookAtPostition(npc, position, includeY, doLerp, lerpAlpha)
end

function module.AimAtTarget(npc, doLerp, lerpAlpha)
	local target = npc.Target.Value
	if not target then
		return
	end

	local position = target:GetPivot().Position

	npc.MindData.AimCFrame = CFrame.lookAt(npc.Instance:GetPivot().Position, position)
end

function module.LeadTarget(npc, shotSpeed, randomness, ignoreDistance)
	local target = npc.Target.Value
	if not target then
		return
	end

	local position = target:GetPivot().Position
	local distance = 1

	if not ignoreDistance then
		distance = (position - npc.Instance:GetPivot().Position).Magnitude
	end

	if not randomness then
		randomness = 0
	end

	local randomVector = Vector3.new(
		rng:NextNumber(-randomness, randomness),
		rng:NextNumber(-randomness, randomness),
		rng:NextNumber(-randomness, randomness)
	)

	if not npc.StatusEffects["Electricity"] then
		position += ((target.PrimaryPart.AssemblyLinearVelocity * (distance / shotSpeed)) * 1.5) + randomVector
	else
		position += randomVector
	end

	npc.MindData.AimCFrame = CFrame.lookAt(npc.Instance:GetPivot().Position, position)

	if npc.Instance.PrimaryPart:FindFirstChild("ChargedAttachment") then
		npc.Instance.PrimaryPart.ChargedAttachment.WorldCFrame = npc.MindData.AimCFrame * CFrame.new(0, 0, -250)
	end
	--lookAtPostition(npc, position, includeY)
	return position
end

function module.RemoveWithDelay(npc, delay, doFade)
	if doFade then
		vfx:FireAllClients("fadeEnemy", "Server", true, npc.Instance, delay - 0.05)
	end

	task.delay(delay, function()
		npc.Instance:Destroy()
	end)
end

function module.SetLeader(npc, leader)
	npc["Leader"] = leader
end

function module.Custom(npc, func, ...)
	return func(npc, ...)
end

--// Main //--

Net:Connect("GiftAdded", function(_, gift)
	if gift == "Sierra_6308" then
		canFear = true

		workspace:SetAttribute("CanFear", true)
	end
end)

Net:Connect("GiftRemoved", function(_, gift)
	if gift == "Sierra_6308" then
		canFear = false

		workspace:SetAttribute("CanFear", false)
	end
end)

return module
