local module = {
	UpgradeIndex = 0,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local permaUpgradeList = require(ReplicatedStorage.Upgrades)

--// Modules
local signal = require(Globals.Packages.Signal)
local signals = require(Globals.Signals)
local gifts = require(Globals.Shared.Gifts)
local net = require(Globals.Packages.Net)

--// Values

module.AquiredGifts = {}

module.OnGiftAdded = signal.new()
module.OnGiftRemoved = signal.new()

function module.CheckGift(giftName)
	return table.find(module.AquiredGifts, giftName)
end

local function AddGift(gift)
	if module.CheckGift(gift) or module.CheckGift("Drav_Is_Dead") then
		return
	end

	table.insert(module.AquiredGifts, gift)

	local giftData = gifts.Perks[gift]
	if not giftData then
		giftData = gifts.Upgrades[gift]
	end
	if not giftData then
		giftData = gifts.Specials[gift]
	end
	if not giftData then
		return
	end

	signals.DoUiAction:Fire("HUD", "AddGift", true, giftData.Icon, gift)
	module.OnGiftAdded:Fire(gift, giftData)
	net:RemoteEvent("GiftAdded"):FireServer(gift, giftData)
end

local function ClearGifts()
	for _, gift in ipairs(module.AquiredGifts) do
		module.OnGiftRemoved:Fire(gift)
		net:RemoteEvent("GiftRemoved"):FireServer(gift)
	end

	module.AquiredGifts = {}
	signals.DoUiAction:Fire("HUD", "ClearGifts", true)
end

function module.CheckUpgrade(upgradeName)
	local upgradeIndex = Players.LocalPlayer:GetAttribute("UpgradeIndex")
	local upgrades = permaUpgradeList.Upgrades

	if not upgradeIndex or upgradeIndex == 0 then
		return
	end

	return upgrades[upgradeIndex].Name == upgradeName
end

function module:OnDied()
	ClearGifts()
end

signals.AddGift:Connect(AddGift)
signals.ClearGifts:Connect(ClearGifts)

return module
