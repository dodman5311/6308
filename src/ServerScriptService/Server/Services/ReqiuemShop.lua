local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStore = require(script.Parent.DataStore)
local Net = require(ReplicatedStorage.Packages.Net)
local Spawners = require(script.Parent.Spawners)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local RequiemShopService = {}

local requiredModules = {}

local shop = ServerStorage.ReqiuemShop

Net:RemoteEvent("EnterLevel")

local function teleportPlayers(cframe: CFrame)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(5)
			repeat
				task.wait()
			until player.Character
			player.Character:PivotTo(cframe)
		end)
	end
end

local function runRequiemModules(actionName: string)
	for _, module in pairs(requiredModules) do
		if not module[actionName] then
			continue
		end
		module[actionName](shop)
	end
end

function RequiemShopService:EnterShop()
	shop.Parent = workspace.Map
	local entryPart = shop:WaitForChild("EntryPart")
	runRequiemModules("OnEntered")

	workspace:SetAttribute("IsInReq", true)

	teleportPlayers(entryPart.CFrame * CFrame.new(0, 2.5, 0))
end

function RequiemShopService:GameInit()
	local modules = shop:FindFirstChild("Modules")
	for _, module in ipairs(modules:GetChildren()) do
		requiredModules[module.Name] = require(module)
	end

	runRequiemModules("OnPlaced")
end

Net:Handle("PurchaseUpgrade", function(player, name, price, index) -- requiem shop buy thingy WAH!
	workspace:SetAttribute("TotalScore", workspace:GetAttribute("TotalScore") - price)
	workspace:SetAttribute(name, index)

	local plusStage = (workspace:GetAttribute("Stage") - 1) * 5
	local level = plusStage + workspace:GetAttribute("Level")

	for _, weapon in ipairs(CollectionService:GetTagged("Weapon")) do
		weapon:Destroy()
	end

	Spawners.spawnWeapons(level)
	ReplicatedStorage.PurchasedUpgrade:Fire()

	local upgradesList = {}

	for _, category in pairs(Upgrades) do
		for upgradeName, _ in pairs(category) do
			upgradesList[upgradeName] = workspace:GetAttribute(upgradeName)
		end
	end

	DataStore.SaveData(player, "ShopUpgrades", upgradesList)

	return workspace:GetAttribute("TotalScore")
end)

return RequiemShopService
