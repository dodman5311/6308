local module = {
	luck = 0,
	repetitionLuck = 0,
	luckyFiveStacks = 0,
	airluck = false,
}
local rng = Random.new()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Globals = require(ReplicatedStorage.Shared.Globals)
local Net = require(Globals.Packages.Net)
local Signals = require(ReplicatedStorage.Shared.Signals)
local UIService = require(Globals.Client.Services.UIService)
local comboService = require(Globals.Client.Services.ComboService)
local giftService = require(Globals.Client.Services.GiftsService)

local assets = ReplicatedStorage.Assets

local luckMods = {}

function module.UpdateLuckModifier(index: string, value: number, changeType: ("Add" | "Per" | "Sub")?)
	changeType = changeType or "Add" :: "Add" | "Per" | "Sub"
	luckMods[index] = { Value = value, ChangeType = changeType }
end

function module.RemoveLuckModifier(index: string)
	if luckMods[index] then
		luckMods[index] = nil
	end
end

local function processHealthLuck(): number
	local addedLuck = 0
	local character = player.Character
	if not character then
		return addedLuck
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return addedLuck
	end

	if giftService.CheckGift("Tough_Luck") then
		addedLuck += (humanoid.MaxHealth - humanoid.Health) * 5
	end

	if giftService.CheckGift("Go_Big") then
		addedLuck += (5 - humanoid.MaxHealth) * 50
	end

	return addedLuck
end

function module.getLuck()
	local result = module.luck

	if giftService.CheckGift("Rabbits_Foot") then
		result += 10
	end

	if module.airluck then
		result += 15
	end

	if giftService.CheckGift("Set_Em_Up") then
		result += math.min(comboService.CurrentCombo, 20) * 2
	end

	result += processHealthLuck()
	result += module.luckyFiveStacks * 5
	result += module.repetitionLuck

	for _, luckMod in luckMods do
		if luckMod.ChangeType == "Add" then
			result += luckMod.Value
		elseif luckMod.ChangeType == "Sub" then
			result -= luckMod.Value
		elseif luckMod.ChangeType == "Per" then
			result += result * (luckMod.Value / 100)
		end
	end

	return result, module.luck
end

local function resetRepLuck(value)
	if not value then
		return
	end

	if module.repetitionLuck > 0 then
		UIService.doUiAction("HUD", "ActivateGift", "Gambler's_Fallacy")
	end

	module.repetitionLuck = 0
	UIService.doUiAction("HUD", "UpdateGiftProgress", "Gambler's_Fallacy", 0)
end

function module.checkChance(chance, goodLuck, PureLuck)
	if chance <= 0 then
		return
	end

	local luck = module.getLuck() / 100 --/ 2

	if goodLuck then
		chance *= (1 + luck)
	elseif goodLuck == false then
		chance /= (1 + luck)
	end

	if rng:NextNumber(0, 100) <= chance then
		resetRepLuck(goodLuck)
		return true
	end

	if
		goodLuck ~= false
		and not PureLuck
		and giftService.CheckGift("Take_Two")
		and player.Character
		and rng:NextNumber(0, 100) <= math.abs(player.Character:WaitForChild("Humanoid").Health - 5) * 15
		and rng:NextNumber(0, 100) <= chance
	then
		resetRepLuck(goodLuck)

		UIService.doUiAction("HUD", "ActivateGift", "Take_Two")
		assets.Sounds.TakeTwo:Play()
		return true
	end

	return false
end

Signals.AddLuck:Connect(function()
	module.luck += 5
end)

Net:RemoteFunction("CheckChance").OnClientInvoke = function(chance, goodLuck)
	return module.checkChance(chance, goodLuck)
end

return module
