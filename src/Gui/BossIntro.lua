local module = {}
--// Services
local DataStoreService = game:GetService("DataStoreService")
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

local voice = Instance.new("Sound")
voice.Parent = script
voice.Volume = 1.5
voice.SoundGroup = SoundService.Voice

--// Modules
local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)
local UiAnimator = require(Globals.Vendor.UIAnimationService)
local Signals = require(Globals.Shared.Signals)
local Signal = require(Globals.Packages.Signal)
local musicService = require(Globals.Client.Services.MusicService)
local gifts = require(Globals.Shared.Gifts)
local MouseOver = require(Globals.Vendor.MouseOverModule)
local GiftsService = require(Globals.Client.Services.GiftsService)
local Gifts = require(Globals.Shared.Gifts)

local net = require(Globals.Packages.Net)

module.onHidden = Signal.new()

local timer = require(Globals.Vendor.Timer):newQueue()
local dialogueWait = timer:new("DialogueWait")

--// Values

local intros = require(Globals.Shared.IntroLines)

--rbxassetid://18265555247
local rewards = {
	["Keeper Of The Third Law"] = {
		"Brick_Hook",
		"Righteous_Motion",
		"Spiked_Sabatons",
	},

	["Visage Of False Hope"] = {
		"Mag_Launcher",
		"Burning_Souls",
		"Galvan_Gaze",
	},

	["Phillip The Everlasting"] = "Master_Scouting",
	["Specimen #09"] = "Overcharge",
}

--// Functions

local function connectButtonHover(button)
	local enter, leave = MouseOver.MouseEnterLeaveEvent(button)

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	button.Parent.Size = UDim2.fromScale(0.8, 0.8)

	enter:Connect(function()
		util.tween(button.Parent, ti, { Size = UDim2.fromScale(0.95, 0.95) })
	end)

	leave:Connect(function()
		util.tween(button.Parent, ti, { Size = UDim2.fromScale(0.8, 0.8) })
	end)
end

local function givePerk(frame, button)
	Signals.DoUiAction:Fire("Cursor", "Toggle", true, false)

	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local title = button.Parent.Title.Text

	Signals.AddGift:Fire(title)

	frame.Condemn.Visible = false

	util.tween(frame.Choices, ti, { Size = UDim2.fromScale(1, 1), GroupTransparency = 1 }, true)

	util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, false, function()
		frame.Background.Visible = false
		frame.Gui.Enabled = false

		net:RemoteEvent("BossExit"):FireServer()
	end)
end

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false
	local choices = frame.Choices

	connectButtonHover(choices.Card_1.Button)
	connectButtonHover(choices.Card_2.Button)
	connectButtonHover(choices.Card_3.Button)

	choices.Card_1.Button.MouseButton1Click:Connect(function()
		givePerk(frame, choices.Card_1.Button)
	end)

	choices.Card_2.Button.MouseButton1Click:Connect(function()
		givePerk(frame, choices.Card_2.Button)
	end)

	choices.Card_3.Button.MouseButton1Click:Connect(function()
		givePerk(frame, choices.Card_3.Button)
	end)
end

function module.Cleanup(player, ui, frame) end

