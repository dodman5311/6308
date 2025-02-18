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
local UiAnimator = require(Globals.Vendor.UIAnimationService)
local SoulsService = require(Globals.Client.Services.SoulsService)
local GiftsService = require(Globals.Client.Services.GiftsService)
local spring = require(Globals.Vendor.Spring)

local grappleIncicatorSpring = spring.new(Vector2.zero)
grappleIncicatorSpring.Damper = 0.5
grappleIncicatorSpring.Speed = 10

--// Values
local frameDelay = 0.045
local targetEnemy = Instance.new("ObjectValue")
local boss
local rng = Random.new()

--// Functions
function module.getObjectInCenter(center, player)
	local inCenter
	local objectsOnScreen = {}
	local leastDistance = math.huge
	local getObject

	boss = nil

	for _, model in ipairs(CollectionService:GetTagged("Enemy")) do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		if humanoid.MaxHealth > 50 then
			boss = model
		end

		local modelPosition = model:GetPivot().Position

		local areaMin = center.AbsolutePosition
		local areaMax = center.AbsolutePosition + center.AbsoluteSize
		local trueCenter = center.AbsolutePosition + center.AbsoluteSize / 2

		local getPosition, onScreen = camera:WorldToScreenPoint(modelPosition)

		if getPosition.Z > 100 or not onScreen then
			continue
		end

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
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = { workspace.Map }

		local cameraPosition = camera.CFrame.Position
		local ray = workspace:Raycast(cameraPosition, modelPosition - cameraPosition, raycastParams)

		if ray then
			continue
		end

		if distanceToCenter < leastDistance then
			leastDistance = distanceToCenter
			getObject = model
		end
		objectsOnScreen[#objectsOnScreen + 1] = model
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
		local inCenter = module.getObjectInCenter(frame.CenterFrame, player)
		targetEnemy.Value = inCenter

		local mouseDelta = UserInputService:GetMouseDelta()
		grappleIncicatorSpring.Target = mouseDelta * 3

		frame.GrappleReady.Position =
			UDim2.new(0.5, grappleIncicatorSpring.Position.X, 0.5, grappleIncicatorSpring.Position.Y)
	end)

	local currentHealthChanged
	local currentBossHealthChanged

	targetEnemy.Changed:Connect(function(value)
		if currentHealthChanged then
			currentHealthChanged:Disconnect()
		end

		if currentBossHealthChanged then
			currentBossHealthChanged:Disconnect()
		end

		if boss then
			frame.BossBar.Visible = true

			local bossHumanoid = boss:FindFirstChildOfClass("Humanoid")

			frame.BossBar.BossName.Text = boss.Name

			currentBossHealthChanged = bossHumanoid.HealthChanged:Connect(function(health)
				frame.BossBar.BarHousing.Bar.Size = UDim2.fromScale(health / bossHumanoid.MaxHealth, 1)

				if health > 0 then
					return
				end
			end)
		else
			frame.BossBar.Visible = false
		end

		if not value and not boss then
			frame.BossBar.Visible = false
		end

		if not value or value == boss then
			module.HideEnemyHealthBar(player, ui, frame)
			frame.Souls.DropChance.Visible = false
			return
		end

		local humanoid = value:FindFirstChildOfClass("Humanoid")

		module.SetUpEnemyHealth(player, ui, frame, humanoid.MaxHealth, value.Name)
		module.UpdateEnemyHealth(player, ui, frame, humanoid.Health, humanoid.MaxHealth, value.Name, true)
		--module.showSoulChance(player, ui, frame, humanoid.MaxHealth)
		module.ShowEnemyHealthBar(player, ui, frame)

		currentHealthChanged = humanoid.HealthChanged:Connect(function(Health)
			module.UpdateEnemyHealth(player, ui, frame, Health, humanoid.MaxHealth, value.Name)
		end)
	end)
end

function module.Cleanup(player, ui, frame)
	frame.BossBar.Visible = false
