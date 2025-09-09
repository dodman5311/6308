local module = {}
--// Services
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local camera = workspace.CurrentCamera

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.DeliverEffects

--// Modules
local Gifts = require(Globals.Shared.Gifts)
local GiftsService = require(Globals.Client.Services.GiftsService)
local MouseOver = require(Globals.Vendor.MouseOverModule)
local Signal = require(Globals.Packages.Signal)
local Signals = require(Globals.Shared.Signals)
local SoulsService = require(Globals.Client.Services.SoulsService)
local UiAnimator = require(Globals.Vendor.UIAnimationService)
local acts = require(Globals.Vendor.Acts)
local musicService = require(Globals.Client.Services.MusicService)
local net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)

local deliveryAmount = 0
local giftCount = 1
module.onHidden = Signal.new()

local giftsToChoose = {}

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

local function connectGiftButtonHover(button)
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

local function givePerk(frame, index)
	for _, buttonFrame in ipairs(frame.Choices:GetChildren()) do
		if not buttonFrame:IsA("Frame") then
			continue
		end

		buttonFrame.Button.Active = false
	end

	Signals.DoUiAction:Fire("Cursor", "Toggle", false)

	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quart)
	local title = giftsToChoose[index]
	for i = 1, 3 do
		if index == i then
			continue
		end

		util.tween(frame["Spin" .. i].A1, ti, { ImageTransparency = 1 })
	end

	sfx.Unlocked_Perk:Play()
	GiftsService.AddGift(title)
	util.tween(frame.Choices, ti, { Size = UDim2.fromScale(1, 1), GroupTransparency = 1 })
	util.tween(frame["Spin" .. index], ti, { Position = UDim2.fromScale(0.5, frame["Spin" .. index].Position.Y.Scale) })
	util.tween(frame.Fart, ti, { ImageTransparency = 0 })
	util.tween(frame.Box, ti, { Size = UDim2.fromScale(0.148, 0.263) }, true)
	frame.Choices.Visible = false

	module.TakeDelivery(Players.LocalPlayer, nil, frame)
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

	local choices = frame.Choices

	connectGiftButtonHover(choices.Card_1.Button)
	connectGiftButtonHover(choices.Card_2.Button)
	connectGiftButtonHover(choices.Card_3.Button)

	choices.Card_1.Button.MouseButton1Click:Connect(function()
		print(1)
		givePerk(frame, 1)
	end)

	choices.Card_2.Button.MouseButton1Click:Connect(function()
		print(2)
		givePerk(frame, 2)
	end)

	choices.Card_3.Button.MouseButton1Click:Connect(function()
		print(3)
		givePerk(frame, 3)
	end)
end

function module.Cleanup(player, ui, frame) end

function module.UpdateSouls(_, _, frame, amount)
	frame.Souls.Count.Text = amount
end

local function getRandomGiftFromDictionary(type: string, list: {}?)
	local dictionary = list or Gifts[type]
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
		if maxHealth >= player:GetAttribute("MaxHealth") then
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
		GiftsService.AddGift("Drav_Is_Dead")
		ui.HUD.Frame.Souls.Image.ImageColor3 = Color3.new(0.35, 0.35, 0.35)
		ui.HUD.Frame.Souls.Count.TextColor3 = Color3.new(0.35, 0.35, 0.35)
		SoulsService.RemoveSoul(SoulsService.Souls)
		module.showDescription(frame, { Desc = "Drav has starved to death. (You've killed your friend)" })
	end
end

function module.showChoices(player, ui, frame, type)
	for _, buttonFrame in ipairs(frame.Choices:GetChildren()) do
		if not buttonFrame:IsA("Frame") then
			continue
		end

		buttonFrame.Button.Active = true
	end

	local ti_0 = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	local choices = frame.Choices
	choices.Visible = true
	Signals.DoUiAction:Fire("Cursor", "Toggle", true)

	for _, v in ipairs(choices:GetChildren()) do
		if not v:IsA("Frame") then
			continue
		end

		v.Visible = false
	end

	for index, perkName in ipairs(giftsToChoose) do
		local perk = Gifts[type][perkName]

		local card = choices:FindFirstChild("Card_" .. index)
		card.Icon.Image = perk.Icon
		card.Title.Text = perkName
		card.Description.Text = perk.Desc
		card.Visible = true
	end

	choices.Size = UDim2.fromScale(0.9, 0.9)
	choices.GroupTransparency = 1
	choices.Visible = true

	sfx.Show_Description:Play()
	util.tween(choices, ti_0, { Size = UDim2.fromScale(1, 1), GroupTransparency = 0 }, true)

	acts:removeAct("InActiveMenu")
