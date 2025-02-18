local module = {
	tickets = 0,
	soulCost = 1,
}
--// Services
local BadgeService = game:GetService("BadgeService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local camera = workspace.CurrentCamera

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.Kiosk

--// Modules
local util = require(Globals.Vendor.Util)
local UiAnimator = require(Globals.Vendor.UIAnimationService)
local MouseOver = require(Globals.Vendor.MouseOverModule)
local Signals = require(Globals.Shared.Signals)
local Signal = require(Globals.Packages.Signal)
local Gifts = require(Globals.Shared.Gifts)
local GiftsService = require(Globals.Client.Services.GiftsService)
local net = require(Globals.Packages.Net)
local MusicService = require(Globals.Client.Services.MusicService)
local SoulsService = require(Globals.Client.Services.SoulsService)
local weapons = require(Globals.Client.Controllers.WeaponController)
local skip = require(Globals.Shared.Skip)
local timer = require(Globals.Vendor.Timer)
local promise = require(Globals.Packages.Promise)
local acts = require(Globals.Vendor.Acts)
local codexService = require(Globals.Client.Services.CodexService)

local chanceService = require(Globals.Vendor.ChanceService)

module.onHidden = Signal.new()

--// Values

local spinGifts = {
	Clover = {
		Icon = "rbxassetid://16422403509",
		Catagories = { "Luck" },
		Desc = "You gain luck. (+1)",
		Chance = 75,
		GoodLuck = true,
	},

	Large_Clover = {
		Icon = "rbxassetid://16422448268",
		Catagories = { "Luck" },
		Desc = "You gain a lot of luck. (+2)",
		Chance = 50,
		GoodLuck = true,
	},

	Kevlar = { -- remove
		Icon = "rbxassetid://16422610651",
		Catagories = { "Tactical" },
		Desc = "You gain armor. (+1)",
		Chance = 100,
		GoodLuck = false,
	},

	Holy_Kevlar = {
		Icon = "rbxassetid://16422610885",
		Catagories = { "Tactical" },
		Desc = "You gain a lot of armor. (+2)",
		Chance = 75,
		GoodLuck = true,
	},

	Small_Magazine = { -- remove
		Icon = "rbxassetid://17631463318",
		Catagories = { "Tactical" },
		Desc = "You gain a few bullets. (+25% ammo)",
		Chance = 100,
		GoodLuck = false,
	},

	Big_Magazine = {
		Icon = "rbxassetid://17631463215",
		Catagories = { "Tactical" },
		Desc = "You gain a lot of bullets. (+50% ammo)",
		Chance = 75,
		GoodLuck = true,
	},

	Riflemans_Crit = {
		Icon = "rbxassetid://17631463771",
		Catagories = { "Arsenal" },
		Desc = "You gain a chance to deal double damage with assault rifles. (+1% chance)",
		Chance = 65,
		GoodLuck = true,
	},

	Breachers_Crit = {
		Icon = "rbxassetid://17631463680",
		Catagories = { "Arsenal" },
		Desc = "You gain a chance to deal double damage with shotguns. (+1% chance)",
		Chance = 65,
		GoodLuck = true,
	},

	Gun_Slingers_Crit = {
		Icon = "rbxassetid://17631463584",
		Catagories = { "Arsenal" },
		Desc = "You gain a chance to deal double damage with pistols. (+1% chance)",
		Chance = 65,
		GoodLuck = true,
	},

	Knights_Crit = {
		Icon = "rbxassetid://17631463457",
		Catagories = { "Arsenal" },
		Desc = "You gain a chance to deal double damage with melees. (+1% chance)",
		Chance = 65,
		GoodLuck = true,
	},

	Perk_Ticket = {
		Icon = "rbxassetid://16422611287",
		Catagories = { "Luck" },
		Desc = "You gain a perk ticket.",
		Chance = 15,
		GoodLuck = true,
	},

	Nothing = { -- remove
		Icon = "rbxassetid://16422611114",
		Catagories = { "Luck" },
		Desc = "You gain jack squat.",
		Chance = 50,
		GoodLuck = false,
	},
}

local isOther = false
local costMult = 1

--// Functions

local function connectButtonHover(button)
	local enter, leave = MouseOver.MouseEnterLeaveEvent(button)

	enter:Connect(function()
		button.BackgroundTransparency = 0.5
	end)

	leave:Connect(function()
		button.BackgroundTransparency = 1
	end)
end

local function connectButtonHoverUnderHand(frame, button)
	local ti = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
	local enter, leave = MouseOver.MouseEnterLeaveEvent(button)

	enter:Connect(function()
		if not button.Parent.Visible then
			return
		end

		button.BackgroundTransparency = 0.5
		util.tween(frame.SpinHands.Image, ti, { ImageTransparency = 0.825 })
		util.tween(frame.SwitchHands.Image, ti, { ImageTransparency = 0.825 })
	end)

	leave:Connect(function()
		button.BackgroundTransparency = 1
		util.tween(frame.SpinHands.Image, ti, { ImageTransparency = 0 })
		util.tween(frame.SwitchHands.Image, ti, { ImageTransparency = 0 })
	end)
end

function module.getRandomGiftFromLocalList()
	local array = {}

	for key, gift in pairs(spinGifts) do
		if not chanceService.checkChance(gift.Chance, gift.GoodLuck) then
			continue
		end

		table.insert(array, key)
	end

	if #array == 0 then
		return
	end

	local selectedKey = array[math.random(1, #array)]
	return selectedKey, spinGifts[selectedKey]
end

local function getRandomGift(catagory)
	if not catagory then
		return module.getRandomGiftFromLocalList()
	end

	local array = {}

	for key, gift in pairs(Gifts.Perks) do
		if GiftsService.CheckGift(key) then
			continue
		end

		if not table.find(gift.Catagories, catagory) then
			continue
		end

		table.insert(array, { key, gift })
	end

	for key, gift in pairs(Gifts.Upgrades) do
		if GiftsService.CheckGift(key) then
			continue
		end

		if not table.find(gift.Catagories, catagory) then
			continue
		end

		if not chanceService.checkChance(25, true, true) then
			if #array > 0 then
				continue
			end

			table.insert(array, {
				"Nothing",
				{
					Icon = "rbxassetid://16422611114",
					Catagories = { "Luck", "Tactical", "Soul", "Arsenal" },
					Desc = "Nothing is now increased. (+2 Nothing)",
				},
			})

			continue
		end

		table.insert(array, { key, gift })
	end

	if #array == 0 then
		return
	end

	local selectedGift = array[math.random(1, #array)]
	return selectedGift[1], selectedGift[2]
end

local function exit(frame)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
	frame.Fade.BackgroundTransparency = 0

	frame.Frame.Visible = false
	frame.Background.Visible = false
	Signals.DoUiAction:Fire("Cursor", "Toggle", false)

	util.tween(frame.Fade, ti, { BackgroundTransparency = 1 }, false, function()
		frame.Gui.Enabled = false
	end)

	--Signals.ResumeGame:Fire()
	module.onHidden:Fire()

	MusicService.playMusic()

	acts:removeAct("InActiveMenu")
end

local function showText(frame, text)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	frame.GiftName.Text = string.gsub(text, "_", " ")

	task.wait(0.5)

	sfx.Collect:Play()

	util.tween(frame.GiftName, ti, { TextTransparency = 0 })
	util.tween(frame.GiftName.UIStroke, ti, { Transparency = 0 }, true)

	task.wait(1)

	util.tween(frame.GiftName, ti, { TextTransparency = 1 })
	util.tween(frame.GiftName.UIStroke, ti, { Transparency = 1 }, true)

	task.wait(0.1)
end

local function useTicket(player, frame, catagory)
	if not getRandomGift(catagory) then
		return -- no gifts left
	end

	sfx.KioskBuy:Play()

	module.tickets -= 1
	frame.Tickets.Count.Text = module.tickets

	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	util.tween(frame.SpinHands.Image, ti, { ImageTransparency = 0 })

	frame.CatagoryButtons.Visible = false

	local chosenGift = module.chooseRandomGift(player, nil, frame, catagory)
	module.TakeDelivery(nil, nil, frame, chosenGift)
end

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false
	frame.Frame.Visible = false
	frame.Background.Visible = false

	connectButtonHover(frame.UseSoul)
	connectButtonHover(frame.UseTicket)
	connectButtonHoverUnderHand(frame, frame.ArsenalButton)
	connectButtonHoverUnderHand(frame, frame.TacticsButton)

	connectButtonHover(frame.LuckButton)
	connectButtonHover(frame.SoulButton)
	connectButtonHover(frame.ExitButton)

	frame.ExitButton.Visible = true
	frame.ExitButton.MouseButton1Click:Connect(function()
		exit(frame)
	end)

	frame.UseSoul.MouseButton1Click:Connect(function()
		if SoulsService.Souls < module.soulCost * costMult then
			return
		end

		sfx.KioskBuy:Play()

		SoulsService.RemoveSoul(module.soulCost * costMult)

		frame.SelectButtons.Visible = false
		frame.ExitButton.Visible = false

		module.UpdateSouls(player, ui, frame, math.round(SoulsService.Souls))
		--module.soulCost = math.clamp(module.soulCost + 1, 1, 25) -- ADD ONTO COST

		costMult = (GiftsService.CheckUpgrade("A+ Dough") and chanceService.checkChance(15, false)) and 2 or 1

		if GiftsService.CheckGift("Buy_1_Get_1") then
			costMult = (isOther and chanceService.checkChance(25, true)) and 0 or costMult

			isOther = not isOther
		end

		frame.SoulCost.Text = -module.soulCost * costMult

		local chosenGift = module.chooseRandomGift(player, ui, frame)
		module.TakeDelivery(player, ui, frame, chosenGift, true)
	end)

	frame.UseTicket.MouseButton1Click:Connect(function()
		if module.tickets <= 0 then
			return
		end

		--sfx.KioskSwitch:Play()
		--sfx.Squeak:Play()
		sfx.Switch:Play()

		frame.SelectButtons.Visible = false

		frame.SwitchHands.Visible = true
		frame.SpinHands.Visible = false

		local anim = UiAnimator.PlayAnimation(frame.SwitchHands, 0.075)
		local switchAnimation = UiAnimator.PlayAnimation(frame.SwitchFrame, 0.075, false, true)

		switchAnimation:OnFrameRached(4):Connect(function()
			frame.SoulCost.Visible = false
			frame.TicketCost.Visible = false
		end)

		anim.OnEnded:Connect(function()
			frame.SwitchHands.Visible = true
			frame.SpinHands.Visible = true
			frame.CatagoryButtons.Visible = true
		end)
	end)

	frame.ArsenalButton.MouseButton1Click:Connect(function()
		useTicket(player, frame, "Arsenal")
	end)

	frame.LuckButton.MouseButton1Click:Connect(function()
		useTicket(player, frame, "Luck")
	end)

	frame.SoulButton.MouseButton1Click:Connect(function()
		useTicket(player, frame, "Soul")
	end)

	frame.TacticsButton.MouseButton1Click:Connect(function()
		useTicket(player, frame, "Tactical")
	end)
end

function module.Cleanup(player, ui, frame) end

function module.UpdateSouls(_, _, frame, amount)
	local soulsFrame = frame.Souls
	local label = soulsFrame.Count

	label.Text = amount
end

function module.UpdateStats(_, _, frame)
	local luck = frame.Stats.Luck

	luck.Text = "Luck " .. chanceService.getLuck()

	for _, statLabel in ipairs(frame.Stats:GetChildren()) do
		local crit = weapons.critChances[statLabel.Name]

		if not crit then
			continue
		end

		statLabel.Visible = crit > 0
		statLabel.Text = statLabel.Name .. " " .. crit .. "%"
	end
end

function module.ShowScreen(player, ui, frame, playerSouls)
	if frame.Gui.Enabled then
		return
	end

	if GiftsService.CheckUpgrade("A+ Dough") then
		spinGifts.Nothing = nil
		spinGifts.Small_Magazine = nil
		spinGifts.Kevlar = nil
	end

	acts:createAct("InActiveMenu")

	frame.Gui.Enabled = true

	MusicService.playTrack("TheKiosk")

	SoulsService.Souls = playerSouls
	frame.SoulCost.Text = -module.soulCost * costMult

	frame.Tickets.Count.Text = module.tickets
	module.UpdateStats(player, ui, frame)

	module.emptyGiftSlot(player, ui, frame)

	module.UpdateSouls(player, ui, frame, SoulsService.Souls)

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
	Signals.DoUiAction:Fire("Cursor", "Toggle", true)

	frame.SelectButtons.Visible = true
	frame.CatagoryButtons.Visible = false

	frame.SoulCost.Visible = true
	frame.TicketCost.Visible = true

	frame.SpinHands.Visible = true

	frame.SwitchHands.Visible = true

	frame.Gift.Visible = true

	frame.Frame.Visible = false
	frame.Background.Visible = false

	frame.Fade.BackgroundTransparency = 1

	frame.Spin.A1.Image = ""

	frame.Sign.Image.Position = UDim2.fromScale(0, 0)
	frame.SwitchFrame.Image.Position = UDim2.fromScale(0, 0)

	UiAnimator.PlayAnimation(frame.Demon, 0.125, true)
	frame.Sign.Visible = false

	util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, true, function()
		frame.Background.Visible = true
		frame.Frame.Visible = true

		util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })
	end)

	frame.Sign.Visible = true
	UiAnimator.PlayAnimation(frame.Sign, 0.1, false, true)

	if UserInputService.GamepadEnabled then
		GuiService:Select(frame.SelectButtons)
	end

	return module.onHidden
end

local function loadToGiftsSlot(frame, catagory)
	module.emptyGiftSlot(nil, nil, frame)

	local spin = frame.Spin

	for _, icon in ipairs(spin:GetChildren()) do
		if not icon:IsA("ImageLabel") then
			continue
		end

		local _, gift = getRandomGift(catagory)
		if not gift then
			continue
		end

		icon.Image = gift.Icon
	end

	for _ = 0, spin.Size.Y.Scale * 6 do
		local _, gift = getRandomGift(catagory)
		if not gift then
			continue
		end

		local dummy = spin.A4:Clone()
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

	frame.Spin.A1.Image = ""
	frame.Spin.A2.Image = ""
	frame.Spin.A3.Image = ""
	frame.Spin.A4.Image = ""
end

local function addArmor(player, amount)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	net:RemoteEvent("SetArmor"):FireServer(humanoid:GetAttribute("Armor") + amount)
end

function module.chooseRandomGift(player, ui, frame, catagory)
	frame.ExitButton.Visible = false

	local name, randomGift = getRandomGift(catagory)

	loadToGiftsSlot(frame, catagory)

	local spin = frame.Spin
	spin.A4.Image = randomGift.Icon
	spin.A4.ImageTransparency = 0

	frame.SpinHands.Visible = true
	frame.SwitchHands.Visible = false

	spin.Position = UDim2.new(0.5, 0, -(spin.Size.Y.Scale + 1), 0)

	local animation = UiAnimator.PlayAnimation(frame.SpinHands, 0.075)
	animation:OnFrameRached(10):Wait()
	animation.OnEnded:Connect(function()
		frame.SpinHands.Visible = true
		frame.SwitchHands.Visible = true
	end)

	local spinTween = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	sfx.Spin:Play()

	local skipped = false

	for i = 0, 1, 0.01 do
		task.delay(TweenService:GetValue(i, Enum.EasingStyle.Quint, Enum.EasingDirection.In) * 3, function()
			if skipped then
				return
			end

			sfx.Click:Play()
		end)
	end

	local t

	skip.enableSkip(function()
		skipped = true
		t:Cancel()
		spin.Position = UDim2.new(0.5, 0, -0.075, 0)
	end)

	t = util.tween(spin, spinTween, { Position = UDim2.new(0.5, 0, -0.075, 0) })

	t.Completed:Wait()

	if catagory then
		Signals.AddGift:Fire(name)
	else
		if name == "Perk_Ticket" then
			module.tickets += 1
		elseif name == "Clover" then
			codexService.AddEntry("Luck")
			chanceService.luck += 1
		elseif name == "Large_Clover" then
			codexService.AddEntry("Luck")
			chanceService.luck += 2
		elseif name == "Kevlar" then
			addArmor(player, 1)
		elseif name == "Holy_Kevlar" then
			addArmor(player, 2)
		elseif name == "Small_Magazine" then
			Signals.AddAmmo:Fire()
		elseif name == "Big_Magazine" then
			Signals.AddAmmo:Fire(true)
		elseif name == "Riflemans_Crit" then
			weapons.critChances.AR += 1
		elseif name == "Breachers_Crit" then
			weapons.critChances.Shotgun += 1
		elseif name == "Gun_Slingers_Crit" then
			weapons.critChances.Pistol += 1
		elseif name == "Knights_Crit" then
			weapons.critChances.Melee += 1
		end
	end

	frame.Tickets.Count.Text = module.tickets
	module.UpdateSouls(player, ui, frame, SoulsService.Souls)

	skip.hideSkip()

	if skipped then
		task.wait(0.25)
		return randomGift
	end
	showText(frame, name)

	return randomGift
end

local function showDescription(frame, gift, rapido)
	local ti = TweenInfo.new(rapido and 0.15 or 1, Enum.EasingStyle.Linear)

	util.tween(frame.Fade, ti, { BackgroundTransparency = 0 }, true)

	sounds.DeliverEffects.Show_Description:Play()

	frame.Desc.Text = gift.Desc

	local rt = util.tween(frame.Desc, ti, { TextTransparency = 0 })

	skip.enableSkip(function()
		rt:Cancel()
		task.wait()
		local t = timer:getTimer("Kiosk_Wait_Desc_1")
		if t then
			t:Complete()
		end
	end)

	rt.Completed:Wait()

	frame.Desc.TextTransparency = 0

	if not rapido then
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
	else
		timer.wait(4, "Kiosk_Wait_Desc_1")
	end

	util.tween(frame.Desc, ti, { TextTransparency = 1 })
	util.tween(frame.ClickPrompt, ti, { TextTransparency = 1 })
	util.tween(frame.Fade, ti, { BackgroundTransparency = 1 })

	skip.hideSkip()
end

function module.TakeDelivery(player, ui, frame, gift, rapido)
	Signals.DoUiAction:Fire("Cursor", "Toggle", false)

	showDescription(frame, gift, rapido)

	module.emptyGiftSlot(player, ui, frame)

	module.UpdateStats(player, ui, frame)

	frame.SwitchFrame.Image.Position = UDim2.fromScale(0, 0)
	frame.SelectButtons.Visible = true
	frame.CatagoryButtons.Visible = false
	Signals.DoUiAction:Fire("Cursor", "Toggle", true)
	frame.ExitButton.Visible = true

	frame.SoulCost.Visible = true
	frame.TicketCost.Visible = true

	if UserInputService.GamepadEnabled then
		GuiService:Select(frame.SelectButtons)
	end
end

function module.resetCost()
	module.soulCost = 1
end

function module.resetTickets()
	module.tickets = 0
end

Signals.AddTicket:Connect(function(amount)
	module.tickets += amount
end)

net:Connect("StartExitSequence", function()
	module.soulCost = math.clamp(module.soulCost - 2, 1, 25)
end)

return module
