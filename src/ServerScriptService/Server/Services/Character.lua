local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local signals = require(Globals.Signals)
local net = require(Globals.Packages.Net)

--// Values

local checkProtectedEvent = net:RemoteEvent("CheckProtected")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.HealthChanged:Connect(function(health)
			if health <= 0 and character:GetAttribute("Protected") then
				humanoid.Health = humanoid.MaxHealth
				checkProtectedEvent:FireClient(player)
			end
		end)
	end)
end)

local function checkProtected(player, souls)
	local character = player.Character
	if not character then
		return
	end

	character:SetAttribute("Protected", souls > 0)
end

net:Connect("CheckProtected", checkProtected)

return module
