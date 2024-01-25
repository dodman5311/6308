local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Player = Players.LocalPlayer

--// Modules
local signals = require(Globals.Signals)
local giftService = require(Globals.Client.Services.GiftsService)

function module:OnSpawn(character, humanoid)
	signals.DoUiAction:Fire("HUD", "UpdatePlayerHealth", true, humanoid.Health, humanoid.MaxHealth)
	signals.DoUiAction:Fire("HUD", "UpdatePlayerHealth", true, humanoid.Health, humanoid.MaxHealth)

	humanoid.HealthChanged:Connect(function(health)
		signals.DoUiAction:Fire("HUD", "UpdatePlayerHealth", true, health, humanoid.MaxHealth)

		if health <= 0 then
			signals.RemoveSoul:Fire(1)
			humanoid.Health = humanoid.MaxHealth
		end
	end)

	if giftService.CheckGift("SpeedRunner") then
		humanoid.WalkSpeed += 5
	end
end

local function onGiftAdded(gift)
	if gift ~= "SpeedRunner" or not Player.Character then
		return
	end

	local humanoid = Player.Character:WaitForChild("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed += 5
end

signals.AddGift:Connect(onGiftAdded)

return module
