local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local util = require(Globals.Vendor.Util)
local animationService = require(Globals.Vendor.AnimationService)
local upgrades = require(Globals.Shared.Upgrades)
local uiAnimationService = require(Globals.Vendor.UIAnimationService)

local function getUpgradeInfo(npc, getPrev: boolean?)
	if not npc.MindData["UpgradeName"] then
		npc.MindData["UpgradeName"] = "Combo_Tier"
	end

	local upgrade
	for _, category in pairs(upgrades) do
		if category[npc.MindData["UpgradeName"]] then
			upgrade = category[npc.MindData["UpgradeName"]]
			break
		end
	end

	if not upgrade then
		return
	end

	local upgradeName = npc.MindData["UpgradeName"]
	local upgradeIndex = workspace:GetAttribute(upgradeName)

	if not getPrev then
		upgradeIndex += 1
	end

	return upgrade[upgradeIndex], upgradeName, upgradeIndex
end

local function updateGui(npc)
	local gui = npc.MindData.Gui
	local upgradeData = getUpgradeInfo(npc)
	local upgradeFrame = gui.Upgrade

	local newFrame = upgradeFrame:Clone()

	newFrame.Position = UDim2.fromScale(0.5, 1)
	newFrame.Parent = gui
	upgradeFrame.Name = "Old"

	if upgradeData then
		newFrame.Title.Text = upgradeData.Name
		newFrame.Description.Text = upgradeData.Description
		newFrame.Cost.Text = upgradeData.Price
		newFrame.RCoin.Visible = true
	else
		newFrame.Title.Text = "MAX"
		newFrame.Description.Text = "Fully upgraded"
		newFrame.Cost.Text = ""
		newFrame.RCoin.Visible = false
	end

	local ti = TweenInfo.new(0.5)

	util.tween(upgradeFrame, ti, { Position = UDim2.fromScale(0.5, -1) }, false, function()
		upgradeFrame:Destroy()
	end)
	util.tween(newFrame, ti, { Position = UDim2.fromScale(0.5, 0) })
	uiAnimationService.PlayAnimation(newFrame.RCoin, 0.1, true)
end

local function attemptPurchase(npc)
	local upgradeData, uName, uIndex = getUpgradeInfo(npc)

	if upgradeData and workspace:GetAttribute("TotalScore") >= upgradeData.Price then
		animationService:playAnimation(npc.Instance, "Buy", Enum.AnimationPriority.Action)
		workspace:SetAttribute("TotalScore", workspace:GetAttribute("TotalScore") - upgradeData.Price)
		workspace:SetAttribute(uName, uIndex)

		util.PlaySound(npc.Instance.Root.Buy, ReplicatedStorage, 0.1)
		updateGui(npc)
	else
		animationService:playAnimation(npc.Instance, "Deny", Enum.AnimationPriority.Action)
	end
end

local function attemptRefund(npc)
	local upgradeData, uName, uIndex = getUpgradeInfo(npc, true)

	if upgradeData and uIndex > 0 then
		animationService:playAnimation(npc.Instance, "Refund", Enum.AnimationPriority.Action)
		workspace:SetAttribute("TotalScore", workspace:GetAttribute("TotalScore") + upgradeData.Price)
		workspace:SetAttribute(uName, uIndex - 1)

		updateGui(npc)
	else
		animationService:playAnimation(npc.Instance, "Deny", Enum.AnimationPriority.Action)
	end
end
local debounce = false

local function interact(npc, health)
	if debounce then
		return
	end
	debounce = true

	if health <= 100000 then
		attemptPurchase(npc)
	else
		attemptRefund(npc)
	end

	task.delay(0.05, function()
		local humanoid = npc.Instance.Humanoid
		humanoid.Health = humanoid.MaxHealth
		debounce = false
	end)
end

local function loadGui(npc)
	local instance: Model = npc.Instance
	local upgradeData = getUpgradeInfo(npc)

	local gui = npc.Instance.UpgradeGui
	local player: Player = game.Players:GetPlayers()[1]
	gui.Parent = player.PlayerGui
	gui.Adornee = instance.Screen
	gui.Enabled = true

	instance.TitleGui.Title.Text =
		string.sub(npc.MindData.UpgradeName, 1, string.find(npc.MindData.UpgradeName, "_") - 1)
	npc.MindData.Gui = gui

	instance.Destroying:Once(function()
		gui:Destroy()
	end)

	if not upgradeData then
		return
	end

	updateGui(npc)
end

local function onSpawned(npc)
	task.defer(loadGui, npc)

	npc.Instance.Root.Halo.Outer:Emit(1)
	npc.Instance.Root.Halo.Main:Emit(1)
end

local module = {
	OnDamaged = {
		{ Function = "Custom", Parameters = { interact } },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Hazard" } },
		{ Function = "Custom", Parameters = { onSpawned } },
	},

	-- OnDied = {
	-- 	{ Function = "Custom", Parameters = { revive } },
	-- },
}

return module