end

function module.HideBossBar(player, ui, frame)
	frame.BossBar.Visible = false
	frame.Ammo.Visible = true
end

function module.reload(player, ui, frame, reloadTime)
	UiAnimator.PlayAnimation(frame.Reloading, 0.05, true)
	frame.Reloading.Visible = true
	frame.Ammo.Visible = false

	local ti = TweenInfo.new(reloadTime, Enum.EasingStyle.Linear)

	frame.Reloading.Image.Prog.Offset = Vector2.new(0, 1)
	util.tween(frame.Reloading.Image.Prog, ti, { Offset = Vector2.new(0, 0) }, false, function()
		UiAnimator.StopAnimation(frame)
		frame.Reloading.Visible = false
		frame.Ammo.Visible = true
	end, Enum.PlaybackState.Completed)
end

function module.hideReload(player, ui, frame)
	frame.Reloading.Visible = false
	UiAnimator.StopAnimation(frame)
end

function module.showDanger(player, ui, frame, color)
	local dangerUi = frame.DangerEffect
	dangerUi.GroupColor3 = color
	if dangerUi.GroupTransparency ~= 1 then
		return
	end

	local ti = TweenInfo.new(0.25)

	UiAnimator.PlayAnimation(dangerUi, 0.035, true)
	util.tween(dangerUi, ti, { GroupTransparency = 0 })
end

function module.hideDanger(player, ui, frame)
	local dangerUi = frame.DangerEffect
	if dangerUi.GroupTransparency ~= 0 then
		return
	end

	local ti = TweenInfo.new(0.5)

	util.tween(dangerUi, ti, { GroupTransparency = 1 }, false, function()
		UiAnimator.StopAnimation(dangerUi)
	end, Enum.PlaybackState.Completed)
end

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

local function updateHealthBar(health, maxHealth, bar, noAnim)
	local units = bar.Units

	for i = #units:GetChildren() - 1, 1, -1 do
		local unit = units[i]

		if unit:FindFirstChild("BarFrame") then
			if not noAnim then
				UiAnimator.PlayAnimation(unit, frameDelay)
			end

			unit.BarFrame.Bar.Size = UDim2.fromScale(health / maxHealth, 1)
			continue
		end

		if i <= math.ceil(health) then
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

	if maxHealth > 9 then
		maxHealth = 1
	end

	for i = 1, maxHealth do
		local newUnit = unit:Clone()
		newUnit.Name = i
		newUnit.Parent = units
		newUnit.Visible = true
	end
end

function module.ShowHit(_, _, frame, crit)
	local newFrame = frame.HitMarker:Clone()
	newFrame.Name = "HitmarkerClone"
	newFrame.Parent = frame.HitMarker.Parent

	if crit then
		newFrame.Image.ImageColor3 = Color3.new(1)
	else
		newFrame.Image.ImageColor3 = Color3.new(1, 1, 1)
	end

	local animation = UiAnimator.PlayAnimation(newFrame, 0.04)

	util.PlaySound(sounds.Hit, script, 0.05)

	animation.OnEnded:Connect(function()
		newFrame:Destroy()
	end)
end

function module.ShowImmune(_, _, frame)
	util.PlaySound(util.getRandomChild(sounds.Immune), script, 0.1)

	local x = frame.CrosshairFrame.X
	x.Visible = true

	task.spawn(function()
		for _ = 0, 4 do
			x.Position = UDim2.fromScale(rng:NextNumber(0.45, 0.55), rng:NextNumber(0.45, 0.55))
			task.wait()
		end
		x.Position = UDim2.fromScale(0.5, 0.5)
		x.Visible = false
	end)
end

function module.UpdateAmmo(_, _, frame, amount)
	local ammoFrame = frame.Ammo
	local label = ammoFrame.Count

	UiAnimator.PlayAnimation(ammoFrame, frameDelay)
	label.Text = amount

	label.Visible = amount ~= math.huge
	ammoFrame.Inf.Visible = amount == math.huge
