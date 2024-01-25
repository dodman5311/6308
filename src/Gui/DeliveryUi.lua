local module = {}
--// Services
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

--// Modules
local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)
local UiAnimator = require(Globals.Vendor.UIAnimationService)
local MouseOver = require(Globals.Vendor.MouseOverModule)
local Signals = require(Globals.Shared.Signals)
local Gifts = require(Globals.Shared.Gifts)
local GiftsService = require(Globals.Client.Services.GiftsService)

local deliveryAmount = 0

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
	deliveryAmount += 0.5

	if deliveryAmount > 1 then
		deliveryAmount = 0
	end

	updateDeliveryText(frame)
end

local function decreaseDelivery(frame)
	deliveryAmount -= 0.5

	if deliveryAmount < 0 then
		deliveryAmount = 1
	end

	updateDeliveryText(frame)
end

function module.Init(player, ui, frame)
	frame.Frame.Visible = false
	frame.Background.Visible = false
	frame.Cursor.Visible = false

	RunService.RenderStepped:Connect(function()
		local mousePos = UserInputService:GetMouseLocation()
		frame.Cursor.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	end)

	connectButtonHover(frame.DecreaseButton, frame.RightButton)
	connectButtonHover(frame.IncreaseButton, frame.LeftButton)

	frame.DecreaseButton.MouseButton1Click:Connect(function()
		decreaseDelivery(frame)
	end)

	frame.IncreaseButton.MouseButton1Click:Connect(function()
		increaseDelivery(frame)
	end)
end

function module.Cleanup(player, ui, frame) end

function module.UpdateSouls(_, _, frame, amount)
	local soulsFrame = frame.Souls
	local label = soulsFrame.Count

	local loggedAmount = label.Text

	if tonumber(loggedAmount) < amount then
		UiAnimator.PlayAnimation(soulsFrame, 0.045)
	end

	label.Text = amount
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

function module.ShowScreen(player, ui, frame, souls)
	module.emptyGiftSlot(player, ui, frame)

	local clickDeliver

	deliveryAmount = 0
	module.UpdateSouls(player, ui, frame, souls)

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
	frame.Cursor.Visible = true

	frame.DeliveryAmount.Text = "0%"

	frame.IncreaseButton.Visible = true
	frame.DecreaseButton.Visible = true
	frame.DeliveryAmount.Visible = true

	frame.Eat.Visible = false
	frame.Demon.Visible = true
	frame.Box.Visible = true
	frame.Gift.Visible = true

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

	clickDeliver = frame.DeliveryAmount.MouseButton1Click:Connect(function()
		clickDeliver:Disconnect()

		local giftType = "Perks"

		if deliveryAmount > 0.5 then
			giftType = "Upgrades"
		end

		if deliveryAmount <= 0 or souls <= 1 or not getRandomGiftFromDictionary(giftType) then
			frame.Fade.BackgroundTransparency = 0

			frame.Frame.Visible = false
			frame.Background.Visible = false
			frame.Cursor.Visible = false

			util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })

			return
		end

		module.UpdateSouls(player, ui, frame, math.round(souls - (souls * deliveryAmount)))
		Signals.RemoveSoul:Fire((souls * deliveryAmount))

		local chosenGift = module.chooseRandomGift(player, ui, frame, giftType)
		module.TakeDelivery(player, ui, frame, chosenGift)
	end)
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

	frame.GiftName.Text = name

	task.wait(0.5)

	util.tween(frame.GiftName, ti, { TextTransparency = 0 })
	util.tween(frame.GiftName.UIStroke, ti, { Transparency = 0 }, true)

	task.wait(1)

	util.tween(frame.GiftName, ti, { TextTransparency = 1 })
	util.tween(frame.GiftName.UIStroke, ti, { Transparency = 1 }, true)

	task.wait(0.1)

	return randomGift
end

local function showDescription(frame, gift)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	frame.Fade.BackgroundTransparency = 0
	frame.Frame.Visible = false
	frame.Desc.Text = gift.Desc

	util.tween(frame.Fade, ti, { BackgroundTransparency = 1 }, true)
	util.tween(frame.Desc, ti, { TextTransparency = 0 }, true)

	task.wait(3)

	util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, true)
	frame.Desc.TextTransparency = 1
end

function module.TakeDelivery(player, ui, frame, gift)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local ti_1 = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	frame.IncreaseButton.Visible = false
	frame.DecreaseButton.Visible = false
	frame.DeliveryAmount.Visible = false
	frame.Cursor.Visible = false

	frame.Eat.Visible = true
	frame.Demon.Visible = false
	frame.Box.Visible = false

	util.tween(frame.Label, ti_1, { ImageTransparency = 1 })

	UiAnimator.StopAnimation(frame.Demon)

	local animation = UiAnimator.PlayAnimation(frame.Eat, 0.065)

	animation.OnEnded:Connect(function()
		showDescription(frame, gift)

		frame.Background.Visible = false
		frame.Cursor.Visible = false

		util.tween(frame.Fade, ti, { BackgroundTransparency = 1 }, true)
	end)

	animation.OnFrame:Connect(function(currentFrame)
		if currentFrame ~= 6 then
			return
		end

		frame.Gift.Visible = false
	end)
end

return module
