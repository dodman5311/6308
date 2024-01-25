local module = {}

--// Services
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local Enemies = ServerStorage.Enemies

local Behaviors = Globals.Server.NpcBehaviors

--//Values
local NpcEvents = {}
local onBeat = {}

local rng = Random.new()

--// Modules
local Signals = require(Globals.Shared.Signals)
local NpcActions = require(Globals.Server.NpcActions)
local SimplePath = require(Globals.Packages.SimplePath)
local Acts = require(Globals.Vendor.Acts)
local Timer = require(Globals.Vendor.Timer)
local AnimationService = require(Globals.Vendor.AnimationService)
local janitor = require(Globals.Packages.Janitor)

--local onHeartbeat = Signals["NpcHeartbeat"]
local beats = {}

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
local function unpackNpcInstance(npc)
	return npc.Instance, npc.Instance:FindFirstChild("Humanoid")
end

local function doActions(npc, actions, ...)
	for _, action in ipairs(actions) do
		if action.State and not npc:IsState(action.State) then
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

		for _, parameter in ipairs({ ... }) do
			table.insert(parameters, parameter)
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

function module:new(NPCType)
	local newModel = Enemies:FindFirstChild(NPCType, true)
	if not newModel then
		warn("Could not find an NPC by the type of ", NPCType)
		return
	end

	newModel = newModel:Clone()
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
	}

	Npc.Janitor:LinkToInstance(Npc.Instance, true)
	Npc.Janitor:LinkToInstance(Npc.Instance.PrimaryPart, true)

	Npc.Janitor:Add(humanoid.Died:Once(function()
		Npc.Janitor:Cleanup()
	end, "Disconnect"))

	Npc.Janitor:Add(function()
		Npc.Acts:removeAllActs()
		Npc.Timer:DestroyAll()
	end, true)

	Npc.Timers = {
		Attack = Npc.Timer:new("Attack"),
		MoveRandom = Npc.Timer:new("MoveRandom"),
	}

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

		for _, module in ipairs(self.Instance:GetDescendants()) do -- run misc modules
			if not module:IsA("ModuleScript") then
				continue
			end

			local required = require(module)
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
	end

	function Npc:Place(position) -- will place into the world without running
		self.Instance.Parent = workspace

		self.Instance:PivotTo(CFrame.new(position + Vector3.new(0, 2.5, 0)))

		return self.Instance
	end

	function Npc:Spawn(position) -- will place into the world and run
		self:Place(position)
		self:Run()

		return self.Instance
	end

	function Npc:IsState(state)
		return Npc.Instance:GetAttribute("State") == state
	end

	function Npc:GetState()
		return Npc.Instance:GetAttribute("State")
	end

	function Npc:Exists()
		local subject = self.Instance
		return subject and subject.Parent and subject.PrimaryPart and subject.PrimaryPart.Parent
	end

	function Npc:GetTarget()
		local targetValue = Npc.Instance:FindFirstChild("Target")
		if not targetValue then
			return
		end

		local target = targetValue.Value

		return target
	end

	Npc:GetBehavior()

	return Npc
end

--// Main //--

RunService.Heartbeat:Connect(function()
	for _, action in ipairs(beats) do
		action()
	end
end)

return module
