local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Globals = require(ReplicatedStorage.Shared.Globals)
local gifts = require(Globals.Shared.Gifts)

local signals = require(Globals.Shared.Signals)

local function convertToArray(dictionary)
	local array = {}

	for name, _ in pairs(dictionary) do
		table.insert(array, name)
	end

	return array
end

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

	Set_Ammo = {
		Parameters = function()
			return {
				{ Name = "Amount", Options = { "_Input" } },
			}
		end,

		ExecuteClient = function(_, amount)
			signals.DoWeaponAction:Fire("UpdateAmmo", tonumber(amount))
		end,
	},

	Give_Souls = {
		Parameters = function()
			return {
				{ Name = "Amount", Options = { "_Input" } },
			}
		end,

		ExecuteClient = function(_, amount)
			signals.AddSoul:Fire(tonumber(amount))
		end,
	},

	TP_To_Spawn = {
		Parameters = function()
			return {
				{ Name = "Player", Options = Players:GetPlayers() },
			}
		end,

		ExecuteServer = function(_, _, Player)
			if not Player.Character then
				return
			end

			local spawnLocation = workspace:FindFirstChild("SpawnLocation")

			if not spawnLocation then
				return
			end
			Player.Character:PivotTo(spawnLocation.CFrame * CFrame.new(0, 3, 0))
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
				{ Name = "Map Style", Options = { "Linear", "Non_Linear" } },
				{ Name = "Map Size", Options = { "_Input" } },
			}
		end,

		ExecuteServer = function(_, _, style, size)
			signals["GenerateMap"]:Fire(style, tonumber(size))
		end,
	},

	Show_Delivery = {

		Parameters = function()
			return {
				{ Name = "Confirm", Options = { true, false } },
			}
		end,

		ExecuteClient = function(_, confirm)
			if not confirm then
				return
			end

			local soulsService = require(Globals.Client.Services.SoulsService)
			signals["DoUiAction"]:Fire("DeliveryUi", "ShowScreen", true, soulsService.Souls)
		end,
	},

	Give_Perk = {

		Parameters = function()
			return {
				{ Name = "Perk", Options = convertToArray(gifts.Perks) },
			}
		end,

		ExecuteClient = function(_, Perk)
			signals["AddGift"]:Fire(Perk)
		end,
	},

	Give_Upgrade = {

		Parameters = function()
			return {
				{ Name = "Upgrade", Options = convertToArray(gifts.Upgrades) },
			}
		end,

		ExecuteClient = function(_, Upgrade)
			signals["AddGift"]:Fire(Upgrade)
		end,
	},
}

return commands
