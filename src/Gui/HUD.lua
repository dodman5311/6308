local module = {}
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local SoulsService = require(Globals.Client.Services.SoulsService)

--// Values
local frameDelay = 0.045
local targetEnemy = Instance.new("ObjectValue")

--// Functions
local function getObjectInCenter(center, player)
	local inCenter
	local objectsOnScreen = {}
	local leastDistance = math.huge
	local getObject

	for _, model in ipairs(CollectionService:GetTagged("Enemy")) do
		if not model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("Humanoid").Health <= 0 then
			continue
		end

		local modelPosition = model:GetPivot().Position

		local areaMin = center.AbsolutePosition
		local areaMax = center.AbsolutePosition + center.AbsoluteSize
		local trueCenter = center.AbsolutePosition + center.AbsoluteSize / 2

		local getPosition, onScreen = camera:WorldToScreenPoint(modelPosition)

		local inArea = getPosition.X > areaMin.X
			and getPosition.Y > areaMin.Y
			and getPosition.X < areaMax.X
			and getPosition.Y < areaMax.Y

		if not inArea then
			continue
		end

		local onScreenPosition = Vector2.new(getPosition.X, getPosition.Y)
		local distanceToCenter = (trueCenter - onScreenPosition).Magnitude / (center.AbsoluteSize.Magnitude / 2)

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { player.Character, model, camera }

		local ray = workspace:Raycast(
			camera.CFrame.Position,
			(modelPosition - camera.CFrame.Position).Unit * (camera.CFrame.Position - modelPosition).Magnitude,
			raycastParams
		)

		if (not ray or ray.Instance:FindFirstAncestor(model)) and onScreen then
			if distanceToCenter < leastDistance then
				leastDistance = distanceToCenter
				getObject = model
			end
			objectsOnScreen[#objectsOnScreen + 1] = model
		end
	end

	if getObject then
		inCenter = getObject
	else
		inCenter = nil
	end
	return inCenter, objectsOnScreen, leastDistance
end

function module.Init(player, ui, frame)
	UserInputService.MouseIconEnabled = false

	frame.Ammo.Count.Text = 0
	frame.Souls.Count.Text = 0

	RunService.RenderStepped:Connect(function()
		local inCenter = getObjectInCenter(frame.CenterFrame, player)
		targetEnemy.Value = inCenter
	end)

	local currentHealthChanged

	targetEnemy.Changed:Connect(function(value)
		if currentHealthChanged then
			currentHealthChanged:Disconnect()
		end

		if not value then
			module.HideEnemyHealthBar(player, ui, frame)
			frame.Souls.DropChance.Visible = false
			return
		end

		local humanoid = value:FindFirstChildOfClass("Humanoid")

		module.SetUpEnemyHealth(player, ui, frame, humanoid.MaxHealth, value.Name)
		module.UpdateEnemyHealth(player, ui, frame, humanoid.Health, humanoid.MaxHealth, value.Name, true)
		module.showSoulChance(player, ui, frame, humanoid.MaxHealth)
		module.ShowEnemyHealthBar(player, ui, frame)

		currentHealthChanged = humanoid.HealthChanged:Connect(function(Health)
			module.UpdateEnemyHealth(player, ui, frame, Health, humanoid.MaxHealth, value.Name)
		end)
	end)
end

function module.Cleanup(player, ui, frame) end

function module.ShowEnemyHealthBar(player, ui, frame)
	local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quart)
	local enemyHealthBar = frame.EnemyHealthBar
	local listLayout = enemyHealthBar.Units.UIListLayout

	enemyHealthBar.Visible = true
	util.tween(listLayout, ti, { Padding = UDim.new(-0.962, 0) })
end

function module.HideEnemyHealthBar(player, ui, frame)
	local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	local enemyHealthBar = frame.EnemyHealthBar
	local listLayout = enemyHealthBar.Units.UIListLayout

	util.tween(listLayout, ti, { Padding = UDim.new(-1, 0) }, false, function()
		enemyHealthBar.Visible = false
	end)
