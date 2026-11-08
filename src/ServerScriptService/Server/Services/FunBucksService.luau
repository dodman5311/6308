local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Packages.Net)

local FunBucks = {}

local function LoadData(player: Player, dataStore: DataStore) -- load data
	local foundData

	local success, errorMessage = pcall(function()
		foundData = dataStore:GetAsync("Pizza_Guy_" .. player.UserId)
	end)
	if not success then
		return warn("Failed to load " .. dataStore.Name, errorMessage)
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

local function SaveData(player, dataStoreName, value)
	local startTime = os.clock()

	local dataStore = DataStoreService:GetDataStore(dataStoreName)
	SaveToStore(player, dataStore, value)

	print(dataStoreName, "saved in", os.clock() - startTime)
end

local function GetStoredFunBucks(player: Player): number
	local funBucks = LoadData(player, DataStoreService:GetDataStore("FunBucks"))
	if not funBucks then
		SaveData(player, "FunBucks", 0)
		funBucks = 0
	end

	return funBucks
end

local function StoreFunBucks(player: Player, amount: number)
	SaveData(player, "FunBucks", amount)
end

local function CheckFunBucks(player: Player): number
	local funBucks = player:GetAttribute("FunBucks")
	if not funBucks then
		funBucks = GetStoredFunBucks(player)
		player:SetAttribute("FunBucks", funBucks)
	end

	return funBucks
end

function FunBucks:GameInit()
	Net:Connect("RecieveFunBucks", function(player: Player, amount: number)
		local funBucks = CheckFunBucks(player)
		player:SetAttribute("FunBucks", funBucks + amount)
	end)

	Net:Connect("SpendFunBucks", function(player: Player, amount: number)
		local funBucks = CheckFunBucks(player)
		player:SetAttribute("FunBucks", math.max(0, funBucks - amount))
	end)

	Net:Handle("CheckFunBucks", CheckFunBucks)

	Players.PlayerRemoving:Connect(function(player: Player)
		local funBucks = CheckFunBucks(player)
		print(funBucks, "saved")

		StoreFunBucks(player, funBucks)
	end)
end

function FunBucks:GameStart()
	--Start Code
end

return FunBucks