end

function module.UpdateSouls(_, _, frame, amount)
	local soulsFrame = frame.Souls
	local label = soulsFrame.Count

	local loggedAmount = label.Text

	if tonumber(loggedAmount) < amount then
		UiAnimator.PlayAnimation(soulsFrame, frameDelay)
	end

	label.Text = amount

	if GiftsService.CheckGift("Drav_Is_Dead") then
		soulsFrame.Image.ImageColor3 = Color3.new(0.35, 0.35, 0.35)
		label.TextColor3 = Color3.new(0.35, 0.35, 0.35)
	else
		soulsFrame.Image.ImageColor3 = Color3.fromRGB(200, 255, 245)
		label.TextColor3 = Color3.fromRGB(200, 255, 245)
	end
end

function module.RemoveSouls(_, _, frame, amount)
	local ti = TweenInfo.new(2.5, Enum.EasingStyle.Quad)

	local LoseSoul = frame.LoseSoul

	LoseSoul.Text = "-" .. amount

	LoseSoul.TextTransparency = 0
	LoseSoul.UIStroke.Transparency = 0

	util.tween(LoseSoul, ti, { TextTransparency = 1 })
	util.tween(LoseSoul.UIStroke, ti, { Transparency = 1 })
end

function module.SetUpPlayerHealth(_, _, frame, maxHealth)
	setUpHealthBar(maxHealth, frame.HealthBar, frame.PlayerHealthUnit)
end

function module.SetUpPlayerArmor(_, _, frame, maxArmor)
	setUpHealthBar(maxArmor, frame.ArmorBar, frame.PlayerArmorUnit)
end

function module.SetUpEnemyHealth(_, _, frame, maxHealth, enemyName)
	frame.EnemyName.Text = enemyName

	local unit = frame.EnemyHealthUnit
	if maxHealth > 9 then
		unit = frame.EnemyBarUnit
	end

	setUpHealthBar(maxHealth, frame.EnemyHealthBar, unit)
end

function module.UpdatePlayerHealth(_, ui, frame, health, maxHealth, isArmor)
	local healthBar = frame.HealthBar

	if isArmor then
		healthBar = frame.ArmorBar
	end

	local oldHealth = 0
	for _, v in ipairs(healthBar.Units:GetChildren()) do
		if v:GetAttribute("IsEmpty") then
			oldHealth += 1
		end
	end

	if #healthBar.Units:GetChildren() - 1 ~= maxHealth then
		if isArmor then
			module.SetUpPlayerArmor(_, _, frame, maxHealth)
		else
			module.SetUpPlayerHealth(_, ui, frame, maxHealth)
		end
	end

	updateHealthBar(health, maxHealth, healthBar)

	if oldHealth < health then
		UiAnimator.PlayAnimation(healthBar, frameDelay)
	end
end

function module.UpdateEnemyHealth(_, _, frame, health, maxHealth, enemyName, noAnim)
	local healthBar = frame.EnemyHealthBar

	if #healthBar.Units:GetChildren() - 1 ~= maxHealth then
		module.SetUpEnemyHealth(_, _, frame, maxHealth, enemyName)
	end

	updateHealthBar(health, maxHealth, healthBar, noAnim)
end

function module.showSoulChance(_, _, frame, maxHealth)
	local Chance = SoulsService.CalculateDropChance(maxHealth)
	frame.Souls.DropChance.Text = math.round(Chance) .. "% Chance"
	frame.Souls.DropChance.Visible = true
end

function module.DamagePulse(player, ui, frame)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	frame.Static.ImageColor3 = Color3.new(1)

	util.tween(frame.Static, ti, { ImageColor3 = Color3.new(1, 1, 1) })
end

function module.ShowInvincible(player, ui, frame)
	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)

	util.tween(frame.Static, ti, { ImageColor3 = Color3.new(1, 0.85, 0) })
