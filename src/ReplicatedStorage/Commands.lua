local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Globals = require(ReplicatedStorage.Shared.Globals)

local signals = require(Globals.Shared.Signals)

local commands = {
	Give_Weapon = {
		Parameters = function()
			return {
				{ Name = "Weapon", Options = Globals.Assets.Models.Weapons:GetChildren() },
			}
		end,

		ExecuteClient = function(_, Weapon)
			signals.DoWeaponAction:Fire("EquipWeapon", Weapon.Name)
		end,
	},

	Set_Player_Health = {

		Parameters = function()
			return {
				{ Name = "Player", Options = Players:GetPlayers() },
				{ Name = "Set Max", Options = { true, false } },
				{ Name = "Amount", Options = { "_Input" } },
			}
		end,

		ExecuteServer = function(_, _, Player, setMax, Value)
			if not Player.Character then
				return Player.Name .. "'s character does not exist"
			end
			local humanoid = Player.Character:FindFirstChild("Humanoid")
			if not humanoid then
				return Player.Name .. " missing humanoid"
			end

			if setMax then
				humanoid.MaxHealth = tonumber(Value)
			end

			humanoid.Health = tonumber(Value)

			print(Player.Name .. "'s health set to " .. Value)
		end,
	},

	God_Mode = {

		Parameters = function()
			return {
				{ Name = "Player", Options = Players:GetPlayers() },
				{ Name = "Enable", Options = { true, false } },
			}
		end,

		PlayersWithGodMode = {},

		ExecuteServer = function(self, _, Player, Value)
			if not Player.Character then
				return Player.Name .. "'s character does not exist"
			end
			local humanoid = Player.Character:FindFirstChild("Humanoid")
			if not humanoid then
				return Player.Name .. " missing humanoid"
			end

			if Value then
				self.PlayersWithGodMode[Player] = humanoid.HealthChanged:Connect(function()
					humanoid.Health = humanoid.MaxHealth
				end)
				print("God mode enabled for " .. Player.Name)
			elseif self.PlayersWithGodMode[Player] then
				self.PlayersWithGodMode[Player]:Disconnect()
				print("God mode disabled for " .. Player.Name)
			end
		end,
	},

	LoadMap = {

		Parameters = function()
			return {
				{ Name = "Map Size", Options = { "_Input" } },
			}
		end,

		ExecuteServer = function(_, _, size)
			signals["GenerateMap"]:Fire(tonumber(size))
		end,
	},
}

return commands
