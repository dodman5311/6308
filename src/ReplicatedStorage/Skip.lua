local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Globals = require(ReplicatedStorage.Shared.Globals)

local player = Players.LocalPlayer
local skipGui = ReplicatedStorage.Skip:Clone()

skipGui.Parent = player.PlayerGui

local util = require(Globals.Vendor.Util)
local Signal = require(Globals.Packages.Signal)
module.onSkipped = Signal.new()
local skipEnabled = false

local ti = TweenInfo.new(0.1)

local connections = {}

function module.enableSkip(callback, ...)
	local args = ...

	skipEnabled = true

	util.tween(skipGui.SkipPrompt, ti, { TextTransparency = 0 })

	table.insert(
		connections,
		module.onSkipped:Once(function()
			callback(args)
		end)
	)
end

function module.hideSkip()
	skipEnabled = false

	for _, connection in ipairs(connections) do
		if not connection then
			continue
		end

		connection:Disconnect()
		connection = nil
	end

	util.tween(skipGui.SkipPrompt, ti, { TextTransparency = 1 })
end

UserInputService.InputBegan:Connect(function(input)
	if not skipEnabled or input.KeyCode ~= Enum.KeyCode.F then
		return
	end

	module.onSkipped:Fire()
	module.hideSkip()
end)

return module
