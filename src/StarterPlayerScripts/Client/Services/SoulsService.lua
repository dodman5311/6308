local module = {
	Souls = 0,
	DropChance = 2,
}

--// Services
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local assets = ReplicatedStorage.Assets

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local player = Players.LocalPlayer

--// Modules
local Signals = require(Globals.Shared.Signals)
local dropService = require(Globals.Shared.DropService)
local net = require(Globals.Packages.Net)
local ComboService = require(Globals.Client.Services.ComboService)
local ChanceService = require(Globals.Vendor.ChanceService)
local GiftsService = require(Globals.Client.Services.GiftsService)
local util = require(Globals.Vendor.Util)
local UIService = require(Globals.Client.Services.UIService)

--// Values

local ironWillActive = false

--// Functions

function module.CalculateDropChance(chanceMod)
	local combo = math.clamp(ComboService.CurrentCombo, 1, 100)
	local chance = (module.DropChance * combo) + chanceMod
	--chance += ChanceService.getLuck()

	local soulCount = module.Souls + #CollectionService:GetTagged("SoulDrop")

	if module.Souls <= 0 then
		chance *= 5
	end

	chance /= (1 + TweenService:GetValue(soulCount / 12, Enum.EasingStyle.Quart, Enum.EasingDirection.In) * 5)

	if GiftsService.CheckUpgrade("Quality Sauce") then
		chance /= 1.15
	end

	if GiftsService.CheckUpgrade("Cheaper Ingredients") then
		chance += 20
	end

	if GiftsService.CheckGift("Drav_Is_Dead") then
		return 0
	end

	return chance
end

local function playDropSound()
	util.PlaySound(assets.Sounds.SoulDropVoices, script, 0.1)
	util.PlaySound(assets.Sounds.SoulDrop, script, 0.1)
end

function module.DropSoul(position, chanceModifier)
	if
		GiftsService.CheckUpgrade("Anchovies")
		and workspace:GetAttribute("Level") ~= math.round(workspace:GetAttribute("Level"))
	then
		return
	end

	local chance = module.CalculateDropChance(chanceModifier)
	if not ChanceService.checkChance(chance) then
		return
	end

	playDropSound()

	local drop = dropService.CreateDrop(position, "Soul")
	drop.PrimaryPart.Sound:Play()
	drop:AddTag("SoulDrop")

	if GiftsService.CheckGift("Echoed_Souls") and ChanceService.checkChance(20, true) then
		local soulDrop = dropService.CreateDrop(position, "Soul")
		soulDrop.PrimaryPart.Sound:Play()
		Debris:AddItem(soulDrop, 5)

		soulDrop.PrimaryPart.Particles.Color = ColorSequence.new(Color3.fromRGB(240, 255, 76))
		UIService.doUiAction("HUD", "ActivateGift", "Echoed_Souls")
	end
end

local function checkProtected()
	net:RemoteEvent("CheckProtected"):FireServer(module.Souls, ironWillActive)
end

local function checkIronWill()
	ironWillActive = GiftsService.CheckGift("Iron_Will") and ChanceService.checkChance(20)

	UIService.doUiAction("HUD", "UpdateGiftProgress", "Iron_Will", ironWillActive and 1 or 0)

	checkProtected()
end

local function AddArmor(amount)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	net:RemoteEvent("SetArmor"):FireServer(humanoid:GetAttribute("Armor") + amount)
end

function module.AddSoul(amount)
	if GiftsService.CheckGift("Drav_Is_Dead") then
		return
	end

	module.Souls += math.round(amount)
	UIService.doUiAction("HUD", "UpdateSouls", module.Souls)

	if GiftsService.CheckGift("Steel_Souls") and ChanceService.checkChance(20, true) then
		UIService.doUiAction("HUD", "ActivateGift", "Steel_Souls")
		AddArmor(1)
	end

	checkProtected()
end

function module.RemoveSoul(amount)
	if module.Souls <= 0 then
		return
	end

	module.Souls -= math.floor(amount)
	UIService.doUiAction("HUD", "UpdateSouls", module.Souls)

	checkProtected()
end

--// Main //--

Signals.AddArmor:Connect(function()
	AddArmor(1)
end)
Signals.AddSoul:Connect(module.AddSoul)
Signals.RemoveSoul:Connect(module.RemoveSoul)

net:Connect("DropSoul", module.DropSoul)

net:RemoteFunction("GetSoulCount").OnClientInvoke = function()
	return module.Souls
end
net:Connect("DropArmor", function(position, chance)
	if chance and not ChanceService.checkChance(chance, true) then
		return
	end
	dropService.CreateDrop(position, "Armor")
end)

net:Connect("CheckProtected", function()
	assets.Sounds.Revive:Play()
	UIService.doUiAction("Effects", "Pulse", Color3.fromRGB(27, 255, 206), 0.75)

	if not ironWillActive then
		UIService.doUiAction("HUD", "RemoveSouls", 1)

		if ironWillActive then
			UIService.doUiAction("HUD", "ActivateGift", "Iron_Will")
			return
		end

		Signals.RemoveSoul:Fire(1)
	end

	if GiftsService.CheckGift("Unending_Fortress") and ChanceService.checkChance(25, true) then
		UIService.doUiAction("HUD", "ActivateGift", "Unending_Fortress")
		net:RemoteEvent("SetArmor"):FireServer(5)
	end

	checkIronWill()
end)

function module:OnSpawn()
	ironWillActive = false
	checkProtected()
end

GiftsService.OnGiftAdded:Connect(function(gift)
	if gift == "Iron_Will" then
		checkIronWill()
	end
end)

return module
