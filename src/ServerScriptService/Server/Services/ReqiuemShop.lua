local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Net = require(ReplicatedStorage.Packages.Net)
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

function RequiemShopService:EnterShop() --isDead)
	shop.Parent = workspace
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

return RequiemShopService
