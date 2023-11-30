local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Globals = require(ReplicatedStorage.Shared.Globals)

local signals = require(Globals.Shared.Signals)

local commands = {
	Give_Weapon = {
		Parameters = {
			{ Name = "Weapon", Options = Globals.Assets.Models.Weapons:GetChildren() },
		},

		ExecuteClient = function(Weapon)
			signals.DoWeaponAction:Fire("EquipWeapon", Weapon.Name)
		end,
	},

	Set_Player_Health = {

		Parameters = {
			{ Name = "Player", Options = Players:GetPlayers() },
			{ Name = "Set Max", Options = { true, false } },
			{ Name = "Amount", Options = { "_Input" } },
		},

		ExecuteServer = function(_, Player, setMax, Value)
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

	LoadMap = {

		Parameters = {
			{ Name = "Map Size", Options = { "_Input" } },
		},

		ExecuteServer = function(_, Player, setMax, Value)
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
}

return commands