end

local function updateHealthBar(health, bar, noAnim)
	local units = bar.Units

	for i = #units:GetChildren() - 1, 1, -1 do
		local unit = units[i]

		if i <= health then
			UiAnimator.StopAnimation(unit)
			unit.Image.Position = UDim2.fromScale(0, 0)
			unit:SetAttribute("IsEmpty", false)
		elseif not unit:GetAttribute("IsEmpty") then
			unit:SetAttribute("IsEmpty", true)

			if noAnim then
				unit.Image.Position = UDim2.fromScale(-3, -1)
			else
				UiAnimator.PlayAnimation(unit, frameDelay, false, true)
			end
		end
	end
end

local function setUpHealthBar(maxHealth, bar, unit)
	local units = bar.Units

	for _, foundUnit in ipairs(units:GetChildren()) do
		if not foundUnit:IsA("Frame") then
			continue
		end

		foundUnit:Destroy()
	end

	for i = 1, maxHealth do
		local newUnit = unit:Clone()
		newUnit.Name = i
		newUnit.Parent = units
		newUnit.Visible = true
	end
end

function module.ShowHit(_, _, frame)
	local newFrame = frame.HitMarker:Clone()
	newFrame.Name = "HitmarkerClone"
	newFrame.Parent = frame.HitMarker.Parent

	local animation = UiAnimator.PlayAnimation(newFrame, 0.04)

	util.PlaySound(sounds.Hit, script, 0.05)

	animation.OnEnded:Connect(function()
		newFrame:Destroy()
	end)
end

function module.UpdateAmmo(_, _, frame, amount)
	local ammoFrame = frame.Ammo
	local label = ammoFrame.Count

	UiAnimator.PlayAnimation(ammoFrame, frameDelay)
	label.Text = amount
end

function module.UpdateSouls(_, _, frame, amount)
	local soulsFrame = frame.Souls
	local label = soulsFrame.Count

	local loggedAmount = label.Text

	if tonumber(loggedAmount) < amount then
		UiAnimator.PlayAnimation(soulsFrame, frameDelay)
	end

	label.Text = amount
end

function module.SetUpPlayerHealth(_, _, frame, maxHealth)
	setUpHealthBar(maxHealth, frame.HealthBar, frame.PlayerHealthUnit)
end

function module.SetUpEnemyHealth(_, _, frame, maxHealth, enemyName)
	frame.EnemyName.Text = enemyName
	setUpHealthBar(maxHealth, frame.EnemyHealthBar, frame.EnemyHealthUnit)
end

function module.UpdatePlayerHealth(_, ui, frame, health, maxHealth)
	local healthBar = frame.HealthBar

	local oldHealth = 0
	for _, v in ipairs(healthBar.Units:GetChildren()) do
		if v:GetAttribute("IsEmpty") then
			oldHealth += 1
		end
	end

	if #healthBar.Units:GetChildren() - 1 ~= maxHealth then
		module.SetUpPlayerHealth(_, ui, frame, maxHealth)
	end

	updateHealthBar(health, healthBar)

	if oldHealth < health then
		UiAnimator.PlayAnimation(healthBar, frameDelay)
	end
end

function module.UpdateEnemyHealth(_, _, frame, health, maxHealth, enemyName, noAnim)
	local healthBar = frame.EnemyHealthBar

	if #healthBar.Units:GetChildren() - 1 ~= maxHealth then
		module.SetUpEnemyHealth(_, _, frame, maxHealth, enemyName)
	end

	updateHealthBar(health, healthBar, noAnim)
end

function module.showSoulChance(_, _, frame, maxHealth)
	local Chance = SoulsService.CalculateDropChance(maxHealth)
	frame.Souls.DropChance.Text = math.round(Chance) .. "% Chance"
	frame.Souls.DropChance.Visible = true
end

return module
