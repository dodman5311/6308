local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local net = require(Globals.Packages.Net)
local mapService = require(Globals.Server.Services.MapService)
local signals = require(Globals.Shared.Signals)
local permaUpgrades = require(ReplicatedStorage.Upgrades)

--// Values
local gameState = {
	Stage = 0,
	Level = 0,
	Weapon = { Name = "", Ammo = 0, Element = "" },
	Souls = 0,

	critChances = {
		AR = 0,
		Pistol = 0,
		Shotgun = 0,
		Melee = 0,
	},

	Luck = 0,
	PerkTickets = 0,

	PerkList = {},
}

--// Functions
local function LoadData(player: Player, dataStore: DataStore) -- load data
	local foundData

	local success, errorMessage = pcall(function()
		foundData = dataStore:GetAsync("Pizza_Guy_" .. player.UserId)
	end)
	if not success then
		warn("Failed to load " .. dataStore.Name, errorMessage)
	else
		return foundData
	end
end

local function SaveToStore(player: Player, dataStore: DataStore, value)
	local success, errorMessage = pcall(function()
		dataStore:SetAsync("Pizza_Guy_" .. player.UserId, value)
	end)
	if not success then
		if dataStore then
			warn("Failed to save " .. dataStore.Name)
		end

		warn(errorMessage)
	end
end

function module.SaveData(player, dataStoreName, value)
	local startTime = os.clock()

	local dataStore = DataStoreService:GetDataStore(dataStoreName)
	SaveToStore(player, dataStore, value)

	print(dataStoreName, "saved in", os.clock() - startTime)
end

function module.LoadGameData(player)
	local startTime = os.clock()
	local upgradeIndex = LoadData(player, DataStoreService:GetDataStore("PlayerUpgradeIndex")) or 0
	local gameSettings = LoadData(player, DataStoreService:GetDataStore("PlayerSettings")) or {}
	local gameState = LoadData(player, DataStoreService:GetDataStore("PlayerGameState")) or {}
	local furthestLevel = LoadData(player, DataStoreService:GetDataStore("PlayerFurthestLevel")) or 0
	local codex = LoadData(player, DataStoreService:GetDataStore("PlayerCodex")) or {}

	player:SetAttribute("furthestLevel", furthestLevel)
	player:SetAttribute("UpgradeIndex", upgradeIndex)

	local permaUpgradeName = permaUpgrades.Upgrades[upgradeIndex] and permaUpgrades.Upgrades[upgradeIndex].Name or ""
	player:SetAttribute("UpgradeName", permaUpgradeName)

	mapService.CurrentStage = gameState["Stage"] and math.clamp(gameState["Stage"], 1, math.huge) or 1
	mapService.CurrentLevel = gameState["Level"] and math.clamp(gameState["Level"], 1, math.huge) or 1

	signals.ActivateUpgrade:Fire(player, permaUpgradeName)

	if permaUpgradeName == "Sister Location" and mapService.CurrentStage < 2 then
		mapService.CurrentStage = 2
		mapService.CurrentLevel = 1
	end

	if permaUpgradeName == "Pizza Chain" and mapService.CurrentStage < 3 then
		mapService.CurrentStage = 3
		mapService.CurrentLevel = 1
	end

	if permaUpgradeName == "Gourmet Kitchen Knife" then
		ReplicatedStorage.Assets.Models.WeaponPickups.Katana:Destroy()
	end

	mapService.proceedToNext(nil, true)
	--signals["ProceedToNextLevel"]:Fire(nil, true)

	net:RemoteEvent("LoadData"):FireClient(player, upgradeIndex, gameState, gameSettings, codex)
	return os.clock() - startTime
end

-- mapService.onLevelPassed:Connect(function(player, gameState)
-- 	SaveData(player, "PlayerGameState", gameState)
-- end)

function module.saveFurthestLevel(player)
	local level = workspace:GetAttribute("Level")
	local stage = workspace:GetAttribute("Stage")

	local plusStage = (stage - 1) * 5
	local totalLevel = plusStage + level

	if totalLevel > player:GetAttribute("furthestLevel") then
		player:SetAttribute("furthestLevel", totalLevel)
		SaveToStore(player, DataStoreService:GetDataStore("PlayerFurthestLevel"), totalLevel)
	end
end

function module.saveGameState(player, gameState)
	local startTime = os.clock()

	local dataStore = DataStoreService:GetDataStore("PlayerGameState")
	gameState.Stage = mapService.CurrentStage
	gameState.Level = mapService.CurrentLevel
	SaveToStore(player, dataStore, gameState)

	print("Game saved in", os.clock() - startTime)
end

net:Connect("SaveGameState", module.saveGameState)
net:Connect("SaveFurthestLevel", module.saveFurthestLevel)
net:Connect("SaveData", module.SaveData)

return module
