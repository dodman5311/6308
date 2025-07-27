local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local npcHandler = require(Globals.Server.HandleNpcs)
local net = require(Globals.Packages.Net)
local vfx = net:RemoteEvent("ReplicateEffect")
local doUiAction = net:RemoteEvent("DoUiAction")
local signals = require(Globals.Signals)

net:RemoteEvent("ApplyElement")

local elements = require(Globals.Shared.Elements)

local function runElementDamage(player, timer, npcModel, elementName)
	if
		player:GetAttribute("UpgradeName") ~= "Brick Oven"
		or elementName == "Soul"
		or npcModel:GetAttribute(elementName)
	then
		return
	end

	local lastStepTime = 0
	timer.OnTimerStepped:Connect(function(currentTimeInTimer)
		if math.floor(currentTimeInTimer) ~= lastStepTime then
			local humanoid = npcModel:FindFirstChild("Humanoid")
			humanoid:TakeDamage(1)
			doUiAction:FireAllClients("HUD", "ShowHit")
		end

		lastStepTime = math.floor(currentTimeInTimer)
	end)
end

function module.applyElement(player, npcModel, elementName)
	if not elementName then
		return
	end

	local npc = npcHandler:GetNpcFromModel(npcModel)

	if not npc then
		return
	end

	local element = elements[elementName]

	if not element then
		return
	end

	local elementTimer = npc:GetTimer(elementName)
	elementTimer.WaitTime = element.time

	runElementDamage(player, elementTimer, npcModel, elementName)

	npc.Instance:SetAttribute(elementName, true)
	npc.StatusEffects[elementName] = true

	vfx:FireAllClients("AddElementalEffect", "Server", true, elementName, npcModel)
	elementTimer:Cancel()

	element.enter(npc)

	elementTimer:Run()

	elementTimer.Function = function()
		element.exit(npc)

		npc.StatusEffects[elementName] = false
		npc.Instance:SetAttribute(elementName, false)
		vfx:FireAllClients("RemoveElementalEffect", "Server", true, elementName, npcModel)
	end
end

net:Connect("ApplyElement", module.applyElement)

return module
