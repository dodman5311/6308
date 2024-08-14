local module = {
	Souls = 0,
	MaxDistance = 15,
	DropChance = 3,
}

--// Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

--// Values

local ironWillActive = false

--// Functions

function module.CalculateDropChance(chanceMod)
	chanceMod = chanceMod or 1

	local combo = math.clamp(ComboService.CurrentCombo, 1, 100)
	local healthMod = math.clamp(chanceMod / 2, 1, 100)
	local chance = (module.DropChance * combo) * healthMod
	--chance += ChanceService.getLuck()

	if module.Souls <= 0 then
		chance *= 4
	end

	if GiftsService.CheckGift("Drav_Is_Dead") then
		return 0
	end

	return math.clamp(chance, 0, 75)
end

function module.DropSoul(position, chanceModifier)
	chanceModifier = chanceModifier or 1

	local chance = module.CalculateDropChance(chanceModifier)
	if not ChanceService.checkChance(chance) then
		return
	end

	dropService.CreateDrop(position, "Soul").Sound:Play()

	if GiftsService.CheckGift("Echoed_Souls") and ChanceService.checkChance(20, true) then
		local soulDrop = dropService.CreateDrop(position, "Soul")
		soulDrop.Sound:Play()
		Debris:AddItem(soulDrop, 5)

		Signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Echoed_Souls")
	end
end

local function checkProtected()
	net:RemoteEvent("CheckProtected"):FireServer(module.Souls, ironWillActive)
end

local function checkIronWill()
	ironWillActive = GiftsService.CheckGift("Iron_Will") and ChanceService.checkChance(20)

	Signals.DoUiAction:Fire("HUD", "UpdateGiftProgress", true, "Iron_Will", ironWillActive and 1 or 0)

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
	Signals.DoUiAction:Fire("HUD", "UpdateSouls", true, module.Souls)

	if GiftsService.CheckGift("Steel_Souls") and ChanceService.checkChance(20, true) then
		Signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Steel_Souls")
		AddArmor(1)
	end

	checkProtected()
end

function module.RemoveSoul(amount)
	if module.Souls <= 0 then
		return
	end

	module.Souls -= math.round(amount)
	Signals.DoUiAction:Fire("HUD", "UpdateSouls", true, module.Souls)

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
	Signals.DoUiAction:Fire("Effects", "Pulse", true, Color3.fromRGB(27, 255, 206), 0.75)

	if not ironWillActive then
		Signals.DoUiAction:Fire("HUD", "RemoveSouls", true, 1)

		if ironWillActive then
			Signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Iron_Will")
			return
		end

		Signals.RemoveSoul:Fire(1)
	end

	if GiftsService.CheckGift("Unending_Fortress") and ChanceService.checkChance(25, true) then
		Signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Unending_Fortress")
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
