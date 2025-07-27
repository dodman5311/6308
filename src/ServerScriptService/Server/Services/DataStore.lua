local module = {
	stageState = {
		Stage = 0,
		Level = 0,
	},
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local net = require(Globals.Packages.Net)
local mapService = require(Globals.Server.Services.MapService)

--// Values

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
	local deathCount = LoadData(player, DataStoreService:GetDataStore("PlayerDeathCount")) or 0
	local upgrades = LoadData(player, DataStoreService:GetDataStore("ShopUpgrades")) or {}
	local gameSettings = LoadData(player, DataStoreService:GetDataStore("PlayerSettings")) or {}
	local gameState = LoadData(player, DataStoreService:GetDataStore("PlayerGameState")) or {}
	local stageState = LoadData(player, DataStoreService:GetDataStore("PlayerStageState")) or {}
	local furthestLevel = LoadData(player, DataStoreService:GetDataStore("PlayerFurthestLevel")) or 0
	local codex = LoadData(player, DataStoreService:GetDataStore("PlayerCodex")) or {}

	player:SetAttribute("furthestLevel", furthestLevel)

	module.stageState = stageState

	mapService.CurrentStage = gameState["Stage"] and math.clamp(gameState["Stage"], 1, math.huge) or 1
	mapService.CurrentLevel = gameState["Level"] and math.clamp(gameState["Level"], 1, math.huge) or 1

	player:SetAttribute("MaxHealth", 5)

	mapService.proceedToNext(nil, true)

	workspace:SetAttribute("TotalScore", gameState.TotalScore or 0)
	workspace:SetAttribute("DeathCount", deathCount or 0)

	for upgradeName, upgradeValue in pairs(upgrades) do
		workspace:SetAttribute(upgradeName, upgradeValue)
	end

	net:RemoteEvent("LoadData"):FireClient(player, upgrades, gameState, gameSettings, codex)
	return os.clock() - startTime
end

function module.getStageState()
	return module.stageState
end

-- mapService.onLevelPassed:Connect(function(player, gameState)
-- 	SaveData(player, "PlayerGameState", gameState)
-- end)

function module.saveFurthestLevel(player)
	local totalLevel = workspace:GetAttribute("TotalLevel")

	if totalLevel > player:GetAttribute("furthestLevel") then
		player:SetAttribute("furthestLevel", totalLevel)
		SaveToStore(player, DataStoreService:GetDataStore("PlayerFurthestLevel"), totalLevel)
	end
end

function module.saveGameState(player, gameState)
	local startTime = os.clock()

	local dataStore = DataStoreService:GetDataStore("PlayerGameState")
	--gameState.Stage = gameState.Stage or mapService.CurrentStage
	--gameState.Level = gameState.Level or mapService.CurrentLevel
	SaveToStore(player, dataStore, gameState)

	print("Game saved in", os.clock() - startTime, gameState)

	if gameState.Level == 1 then
		SaveToStore(player, DataStoreService:GetDataStore("PlayerStageState"), gameState)
		module.stageState = gameState
		print("STAGE saved in", os.clock() - startTime, gameState)
	end

	net:RemoteEvent("DoUiAction"):FireAllClients("Notify", "GameSaved")
end

net:Connect("SaveGameState", module.saveGameState)
net:Connect("SaveFurthestLevel", module.saveFurthestLevel)
net:Connect("SaveData", module.SaveData)
net:Handle("GetStageState", module.getStageState)

return module
