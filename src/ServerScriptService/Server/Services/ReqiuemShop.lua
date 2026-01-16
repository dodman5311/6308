local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Net = require(ReplicatedStorage.Packages.Net)
local RequiemShopService = {}

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

local function runRequiemModules()
	local modules = shop:FindFirstChild("Modules")
	for _, module in ipairs(modules:GetChildren()) do
		require(module).OnPlaced(shop)
	end
end

function RequiemShopService:EnterShop() --isDead)
	shop.Parent = workspace
	local entryPart = shop:WaitForChild("EntryPart")

	workspace:SetAttribute("IsInReq", true)

	teleportPlayers(entryPart.CFrame * CFrame.new(0, 2.5, 0))
	-- if isDead then
	-- 	task.delay(6, teleportPlayers, entryPart.CFrame * CFrame.new(0, 2.5, 0))
	-- end
end

function RequiemShopService:GameInit()
	runRequiemModules()
	--Prestart Code
end

function RequiemShopService:GameStart()
	--Start Code
end

return RequiemShopService
