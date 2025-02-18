local module = {}
--// Services
local BadgeService = game:GetService("BadgeService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextService = game:GetService("TextService")
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
local Signals = require(Globals.Shared.Signals)

--// Values

--// Functions

function module.Init(player, ui, frame)
	for _, v in ipairs(frame.Gui:GetChildren()) do
		if not v:IsA("Frame") then
			continue
		end
		v.Visible = false
	end

	task.delay(1, function()
		StarterGui:SetCore("BadgesNotificationsActive", false)
	end)
end

function module.Cleanup(player, ui, frame) end

function module.ArenaComplete(player, ui, frame, awardTicket, result)
	local complete = frame.ArenaComplete
	complete.Image.Visible = true

	if result == "Failure" then
		complete = frame.ArenaFailed
	else
		complete.Reward.Text = ""
		sounds.Completed:Play()
	end

	complete.Visible = true

	local animation = UiAnimator.PlayAnimation(complete, 0.05, false, true)

	animation:OnFrameRached(4):Connect(function()
		animation:Pause()
		task.wait(0.75)
		animation:Resume()
	end)

	animation.OnEnded:Connect(function()
		complete.Image.Visible = false

		if not awardTicket or result == "Failure" then
			complete.Visible = false
			return
		end

		local text = "Perk Ticket Awarded"

		sounds.Paper:Play()
		Signals.AddTicket:Fire(1)

		for i = 0, string.len(text) do
			complete.Reward.Text = string.sub(text, 0, i)
			task.wait()
		end
		task.wait(1)
		for i = string.len(text), 0, -1 do
			complete.Reward.Text = string.sub(text, 0, i)
			task.wait()
		end

		complete.Visible = false
	end)
end

function module.ArenaBegun(player, ui, frame)
	frame.Ratio.Visible = true
	frame.ArenaBegun.Visible = true

	sounds.ArenaBegun:Play()

	local animation = UiAnimator.PlayAnimation(frame.ArenaBegun, 0.06)

	animation.OnEnded:Connect(function()
		frame.ArenaBegun.Visible = false
	end)
end

local tipsShown = {}

function module.ShowTip(player, ui, frame, tip: string, showOnce: boolean?, condition: boolean?)
	if condition == false then
		return
	end

	if showOnce then
		if table.find(tipsShown, tip) then
			return
		end
		table.insert(tipsShown, tip)
	end

	frame.Ratio.Visible = true
	frame.TipFrame.Visible = true

	local ti = TweenInfo.new(0.25)
	frame.TipFrame.Tip.Message.Text = tip

	UiAnimator.PlayAnimation(frame.TipFrame.Tip.DravIcon, 0.1, true)

	util.tween(frame.TipFrame.Tip, ti, { Position = UDim2.fromScale(0, 0) })
	task.delay(5, function()
		util.tween(frame.TipFrame.Tip, ti, { Position = UDim2.fromScale(0, -1) })
	end)
end

function module.AmbushBegun(player, ui, frame)
	frame.Ambush.Visible = true

	sounds.Ambush:Play()

	local animation = UiAnimator.PlayAnimation(frame.Ambush, 0.06)

	animation.OnEnded:Connect(function()
		frame.Ambush.Visible = false
	end)
end

function module.ShowFeared(player, ui, frame, enemyModel)
	if not enemyModel.Parent then
		return
	end

	local newFear = frame.Fear:Clone()
	newFear.Parent = enemyModel
	newFear.Enabled = true

	local ti = TweenInfo.new(0.65, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

	UiAnimator.PlayAnimation(newFear.Frame, 0.045, true)

	--Debris:AddItem(newFear, 0.5)

	util.tween(newFear.Frame.Image, ti, { ImageTransparency = 1 }, true)

	newFear:Destroy()
end

function module.ShowWeapon(player, ui, frame, weaponName)
	local pickupFrame = frame.GunPickup

	pickupFrame.NameLabel.Text = string.upper(weaponName)
	pickupFrame.NameLabel.TextTransparency = 0
	pickupFrame.Visible = true

	sounds.Pickup:Play()

	local ti = TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

	util.tween(pickupFrame.NameLabel, ti, { TextTransparency = 1 }, false, function()
		pickupFrame.Visible = false
	end)
end

local notiQueue = {}

function module.AddEntry(player, ui, frame, entryName, important)
	local noti = frame.Codex:Clone()
	noti.Name = "NewNoti"
	noti.Parent = frame.Gui

	table.insert(notiQueue, noti)

	while notiQueue[1] ~= noti do
		task.wait()
	end

	local notification = noti.Frame.Notification
	local entryTitle = noti.Frame.EntryTitle

	notification.Position = UDim2.fromScale(0.45, 0)

	noti.Visible = true

	entryTitle.Text = entryName
	notification.Important.Visible = important

	-- if important then
	-- 	entryTitle.TextColor3 = Color3.fromRGB(255, 150, 150)
	-- 	notification.ImageColor3 = Color3.fromRGB(255, 150, 150)
	-- else
	-- 	entryTitle.TextColor3 = Color3.new(1, 1, 1)
	-- 	notification.ImageColor3 = Color3.new(1, 1, 1)
	-- end

	if important then
		util.PlaySound(sounds.ImportantEntry, script)
		acts:createAct("EntryAdded")
	end

	local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quart)
	util.tween(notification, ti, { Position = UDim2.fromScale(0, 0) })

	task.wait(important and 4 or 2)

	util.tween(notification, ti, { Position = UDim2.fromScale(0.45, 0) }, true)

	table.remove(notiQueue, table.find(notiQueue, noti))
	noti:Destroy()

	if important then
		acts:removeAct("EntryAdded")
	end
end

function module.AchievementUnlocked(player, ui, frame, id)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	local badgeInfo = BadgeService:GetBadgeInfoAsync(id)
	sounds.Achievement:Play()

	if not badgeInfo then
		return
	end

	local achievementUi = frame.Achievement:Clone()
	achievementUi.Name = "ActiveAchievement"
	achievementUi.Parent = frame.Gui
	achievementUi.Title.Text = badgeInfo.Name
	achievementUi.Description.Text = badgeInfo.Description
	achievementUi.Icon.Image = "rbxassetid://" .. badgeInfo.IconImageId
	achievementUi.Position = UDim2.fromScale(1, 1.2)

	achievementUi.Visible = true

	util.tween(achievementUi, ti, { Position = UDim2.fromScale(1, 1) }, true)
	task.wait(5)
	util.tween(achievementUi, ti, { Position = UDim2.fromScale(1, 1.2) }, true)
	achievementUi:Destroy()
end

function module.GameSaved(player, ui, frame)
	frame.GameSaved.Visible = true
	local icon = frame.GameSaved.Icon

	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	util.tween(icon, ti, { ImageTransparency = 0 }, false, function()
		task.wait(2.5)
		util.tween(icon, ti, { ImageTransparency = 1 })
	end)
end

return module
