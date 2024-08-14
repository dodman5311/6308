local module = {
	luck = 0,
	repetitionLuck = 0,
	airluck = false,
}
local rng = Random.new()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local Globals = require(ReplicatedStorage.Shared.Globals)
local giftService = require(Globals.Client.Services.GiftsService)
local comboService = require(Globals.Client.Services.ComboService)
local Net = require(Globals.Packages.Net)

local signals = require(Globals.Signals)

function module.getLuck()
	local result = module.luck
	if giftService.CheckGift("Rabbits_Foot") then
		result += 5
	end

	if module.airluck then
		result += 10
	end

	if giftService.CheckGift("Set_Em_Up") then
		result += comboService.CurrentCombo
	end

	if giftService.CheckGift("Tough_Luck") then
		local character = player.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		result += (humanoid.MaxHealth - humanoid.Health) * 2
	end

	result += module.repetitionLuck

	return result
end

local function resetRepLuck(value)
	if not value then
		return
	end

	if module.repetitionLuck > 0 then
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Gambler's_Fallacy")
	end

	module.repetitionLuck = 0
	signals.DoUiAction:Fire("HUD", "UpdateGiftProgress", true, "Gambler's_Fallacy", 0)
end

function module.checkChance(chance, goodLuck, PureLuck)
	if chance <= 0 then
		return
	end

	local luck = module.getLuck() / 2

	if goodLuck then
		chance += luck
	elseif goodLuck == false then
		chance -= luck
	end

	if rng:NextNumber(0, 100) <= chance then
		resetRepLuck(goodLuck)
		return true
	end

	if
		not PureLuck
		and giftService.CheckGift("Take_Two")
		and player.Character
		and player.Character:WaitForChild("Humanoid").Health <= 1
		and rng:NextNumber(0, 100) <= chance
	then
		resetRepLuck(goodLuck)

		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Take_Two")
		return true
	end

	return false
end

function module.doWithChance(chance, useLuck, callback, ...)
	if useLuck then
		chance += module.getLuck()
	end

	if rng:NextNumber(0, 100) > chance then
		return
	end

	return callback(...)
end

Net:RemoteFunction("CheckChance").OnClientInvoke = function(chance, goodLuck)
	return module.checkChance(chance, goodLuck)
end

return module