end

function module.ShowScreen(player, ui, frame, extraSouls)
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

	frame.Souls.Added.Visible = extraSouls and extraSouls > 0
	frame.Souls.Added.Text = "+" .. extraSouls

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
	Signals.DoUiAction:Fire("Cursor", "Toggle", true)

	frame.DeliveryAmount.Text = "0%"

	frame.IncreaseButton.Visible = true
	frame.DecreaseButton.Visible = true
	frame.DeliveryAmount.Visible = true

	frame.Eat.Visible = false
	frame.Demon.Visible = true
	frame.Box.Visible = true
	frame.Fart.Visible = true
	frame.Gift.Visible = true

	frame.LeftButton.Visible = true
	frame.RightButton.Visible = true

	frame.Label.ImageTransparency = 0

	frame.Frame.Visible = false
	frame.Background.Visible = false

	frame.Fade.BackgroundTransparency = 1

	frame.Spin1.A1.Image = ""
	frame.Spin2.A1.Image = ""
	frame.Spin3.A1.Image = ""

	util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, false, function()
		frame.Background.Visible = true
		frame.Frame.Visible = true

		util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })
	end)

	UiAnimator.PlayAnimation(frame.Demon, 0.125, true)

	task.wait(0.25)

	frame.DeliveryAmount.MouseButton1Click:Once(function()
		giftsToChoose = {}

		sfx.Deliver:Play()
		local giftType = "Perks"

		if deliveryAmount > 0.5 then
			giftType = "Upgrades"
		end

		if deliveryAmount <= 0 or SoulsService.Souls <= 1 or not getRandomGiftFromDictionary(giftType) then
			Signals.DoUiAction:Fire("Cursor", "Toggle", false)

			util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, true)

			causeHunger(player, ui, frame)

			if SoulsService.Souls == 1 then
				SoulsService.RemoveSoul(1)
				module.UpdateSouls(player, ui, frame, SoulsService.Souls)
			end

			frame.Frame.Visible = false
			frame.Background.Visible = false
			Signals.DoUiAction:Fire("Cursor", "Toggle", false)

			util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })

			module.onHidden:Fire()
			acts:removeAct("InActiveMenu")
			return
		end

		local soulsToGive = SoulsService.Souls * deliveryAmount

		if deliveryAmount > 0.5 then
			if soulsToGive >= 6 then
				giftCount = 3
			elseif soulsToGive >= 4 then
				giftCount = 2
			else
				giftCount = 1
			end
		else
			if soulsToGive >= 3 then
				giftCount = 3
			elseif soulsToGive >= 2 then
				giftCount = 2
			else
				giftCount = 1
			end
		end

		SoulsService.RemoveSoul(soulsToGive)

		module.UpdateSouls(player, ui, frame, SoulsService.Souls)

		local chosenGift

		local ti = TweenInfo.new(sounds.SpinSound.TimeLength, Enum.EasingStyle.Quart)
		local ti_1 = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

		if giftCount == 2 then
			frame.Spin1.Position = UDim2.fromScale(0.375, 0)
			frame.Spin2.Position = UDim2.fromScale(0.625, 0)

			util.tween(frame.Box, ti, { Size = UDim2.fromScale(0.225, 0.263) })
		elseif giftCount == 3 then
			frame.Spin1.Position = UDim2.fromScale(0.25, 0)
			frame.Spin2.Position = UDim2.fromScale(0.5, 0)
			frame.Spin3.Position = UDim2.fromScale(0.75, 0)

			util.tween(frame.Box, ti, { Size = UDim2.fromScale(0.315, 0.263) })
		else
			frame.Spin1.Position = UDim2.fromScale(0.5, 0)
			frame.Box.Size = UDim2.fromScale(0.148, 0.263)

			local name = getRandomGiftFromDictionary(giftType, Gifts[giftType])
			chosenGift = module.chooseRandomGift(player, ui, frame.Spin1, giftType, name)
			module.TakeDelivery(player, ui, frame, chosenGift)

			if UserInputService.GamepadEnabled then
				GuiService:Select(frame.Frame)
			end

			return module.onHidden
		end

		util.tween(frame.Label, ti_1, { ImageTransparency = 1 })
		util.tween(frame.Fart, ti_1, { ImageTransparency = 1 })

		local availableGifts = table.clone(Gifts[giftType])

		for i = 1, giftCount do
			local name = getRandomGiftFromDictionary(giftType, availableGifts)
			availableGifts[name] = nil
			table.insert(giftsToChoose, name)

			if i == giftCount then
				module.chooseRandomGift(player, ui, frame["Spin" .. i], giftType, giftsToChoose[i])
			else
				task.spawn(function()
					module.chooseRandomGift(player, ui, frame["Spin" .. i], giftType, giftsToChoose[i])
				end)
			end
		end

		task.wait(0.5)

		module.showChoices(player, ui, frame, giftType)
	end)

	if UserInputService.GamepadEnabled then
		GuiService:Select(frame.Frame)
	end

	return module.onHidden
