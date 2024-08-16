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

	Player = {

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
	},

	Recources = {
		Simulate_Progression = {
			Parameters = function()
				return {
					{ Name = "Levels Passed", Options = { "_Input" } },
					{ Name = "Combat Level", Options = { "_Input" } },
				}
			end,

			ExecuteClient = function(_, levelsPassed, combatLevel)
				local weapons = require(Globals.Client.Controllers.WeaponController)
				local kiosk = require(ReplicatedStorage.Gui.Kiosk)
				local chanceService = require(Globals.Vendor.ChanceService)

				local perkIndexes = {}
				local upgradeIndexes = {}

				for index, _ in pairs(gifts.Perks) do
					table.insert(perkIndexes, index)
				end

				for index, _ in pairs(gifts.Upgrades) do
					table.insert(upgradeIndexes, index)
				end

				for level = 1, levelsPassed do
					local isUpgrade = math.random(0, 100) <= 35
					local randomGift

					if isUpgrade then
						randomGift = upgradeIndexes[math.random(1, #upgradeIndexes)]
					else
						randomGift = perkIndexes[math.random(1, #perkIndexes)]
					end

					signals["AddGift"]:Fire(randomGift)

					if level == 3 then
						signals["AddGift"]:Fire("Master_Scouting")
					end

					if level == 5 then
						local r = math.random(1, 3)

						if r == 1 then
							signals["AddGift"]:Fire("Brick_Hook")
						elseif r == 2 then
							signals["AddGift"]:Fire("Righteous_Motion")
						elseif r == 3 then
							signals["AddGift"]:Fire("Spiked_Sabatons")
						end

						
					end

					if level == 7 then
						signals["AddGift"]:Fire("Overcharge")
					end

					for _ = 1, combatLevel do
						local result = kiosk.getRandomGiftFromLocalList()

						if result == "Perk_Ticket" then
							local randomTicketGift

							if math.random(0, 100) <= 25 then
								randomTicketGift = upgradeIndexes[math.random(1, #upgradeIndexes)]
							else
								randomTicketGift = perkIndexes[math.random(1, #perkIndexes)]
							end

							signals["AddGift"]:Fire(randomTicketGift)
						elseif result == "Clover" then
							chanceService.luck += 1
						elseif result == "Large_Clover" then
							chanceService.luck += 2
						elseif result == "Riflemans_Crit" then
							weapons.critChances.AR += 1
						elseif result == "Breachers_Crit" then
							weapons.critChances.Shotgun += 1
						elseif result == "Gun_Slingers_Crit" then
							weapons.critChances.Pistol += 1
						elseif result == "Knights_Crit" then
							weapons.critChances.Melee += 1
						end
					end
				end

				signals.AddSoul:Fire(math.random(3, 6))
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

		Give_Perk_Ticket = {

			Parameters = function()
				return {
					{ Name = "Amount", Options = { "_Input" } },
				}
			end,

			ExecuteClient = function(_, amount)
				local kiosk = require(ReplicatedStorage.Gui.Kiosk)

				kiosk.tickets += amount
			end,
		},

		Give_Weapon = {
			Parameters = function()
				return {
					{ Name = "Weapon", Options = Globals.Assets.Models.Weapons:GetChildren() },
					{ Name = "Element", Options = { "None", "Fire", "Electricity", "Soul", "Ice" } },
				}
			end,

			ExecuteClient = function(_, Weapon, element)
				if element == "None" then
					element = nil
				end

				signals.DoWeaponAction:Fire("EquipWeapon", Weapon.Name, nil, element)
			end,
		},

		Set_Player_Armor = {

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
					humanoid:SetAttribute("MaxArmor", tonumber(Value))
				end

				humanoid:SetAttribute("Armor", tonumber(Value))

				print(Player.Name .. "'s armor set to " .. Value)
			end,
		},
	},

	Perks = {
		Give_Random_Perks = {
			Parameters = function()
				return {
					{ Name = "Amount", Options = { "_Input" } },
				}
			end,

			ExecuteClient = function(_, amount)
				local perkIndexes = {}
				local upgradeIndexes = {}

				for index, _ in pairs(gifts.Perks) do
					table.insert(perkIndexes, index)
				end

				for index, _ in pairs(gifts.Upgrades) do
					table.insert(upgradeIndexes, index)
				end

				for _ = 1, amount do
					local isUpgrade = math.random(0, 100) <= 35
					local randomGift

					if isUpgrade then
						randomGift = upgradeIndexes[math.random(1, #upgradeIndexes)]
					else
						randomGift = perkIndexes[math.random(1, #perkIndexes)]
					end

					signals["AddGift"]:Fire(randomGift)
				end
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

		Give_Special = {

			Parameters = function()
				return {
					{ Name = "Special", Options = convertToArray(gifts.Specials) },
				}
			end,

			ExecuteClient = function(_, Special)
				signals["AddGift"]:Fire(Special)
			end,
		},
	},

	Game = {
		Play_Sound = {
			Parameters = function()
				local assets = game:GetService("ReplicatedStorage").Assets:GetDescendants()
				local enemies = game:GetService("ReplicatedStorage").Enemies:GetDescendants()
				local getSounds = {}

				for _, v in ipairs(assets) do
					if not v:IsA("Sound") or v:FindFirstAncestor("Music") then
						continue
					end

					table.insert(getSounds, v)
				end

				for _, v in ipairs(enemies) do
					if not v:IsA("Sound") then
						continue
					end

					table.insert(getSounds, v)
				end

				return {
					{
						Name = "Sound To Play",
						Options = getSounds,
						Sub = function(option)
							local parent = option:FindFirstAncestorOfClass("Model")
								or option:FindFirstAncestorOfClass("Folder")

							return parent and parent.Name or ""
						end,
					},
					{ Name = "Volume", Options = { "_Input" } },
				}
			end,

			ExecuteClient = function(_, sound, volume)
				local util = require(Globals.Vendor.Util)

				local soundToPlay = util.PlaySound(sound, script)
				soundToPlay.Volume = volume
				soundToPlay.Looped = false
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

		ClearEnemies = {

			Parameters = function()
				return {
					{ Name = "Clear all", Options = { true, false } },
					{ Name = "Enemies to clear", Options = { "_Input" } },
				}
			end,

			ExecuteServer = function(_, _, clearAll, toClear)
				local collectionService = game:GetService("CollectionService")

				for _, enemy in ipairs(collectionService:GetTagged("Enemy")) do
					if enemy.Name ~= toClear and not clearAll then
						continue
					end

					enemy:Destroy()
				end
			end,
		},

		ProceedToLevel = {

			Parameters = function()
				return {
					{ Name = "Stage number", Options = { "_Input" } },
					{ Name = "Level number", Options = { "_Input" } },
				}
			end,

			ExecuteServer = function(_, player, stage_number, level_number)
				local stage = tonumber(stage_number)
				local level = tonumber(level_number) - 1

				local mapService = require(Globals.Services.MapService)

				mapService.CurrentStage = stage
				mapService.CurrentLevel = level

				require(Globals.Shared.ExitSequence).Exit(player, os.clock(), stage, level)
			end,
		},

		SpawnEnemy = {
			Parameters = function()
				local enemies = game:GetService("ReplicatedStorage").Enemies:GetDescendants()
				local getEnemies = {}

				for _, v in ipairs(enemies) do
					if not v:IsA("Model") or v:FindFirstAncestorOfClass("Model") then
						continue
					end

					table.insert(getEnemies, v)
				end

				return {
					{ Name = "Enemy", Options = getEnemies },
					{ Name = "Amount", Options = { "_Input" } },
				}
			end,

			ExecuteServer = function(_, player, Enemy, amount)
				print(player, Enemy)

				if not Enemy then
					return
				end

				local character = player.Character
				if not character then
					return
				end

				local hnpcs = require(Globals.Server.HandleNpcs)

				if amount then
					for _ = 1, amount do
						local npc = hnpcs.new(Enemy.Name)
						npc:Spawn(character:GetPivot() * CFrame.new(0, 0, -10))
					end
				else
					local npc = hnpcs.new(Enemy.Name)
					npc:Spawn(character:GetPivot() * CFrame.new(0, 0, -10))
				end
			end,
		},

		["Hampter_Mode!"] = {

			Parameters = function()
				return {
					{ Name = "Are you sure?", Options = { true, false } },
					{ Name = "Are you really sure?", Options = { true, false } },
					{ Name = "This can't be undone.", Options = { "Do it!", "Nevermind" } },
				}
			end,

			ExecuteServer = function(_, g, g1, g2)
				if not g or not g1 then
					return
				end

				if not g2 or g2 == "Nevermind" then
					return
				end

				require(Globals.Server.HandleNpcs).enableHampterMode()
			end,
		},
	},

	UI = {

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

		Show_Intro = {

			Parameters = function()
				return {
					{ Name = "Boss", Options = { "Keeper Of The Third Law", "Visage Of False Hope" } },
				}
			end,

			ExecuteClient = function(_, boss)
				if not boss then
					return
				end

				local MusicService = require(Globals.Client.Services.MusicService)
				MusicService.stopMusic()

				signals["DoUiAction"]:Fire("BossIntro", "ShowIntro", true, boss)
			end,
		},

		Show_Defeated = {

			Parameters = function()
				return {
					{ Name = "Boss", Options = { "Keeper Of The Third Law", "Phillip The Everlasting" } },
				}
			end,

			ExecuteClient = function(_, boss)
				if not boss then
					return
				end

				signals["DoUiAction"]:Fire("BossIntro", "ShowCompleted", true, boss)
			end,
		},

		Show_Kiosk = {

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
				signals["DoUiAction"]:Fire("Kiosk", "ShowScreen", true, soulsService.Souls)
			end,
		},

		Notify = {
			Parameters = function()
				return {
					{ Name = "NotifyAction", Options = { "ArenaBegun", "ArenaComplete" } },
				}
			end,

			ExecuteClient = function(_, NotifyAction)
				signals["DoUiAction"]:Fire("Notify", NotifyAction, true)
			end,
		},
	},

	Settings = {
		Screen_Effects = {
			Parameters = function()
				return {
					{ Name = "Enabled", Options = { true, false } },
				}
			end,

			ExecuteClient = function(_, value)
				game.Players.LocalPlayer.PlayerGui.ScreenEffects.Distortions.Visible = value
			end,
		},

		View_Bobbing = {
			Parameters = function()
				return {
					{ Name = "Enabled", Options = { true, false } },
				}
			end,

			ExecuteClient = function(_, value)
				require(Globals.Client.Controllers.CameraController).viewBobbingEnabled = value
			end,
		},

		Music_Volume = {
			Parameters = function()
				return {
					{ Name = "Volume", Options = { "_Input" } },
				}
			end,

			ExecuteClient = function(_, value)
				game:GetService("SoundService").Music.Volume = value
			end,
		},
	},
}

return commands