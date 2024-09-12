local module = {}

--// Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local Enemies = ReplicatedStorage.Enemies

local Behaviors = Globals.Server.NpcBehaviors

--//Values
local NpcEvents = {}
local onBeat = {}
local Npcs = {}

local rng = Random.new()

--// Modules
local NpcActions = require(Globals.Server.NpcActions)
local SimplePath = require(Globals.Packages.SimplePath)
local Acts = require(Globals.Vendor.Acts)
local Timer = require(Globals.Vendor.Timer)
local AnimationService = require(Globals.Vendor.AnimationService)
local janitor = require(Globals.Packages.Janitor)

local net = require(Globals.Packages.Net)
local lessHealth = false
local hampterMode = false

--local onHeartbeat = Signals["NpcHeartbeat"]
local beats = {}

local isPaused = false

local onHeartbeat = {
	Connect = function(_, callback)
		table.insert(beats, callback)

		return {
			Disconnect = function()
				table.remove(beats, table.find(beats, callback))
			end,
		}
	end,
}

--// Functions

local function makeEnemyHampter(enemy)
	if not enemy.PrimaryPart then
		return
	end

	local newHampterPart = ReplicatedStorage.Hampter:Clone()
	newHampterPart.Parent = enemy
	local weld = Instance.new("Weld")
	weld.Parent = newHampterPart
	weld.Part0 = enemy.PrimaryPart
	weld.Part1 = newHampterPart

	for _, part in ipairs(enemy:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.Transparency = 1
	end
end

function module.enableHampterMode()
	hampterMode = true

	for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
		makeEnemyHampter(enemy)
	end
end

local function unpackNpcInstance(npc)
	return npc.Instance, npc.Instance:FindFirstChild("Humanoid")
end

local function doActions(npc, actions, ...)
	for _, action in ipairs(actions) do
		if action.State and not npc:IsState(action.State) then
			continue
		end

		if action.NotState and npc:IsState(action.NotState) then
			continue
		end

		if not NpcActions[action.Function] then
			warn("There is no NPC action by the name of ", action.Function)
			continue
		end

		local function doAction(...)
			local result = NpcActions[action.Function](npc, ...)
			if not action.ReturnEvent then
				return
			end

			NpcEvents[action.ReturnEvent](npc, npc.Behavior[action.ReturnEvent], result)
		end

		local parameters = {}

		if action.Parameters then
			for _, parameter in ipairs(action.Parameters) do
				if typeof(parameter) == "table" and parameter["Min"] and parameter["Max"] then
					parameter = rng:NextNumber(parameter["Min"], parameter["Max"])
				end

				table.insert(parameters, parameter)
			end
		end

		if not action["IgnoreEventParams"] then
			for _, parameter in ipairs({ ... }) do
				table.insert(parameters, parameter)
			end
		end

		task.spawn(doAction, table.unpack(parameters))
	end
end

function NpcEvents.OnStep(npc, actions)
	local func = function()
		doActions(npc, actions)
	end

	onBeat = onHeartbeat:Connect(func)
	npc.Janitor:Add(onBeat, "Disconnect")

	return onBeat
end

function NpcEvents.TargetFound(npc, actions)
	local function action(target)
		if not target then
			return
		end

		doActions(npc, actions, target)
	end

	return npc.Target.Changed:Connect(action)
end

function NpcEvents.TargetLost(npc, actions)
	local function action(target)
		if target then
			return
		end

		doActions(npc, actions, npc["LastTarget"])
	end

	return npc.Target.Changed:Connect(action)
end

function NpcEvents.InCloseRange(npc, actions, closeDistance)
	local subject = npc.Instance

	local func = function()
		if not npc.Target.Value then
			return
		end

		local closeDistance = closeDistance or 10
		local distance = (subject:GetPivot().Position - npc.Target.Value:GetPivot().Position).Magnitude

		if distance > closeDistance then
			return
		end

		doActions(npc, actions)
	end

	onBeat = onHeartbeat:Connect(func)
	npc.Janitor:Add(onBeat, "Disconnect")

	return onBeat
end

function NpcEvents.OnSpawned(npc, actions)
	doActions(npc, actions)
end

function NpcEvents.OnDied(npc, actions)
	local _, humanoid = unpackNpcInstance(npc)

	humanoid.Died:Connect(function()
		doActions(npc, actions)
	end)
end

function NpcEvents.OnDamaged(npc, actions)
	local _, humanoid = unpackNpcInstance(npc)

	local logHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if logHealth > health then
			doActions(npc, actions, health)
		end

		logHealth = health
	end)
end

function module:GetNpcFromModel(model)
	for _, npc in ipairs(Npcs) do
		if npc.Instance == model then
			return npc
		end
	end
end

