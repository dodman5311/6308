local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local signals = require(Globals.Signals)
local net = require(Globals.Packages.Net)

--// Values

local gifts = {}

function module.CheckGift(giftName)
	return table.find(gifts, giftName)
end

local function AddGift(gift)
	table.insert(gifts, gift)
end

signals.AddGift:Connect(AddGift)

return module