function module.ShowIntro(player, ui, frame, bossName)
	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
	local ti_0 = TweenInfo.new(1, Enum.EasingStyle.Linear)

	for _, v in ipairs(frame.Gui:GetChildren()) do
		v.Visible = false
	end

	acts:createAct("InActiveMenu")

	frame.Gui.Enabled = true

	frame.Background.BackgroundTransparency = 1
	frame.Background.Visible = true

	util.tween(frame.Background, ti, { BackgroundTransparency = 0 })

	task.wait(2.5)

	local intro = intros[bossName]

	if not intro then
		util.tween(frame.Background, ti, { BackgroundTransparency = 1 })
		return
	end

	local bossAmbience = sounds:FindFirstChild("Ambience_" .. bossName)

	bossAmbience.Volume = 0.2
	bossAmbience:Play()

	local bossFrame = frame[bossName]
	UiAnimator.PlayAnimation(bossFrame, 0.2, true)

	bossFrame.Image.ImageTransparency = 1
	bossFrame.Visible = true

	util.tween(bossFrame.Image, ti_0, { ImageTransparency = 0 }, true)

	task.wait(1)

	frame.MessageBox.Message.Text = ""
	frame.MessageBox.ImageTransparency = 1
	frame.MessageBox.Visible = true

	util.tween(frame.MessageBox, ti_0, { ImageTransparency = 0 }, true)

	for _, dialogue in ipairs(intro) do
		voice.SoundId = dialogue.Sound

		local startTime = os.clock()
		while not voice.IsLoaded and os.clock() - startTime < 5 do
			task.wait()
		end

		voice:Play()

		local textLength = string.len(dialogue.Text)
		local waitTime = (voice.TimeLength - 1) / textLength
		local loadTime = math.clamp(textLength / 500, 0.3, 0.5)

		local lastStep = os.clock()
		local i = 0
		local t = 1

		frame.MessageBox.Message.Visible = false
		task.delay(loadTime, function()
			frame.MessageBox.Message.Visible = true
		end)

		local step = RunService.RenderStepped:Connect(function()
			local preString = string.sub(dialogue.Text, 0, i - 1)

			local letter = '<font transparency="' .. t .. '">' .. string.sub(dialogue.Text, i, i)

			local postString = '</font><font transparency="1">'
				.. string.sub(dialogue.Text, i + 1, textLength)
				.. "</font>"

			frame.MessageBox.Message.Text = preString .. letter .. postString

			t = math.clamp(t - 0.1, 0, 1)

			if os.clock() - lastStep < waitTime then
				return
			end

			i += 1
			t = 1

			lastStep = os.clock()
		end)

		voice.Ended:Wait()
		step:Disconnect()

		frame.MessageBox.Message.Text = dialogue.Text

		task.wait(dialogue.Wait)
		-- dialogueWait.WaitTime = dialogue.Wait
		-- dialogueWait:Run()
		-- dialogueWait.OnEnded:Wait()

		frame.MessageBox.Message.Visible = false
	end

	frame.MessageBox.Message.Text = ""

	util.tween(bossFrame.Image, ti_0, { ImageTransparency = 1 })
	util.tween(frame.MessageBox, ti_0, { ImageTransparency = 1 }, true)

	task.delay(0.05, function()
		module.onHidden:Fire()
		acts:removeAct("InActiveMenu")
	end)

	util.tween(frame.Background, ti_0, { BackgroundTransparency = 1 }, false, function()
		frame.Gui.Enabled = false
	end)
	util.tween(bossAmbience, ti_0, { Volume = 0 }, false, function()
		bossAmbience:Stop()
		bossAmbience.Volume = 0.2

		musicService.playTrack(bossName, 0.5)
	end)

	return module.onHidden
end

function module.ShowCompleted(player, ui, frame, bossName)
	local isMiniboss = ReplicatedStorage.Enemies:FindFirstChild(bossName, true):HasTag("MiniBoss")

	for _, v in ipairs(frame.Gui:GetChildren()) do
		v.Visible = false
	end

	acts:createAct("InActiveMenu")

	local condemnFrame = frame.Condemn

	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local ti_0 = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

	frame.Gui.Enabled = true

	condemnFrame.FrameImage.ImageTransparency = 1
	frame.Background.BackgroundTransparency = 1
	frame.Background.Visible = true

	util.tween(frame.Background, ti, { BackgroundTransparency = 0 })

	task.wait(1.25)

	if isMiniboss then
		sounds.BossKillNoVoices:Play()
	else
		sounds.BossKill:Play()
	end

	task.wait(1.25)

	condemnFrame.Visible = true

	util.tween(condemnFrame.FrameImage, ti_0, { ImageTransparency = 0 }, true)

	UiAnimator.PlayAnimation(condemnFrame.Face, 0.1).OnEnded:Wait()

	util.tween(condemnFrame.FrameImage, ti_0, { ImageTransparency = 1 }, true)

	module.showChoices(player, ui, frame, bossName)
end

