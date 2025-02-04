local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local animationService = require(Globals.Vendor.AnimationService)

return {
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
		enter = function() end,

		exit = function() end,
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
			if npc.Name ~= "Visage Of False Hope" then
				npc.Instance.PrimaryPart.Anchored = false
			end

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
		enter = function() end,

		exit = function() end,
	},

	SoulFire = {
		time = 3,
		enter = function() end,

		exit = function() end,
	},
}
