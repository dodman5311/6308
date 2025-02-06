local module = {
	UpgradeIndex = 0,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local permaUpgradeList = require(ReplicatedStorage.Upgrades)
local codexService = require(Globals.Client.Services.CodexService)
local player = Players.LocalPlayer

--// Modules
local signal = require(Globals.Packages.Signal)
local signals = require(Globals.Signals)
local gifts = require(Globals.Shared.Gifts)
local net = require(Globals.Packages.Net)

local UIService = require(Globals.Client.Services.UIService)

--// Values

module.AquiredGifts = {}
module.ActiveGift = ""

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

	if table.find(giftData.Catagories, "Luck") then
		codexService.AddEntry("Luck")
	end

	UIService.doUiAction("HUD", "AddGift", giftData.Icon, gift)
	module.OnGiftAdded:Fire(gift, giftData)
	net:RemoteEvent("GiftAdded"):FireServer(gift, giftData)
end

local function ClearGifts()
	for _, gift in ipairs(module.AquiredGifts) do
		module.OnGiftRemoved:Fire(gift)
		net:RemoteEvent("GiftRemoved"):FireServer(gift)
	end

	module.AquiredGifts = {}
	UIService.doUiAction("HUD", "ClearGifts")
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
	if
		module.CheckUpgrade("Anchovies")
		and workspace:GetAttribute("Level") ~= math.round(workspace:GetAttribute("Level"))
		and player:GetAttribute("Anchovies")
		and player:GetAttribute("Anchovies") > 0
	then
		return
	end

	ClearGifts()
end

signals.AddGift:Connect(AddGift)
signals.ClearGifts:Connect(ClearGifts)

return module
