local ReplicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local Util = require(ReplicatedStorage.Vendor.Util)
local assets = ReplicatedStorage.Assets

local RESCUE_REWARD = 25

print("BigFartPaulBlart!")

local function cheekyWeekyBubbiki(npc)
	local model = npc.Instance

	model.PrimaryPart.Anchored = true

	local ti = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	for _, v in ipairs(model:GetDescendants()) do
		if not v:IsA("BasePart") then
			continue
		end

		Util.tween(v, ti, { Transparency = 1 })
	end

	task.delay(3, npc.Instance.Destroy, npc.Instance)
end

local function HowDeepIsYourLoveIsItLikeTheOcean(npc)
	local prompt = npc.Instance:FindFirstChild("Rescue", true)
	if not prompt then
		return
	end

	prompt:Destroy()
end

local function epicSussyBallsNStuff(npc)
	workspace:SetAttribute("TotalScore", workspace:GetAttribute("TotalScore") + RESCUE_REWARD) -- give coins
	assets.Sounds.RCoinsSmall:Play()
	HowDeepIsYourLoveIsItLikeTheOcean(npc)
end

local function eatAssFreakyStyle(npc)
	local prompt: ProximityPrompt = npc.Instance:FindFirstChild("Rescue", true)
	prompt.Triggered:Connect(function()
		epicSussyBallsNStuff(npc)
		cheekyWeekyBubbiki(npc)
	end)
end

local module = {
	OnSpawned = {
		{ Function = "Custom", Parameters = { eatAssFreakyStyle } },
		{ Function = "SetLeader", Parameters = { players:GetPlayers()[1] } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Commrad" } },
		{ Function = "SetCollision", Parameters = { "Player" } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { HowDeepIsYourLoveIsItLikeTheOcean } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 3, true } },
	},
}

return module