end

local function loadToGiftsSlot(spinFrame, type)
	spinFrame.A1.ImageTransparency = 0

	for _ = 0, spinFrame.Size.Y.Scale do
		local _, gift = getRandomGiftFromDictionary(type)

		local dummy = spinFrame.A1:Clone()
		dummy.Name = "Dummy"
		dummy.Parent = spinFrame
		dummy.Visible = true
		dummy.Image = gift.Icon
	end
end

function module.emptyGiftSlot(player, ui, frame)
	local spin = frame.Spin1

	for _, imageLabel in ipairs(spin:GetChildren()) do
		if imageLabel.Name ~= "Dummy" then
			continue
		end

		imageLabel:Destroy()
	end
end

function module.chooseRandomGift(player, ui, spinFrame, type, name)
	local randomGift = Gifts[type][name]

	loadToGiftsSlot(spinFrame, type)

	spinFrame.A1.Image = randomGift.Icon
	spinFrame.A1.ImageTransparency = 0
	spinFrame.Visible = true

	local frame = spinFrame.Parent.Parent

	frame.DeliveryAmount.Visible = false

	local spinTween = TweenInfo.new(sounds.SpinSound.TimeLength, Enum.EasingStyle.Quart)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	local logPos = spinFrame.Position.X.Scale
	spinFrame.Position = UDim2.new(0.5, 0, -spinFrame.Size.Y.Scale, 0)

	sounds.SpinSound:Play()

	util.tween(spinFrame, spinTween, { Position = UDim2.new(logPos, 0, 0, 0) }, true)

	frame.GiftName.Text = string.gsub(name, "_", " ")

	if giftCount > 1 then
		return randomGift
	end

	GiftsService.AddGift(name)

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

	util.tween(frame.Fade, ti, { BackgroundTransparency = 1 }, true)

	if gift then
		sfx.Show_Description:Play()
		frame.Desc.Text = gift.Desc

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
	end

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
	Signals.DoUiAction:Fire("Cursor", "Toggle", false)

	frame.Demon.Visible = false
	frame.Box.Visible = false
	frame.Fart.Visible = false

	frame.LeftButton.Visible = false
	frame.RightButton.Visible = false

	util.tween(frame.Label, ti_1, { ImageTransparency = 1 })
	util.tween(frame.Fart, ti_1, { ImageTransparency = 0 })
	util.tween(frame.Box, ti_1, { Size = UDim2.fromScale(0.148, 0.263) })

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
		--if giftCount == 1 and gift then
		module.showDescription(frame, gift)
		--end

		local maxHealth = player.Character.Humanoid.MaxHealth
		if maxHealth < player:GetAttribute("MaxHealth") then
			if deliveryAmount == 1 then
				net:RemoteEvent("UpdatePlayerHealth"):FireServer(player:GetAttribute("MaxHealth"))
				module.showDescription(frame, { Desc = "Drav's hunger is satiated. (Full Max HP)" })
			else
				net:RemoteEvent("UpdatePlayerHealth"):FireServer(maxHealth + 1)
				module.showDescription(frame, { Desc = "Drav's hunger is partially restored. (+1 Max HP)" })
			end
		end

		frame.Background.Visible = false
		Signals.DoUiAction:Fire("Cursor", "Toggle", false)

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
