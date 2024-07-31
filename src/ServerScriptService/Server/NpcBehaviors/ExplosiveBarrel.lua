local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)

local stats = {
	NpcType = "Hazard",
}

local function explode(npc)
	local model = npc.Instance
	model.PrimaryPart.Transparency = 1

	local explosionPosition = model:GetPivot().Position

	net:RemoteEvent("CreateExplosion"):FireAllClients(explosionPosition, 30, 5, Players:FindFirstChildOfClass("Player"))
end

local module = {
	OnSpawned = {
		{ Function = "AddTag", Parameters = { stats.NpcType } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { explode } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 5 } },
	},
}

return module
