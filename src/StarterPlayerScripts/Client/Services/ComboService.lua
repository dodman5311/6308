local module = {
	CurrentCombo = 0,
	ComboTime = 4,
	MaxCombo = 0,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local Timer = require(Globals.Vendor.Timer)
local UIService = require(Globals.Client.Services.UIService)
local giftService = require(Globals.Client.Services.GiftsService)
local net = require(Globals.Packages.Net)

local comboTimer

local function resetCombo()
	if workspace:GetAttribute("Combo_Tier") >= 3 then
		module.CurrentCombo = math.clamp(module.CurrentCombo - 5, 0, math.huge)
		comboTimer:Run()
	else
		module.CurrentCombo = 0
	end

	if module.CurrentCombo <= 0 then
		UIService.fullUi.HUD.ComboFrame.Visible = false
	else
		UIService.doUiAction("HUD", "SetCombo", module.CurrentCombo)
	end
end

comboTimer = Timer:new("ComboTimer", module.ComboTime, resetCombo)

function module.ResetCombo()
	comboTimer:Cancel()
	resetCombo()
end

local function getComboTime()
	local comboTime = module.ComboTime

	if giftService.CheckGift("Kill_Chain") then
		comboTime += 0.5
	end

	if workspace:GetAttribute("Combo_Tier") >= 2 then
		comboTime += 1
	end
	return comboTime
end

function module.AddToCombo(amount)
	comboTimer.WaitTime = getComboTime()

	module.CurrentCombo += amount
	comboTimer:Reset()
	comboTimer:Run()

	UIService.doUiAction("HUD", "SetCombo", module.CurrentCombo)

	if module.CurrentCombo > 0 then
		UIService.fullUi.HUD.ComboFrame.Visible = true
	end

	if module.CurrentCombo > module.MaxCombo then
		module.MaxCombo = module.CurrentCombo
	end
end

function module.ReduceCombo(amount)
	module.CurrentCombo -= amount

	UIService.doUiAction("HUD", "SetCombo", module.CurrentCombo)

	if module.CurrentCombo <= 0 then
		module.ResetCombo()
	end
end

function module.RestartTimer()
	comboTimer:Reset()
end

comboTimer.OnTimerStepped:Connect(function(currentTime)
	local comboTime = getComboTime()
	UIService.fullUi.HUD.ComboBar.Size = UDim2.fromScale((comboTime - currentTime) / comboTime, 0.1)
end)

function module:OnDied()
	module.MaxCombo = 0
end

local function giveMaxCombo()
	local m = module.MaxCombo
	module.MaxCombo = 0
	return m
end

net:RemoteFunction("GetMaxCombo").OnClientInvoke = giveMaxCombo

return module
