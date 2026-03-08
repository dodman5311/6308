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
local Skip = require(ReplicatedStorage.Shared.Skip)

local camera = workspace.CurrentCamera

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.DeathScreen

--// Modules
local MusicService = require(Globals.Client.Services.MusicService)
local Signals = require(Globals.Shared.Signals)
local UIAnimationService = require(ReplicatedStorage.Vendor.UIAnimationService)
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

	coinsFrame.CoinRequirement.Text = (workspace:GetAttribute("LogDeathCount") + 1) * 400

	local coinAnim = UIAnimationService.PlayAnimation(coinsFrame.CoinsIcon, 0.1, true)

	local animation
	local skipped = false
	local completed = false

	local step_1 = task.spawn(function()
		task.wait(1)

		coinsCheckFrame.Visible = true
		coinsFrame.Visible = true

		ContentProvider:PreloadAsync { coinsCheckFrame.Image }

		animation = UIAnimationService.PlayAnimation(coinsCheckFrame, 0.075)
		animation:OnFrameReached(16):Wait()

		animation:Pause()
		task.wait(1.5)
		animation:Resume()

		animation:OnFrameReached(18):Wait()
		animation:Pause()

		ContentProvider:PreloadAsync { coinsFrame.CoinsIcon.Image }

		util.tween(coinsFrame.CoinsIcon.Image, ti, { ImageTransparency = 0 })
		util.tween(
			{ coinsFrame.Center, coinsFrame.CoinRequirement, coinsFrame.CoinsCount },
			ti,
			{ TextTransparency = 0 },
			true
		)

		if workspace:GetAttribute("LogTotalScore") ~= 0 then
			util.tween(coinCountNumber, ti2, { Value = workspace:GetAttribute("LogTotalScore") }, true)
		end

		Skip.hideSkip()
		completed = true
	end)

	Skip.enableSkip(function()
		task.cancel(step_1)

		coinsCheckFrame.Visible = true
		coinsFrame.Visible = true

		coinsFrame.CoinsIcon.Image.ImageTransparency = 0
		coinsFrame.Center.TextTransparency = 0
		coinsFrame.CoinRequirement.TextTransparency = 0
		coinsFrame.CoinsCount.TextTransparency = 0

		if workspace:GetAttribute("LogTotalScore") ~= 0 then
			coinCountNumber.Value = workspace:GetAttribute("LogTotalScore")
		end

		skipped = true
		completed = true
	end)

	repeat
		task.wait()
	until completed

	if skipped then
		animation = UIAnimationService.PlayAnimation(coinsCheckFrame, 0.075, false, false, 18)
		animation:Pause()
	end

	task.wait(1)

	util.tween(coinsFrame.CoinsIcon.Image, ti, { ImageTransparency = 1 })
	util.tween({ coinsFrame.Center, coinsFrame.CoinRequirement, coinsFrame.CoinsCount }, ti, { TextTransparency = 1 })

	coinAnim:Stop()

	animation:Resume()
	animation:OnFrameReached(20):Wait()
	animation:Pause()

	local coinAnimation

	if workspace:GetAttribute("LogTotalScore") < (workspace:GetAttribute("LogDeathCount") + 1) * 400 then
		local clearThread = task.spawn(function()
			completed = false

			task.wait(2)

			Signals.DoUiAction:Fire("Requiem", "ShowRequiemShop", "DeathScreen")
			for i = 1, 8 do
				local waitTime = math.abs((8 - i) / 8)
				Signals.DoUiAction:Fire("Requiem", "setTreeIndex", i, nil, true)
				task.wait(waitTime)
				local sound = util.PlaySound(sounds.RCoinsSmall, script)
				util.tween(sound, TweenInfo.new(1), { PlaybackSpeed = 0.35 })
				Signals.DoUiAction:Fire("Requiem", "updateIndexedTree")
				task.wait(waitTime)
			end
			Signals.DoUiAction:Fire("Requiem", "HideRequiemShop")
			task.wait(0.5)

			local bank = frame.PiggyBank

			coinAnimation = UIAnimationService.PlayAnimation(bank.Coins.Animation, 0.075, true)

			bank.Coins.Animation.Image.ImageTransparency = 1
			bank.Coins.Count.TextTransparency = 1
			bank.Coins.Count.UIStroke.Transparency = 1
			bank.Icon.ImageTransparency = 1
			bank.Visible = true

			local ti_b = TweenInfo.new(0.5)
			local ti_c = TweenInfo.new(1, Enum.EasingStyle.Elastic)
			bank.Coins.Count.Text = workspace:GetAttribute("StoredScore") * 2

			util.tween({ bank.Icon, bank.Coins.Animation.Image }, ti_b, { ImageTransparency = 0 })
			util.tween({ bank.Coins.Count.UIStroke }, ti_b, { Transparency = 0 })
			util.tween(bank, ti_b, { BackgroundTransparency = 0.5 })
			util.tween({ bank.Coins.Count }, ti_b, { TextTransparency = 0 }, true)
			task.wait(1.5)

			bank.Position = UDim2.fromScale(0.525, 0.5)

			bank.Coins.Count.Text = workspace:GetAttribute("StoredScore")

			util.tween(util.PlaySound(sounds.RCoinsSmall, script), TweenInfo.new(1), { PlaybackSpeed = 0.4 })
			util.tween({ bank }, ti_c, { Position = UDim2.fromScale(0.5, 0.5) }, true)

			task.wait(1)

			util.tween({ bank.Icon, bank.Coins.Animation.Image }, ti_b, { ImageTransparency = 1 })
			util.tween({ bank.Coins.Count }, ti_b, { TextTransparency = 1 })
			util.tween(bank, ti_b, { BackgroundTransparency = 1 })
			util.tween({ bank.Coins.Count.UIStroke }, ti_b, { Transparency = 1 }, true)

			bank.Visible = false
			coinAnimation:Stop()
			coinAnimation = nil

			Skip.hideSkip()
			completed = true
		end)

		Skip.enableSkip(function()
			task.cancel(clearThread)
			Signals.DoUiAction:Fire("Requiem", "HideRequiemShop")
			frame.PiggyBank.Visible = false
			completed = true
			if coinAnimation then
				coinAnimation:Stop()
			end
		end)
	else
		completed = true
	end

	repeat
		task.wait()
	until completed

	animation:Resume()
	animation.OnEnded:Wait()

	coinsCheckFrame.Visible = false

	task.delay(2, function()
		Signals.DoUiAction:Fire("Notify", "ShowLevelDisplay")
	end)
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

	local function endReq()
		sfx.EvilVoices:Stop()
		Requiem.Visible = false

		showCoinCheck(frame)

		SoundService.AmbientReverb = Enum.ReverbType.NoReverb
		util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, true)
		frame.Gui.Enabled = false

		if workspace:GetAttribute("IsInReq") then
			MusicService.playTrack("Reqiuem")
		else
			MusicService.playMusic()
		end

		SoundService.Music.Volume = logVolume
		module.unlocked = false
	end

	local function showRequiem()
		task.wait(0.8)

		SoundService.AmbientReverb = Enum.ReverbType.Arena
		sfx.EvilVoices:Play()

		task.wait(0.2)

		UIAnimationService.PlayAnimation(Requiem, 0.2, false, true).OnEnded:Wait()
		task.wait(4)
		Skip.hideSkip()
		endReq()
	end

	breakAnimation.OnEnded:Once(function()
		HealthBroken.Visible = false
		local req = task.spawn(showRequiem)

		Skip.enableSkip(function()
			task.cancel(req)
			task.defer(endReq)
		end)
	end)
end

return module
