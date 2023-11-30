local module = {
	Souls = 20,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local signals = require(Globals.Signals)

function module:OnSpawn(character, humanoid)
	signals.DoUiAction:Fire("HUD", "UpdatePlayerHealth", true, humanoid.Health, humanoid.MaxHealth)

	humanoid.HealthChanged:Connect(function(health)
		signals.DoUiAction:Fire("HUD", "UpdatePlayerHealth", true, health, humanoid.MaxHealth)
	end)
end

return module
