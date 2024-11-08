local module = {
	unlocked = false,
}
--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
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

local levelsPassed = Instance.new("IntValue")

--// Values

--// Functions

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false

	levelsPassed.Value = player:GetAttribute("furthestLevel")

	levelsPassed.Changed:Connect(function(value)
		frame.Unlock.ProgressNumber.Text = value
		util.PlaySound(sfx.Tick, script, 0.05)
	end)

	frame.ContinueButton.MouseButton1Click:Connect(function()
		local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

		SoundService.AmbientReverb = Enum.ReverbType.NoReverb

		util.tween(frame.ReturnToMenu, ti, { GroupTransparency = 1 })
		util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, true)
		frame.Gui.Enabled = false
		frame.Unlock.Visible = false
		frame.ReturnToMenu.Visible = false

		Signals.DoUiAction:Fire("Cursor", "Toggle", true, false)
	end)

	frame.ReturnButton.MouseButton1Click:Connect(function()
		frame.Loading.Visible = true
		frame.LoadingBackground.Visible = true

		TeleportService:SetTeleportGui(ReplicatedStorage.LoadingScreen)
		TeleportService:Teleport(17820071397, player)
	end)
end

function module.Cleanup(player, ui, frame) end

local function showUnlock(player, ui, frame)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local unlock = frame.Unlock

	task.wait(2)

	local animationTime = 0.055

	unlock.Visible = true
	unlock.Image.Visible = true
	unlock.Image.ImageTransparency = 1
	unlock.UpgradeUnlocked.Visible = false
	unlock.ProgressNumber.TextTransparency = 1

	sfx.Boom:Play()

	for i = 1, 0, -0.25 do
		unlock.Image.ImageTransparency = i
		task.wait(animationTime)
	end

	unlock.Image.ImageTransparency = 0

	task.wait(0.1)

	sfx.RingLow:Play()

	local animation = UiAnimator.PlayAnimation(unlock, animationTime, false)

	animation:OnFrameRached(6):Once(function()
		for i = 1, 0, -0.25 do
			unlock.ProgressNumber.TextTransparency = i
			task.wait(animationTime)
		end

		unlock.ProgressNumber.TextTransparency = 0
	end)

	animation:OnFrameRached(11):Once(function()
		animation:Pause()

		util.tween(
			levelsPassed,
			TweenInfo.new(0.5, Enum.EasingStyle.Quart),
			{ Value = player:GetAttribute("furthestLevel") },
			true
		)

		task.wait(1)

		for i = 0, 1, 0.25 do
			unlock.ProgressNumber.TextTransparency = i
			task.wait(animationTime)
		end

		sfx.ReverseGlass:Play()

		task.wait(0.1)

		animation:Resume()
		animation.OnEnded:Connect(function()
			unlock.Image.Visible = false
			frame.WhiteFrame.Visible = true

			unlock.UpgradeUnlocked.Size = UDim2.fromScale(1, 1)
			unlock.UpgradeUnlocked.ImageTransparency = 0
			unlock.UpgradeUnlocked.Visible = true
			frame.WhiteFrame.BackgroundTransparency = 0

			sfx.Break:Play()

			util.tween(
				unlock.UpgradeUnlocked,
				TweenInfo.new(3.5, Enum.EasingStyle.Quart),
				{ Size = UDim2.fromScale(1.05, 1.05) }
			)

			for i = 0, 1, 0.25 do
				frame.WhiteFrame.BackgroundTransparency = i
				task.wait(animationTime)
			end

			task.wait(3.5)

			util.tween(unlock.UpgradeUnlocked, ti, { ImageTransparency = 1 })
			frame.ReturnToMenu.Visible = true
			frame.ReturnToMenu.GroupTransparency = 1
			util.tween(frame.ReturnToMenu, ti, { GroupTransparency = 0 })
			Signals.DoUiAction:Fire("Cursor", "Toggle", true, true)
		end)
	end)
end

function module.ShowDeathScreen(player, ui, frame)
	local logVolume = SoundService.Music.Volume
	SoundService.Music.Volume = 0

	frame.Gui.Enabled = true

	local HealthBroken = frame.HealthBroken
	local Requiem = frame.Requiem
	local unlock = frame.Unlock

	unlock.Visible = false

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

		SoundService.AmbientReverb = Enum.ReverbType.Arena
		sfx.EvilVoices:Play()

		task.wait(0.2)

		UiAnimator.PlayAnimation(Requiem, 0.2, false, true).OnEnded:Once(function()
			task.wait(3.95)
			MusicService.playMusic()
			task.wait(0.05)
			SoundService.Music.Volume = logVolume

			sfx.EvilVoices:Stop()
			Requiem.Visible = false

			if module.unlocked then
				showUnlock(player, ui, frame)
			else
				SoundService.AmbientReverb = Enum.ReverbType.NoReverb
				util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, true)
				frame.Gui.Enabled = false
			end

			module.unlocked = false
		end)
	end)
end

Players.LocalPlayer:GetAttributeChangedSignal("furthestLevel"):Connect(function()
	if Players.LocalPlayer:GetAttribute("furthestLevel") <= 2 then
		return
	end
	module.unlocked = true
end)

return module