end

function module.HideInvincible(player, ui, frame)
	local ti = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

	util.tween(frame.Static, ti, { ImageColor3 = Color3.new(1, 1, 1) })
end

function module.SetCombo(player, ui, frame, amount)
	local comboNumber = frame.ComboNumber
	local comboFrame = frame.ComboFrame

	comboNumber.Text = amount
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Back)

	comboFrame.Size = UDim2.fromScale(0.3, 0.3)
	comboFrame.Rotation = -10

	util.tween(comboFrame, ti, { Size = UDim2.fromScale(0.25, 0.25), Rotation = -5 })

	if amount >= 30 then
		comboFrame.GroupColor3 = Color3.fromRGB(200, 255, 245)
	elseif amount >= 20 then
		comboFrame.GroupColor3 = Color3.fromRGB(230, 0, 255)
	elseif amount >= 10 then
		comboFrame.GroupColor3 = Color3.fromRGB(255, 220, 0)
	elseif amount >= 5 then
		comboFrame.GroupColor3 = Color3.fromRGB(50, 255, 0)
	else
		comboFrame.GroupColor3 = Color3.new(1, 1, 1)
	end
end

function module.AddGift(player, ui, frame, icon, giftName)
	local gift = frame.GiftImage:Clone()
	gift:AddTag("GiftIcon")

	gift.Image = icon
	gift.Name = giftName

	if #frame.Gifts:GetChildren() > 13 then
		gift.Parent = frame.Gifts_2
	else
		gift.Parent = frame.Gifts
	end

	gift.Visible = true
end

function module.ClearGifts(player, ui, frame)
	for _, gift in ipairs(CollectionService:GetTagged("GiftIcon")) do
		gift:Destroy()
	end
end

function module.ActivateGift(player, ui, frame, giftName)
	for _, gift in ipairs(CollectionService:GetTagged("GiftIcon")) do
		if gift.Name ~= giftName then
			continue
		end

		gift.Activate.Visible = true
		UiAnimator.PlayAnimation(gift.Activate, 0.025, false, false).OnEnded:Once(function()
			gift.Activate.Visible = false
		end)
	end
end

function module.UpdateGiftProgress(player, ui, frame, giftName, progress)
	for _, gift in ipairs(CollectionService:GetTagged("GiftIcon")) do
		if gift.Name ~= giftName then
			continue
		end
		gift.Progress.Offset = Vector2.new(0, -progress)
	end
end

function module.CooldownGift(player, ui, frame, giftName, cooldownTime)
	local ti = TweenInfo.new(cooldownTime, Enum.EasingStyle.Linear)

	for _, gift in ipairs(CollectionService:GetTagged("GiftIcon")) do
		if gift.Name ~= giftName then
			continue
		end

		gift.Progress.Offset = Vector2.new(0, -1)
		util.tween(gift.Progress, ti, { Offset = Vector2.new(0, 0) })
	end
end

function module.TweenGift(player, ui, frame, giftName, endValue, ti)
	for _, gift in ipairs(CollectionService:GetTagged("GiftIcon")) do
		if gift.Name ~= giftName then
			continue
		end

		util.tween(gift.Progress, ti, { Offset = Vector2.new(0, endValue) })
	end
end

function module.SetCrosshair(player, ui, frame, id, showLeft)
	frame.CrosshairFrame.Image.Image = id

	frame.LeftCrosshairFrame.Visible = showLeft
end

function module.PumpCrosshair(player, ui, frame, isLeft)
	if isLeft then
		UiAnimator.PlayAnimation(frame.LeftCrosshairFrame, 0.045)
	else
		UiAnimator.PlayAnimation(frame.CrosshairFrame, 0.045)
	end
end

function module.ShowSideBar(player, ui, frame)
	local sideBar = frame.SideBar
	sideBar.Visible = true

	for _, bar in ipairs(sideBar:GetChildren()) do
		if not bar:IsA("Frame") then
			continue
		end

		bar.Image.Position = UDim2.fromScale(-3, 0)
	end
