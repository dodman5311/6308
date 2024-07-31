local module = {}
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local camera = workspace.CurrentCamera

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.DeathScreen

--// Modules
local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)
local UiAnimator = require(Globals.Vendor.UIAnimationService)
local Signals = require(Globals.Shared.Signals)
local MusicService = require(Globals.Client.Services.MusicService)

local deliveryAmount = 0

--// Values

--// Functions

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false
end

function module.Cleanup(player, ui, frame) end

function module.ShowDeathScreen(player, ui, frame)
	local logVolume = SoundService.Music.Volume
	SoundService.Music.Volume = 0

	frame.Gui.Enabled = true

	local HealthBroken = frame.HealthBroken
	local Requiem = frame.Requiem

	frame.Background.BackgroundTransparency = 0
	HealthBroken.Visible = true
	Requiem.Visible = true

	Requiem.Image.Position = UDim2.fromScale(0, 0)

	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local ti_0 = TweenInfo.new(2.5, Enum.EasingStyle.Linear)

	task.wait(0.5)

	local breakAnimation = UiAnimator.PlayAnimation(HealthBroken, 0.05, false, false)

	breakAnimation:OnFrameRached(12):Once(function()
		sfx.Hit:Play()
		sfx.Break_Debris:Play()
		sfx.Break_Glass:Play()
		sfx.Break_Impact:Play()

		sfx.Scream.Volume = 0.75
		sfx.Scream:Play()

		util.tween(sfx.Scream, ti_0, { Volume = 0 })
	end)
	breakAnimation.OnEnded:Once(function()
		HealthBroken.Visible = false
		task.wait(0.8)

		sfx.EvilVoices:Play()

		task.wait(0.2)

		UiAnimator.PlayAnimation(Requiem, 0.2, false, true).OnEnded:Once(function()
			task.wait(3.95)
			MusicService.playMusic()
			task.wait(0.05)
			SoundService.Music.Volume = logVolume

			sfx.EvilVoices:Stop()
			Requiem.Visible = false

			util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, true)
			frame.Gui.Enabled = false
		end)
	end)
end

return module
