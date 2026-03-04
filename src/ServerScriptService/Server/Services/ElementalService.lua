local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local net = require(Globals.Packages.Net)
local npcHandler = require(Globals.Server.HandleNpcs)
local vfx = net:RemoteEvent("ReplicateEffect")
local doUiAction = net:RemoteEvent("DoUiAction")
local signals = require(Globals.Signals)

net:RemoteEvent("ApplyElement")
local awardKill = net:RemoteEvent("AwardKill")

local doDamage = false

local elements = require(Globals.Shared.Elements)

local function runElementDamage(player, timer, npcModel, elementName)
	if not doDamage or npcModel:GetAttribute(elementName) then
		return
	end

	local nextTimeInTimer = 0

	timer.OnTimerStepped:Connect(function(currentTimeInTimer)
		if nextTimeInTimer < currentTimeInTimer then
			local humanoid = npcModel:FindFirstChild("Humanoid")
			local position = npcModel:GetPivot().Position

			humanoid:TakeDamage(1)
			doUiAction:FireAllClients("HUD", "ShowHit")

			if humanoid.Health <= 0 then
				awardKill:FireAllClients(npcModel, position)
			end

			nextTimeInTimer = currentTimeInTimer + 1
		end
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

net:Connect("GiftAdded", function(_, gift)
	if gift == "Venom" then
		doDamage = true
	end
end)

net:Connect("GiftRemoved", function(_, gift)
	if gift == "Venom" then
		doDamage = false
	end
end)

net:Connect("ApplyElement", module.applyElement)

return module
