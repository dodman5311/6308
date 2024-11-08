local module = {}
--// Services
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local camera = workspace.CurrentCamera

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.DeliverEffects

--// Modules
local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)
local UiAnimator = require(Globals.Vendor.UIAnimationService)
local MouseOver = require(Globals.Vendor.MouseOverModule)
local Signals = require(Globals.Shared.Signals)
local Signal = require(Globals.Packages.Signal)
local Gifts = require(Globals.Shared.Gifts)
local GiftsService = require(Globals.Client.Services.GiftsService)
local SoulsService = require(Globals.Client.Services.SoulsService)
local net = require(Globals.Packages.Net)
local musicService = require(Globals.Client.Services.MusicService)

local deliveryAmount = 0
module.onHidden = Signal.new()

--// Values

--// Functions

local function connectButtonHover(button, reactFrame)
	local enter, leave = MouseOver.MouseEnterLeaveEvent(button)

	enter:Connect(function()
		reactFrame.ImageColor3 = Color3.fromRGB(6, 85, 65)
	end)

	leave:Connect(function()
		reactFrame.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end)
end

local function updateDeliveryText(frame)
	frame.DeliveryAmount.Text = deliveryAmount * 100 .. "%"
end

local function increaseDelivery(frame)
	sfx.Select:Play()

	deliveryAmount += 0.5

	if deliveryAmount > 1 then
		deliveryAmount = 0
	end

	updateDeliveryText(frame)
end

local function decreaseDelivery(frame)
	sfx.Select:Play()

	deliveryAmount -= 0.5

	if deliveryAmount < 0 then
		deliveryAmount = 1
	end

	updateDeliveryText(frame)
end

function module.Init(player, ui, frame)
	frame.Frame.Visible = false
	frame.Background.Visible = false

	connectButtonHover(frame.DecreaseButton, frame.RightButton)
	connectButtonHover(frame.IncreaseButton, frame.LeftButton)

	frame.DecreaseButton.MouseButton1Click:Connect(function()
		decreaseDelivery(frame)
	end)

	frame.IncreaseButton.MouseButton1Click:Connect(function()
		increaseDelivery(frame)
	end)

	local enter, leave = MouseOver.MouseEnterLeaveEvent(frame.DeliveryAmount)

	enter:Connect(function()
		frame.DeliveryAmount.TextColor3 = Color3.fromRGB(0, 255, 225)
		frame.DeliveryAmount.UIStroke.Color = Color3.fromRGB(13, 82, 60)
	end)

	leave:Connect(function()
		frame.DeliveryAmount.TextColor3 = Color3.fromRGB(255, 255, 255)
		frame.DeliveryAmount.UIStroke.Color = Color3.fromRGB(82, 82, 82)
	end)
end

function module.Cleanup(player, ui, frame) end

function module.UpdateSouls(_, _, frame, amount)
	frame.Souls.Count.Text = amount
end

local function getRandomGiftFromDictionary(type)
	local dictionary = Gifts[type]
	local array = {}

	for key, _ in pairs(dictionary) do
		if GiftsService.CheckGift(key) then
			continue
		end

		table.insert(array, key)
	end

	if #array == 0 then
		return
	end

	local selectedKey = array[math.random(1, #array)]
	return selectedKey, dictionary[selectedKey]
end

function module.fakeScreen(player, ui, frame)
	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

	util.tween(frame.Fade, ti, { BackgroundTransparency = 0 })
	task.wait(1)
	util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })

	--musicService.playMusic()
	task.delay(0.1, function()
		module.onHidden:Fire()
		acts:removeAct("InActiveMenu")
	end)
	return module.onHidden
end

