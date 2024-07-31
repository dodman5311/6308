local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local npcHandler = require(Globals.Server.HandleNpcs)
local animationService = require(Globals.Vendor.AnimationService)
local net = require(Globals.Packages.Net)
local vfx = net:RemoteEvent("ReplicateEffect")

net:RemoteEvent("ApplyElement")

local elements = {
	Electricity = {
		time = 3,
		enter = function(npc)
			local humanoid = npc.Instance:FindFirstChild("Humanoid")

			npc.LogWalkspeed = humanoid.WalkSpeed
			humanoid.WalkSpeed /= 5
		end,

		exit = function(npc)
			local humanoid = npc.Instance:FindFirstChild("Humanoid")

			humanoid.WalkSpeed = npc.LogWalkspeed
		end,
	},
	Fire = {
		time = 4,
		enter = function(npc) end,

		exit = function(npc) end,
	},
	Ice = {
		time = 2,
		enter = function(npc)
			npc.Instance.PrimaryPart.Anchored = true

			local animations = animationService:getLoadedAnimations(npc.Instance)
			if not animations then
				return
			end
			for _, anim in pairs(animations) do
				anim:AdjustSpeed(0)
			end
		end,

		exit = function(npc)
			npc.Instance.PrimaryPart.Anchored = false

			local animations = animationService:getLoadedAnimations(npc.Instance)
			if not animations then
				return
			end
			for _, anim in pairs(animations) do
				anim:AdjustSpeed(1)
			end
		end,
	},
	Soul = {
		time = 2.5,
		enter = function(npc) end,

		exit = function(npc) end,
	},
}

function module.applyElement(_, npcModel, elementName)
	if not elementName then
		return
	end

	local npc = npcHandler:GetNpcFromModel(npcModel)

	if not npc then
		return
	end

	local element = elements[elementName]

	local elementTimer = npc:GetTimer(elementName)
	elementTimer.WaitTime = element.time

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
