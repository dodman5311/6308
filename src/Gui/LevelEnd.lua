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
local Signals = require(Globals.Shared.Signals)

local ComboValue = Instance.new("IntValue")
local EnemiesValue = Instance.new("IntValue")
local ItemsValue = Instance.new("IntValue")
local TimeValue = Instance.new("IntValue")

--// Values

local soulsAwarded = 0

--// Functions
local function Format(Int)
	return string.format("%02i", Int)
end

local function convertToHMS(Seconds)
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds = Seconds - Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes = Minutes - Hours * 60
	return Format(Hours) .. ":" .. Format(Minutes) .. ":" .. Format(Seconds)
end

local function AddToMaxScore(number, frame)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local scoreAmount = frame.Score.Amount
	frame.Score.Size = UDim2.fromScale(0.5, 0.1)
	frame.Score.Rotation = -5

	scoreAmount.Text += number
	util.tween(frame.Score, ti, { Size = UDim2.fromScale(0.422, 0.075), Rotation = 0 }, true)
end

local function awardSouls(frame, value, threshold)
	if value < threshold then
		return
	end

	local amount = math.floor((value - threshold) / 100) + 1

	soulsAwarded += amount
	frame.SoulAwarded.Count.Text = "+" .. amount
	frame.SoulAwarded.Visible = true
end

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false

	ComboValue.Changed:Connect(function(value)
		frame.Combo.Amount.Text = "X" .. value
	end)

	EnemiesValue.Changed:Connect(function(value)
		frame.Enemies.Amount.Text = value .. "%"
	end)

	ItemsValue.Changed:Connect(function(value)
		frame.Items.Amount.Text = value .. "%"
	end)

	TimeValue.Changed:Connect(function(value)
		frame.MapTime.Text = convertToHMS(value)
	end)
end

function module.Cleanup(player, ui, frame) end

function module.ShowLevelEnd(player, ui, frame, levelData)
	frame.Gui.Enabled = true
	frame.Frame.GroupTransparency = 1
	soulsAwarded = 0

	if not levelData then
		levelData = {
			Name = "The Suburbs : 1",
			TimeTaken = 120,
			EnemiesKilled = 100,
			ArenasCompleted = 100,
			MaxCombo = 30,
		}
	end

	frame.MapName.Text = levelData.Name

	TimeValue.Value = 0
	EnemiesValue.Value = 0
	ItemsValue.Value = 0
	ComboValue.Value = 0

	frame.Score.Amount.Text = 0
	frame.Combo.Amount.Text = "X0"
	frame.Enemies.Amount.Text = "0%"
	frame.Items.Amount.Text = "0%"
	frame.MapTime.Text = convertToHMS(0)

	frame.SoulAwarded.Visible = false

	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
	local ti_0 = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	UiAnimator.PlayAnimation(frame.Skull, 0.045, true)

	util.tween(frame.Frame, ti_0, { GroupTransparency = 0 }, true)
	task.wait(1)

	util.tween(TimeValue, ti, { Value = levelData.TimeTaken }, true)

	task.wait(0.5)

	util.tween(EnemiesValue, ti, { Value = levelData.EnemiesKilled }, true)
	AddToMaxScore(EnemiesValue.Value, frame)

	task.wait(0.5)

	util.tween(ItemsValue, ti, { Value = levelData.ArenasCompleted }, true)
	AddToMaxScore(ItemsValue.Value, frame)

	task.wait(0.5)

	util.tween(ComboValue, ti, { Value = levelData.MaxCombo }, true)
	AddToMaxScore(ComboValue.Value * 10, frame)

	task.wait(0.5)

	awardSouls(frame.Score, tonumber(frame.Score.Amount.Text), 300)

	task.wait(2)

	task.delay(0.5, function()
		frame.Frame.GroupTransparency = 1
		frame.Gui.Enabled = false
		UiAnimator.StopAnimation(frame.Skull)
	end)

	return soulsAwarded
end

return module
