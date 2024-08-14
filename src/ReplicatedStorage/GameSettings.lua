local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local cameraController = require(Globals.Client.Controllers.CameraController)

local settings = {
	"Audio",

	{
		Name = "Music Volume",
		Type = "Slider",
		MaxValue = 100,
		Value = 100,
		OnChanged = function(self)
			game:GetService("SoundService").Music.Volume = self.Value / 100
		end,
	},

	{
		Name = "Effects Volume",
		Type = "Slider",
		MaxValue = 100,
		Value = 100,
		OnChanged = function(self)
			game:GetService("SoundService").Effects.Volume = self.Value / 100
		end,
	},

	{
		Name = "Voice Volume",
		Type = "Slider",
		MaxValue = 100,
		Value = 100,
		OnChanged = function(self)
			game:GetService("SoundService").Voice.Volume = self.Value / 100
		end,
	},

	"Interface",

	{
		Name = "Distortion",
		Type = "Boolean",
		Value = true,
		OnChanged = function(self)
			local screenEffects = playerGui:WaitForChild("ScreenEffects")
			local distortions = screenEffects.Distortions

			distortions.Visible = self.Value
		end,
	},
	{
		Name = "HUD",
		Type = "Boolean",
		Value = true,
		OnChanged = function(self)
			local hud = playerGui:WaitForChild("HUD")

			hud.Enabled = self.Value
		end,
	},
	{
		Name = "Notifications",
		Type = "Boolean",
		Value = true,
		OnChanged = function(self)
			local noti = playerGui:WaitForChild("Notify")

			noti.Enabled = self.Value
		end,
	},

	"Gameplay",

	{
		Name = "View Bobbing",
		Type = "Boolean",
		Value = true,
		OnChanged = function(self)
			cameraController.viewBobbingEnabled = self.Value
		end,
	},
}

local function applySettings()
	for _, setting in ipairs(settings) do
		if typeof(setting) == "string" then
			continue
		end

		setting:OnChanged()
	end
end

task.delay(0.5, applySettings)

return settings