function module.showDescription(frame, gift)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	frame.GiftDesc.Text = gift.Desc

	util.tween(frame.Award, ti, { GroupTransparency = 1 }, true)

	sounds.DeliverEffects.Show_Description:Play()

	frame.GiftDesc.Visible = true
	frame.ClickPrompt.Visible = true

	util.tween(frame.GiftDesc, ti, { TextTransparency = 0 }, true)
	util.tween(frame.ClickPrompt, ti, { TextTransparency = 0 })

	local skipKeyPressed = false

	local keyPressed = UserInputService.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonX
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			skipKeyPressed = true
		end
	end)

	repeat
		task.wait()
	until skipKeyPressed
	keyPressed:Disconnect()

	util.tween(frame.GiftDesc, ti, { TextTransparency = 1 })
	util.tween(frame.ClickPrompt, ti, { TextTransparency = 1 }, true)

	frame.Condemn.Visible = false

	util.tween(frame.Choices, ti, { Size = UDim2.fromScale(1, 1), GroupTransparency = 1 }, true)

	util.tween(frame.Background, ti, { BackgroundTransparency = 1 }, false, function()
		frame.Background.Visible = false
		frame.Gui.Enabled = false

		net:RemoteEvent("MiniBossExit"):FireServer()
	end)
end

function module.chooseGift(player, ui, frame, bossName)
	local name = rewards[bossName]
	local randomGift = gifts.Specials[name]

	local spin = frame.Gift.A1
	spin.Image = randomGift.Icon
	spin.ImageTransparency = 0

	local spinTween = TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	local ti_0 = TweenInfo.new(0.5, Enum.EasingStyle.Elastic)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	sounds.SpinSound.TimePosition = 1.5
	sounds.SpinSound:Play()

	spin.Size = UDim2.fromScale(2, 2)
	spin.ImageTransparency = 1

	util.tween(spin, spinTween, { Size = UDim2.fromScale(1, 1), ImageTransparency = 0 }, true)
	spin.Position = UDim2.fromScale(0.75, 0.5)
	util.tween(spin, ti_0, { Position = UDim2.fromScale(0.5, 0.5) })

	sounds.SpinSound:Stop()
	sounds.SpinSound.TimePosition = 0
	sounds.DeliverEffects.Perk_Take:Play()

	Signals.AddGift:Fire(name)

	frame.GiftName.Text = string.gsub(name, "_", " ")

	task.wait(0.5)

	sounds.DeliverEffects.Unlocked_Perk:Play()

	util.tween(frame.GiftName, ti, { TextTransparency = 0 })
	util.tween(frame.Awarded, ti, { TextTransparency = 0 })

	task.wait(2)

	util.tween(frame.GiftName, ti, { TextTransparency = 1 })
	util.tween(frame.Awarded, ti, { TextTransparency = 1 })

	task.wait(0.1)

	return randomGift
end

function module.showChoices(player, ui, frame, bossName)
	local ti_0 = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	if typeof(rewards[bossName]) == "string" then
		local award = frame.Award
		award.Awarded.TextTransparency = 1
		award.GiftName.TextTransparency = 1

		award.GroupTransparency = 1
		award.Visible = true
		util.tween(award, ti_0, { Size = UDim2.fromScale(1, 1), GroupTransparency = 0 })
		module.showDescription(frame, module.chooseGift(player, ui, frame, bossName))

		acts:removeAct("InActiveMenu")

		return
	end

	local choices = frame.Choices
	Signals.DoUiAction:Fire("Cursor", "Toggle", true, true)

	for index, perkName in ipairs(rewards[bossName]) do
		local perk = gifts.Specials[perkName]

		local card = choices:FindFirstChild("Card_" .. index)
		card.Icon.Image = perk.Icon
		card.Title.Text = perkName
		card.Desc.Text = perk.Desc
	end

	choices.Size = UDim2.fromScale(0.9, 0.9)
	choices.GroupTransparency = 1
	choices.Visible = true

	util.tween(choices, ti_0, { Size = UDim2.fromScale(1, 1), GroupTransparency = 0 }, true)

	acts:removeAct("InActiveMenu")
end

return module
