local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local cameraController = require(Globals.Client.Controllers.CameraController)
local signals = require(Globals.Signals)

local settings = {
	"Audio",

	{
		Name = "Music Volume",
		Type = "Slider",
		MaxValue = NumberRange.new(0, 100),
		Value = 100,
		OnChanged = function(self)
			game:GetService("SoundService").Music.Volume = self.Value / 100
		end,
	},

	{
		Name = "Effects Volume",
		Type = "Slider",
		MaxValue = NumberRange.new(0, 100),
		Value = 100,
		OnChanged = function(self)
			game:GetService("SoundService").Effects.Volume = self.Value / 100
		end,
	},

	{
		Name = "Voice Volume",
		Type = "Slider",
		MaxValue = NumberRange.new(0, 100),
		Value = 100,
		OnChanged = function(self)
			game:GetService("SoundService").Voice.Volume = self.Value / 100
		end,
	},

	"Controls",

	{
		Name = "Mouse Sensitivity",
		Type = "Slider",
		MaxValue = NumberRange.new(0, 100),
		Value = 50,
		OnChanged = function(self)
			UserInputService.MouseDeltaSensitivity = (self.Value / 100) * 2
		end,
	},

	"Graphics",

	{
		Name = "Gamma",
		Type = "Slider",
		MaxValue = NumberRange.new(0, 100),
		Value = 25,
		OnChanged = function(self, frame)
			game:GetService("Lighting").ExposureCompensation = self.Value / 100

			if not frame then
				return
			end

			local ti_0 = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

			TweenService:Create(frame.Background, ti_0, { BackgroundTransparency = 1 }):Play()
			--TweenService:Create(frame.Background, ti_1, { BackgroundTransparency = 0 }):Play()
		end,
	},

	{
		Name = "Screen Filter",
		Type = "Slider",
		--Value = true,

		MaxValue = NumberRange.new(0, 2),
		Value = 1,
		OnChanged = function(self)
			local screenEffects = playerGui:WaitForChild("ScreenEffects")
			local distortions = screenEffects.Distortions

			local value = math.round(self.Value)

			for _, frame in ipairs(distortions:GetChildren()) do
				frame.Visible = tonumber(frame.Name) == value
			end
		end,
	},

	"Interface",

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
		Name = "Field of View",
		Type = "Slider",
		MaxValue = NumberRange.new(50, 120),
		Value = 70,
		OnChanged = function(self)
			local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quint)
			require(Globals.Vendor.Util).tween(workspace.CurrentCamera, ti, { FieldOfView = self.Value })
		end,
	},

	{
		Name = "View Bobbing",
		Type = "Boolean",
		Value = true,
		OnChanged = function(self)
			cameraController.viewBobbingEnabled = self.Value
		end,
	},

	{
		Name = "Damage Feedback",
		Type = "Slider",
		MaxValue = NumberRange.new(0, 2),
		Value = 2,
		OnChanged = function(self) end,
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

local function loadSaveData(upgradeIndex, gameState, settingsToLoad)
	if not settingsToLoad then
		return
	end

	for _, value in ipairs(settings) do
		local foundSetting = settingsToLoad[value.Name]
		if foundSetting == nil then
			continue
		end

		value.Value = foundSetting
	end

	applySettings()
end

signals.LoadSavedDataFromClient:Connect(loadSaveData)

return settings