local function causeHunger(player, ui, frame)
	local maxHealth = player.Character.Humanoid.MaxHealth

	if deliveryAmount > 0 and SoulsService.Souls > 0 then
		if maxHealth >= 5 then
			return
		end

		net:RemoteEvent("UpdatePlayerHealth"):FireServer(maxHealth + 1)
		module.showDescription(frame, { Desc = "Drav's hunger is partially restored. (+1 Max HP)" })

		return
	end

	if maxHealth > 1 then
		net:RemoteEvent("UpdatePlayerHealth"):FireServer(maxHealth - 1)
		module.showDescription(frame, { Desc = "Drav is starved. (-1 Max HP)" })
	else
		Signals.ClearGifts:Fire()
		Signals.AddGift:Fire("Drav_Is_Dead")
		ui.HUD.Frame.Souls.Image.ImageColor3 = Color3.new(0.35, 0.35, 0.35)
		ui.HUD.Frame.Souls.Count.TextColor3 = Color3.new(0.35, 0.35, 0.35)
		SoulsService.RemoveSoul(SoulsService.Souls)
		module.showDescription(frame, { Desc = "Drav has starved to death. (You've killed your friend)" })
	end
end

function module.ShowScreen(player, ui, frame)
	if GiftsService.CheckGift("Drav_Is_Dead") then
		return module.fakeScreen(player, ui, frame)
	end

	acts:createAct("InActiveMenu")

	musicService.playTrack("Delivery", 1)

	sfx.Open_Deliver:Play()
	sfx.Open_Growl:Play()

	module.emptyGiftSlot(player, ui, frame)

	deliveryAmount = 0
	module.UpdateSouls(player, ui, frame, SoulsService.Souls)

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
	Signals.DoUiAction:Fire("Cursor", "Toggle", true, true)

	frame.DeliveryAmount.Text = "0%"

	frame.IncreaseButton.Visible = true
	frame.DecreaseButton.Visible = true
	frame.DeliveryAmount.Visible = true

	frame.Eat.Visible = false
	frame.Demon.Visible = true
	frame.Box.Visible = true
	frame.Gift.Visible = true

	frame.LeftButton.Visible = true
	frame.RightButton.Visible = true

	frame.Label.ImageTransparency = 0

	frame.Frame.Visible = false
	frame.Background.Visible = false

	frame.Fade.BackgroundTransparency = 1

	frame.Spin.A1.Image = ""

	util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, false, function()
		frame.Background.Visible = true
		frame.Frame.Visible = true

		util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })
	end)

	UiAnimator.PlayAnimation(frame.Demon, 0.125, true)

	task.wait(0.25)

	frame.DeliveryAmount.MouseButton1Click:Once(function()
		sfx.Deliver:Play()
		local giftType = "Perks"

		if deliveryAmount > 0.5 then
			giftType = "Upgrades"
		end

		if deliveryAmount <= 0 or SoulsService.Souls <= 1 or not getRandomGiftFromDictionary(giftType) then
			Signals.DoUiAction:Fire("Cursor", "Toggle", true, false)

			util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, true)

			causeHunger(player, ui, frame)

			if SoulsService.Souls == 1 then
				SoulsService.RemoveSoul(1)
				module.UpdateSouls(player, ui, frame, SoulsService.Souls)
			end

			frame.Frame.Visible = false
			frame.Background.Visible = false
			Signals.DoUiAction:Fire("Cursor", "Toggle", true, false)

			util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })

			module.onHidden:Fire()
			acts:removeAct("InActiveMenu")
			return
		end

		SoulsService.RemoveSoul(SoulsService.Souls * deliveryAmount)
		module.UpdateSouls(player, ui, frame, SoulsService.Souls)

		local chosenGift = module.chooseRandomGift(player, ui, frame, giftType)
		module.TakeDelivery(player, ui, frame, chosenGift)
	end)

	if UserInputService.GamepadEnabled then
		GuiService:Select(frame.Frame)
	end

	return module.onHidden
end

local function loadToGiftsSlot(frame, type)
	local spin = frame.Spin

	for _ = 0, spin.Size.Y.Scale do
		local _, gift = getRandomGiftFromDictionary(type)

		local dummy = spin.A1:Clone()
		dummy.Name = "Dummy"
		dummy.Parent = spin
		dummy.Visible = true
		dummy.Image = gift.Icon
	end
end

function module.emptyGiftSlot(player, ui, frame)
	local spin = frame.Spin

	for _, imageLabel in ipairs(spin:GetChildren()) do
		if imageLabel.Name ~= "Dummy" then
			continue
		end

		imageLabel:Destroy()
	end
