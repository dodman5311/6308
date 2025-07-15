local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local util = require(Globals.Vendor.Util)
local animationService = require(Globals.Vendor.AnimationService)
local upgrades = require(Globals.Shared.Upgrades)
local uiAnimationService = require(Globals.Vendor.UIAnimationService)
local spawners = require(Globals.Services.Spawners)

local debounce = false
local inTransition = false
local PADDING = 0.25
local RACK_SIZE = 20

local categories = {}

for category, _ in pairs(upgrades) do
	table.insert(categories, category)
end

local function weldUpgradeUnit(upgradeUnitNpc, weldPart): Weld
	local newWeldConstraint = Instance.new("Weld")
	newWeldConstraint.Parent = upgradeUnitNpc.Instance
	newWeldConstraint.Part0 = weldPart
	newWeldConstraint.Part1 = upgradeUnitNpc.Instance.PrimaryPart
	return newWeldConstraint
end

local function showUnits(npc, direction)
	if inTransition then
		return
	end
	inTransition = true

	local unitCount = 1
	local numericalUnitIndex = 0
	local weldPart
	local lastWeldPart

	direction = direction or 1

	if npc.MindData.CurrentWeldIndex == "A" then
		weldPart = npc.Instance.UnitsA
		lastWeldPart = npc.Instance.UnitsB
	else
		weldPart = npc.Instance.UnitsB
		lastWeldPart = npc.Instance.UnitsA
	end

	weldPart.Weld.C1 = CFrame.new(-30, 0, 0)

	local unitsToLoad = upgrades[npc.MindData.CurrentCategory]

	for _, _ in pairs(unitsToLoad) do
		unitCount += 1
	end

	local xRange = RACK_SIZE / (unitCount - 1)
	local startX = -((PADDING + xRange) * unitCount) / 2

	for upgradeName, _ in pairs(unitsToLoad) do
		numericalUnitIndex += 1
		local xPos = startX + (numericalUnitIndex * (PADDING + xRange))
		local upgradeUnitNpc = spawners.placeNewObject(0, npc.Instance:GetPivot(), "Npc", "UpgradeUnit")
		upgradeUnitNpc.MindData["UpgradeName"] = upgradeName
		upgradeUnitNpc.Instance.Parent = weldPart

		local newWeld = weldUpgradeUnit(upgradeUnitNpc, weldPart)
		newWeld.C1 = CFrame.new(xPos, 0, 0)
	end

	task.spawn(function()
		for i = -30 * direction, 0, 4 * direction do
			weldPart.Weld.C1 = CFrame.new(i, 0, 0)
			task.wait(0.05)
		end

		weldPart.Weld.C1 = CFrame.new(0, 0, 0)
	end)

	task.spawn(function()
		for i = 0, 30 * direction, 4 * direction do
			lastWeldPart.Weld.C1 = CFrame.new(i, 0, 0)
			task.wait(0.05)
		end

		--lastWeldPart.Weld.C1 = CFrame.new(-30, 0, 0)

		for _, unit in ipairs(lastWeldPart:GetChildren()) do
			if unit:IsA("Model") then
				unit:Destroy()
			end
		end

		inTransition = false
	end)

	if npc.MindData.CurrentWeldIndex == "A" then
		npc.MindData.CurrentWeldIndex = "B"
	else
		npc.MindData.CurrentWeldIndex = "A"
	end
end

local function next(npc)
	local index = table.find(categories, npc.MindData.CurrentCategory)

	if index >= #categories then
		index = 1
	else
		index += 1
	end

	npc.MindData.CurrentCategory = categories[index]

	showUnits(npc)
end

local function previous(npc)
	local index = table.find(categories, npc.MindData.CurrentCategory)

	if index <= 1 then
		index = #categories
	else
		index -= 1
	end

	npc.MindData.CurrentCategory = categories[index]

	showUnits(npc, -1)
end

local function interact(npc, health)
	if debounce then
		return
	end
	debounce = true

	if health <= 100000 then
		next(npc)
	else
		previous(npc)
	end

	task.delay(0.05, function()
		local humanoid = npc.Instance.Humanoid
		humanoid.Health = humanoid.MaxHealth
		debounce = false
	end)
end

local function onSpawned(npc)
	npc.MindData.CurrentCategory = categories[1]
	npc.MindData.CurrentWeldIndex = "A"

	showUnits(npc)
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
