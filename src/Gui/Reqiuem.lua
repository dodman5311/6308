local module = {
	tickets = 0,
	soulCost = 1,
}
--// Services
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.Kiosk

--// Modules
local util = require(Globals.Vendor.Util)
local Signal = require(Globals.Packages.Signal)

module.onHidden = Signal.new()

--// Values

local upgradeIndexOrder = {
	"Shotguns",
	"Rifles",
	"Pistols",
	"Melee",
	"Core",
	"Stage_1_Perks",
	"Stage_2_Perks",
	"Stage_3_Perks"
}

--// Functions

local function setTreeIndex(frame, index : string)
	local getTree = frame.Trees:FindFirstChild(index)
	local ti = TweenInfo.new(0.25)

	getTree.GroupTransparency = 1
	getTree.Visible = true

	util.tween(getTree, ti, {GroupTransparency = 0})

	for _,tree in ipairs(frame.Trees:GetChildren()) do
		if not tree:IsA("CanvasGroup") then
			continue
		end

		if tree.Name == index then
			util.tween(getTree, ti, {GroupTransparency = 0})
			util.tween(getTree, ti, {Size = UDim2.fromScale(1, 1)})
		else
			util.tween(getTree, ti, {GroupTransparency = 1})
			util.tween(getTree, ti, {Size = UDim2.fromScale(0.75, 0.75)})
		end
	end
end

function module.ShowRequiemShop(_, _, frame)
	setTreeIndex(frame, "Core")
end

function module.Init(player, ui, frame)
	
end

function module.Cleanup(player, ui, frame) end

return module