end

function module.chooseRandomGift(player, ui, frame, type)
	local name, randomGift = getRandomGiftFromDictionary(type)

	loadToGiftsSlot(frame, type)

	local spin = frame.Spin
	spin.A1.Image = randomGift.Icon
	spin.A1.ImageTransparency = 0

	frame.DeliveryAmount.Visible = false

	local spinTween = TweenInfo.new(sounds.SpinSound.TimeLength, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	spin.Position = UDim2.new(0.5, 0, -spin.Size.Y.Scale, 0)

	sounds.SpinSound:Play()
	util.tween(spin, spinTween, { Position = UDim2.new(0.5, 0, 0, 0) }, true)

	Signals.AddGift:Fire(name)

	frame.GiftName.Text = string.gsub(name, "_", " ")

	task.wait(0.5)

	sfx.Unlocked_Perk:Play()

	util.tween(frame.GiftName, ti, { TextTransparency = 0 })
	util.tween(frame.GiftName.UIStroke, ti, { Transparency = 0 }, true)

	task.wait(1)

	util.tween(frame.GiftName, ti, { TextTransparency = 1 })
	util.tween(frame.GiftName.UIStroke, ti, { Transparency = 1 }, true)

	task.wait(0.1)

	return randomGift
end

function module.showDescription(frame, gift)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	frame.Fade.BackgroundTransparency = 0
	frame.Frame.Visible = false
	frame.Desc.Text = gift.Desc

	util.tween(frame.Fade, ti, { BackgroundTransparency = 1 }, true)

	sfx.Show_Description:Play()

	util.tween(frame.Desc, ti, { TextTransparency = 0 }, true)
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

	util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, true)
	frame.Desc.TextTransparency = 1
	frame.ClickPrompt.TextTransparency = 1

	frame.Frame.Visible = false
end

function module.TakeDelivery(player, ui, frame, gift)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local ti_1 = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	frame.Eat.Visible = true

	frame.IncreaseButton.Visible = false
	frame.DecreaseButton.Visible = false
	frame.DeliveryAmount.Visible = false
	Signals.DoUiAction:Fire("Cursor", "Toggle", true, false)

	frame.Demon.Visible = false
	frame.Box.Visible = false

	frame.LeftButton.Visible = false
	frame.RightButton.Visible = false

	util.tween(frame.Label, ti_1, { ImageTransparency = 1 })

	UiAnimator.StopAnimation(frame.Demon)

	local animation = UiAnimator.PlayAnimation(frame.Eat, 0.065)

	sfx.Build_Growl:Play()
	animation:OnFrameRached(6):Once(function()
		sfx.Perk_Take:Play()
		sfx.Perk_Take_Metal:Play()
		sfx.Perk_Take_Metal_2:Play()
		sfx.Chain_Movement:Play()
	end)

	animation:OnFrameRached(14):Once(function()
		sfx.Bite_Effect:Play()
		task.delay(0.25, function()
			sfx.After_Growl:Play()
		end)
	end)

	animation.OnEnded:Connect(function()
		module.showDescription(frame, gift)

		local maxHealth = player.Character.Humanoid.MaxHealth
		if maxHealth < 5 then
			if deliveryAmount == 1 then
				net:RemoteEvent("UpdatePlayerHealth"):FireServer(5)
				module.showDescription(frame, { Desc = "Drav's hunger is satiated. (5 Max HP)" })
			else
				net:RemoteEvent("UpdatePlayerHealth"):FireServer(maxHealth + 1)
				module.showDescription(frame, { Desc = "Drav's hunger is partially restored. (+1 Max HP)" })
			end
		end

		frame.Background.Visible = false
		Signals.DoUiAction:Fire("Cursor", "Toggle", true, false)

		util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })

		--musicService.playMusic()
		module.onHidden:Fire()
		acts:removeAct("InActiveMenu")
	end)

	animation:OnFrameRached(6):Connect(function()
		frame.Gift.Visible = false
	end)
end

return module
