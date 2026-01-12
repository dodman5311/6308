local module = {
	unlocked = false,
}
--// Services
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local camera = workspace.CurrentCamera

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.DeathScreen

--// Modules
local MusicService = require(Globals.Client.Services.MusicService)
local Signals = require(Globals.Shared.Signals)
local UIAnimationService = require(ReplicatedStorage.Vendor.UIAnimationService)
local acts = require(Globals.Vendor.Acts)
local giftService = require(Globals.Client.Services.GiftsService)
local net = require(Globals.Packages.Net)
local soulsService = require(Globals.Client.Services.SoulsService)
local util = require(Globals.Vendor.Util)
local deliveryAmount = 0

local levelsPassed = Instance.new("IntValue")
local coinCountNumber = Instance.new("IntValue")

--// Values

--// Functions

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false

	levelsPassed.Value = player:GetAttribute("furthestLevel")

	levelsPassed.Changed:Connect(function(value)
		frame.Unlock.ProgressNumber.Text = value
		util.PlaySound(sfx.Tick, script, 0.05)
	end)

	coinCountNumber.Changed:Connect(function(value)
		frame.CoinCheck.Coins.CoinsCount.Text = value
	end)

	frame.ContinueButton.MouseButton1Click:Connect(function()
		local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

		SoundService.AmbientReverb = Enum.ReverbType.NoReverb

		util.tween(frame.ReturnToMenu, ti, { GroupTransparency = 1 })
		util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, true)
		frame.Gui.Enabled = false
		frame.Unlock.Visible = false
		frame.ReturnToMenu.Visible = false

		Signals.DoUiAction:Fire("Cursor", "Toggle", false)
	end)

	frame.ReturnButton.MouseButton1Click:Connect(function()
		local loadingScreen = ReplicatedStorage.LoadingScreen:Clone()
		loadingScreen.Parent = player.PlayerGui

		loadingScreen.Background.BackgroundTransparency = 1
		util.tween(loadingScreen.Background, TweenInfo.new(0.5), { BackgroundTransparency = 0 })

		loadingScreen.Enabled = true

		TeleportService:SetTeleportGui(ReplicatedStorage.LoadingScreen)
		TeleportService:Teleport(16281075967, player)
	end)
end

function module.Cleanup(player, ui, frame) end

local function showCoinCheck(frame)
	local coinsCheckFrame = frame.CoinCheck
	local coinsFrame = coinsCheckFrame.Coins

	coinsFrame.CoinsIcon.Image.ImageTransparency = 1
	coinsFrame.Center.TextTransparency = 1
	coinsFrame.CoinRequirement.TextTransparency = 1
	coinsFrame.CoinsCount.TextTransparency = 1

	coinCountNumber.Value = 0

	local ti = TweenInfo.new(1)
	local ti2 = TweenInfo.new(2)

	task.wait(1)

	coinsCheckFrame.Visible = true
	coinsFrame.Visible = true

	ContentProvider:PreloadAsync { coinsCheckFrame.Image }

	local animation = UIAnimationService.PlayAnimation(coinsCheckFrame, 0.075)
	animation:OnFrameReached(16):Once(function()
		animation:Pause()
		task.wait(1.5)
		animation:Resume()
	end)
	animation:OnFrameReached(18):Once(function()
		animation:Pause()
		coinsFrame.CoinRequirement.Text = (workspace:GetAttribute("DeathCount")) * 400

		ContentProvider:PreloadAsync { coinsFrame.CoinsIcon.Image }
		local coinAnim = UIAnimationService.PlayAnimation(coinsFrame.CoinsIcon, 0.1, true)

		util.tween(coinsFrame.CoinsIcon.Image, ti, { ImageTransparency = 0 })
		util.tween(
			{ coinsFrame.Center, coinsFrame.CoinRequirement, coinsFrame.CoinsCount },
			ti,
			{ TextTransparency = 0 },
			true
		)

		if workspace:GetAttribute("TotalScore") ~= 0 then
			util.tween(coinCountNumber, ti2, { Value = workspace:GetAttribute("TotalScore") }, true)
		end

		task.wait(1)

		util.tween(coinsFrame.CoinsIcon.Image, ti, { ImageTransparency = 1 })
		util.tween(
			{ coinsFrame.Center, coinsFrame.CoinRequirement, coinsFrame.CoinsCount },
			ti,
			{ TextTransparency = 1 }
		)

		coinAnim:Stop()

		animation:Resume()
	end)
	animation.OnEnded:Wait()
	coinsCheckFrame.Visible = false
end

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

	local breakAnimation = UIAnimationService.PlayAnimation(HealthBroken, 0.05, false, false)

	breakAnimation:OnFrameReached(12):Once(function()
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

		SoundService.AmbientReverb = Enum.ReverbType.Arena
		sfx.EvilVoices:Play()

		task.wait(0.2)

		UIAnimationService.PlayAnimation(Requiem, 0.2, false, true).OnEnded:Once(function()
			task.wait(4)

			print("A")

			sfx.EvilVoices:Stop()
			Requiem.Visible = false

			showCoinCheck(frame)

			SoundService.AmbientReverb = Enum.ReverbType.NoReverb
			util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, true)
			frame.Gui.Enabled = false

			MusicService.playMusic()
			SoundService.Music.Volume = logVolume
			module.unlocked = false
		end)
	end)
end

return module