function module.new(NPCType)
	local newModel = Enemies:FindFirstChild(NPCType, true)
	if not newModel then
		warn("Could not find an NPC by the type of ", NPCType)
		return
	end

	newModel = newModel:Clone()
	newModel:AddTag("Npc")

	local humanoid = newModel:WaitForChild("Humanoid")

	for _, part in ipairs(newModel:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end
		part.CollisionGroup = "Npcs"
	end

	local Npc = {
		Type = NPCType,
		Instance = newModel,
		Behavior = nil,

		Path = SimplePath.new(newModel),
		Acts = Acts:new(),
		Timer = Timer:newQueue(),
		Target = nil,
		Janitor = janitor:new(),

		Timers = {},
		Connections = {},
		StatusEffects = {},
	}

	Npc.Janitor:LinkToInstance(Npc.Instance, true)
	Npc.Janitor:LinkToInstance(Npc.Instance.PrimaryPart, true)

	Npc.Janitor:Add(humanoid.Died:Once(function()
		Npc.Janitor:Cleanup()
	end, "Disconnect"))

	Npc.Janitor:Add(function()
		table.remove(Npcs, table.find(Npcs, Npc))

		NpcActions.SwitchToState(Npc, "Dead")

		Npc.Acts:removeAllActs()
		Npc.Timer:DestroyAll()
	end, true)

	function Npc:SetUpAttributes()
		local subject = self.Instance

		local targetValue = Instance.new("ObjectValue")
		targetValue.Name = "Target"
		targetValue.Parent = subject
		self.Target = targetValue

		subject:SetAttribute("State", "Idle")
	end

	function Npc:GetBehavior()
		local behavior = Behaviors:FindFirstChild(self.Type)
		if not behavior then
			return
		end

		self.Behavior = require(behavior)

		for _, foundModule in ipairs(self.Instance:GetDescendants()) do -- run misc modules
			if not foundModule:IsA("ModuleScript") then
				continue
			end

			local required = require(foundModule)
			required.npc = self

			if not required["OnSpawned"] then
				continue
			end
			required.OnSpawned()
		end

		return self.Behavior
	end

	function Npc:Run()
		self:SetUpAttributes()

		if Npc.Instance:FindFirstChild("Animations") then
			AnimationService:loadAnimations(Npc.Instance, Npc.Instance.Animations)
		end

		for eventName, actions in pairs(self.Behavior) do
			if not NpcEvents[eventName] then
				warn("There is no NPC event by the name of ", eventName)
				continue
			end

			local params
			if actions["Parameters"] then
				params = table.unpack(actions["Parameters"])
			end

			local result = NpcEvents[eventName](self, actions, params)
			if not result then
				continue
			end

			table.insert(self.Connections, result)
		end

		if lessHealth and humanoid.MaxHealth > 1 then
			humanoid.MaxHealth = math.clamp(math.floor(humanoid.MaxHealth - 1), 1, math.huge)
			humanoid.Health = humanoid.MaxHealth
		end
	end

	function Npc:Place(position) -- will place into the world without running
		self.Instance.Parent = workspace

		if typeof(position) == "Vector3" then
			self.Instance:PivotTo(CFrame.new(position + Vector3.new(0, 2.5, 0)))
		else
			self.Instance:PivotTo(position * CFrame.new(0, 2.5, 0))
		end

		return self.Instance
	end

	function Npc:Spawn(position) -- will place into the world and run
		self:Place(position)
		self:Run()

		if hampterMode then
			makeEnemyHampter(self.Instance)
		end

		return self.Instance
	end

	function Npc:IsState(state)
		return self.Instance:GetAttribute("State") == state
	end

	function Npc:GetState()
		return self.Instance:GetAttribute("State")
	end

	function Npc:Exists()
		local subject = self.Instance
		return subject and subject.Parent and subject.PrimaryPart and subject.PrimaryPart.Parent
	end

	function Npc:GetTarget()
		local targetValue = self.Instance:FindFirstChild("Target")
		if not targetValue then
			return
		end

		local target = targetValue.Value

		return target
	end

	function Npc:GetTimer(timerName)
		local foundTimer = self.Timers[timerName]

		if not foundTimer then
			self.Timers[timerName] = self.Timer:new(timerName)
			return self.Timers[timerName]
		end

		return foundTimer
	end

	Npc:GetBehavior()

	table.insert(Npcs, Npc)

	return Npc
end

--// Main //--

RunService.Heartbeat:Connect(function()
	for _, action in ipairs(beats) do
		if isPaused then
			return
		end
		action()
	end
end)

net:Connect("PauseGame", function()
	isPaused = true

	for _, Npc in ipairs(Npcs) do
		if Npc.Instance.Parent and Npc.Instance.PrimaryPart then
			Npc.Instance.PrimaryPart.Anchored = true
		end

		local animations = AnimationService:getLoadedAnimations(Npc.Instance)
		if not animations then
			continue
		end
		for _, anim in pairs(animations) do
			anim:AdjustSpeed(0)
		end
	end
end)

net:Connect("ResumeGame", function()
	for _, Npc in ipairs(Npcs) do
		if
			Npc.Instance.Parent
			and Npc.Instance.PrimaryPart
			and not Npc.StatusEffects["Ice"]
			and not Npc.Instance:HasTag("IsAnchored")
		then
			Npc.Instance.PrimaryPart.Anchored = false
		end

		local animations = AnimationService:getLoadedAnimations(Npc.Instance)
		if not animations or Npc.StatusEffects["Ice"] then
			continue
		end
		for _, anim in pairs(animations) do
			anim:AdjustSpeed(1)
		end
	end

	isPaused = false
end)

net:Connect("GiftAdded", function(player, gift)
	if gift ~= "“Do you like hurting?”" then
		return
	end

	lessHealth = true

	for _, Npc in ipairs(Npcs) do
		local humanoid = Npc.Instance:WaitForChild("Humanoid")
		if not humanoid then
			return
		end

		if humanoid.MaxHealth > 1 then
			humanoid.MaxHealth = math.clamp(math.floor(humanoid.MaxHealth - 1), 1, math.huge)

			if humanoid.Health > humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end
end)

net:Connect("GiftRemoved", function(player, gift)
	if gift ~= "“Do you like hurting?”" then
		return
	end
	lessHealth = false
end)

return module
