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

local function SaveData(player: Player, dataStore: DataStore, value)
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

function module.LoadGameData(player)
	local startTime = os.clock()
	local upgradeIndex = LoadData(player, DataStoreService:GetDataStore("PlayerUpgradeIndex")) or 0
	local gameSettings = LoadData(player, DataStoreService:GetDataStore("PlayerSettings")) or {}
	local gameState = LoadData(player, DataStoreService:GetDataStore("PlayerGameState")) or {}
	local furthestLevel = LoadData(player, DataStoreService:GetDataStore("PlayerFurthestLevel")) or 0

	player:SetAttribute("furthestLevel", furthestLevel)
	player:SetAttribute("UpgradeIndex", upgradeIndex)

	local permaUpgradeName = permaUpgrades.Upgrades[upgradeIndex] and permaUpgrades.Upgrades[upgradeIndex].Name or ""
	player:SetAttribute("UpgradeName", permaUpgradeName)

	mapService.CurrentStage = gameState["Stage"] and math.clamp(gameState["Stage"], 1, math.huge) or 1
	mapService.CurrentLevel = gameState["Level"] and math.clamp(gameState["Level"], 1, math.huge) or 1

	print(mapService.CurrentStage, mapService.CurrentLevel)

	mapService.proceedToNext(nil, true)
	--signals["ProceedToNextLevel"]:Fire(nil, true)

	signals.ActivateUpgrade:Fire(player, permaUpgradeName)
	net:RemoteEvent("LoadData"):FireClient(player, upgradeIndex, gameState, gameSettings)
	return os.clock() - startTime
end

-- mapService.onLevelPassed:Connect(function(player, gameState)
-- 	SaveData(player, "PlayerGameState", gameState)
-- end)

function module.saveGameState(player, gameState)
	local dataStore = DataStoreService:GetDataStore("PlayerGameState")
	gameState.Stage = mapService.CurrentStage
	gameState.Level = mapService.CurrentLevel
	SaveData(player, dataStore, gameState)

	local plusStage = (gameState.Stage - 1) * 5
	local totalLevel = plusStage + gameState.Level

	if totalLevel > player:GetAttribute("furthestLevel") then
		player:SetAttribute("furthestLevel", totalLevel)
		print(player:GetAttribute("furthestLevel"))
		SaveData(player, DataStoreService:GetDataStore("PlayerFurthestLevel"), totalLevel)
	end
end

net:Connect("SaveGameState", module.saveGameState)

net:Connect("SaveData", function(player, dataStoreName, value)
	local dataStore = DataStoreService:GetDataStore(dataStoreName)
	SaveData(player, dataStore, value)
end)

return module
