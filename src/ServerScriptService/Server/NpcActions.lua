local module = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local map = workspace.Map

--// Modules
local Timer = require(Globals.Vendor.Timer)
local Spring = require(Globals.Vendor.Spring)
local Util = require(Globals.Vendor.Util)
local AnimationService = require(Globals.Vendor.AnimationService)
local Net = require(Globals.Packages.Net)

--// Values

local createProjectileRemote = Net:RemoteEvent("CreateProjectile")
local rng = Random.new()

--// Library Functions

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

local function getNearest(npc, maxDistance, entityType)
	local getList = {}
	if entityType == "Player" then
		for _, player in ipairs(Players:GetPlayers()) do
			table.insert(getList, player.Character)
		end
	else
		getList = CollectionService:GetTagged(entityType)
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

--// NPC ACTIONS //--

function module.AddTag(npc, Tag)
	npc.Instance:AddTag(Tag)
end

function module.MoveToRandomUnit(npc)
	-- local distanceToPoint = npc["MovingToPoint"] and (npc.Instance:GetPivot().Position - npc.MovingToPoint).Magnitude
	-- 	or 0
	--distanceToPoint <= 25 or
	if npc.Path.Status == "Idle" then
		local getUnit = Util.getRandomChild(workspace.Map)
		--local point = getUnit:GetPivot().Position

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Whitelist
		rp.FilterDescendantsInstances = { map }

		local origin = getUnit:GetPivot()
		local raycast = workspace:Raycast(origin.Position, origin.UpVector * -200, rp)

		if raycast then
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

function module.PlayAnimation(npc, animationName, priority, noReplay, ...)
	AnimationService:playAnimation(npc.Instance, animationName, priority, noReplay, ...)
end

local function createProjectile(speed, cframe, spread)
	createProjectileRemote:FireAllClients(speed, cframe, spread)
end

local function Shoot(npc, cooldown, amount, speed, bulletCount)
	if typeof(amount) == "table" then
		amount = math.random(amount.Min, amount.Max)
	end

	if not bulletCount then
		bulletCount = 1
	end

	task.spawn(function()
		for _ = 1, amount do
			if npc:GetState() == "Dead" then
				return
			end

			AnimationService:playAnimation(npc.Instance, "Attack", Enum.AnimationPriority.Action3)
			if npc.Instance.PrimaryPart:FindFirstChild("Attack") then
				npc.Instance.PrimaryPart.Attack:Play()
			end

			local cframe = npc.Instance:GetPivot() * CFrame.new(0, 0, -1)

			for _ = 1, bulletCount do
				createProjectile(speed, cframe, bulletCount - 1)
			end

			task.wait(cooldown)
		end
	end)
end

function module.ShootProjectile(npc, shotDelay, cooldown, amount, speed, bulletCount)
	if npc.Instance:GetAttribute("State") ~= "Attacking" then
		return
	end

	local AttackTimer = npc.Timers.Attack

	AttackTimer.WaitTime = shotDelay
	AttackTimer.Function = Shoot
	AttackTimer.Parameters = { npc, cooldown, amount, speed, bulletCount }

	AttackTimer:Run()
end

local function swing(npc, distance, stopMovement)
	if npc:GetState() == "Dead" then
		return
	end

	local animation = AnimationService:playAnimation(npc.Instance, "Attack", Enum.AnimationPriority.Action3)
	if animation and stopMovement then
		task.spawn(function()
			npc.Instance.PrimaryPart.Anchored = true
			animation.Stopped:Wait()
			npc.Instance.PrimaryPart.Anchored = false
		end)
	end

	if npc.Instance.PrimaryPart:FindFirstChild("Attack") then
		npc.Instance.PrimaryPart.Attack:Play()
	end

	local cframe = npc.Instance:GetPivot()

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { npc }
	raycastParams.CollisionGroup = "Npcs"

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

function module.AttackInMelee(npc, distance, swingDelay, stopMovement)
	if npc.Instance:GetAttribute("State") ~= "Attacking" then
		return
	end

	local AttackTimer = npc.Timers.Attack

	AttackTimer.WaitTime = swingDelay
	AttackTimer.Function = swing
	AttackTimer.Parameters = { npc, distance, stopMovement }

	AttackTimer:Run()
end

function module.MoveRandom(npc, MaxDistance, delay)
	local MoveTimer = npc.Timers.MoveRandom

	MoveTimer.WaitTime = delay
	MoveTimer.Function = MoveToRandomPosition
	MoveTimer.Parameters = { npc, MaxDistance }

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
		end),
		"Disconnect",
		"Pathfinding"
	)

	npc.Janitor:Add(
		npc.Path.Reached:Connect(function()
			npc.Acts:removeAct("OnPath")
			npc.Janitor:Remove("Pathfind")
		end),
		"Disconnect",
		"Pathfinding"
	)

	pcall(function()
		npc.Path:Run(point)
	end)
end

function module.SwitchToState(npc, state)
	npc.Instance:SetAttribute("State", state)
end

function module.SearchForTarget(npc, targetType, maxDistance)
	local target, distance = getNearest(npc, maxDistance, targetType)
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

function module.LeadTarget(npc, includeY, shotSpeed, randomness)
	local target = npc.Target.Value
	if not target then
		return
	end

	local position = target:GetPivot().Position
	local distance = (position - npc.Instance:GetPivot().Position).Magnitude

	local randomVector = Vector3.new(
		rng:NextNumber(-randomness, randomness),
		rng:NextNumber(-randomness, randomness),
		rng:NextNumber(-randomness, randomness)
	)
	position += ((target.PrimaryPart.AssemblyLinearVelocity * (distance / shotSpeed)) * 1.5) + randomVector

	lookAtPostition(npc, position, includeY)
end

function module.RemoveWithDelay(npc, delay)
	task.delay(delay, function()
		npc.Instance:Destroy()
	end)
end

--// Main //--

return module