end

function module.HideSideBar(player, ui, frame)
	frame.SideBar.Visible = false
end

function module.UpdateSideBar(player, ui, frame, number)
	local sideBar = frame.SideBar

	for _, bar in ipairs(sideBar:GetChildren()) do
		if not bar:IsA("Frame") then
			continue
		end

		if tonumber(bar.Name) <= number then
			bar.Image.Position = UDim2.fromScale(-3, 0)
			continue
		end

		bar.Image.Position = UDim2.fromScale(0, 0)
	end
end

function module.RefreshSideBar(player, ui, frame)
	local sideBar = frame.SideBar

	for _, bar in ipairs(sideBar:GetChildren()) do
		if not bar:IsA("Frame") or bar.Image.Position == UDim2.new(-3, 0) then
			continue
		end

		UiAnimator.PlayAnimation(bar, 0.04, false, true)
	end
end

function module.ToggleReloadPrompt(player, ui, frame, value)
	local reloadPrompt = frame.ReloadPrompt

	reloadPrompt.Visible = value

	if not value then
		return
	end

	task.spawn(function()
		local switch = true

		repeat
			task.wait(0.075)

			if switch then
				reloadPrompt.BackgroundColor3 = Color3.new(1, 1, 1)
				reloadPrompt.Prompt.TextColor3 = Color3.new(1)
				reloadPrompt.UIStroke.Color = Color3.new(1)
			else
				reloadPrompt.BackgroundColor3 = Color3.new(1)
				reloadPrompt.Prompt.TextColor3 = Color3.new(1, 1, 1)
				reloadPrompt.UIStroke.Color = Color3.new(1, 1, 1)
			end

			switch = not switch

		until not reloadPrompt.Visible
	end)
end

function module.ToggleGrappleIndicator(player, ui, frame, value)
	frame.GrappleReady.Visible = value
end

function module.SetGrappleIndicatorTransparency(player, ui, frame, value)
	frame.GrappleReady.ImageTransparency = value
end

function module.GrappleCooldown(player, ui, frame, cooldownTime, goal)
	local gradient: UIGradient = frame.GrappleReady.UIGradient
	local ti = TweenInfo.new(cooldownTime, Enum.EasingStyle.Linear)

	util.tween(gradient, ti, { Offset = Vector2.new(0, -goal) })
end

function module.ShowOvercharge(player, ui, frame, isArsenalBar)
	local overChargeBar = isArsenalBar and frame.ArsenalBar or frame.OverchargeBar

	overChargeBar.Visible = true
	overChargeBar.BarFrame.Bar.Size = UDim2.fromScale(1, 0)

	UiAnimator.PlayAnimation(overChargeBar.BarFrame.Bar.BarAnimation, 0.1, true)
end

function module.HideOvercharge(player, ui, frame, isArsenalBar)
	local overChargeBar = isArsenalBar and frame.ArsenalBar or frame.OverchargeBar
	overChargeBar.Visible = false

	UiAnimator.StopAnimation(overChargeBar.BarFrame.Bar.BarAnimation)
end

function module.UpdateOvercharge(player, ui, frame, number, isArsenalBar)
	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Quad)

	local overChargeBar = isArsenalBar and frame.ArsenalBar or frame.OverchargeBar
	util.tween(overChargeBar.BarFrame.Bar, ti, { Size = UDim2.fromScale(1, number) })
end

function module.EmptyOvercharge(player, ui, frame, emptyTime, isArsenalBar)
	local ti = TweenInfo.new(emptyTime, Enum.EasingStyle.Linear)

	local overChargeBar = isArsenalBar and frame.ArsenalBar or frame.OverchargeBar
	util.tween(overChargeBar.BarFrame.Bar, ti, { Size = UDim2.fromScale(1, 0) })
end

return module
