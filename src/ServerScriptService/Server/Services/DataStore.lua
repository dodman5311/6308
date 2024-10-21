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

Players.PlayerAdded:Connect(function(player)
	local upgradeIndex = LoadData(player, DataStoreService:GetDataStore("PlayerUpgradeIndex")) or 0
	local gameSettings = LoadData(player, DataStoreService:GetDataStore("PlayerSettings")) or {}
	local gameState = LoadData(player, DataStoreService:GetDataStore("PlayerGameState")) or {}

	net:RemoteEvent("LoadData"):FireClient(player, upgradeIndex, gameState, gameSettings)

	mapService.CurrentStage = gameState["Stage"] and math.clamp(gameState["Stage"], 1, math.huge) or 1
	mapService.CurrentLevel = gameState["Level"] and math.clamp(gameState["Level"], 1, math.huge) or 1

	signals["ProceedToNextLevel"]:Fire(nil, true)
end)

-- mapService.onLevelPassed:Connect(function(player, gameState)
-- 	SaveData(player, "PlayerGameState", gameState)
-- end)

function module.saveGameState(player, gameState)
	local dataStore = DataStoreService:GetDataStore("PlayerGameState")
	gameState.Stage = mapService.CurrentStage
	gameState.Level = mapService.CurrentLevel
	SaveData(player, dataStore, gameState)
end

net:Connect("SaveGameState", module.saveGameState)

net:Connect("SaveData", function(player, dataStoreName, value)
	local dataStore = DataStoreService:GetDataStore(dataStoreName)
	SaveData(player, dataStore, value)
end)

return module
