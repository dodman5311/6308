local module = {}
--// Services
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds

local mapCamera = Instance.new("Camera")
local weaponCamera = Instance.new("Camera")
local zoomAmount = 0
local mouse2Down = false
local mouse1Down = false
local lastMouseUp = os.clock()

--// Modules
local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)
local Signals = require(Globals.Shared.Signals)
local MouseOver = require(Globals.Vendor.MouseOverModule)
local weapons = require(Globals.Client.Controllers.WeaponController)
local giftService = require(Globals.Client.Services.GiftsService)
local gifts = require(Globals.Shared.Gifts)
local codexService = require(Globals.Client.Services.CodexService)
local gameSettings = require(Globals.Shared.GameSettings)
local SoulsService = require(Globals.Client.Services.SoulsService)
local net = require(Globals.Packages.Net)
local characterController = require(Globals.Client.Controllers.CharacterController)

--// Values
local currentMenu = nil
local currentCatagory = "Weapons"

--// Functions

local weaponIcons = {
	Shotgun = "rbxassetid://18298958678",
	Pistol = "rbxassetid://18298957212",
	Melee = "rbxassetid://18298955289",
	AR = "rbxassetid://18298954616",
}

local function showAttention(frame)
	frame.Codex_Lbl.Attention.Visible = false

	for _, v in ipairs(frame.Codex_Menu:GetDescendants()) do
		if v.Name == "Attention" then
			v.Visible = false
		end
	end

	for index, entry in pairs(codexService.CodexEntries) do
		if entry.Viewed then
			continue
		end

		if currentMenu ~= "Codex" then
			frame.Codex_Lbl.Attention.Visible = true
		end

		frame[entry.Catagory .. "_Lbl"].Attention.Visible = true

		for _, v in ipairs(frame.Codex_Menu.CodexList:GetChildren()) do
			if v.Name == index then
				v.Attention.Visible = true
			end
		end
	end
end

local function loadCodexCatagory(frame, catagory)
	for _, v in ipairs(frame.CodexList:GetChildren()) do
		if not v:IsA("ImageButton") then
			continue
		end

		v:Destroy()
	end

	frame.EntryText.Text = ""

	for entryName, entry in pairs(codexService.CodexEntries) do
		if entry.Catagory ~= catagory then
			continue
		end

		local newButton: ImageButton = frame.CodexEntry:Clone()
		newButton.Parent = frame.CodexList
		newButton.Visible = true
		newButton.EntryTitle.Text = entryName
		newButton.Name = entryName

		newButton.MouseButton1Click:Connect(function()
			frame.EntryText.Text = entry.Entry

			codexService.CodexEntries[entryName].Viewed = true

			showAttention(frame)
		end)

		local enter, leave = MouseOver.MouseEnterLeaveEvent(newButton)
		enter:Connect(function()
			local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quart)

			util.tween(
				newButton,
				ti,
				{ ImageColor3 = Color3.fromRGB(135, 255, 230), Size = UDim2.fromScale(0.875, 0.125) }
			)
		end)

		leave:Connect(function()
			local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quart)

			util.tween(
				newButton,
				ti,
				{ ImageColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.fromScale(0.85, 0.1) }
			)
		end)
	end

	showAttention(frame)
end

local function catagoryButtonLeft(button, player, ui, frame)
	if currentCatagory == button.Name then
		return
	end

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

	util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
end

local function catagoryButtonAction(button, player, ui, frame)
	loadCodexCatagory(frame, button.Name)

	local lastCatagory = currentCatagory
	currentCatagory = button.Name

	if not lastCatagory or lastCatagory == currentCatagory then
		return
	end

	catagoryButtonLeft(frame.Codex_Menu.Buttons:FindFirstChild(lastCatagory), player, ui, frame)
end

local function catagoryButtonEntered(button, player, ui, frame)
	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

	util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(255, 75, 75) })
end

local buttonFunctions = {
	Map = {
		Action = function(button, player, ui, frame)
			module.openMap(player, ui, frame)
		end,

		Entered = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(135, 255, 135) })
		end,

		Left = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
		end,
	},

	Arsenal = {
		Action = function(button, player, ui, frame)
			module.openArsenal(player, ui, frame)
		end,

		Entered = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(255, 135, 135) })
		end,

		Left = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
		end,
	},

	Codex = {
		Action = function(button, player, ui, frame)
			module.openCodex(player, ui, frame)
		end,

		Entered = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(135, 255, 230) })
		end,

		Left = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
		end,
	},

	Settings = {
		Action = function(button, player, ui, frame)
			module.openSettings(player, ui, frame)
		end,

		Entered = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(135, 153, 255) })
		end,

		Left = function(button, player, ui, frame)
			local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

			util.tween(frame[button.Name .. "_Lbl"], ti, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
		end,
	},

	Areas = {
		Action = catagoryButtonAction,

		Entered = catagoryButtonEntered,

		Left = catagoryButtonLeft,
	},

	Bosses = {
		Action = catagoryButtonAction,

		Entered = catagoryButtonEntered,

		Left = catagoryButtonLeft,
	},

	Enemies = {
		Action = catagoryButtonAction,

		Entered = catagoryButtonEntered,

		Left = catagoryButtonLeft,
	},

	Misc = {
		Action = catagoryButtonAction,

		Entered = catagoryButtonEntered,

		Left = catagoryButtonLeft,
	},

	Weapons = {
		Action = catagoryButtonAction,

		Entered = catagoryButtonEntered,

		Left = catagoryButtonLeft,
	},
}

local function Lerp(num, goal, i)
	return num + (goal - num) * i
end

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false

	for _, button in ipairs(frame.Gui:GetDescendants()) do
		if not button:IsA("TextButton") then
			continue
		end

		local enter, leave = MouseOver.MouseEnterLeaveEvent(button)
		local buttonFunction = buttonFunctions[button.Name]
		if not buttonFunction then
			continue
		end

		button.MouseButton1Click:Connect(function()
			buttonFunction.Action(button, player, ui, frame)
		end)

		enter:Connect(function()
			buttonFunction.Entered(button, player, ui, frame)
		end)

		leave:Connect(function()
			buttonFunction.Left(button, player, ui, frame)
		end)
	end

	frame.Restart.MouseButton1Click:Connect(function()
		if frame.ConfirmRestartFrame.Visible then
			return
		end

		frame.ConfirmRestartFrame.Visible = true
	end)

	frame.ConfirmRestart.MouseButton1Click:Connect(function()
		frame.ConfirmRestartFrame.Visible = false
		module.Close(player, ui, frame)

		SoulsService.RemoveSoul(SoulsService.Souls)
		net:RemoteEvent("UpdatePlayerHealth"):FireServer(5, 0, false)
	end)

	frame.CancelRestart.MouseButton1Click:Connect(function()
		frame.ConfirmRestartFrame.Visible = false
	end)
end

UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoomAmount -= input.Position.Z
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		mouse2Down = true
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouse1Down = true
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		if os.clock() - lastMouseUp <= 0.1 then
			mouse2Down = true
			mouse1Down = false
		else
			mouse1Down = true
		end
	end
end)

local lastTouchScale

UserInputService.TouchPinch:Connect(function(pos, scale, velocity, state)
	if state == Enum.UserInputState.Change or state == Enum.UserInputState.End then
		local difference = scale - lastTouchScale
		zoomAmount -= (difference * 10)

		mouse1Down = false
	end

	lastTouchScale = scale
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		mouse2Down = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		mouse1Down = false
		lastMouseUp = os.clock()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		mouse2Down = false
	end
end)

local function processCamera(frame)
	local map = frame.MapViewport:FindFirstChild("Map")
	if not map then
		return
	end

	local mapCenter = map:GetBoundingBox()

	mapCamera.Parent = frame.Gui
	mapCamera.CameraType = Enum.CameraType.Scriptable
	mapCamera.FieldOfView = 50

	zoomAmount = 15

	local zoomSensitivity = 3
	local moveSensitivity = 1
	local turnSensitivity = 1

	local cameraOffset = CFrame.new()
	local camAngleX = 45
	local camAngleY = 45

	local lerpedZoom = 0
	local lerpedOffset = CFrame.new()
	local lerpedAngle = Vector2.new()

	RunService:BindToRenderStep("ProcessMapCamera", Enum.RenderPriority.Camera.Value, function()
		if UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
			print(zoomAmount)
			zoomAmount -= 0.25
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.ButtonB) then
			zoomAmount += 0.25
		end

		if mouse2Down or mouse1Down then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local delta = UserInputService:GetMouseDelta()

			if mouse1Down then
				cameraOffset *= CFrame.new(delta.X * moveSensitivity, -delta.Y * moveSensitivity, 0)
			end

			if mouse2Down then
				camAngleX += delta.X * turnSensitivity
				camAngleY += delta.Y * turnSensitivity
			end
		end

		lerpedOffset = lerpedOffset:Lerp(cameraOffset, 0.1)
		lerpedAngle = lerpedAngle:Lerp(Vector2.new(camAngleX, camAngleY), 0.25)

		mapCamera.CFrame = CFrame.new(mapCenter.Position)
			* CFrame.Angles(0, math.rad(-lerpedAngle.X), 0)
			* CFrame.Angles(math.rad(-lerpedAngle.Y), 0, 0)
			* lerpedOffset

		lerpedZoom = Lerp(lerpedZoom, zoomAmount, 0.1)
		mapCamera.CFrame *= CFrame.new(0, 0, (lerpedZoom * 10) * zoomSensitivity)
	end)
end

local function hideAllMenus(frame)
	RunService:UnbindFromRenderStep("ProcessMapCamera")
	RunService:UnbindFromRenderStep("RotateWeapon")
	RunService:UnbindFromRenderStep("ResizeScrollBar")

	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)

	util.tween(frame.Map_Menu, ti, { GroupTransparency = 1 }, false, function()
		frame.Map_Menu.Visible = false
	end, Enum.PlaybackState.Completed)
	util.tween(frame.Codex_Menu, ti, { GroupTransparency = 1 }, false, function()
		frame.Codex_Menu.Visible = false
	end, Enum.PlaybackState.Completed)
	util.tween(frame.Arsenal_Menu, ti, { GroupTransparency = 1 }, false, function()
		frame.Arsenal_Menu.Visible = false
	end, Enum.PlaybackState.Completed)
	util.tween(frame.Settings_Menu, ti, { GroupTransparency = 1 }, false, function()
		frame.Settings_Menu.Visible = false
	end, Enum.PlaybackState.Completed)

	showAttention(frame)
end

local function loadMap(player, frame)
	local viewport = frame.MapViewport

	if viewport:FindFirstChild("Map") then
		viewport.Map:Destroy()
	end

	local map = workspace.Map:Clone()
	map:PivotTo(CFrame.new())

	for _, v in ipairs(map:GetDescendants()) do
		if v:IsA("Texture") then
			v:Destroy()
		end
		if v:IsA("Decal") then
			v:Destroy()
		end

		if v:IsA("UnionOperation") then
			v.UsePartColor = true
		end

		if v:IsA("MeshPart") then
			v.TextureID = ""
		end

		if string.match(v.Name, "Arena_") then
			v.Name = "Arena"
		end

		if v:IsA("BasePart") then
			local arena = v:FindFirstAncestor("Arena")

			v.Material = Enum.Material.ForceField
			if v:FindFirstAncestor("Exit") then
				v.Color = Color3.fromRGB(255, 0, 0)
			elseif v:FindFirstAncestor("Start_" .. workspace:GetAttribute("Stage")) then
				v.Color = Color3.fromRGB(50, 255, 0)
			elseif v:FindFirstAncestor("Kiosk") then
				v.Color = Color3.fromRGB(0, 255, 175)
			elseif arena and arena:FindFirstChild("ArenaHitbox") then
				v.Color = Color3.fromRGB(255, 0, 255)
			elseif arena then
				v.Color = Color3.fromRGB(150, 150, 150)
			else
				v.Color = Color3.fromRGB(255, 200, 0)
			end
		end

		if v:IsA("ParticleEmitter") then
			v:Destroy()
		end
	end

	for _, weapon in ipairs(CollectionService:GetTagged("Weapon")) do
		local newWeapon = weapon:Clone()
		newWeapon.Parent = map

		for _, part in ipairs(newWeapon:GetDescendants()) do
			if not part:IsA("BasePart") or part.Transparency == 1 then
				continue
			end
			part.Transparency = 0
		end
	end

	for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
		local newPart = Instance.new("Part")
		newPart.Color = Color3.new(1)
		newPart.Anchored = true
		newPart.Material = Enum.Material.Neon
		newPart.CFrame = enemy:GetPivot()
		newPart.Size = Vector3.new(2, 4, 2)
		newPart.Name = "Enemy"
		newPart.Parent = map
	end

	for _, machine in ipairs(CollectionService:GetTagged("VendingMachine")) do
		local newPart = ReplicatedStorage.MapVendingMachine:Clone()
		newPart.Color = machine.PrimaryPart.Color
		newPart.CFrame = machine:GetPivot()

		newPart.Parent = map
	end

	if player.Character then
		local playerPart = ReplicatedStorage.MapPlayer:Clone()
		playerPart.CFrame = player.Character:GetPivot() * CFrame.Angles(math.rad(90), 0, 0)
		playerPart.Parent = map
	end

	map.Parent = viewport

	viewport.CurrentCamera = mapCamera
end

local function loadPerksList(frame)
	local getGifts = giftService.AquiredGifts
	local perkList = frame.PerksList

	for _, button in ipairs(perkList:GetChildren()) do
		if not button:IsA("ImageButton") then
			continue
		end

		button:Destroy()
	end

	for _, gift in ipairs(getGifts) do
		local button = frame.Empty:Clone()
		button.Name = gift
		button.Parent = perkList
		button.Visible = true

		local giftData

		if gifts.Perks[gift] then
			giftData = gifts.Perks[gift]
		elseif gifts.Upgrades[gift] then
			giftData = gifts.Upgrades[gift]
		elseif gifts.Specials[gift] then
			giftData = gifts.Specials[gift]
		end

		button.Icon.Image = giftData.Icon
		button.Icon.ImageColor3 = Color3.new(1, 1, 1)

		local enter, leave = MouseOver.MouseEnterLeaveEvent(button)

		enter:Connect(function()
			local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quart)

			util.tween(button.Icon, ti, { Size = UDim2.fromScale(1.2, 1.2) })

			frame.PerkInfo.Text = giftData.Desc
			frame.PerkInfo.Visible = true
			frame.WeaponViewport.Visible = false
		end)

		leave:Connect(function()
			local ti = TweenInfo.new(0.1, Enum.EasingStyle.Quad)

			util.tween(button.Icon, ti, { Size = UDim2.fromScale(1, 1) })

			frame.PerkInfo.Visible = false
			frame.WeaponViewport.Visible = true
		end)
	end
end

local function loadArsenal(frame)
	local viewport = frame.WeaponViewport
	viewport.Visible = true
	frame.PerkInfo.Visible = false

	local Model = viewport:FindFirstChildOfClass("Model")
	if Model then
		Model:Destroy()
	end

	local weapon = weapons.currentWeapon
	local weaponModel: Model = weapon and assets.Models.Weapons:FindFirstChild(weapon.Name):Clone()
		or assets.Models["Cleanse & Repent"]:Clone()

	weaponModel.Parent = viewport

	weaponCamera.Parent = frame.Gui
	weaponCamera.CameraType = Enum.CameraType.Scriptable
	weaponCamera.FieldOfView = 50

	viewport.CurrentCamera = weaponCamera

	local size = weaponModel:GetExtentsSize()

	weaponModel:PivotTo(weaponCamera.CFrame * CFrame.new(0, 0, -(size.Magnitude + 1)))

	RunService:BindToRenderStep("RotateWeapon", Enum.RenderPriority.Camera.Value, function()
		weaponModel:PivotTo(weaponModel:GetPivot() * CFrame.Angles(0, math.rad(0.5), 0))
	end)

	local defaultStats = {
		Type = "Pistol",
		Damage = 1,
		FireDelay = 0.2,
		BulletCount = 1,
		Crosshair = "Default",
		Effect = "Akimbo",
		Recoil = {
			RecoilVector = Vector3.new(-1.75, 0.3, 0),
			RandomVector = Vector3.new(0.2, 0.1, 4),
			Magnitude = 1,
			Speed = 0.75,
		},
	}
	local gunStats = weaponModel:FindFirstChild("Data") and require(weaponModel.Data) or defaultStats

	local recoil = (gunStats.Recoil.RecoilVector.Magnitude * gunStats.Recoil.Magnitude) / (gunStats.Recoil.Speed / 2)
	local fireRate = (60 / gunStats.FireDelay) / 60

	local damageNum = frame.Damage_Num
	damageNum.Text = gunStats.Damage

	if gunStats.BulletCount > 1 then
		damageNum.Text ..= " x " .. gunStats.BulletCount
	end

	if gunStats["SplashDamage"] then
		damageNum.Text ..= " + " .. gunStats.SplashDamage
	end

	if gunStats["LockAmount"] then
		damageNum.Text = gunStats.Damage - (math.ceil(gunStats.LockAmount / 2) - 1) .. " - " .. damageNum.Text
	end

	local firerateDisplay = math.round(fireRate)
	if fireRate < 1 then
		firerateDisplay = math.round(fireRate * 10) / 10
	end

	frame.Recoil_Num.Text = math.ceil(recoil)
	frame.Speed_Num.Text = firerateDisplay
	frame.WeaponName.Text = weaponModel.Name

	local icon = weaponIcons[gunStats.Type]

	frame.WeaponIcon.Image = icon

	frame.Effect_Lbl.Text = gunStats.Effect
end

local function loadCodex(frame)
	RunService:BindToRenderStep("ResizeScrollBar", Enum.RenderPriority.Camera.Value, function()
		local list: ScrollingFrame = frame.CodexList
		local text: TextLabel = frame.EntryText

		list.ScrollBarThickness = list.AbsoluteSize.X / 10.55
		text.TextSize = text.AbsoluteSize.X / 20
	end)
end

local function setBoolToValue(buttonFrame, value)
	local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quart)

	local endPos = value and UDim2.fromScale(0.11, 0) or UDim2.fromScale(0, 0)
	local endColor = value and Color3.fromRGB(160, 255, 175) or Color3.fromRGB(170, 70, 70)

	util.tween(buttonFrame.Switch, ti, { Position = endPos })
	util.tween(buttonFrame.ValueColor, ti, { ImageColor3 = endColor })

	buttonFrame.Value.Text = tostring(value)
end

local function setSliderToValue(barFrame, input, maxValue)
	local mousePosition = Vector2.new(input.Position.X, input.Position.Y)
	local xPosition = (mousePosition.X - barFrame.AbsolutePosition.X) / barFrame.AbsoluteSize.X
	local alphaValue = math.round(xPosition * 100) / 100

	if alphaValue >= 0.98 then
		alphaValue = 1
	elseif alphaValue <= 0.02 then
		alphaValue = 0
	end

	local value = alphaValue * maxValue

	barFrame.Parent.Value.Text = math.round(value)
	barFrame.Bar.Size = UDim2.fromScale(alphaValue, 1)

	return value
end

local function loadSettings(frame)
	local settingsMenu = frame.Settings_Menu

	for _, v in ipairs(settingsMenu.Settings:GetChildren()) do
		if v:IsA("UIListLayout") then
			continue
		end

		v:Destroy()
	end

	for index, settingTable in ipairs(gameSettings) do
		if typeof(settingTable) == "string" then
			local categoryLabel = settingsMenu.Buttons.Category:Clone()
			categoryLabel.Parent = settingsMenu.Settings
			categoryLabel.Text = settingTable
			categoryLabel.LayoutOrder = index
			categoryLabel.Visible = true
			continue
		end

		local settingsButton = settingsMenu.Buttons:FindFirstChild(settingTable.Type)

		if not settingsButton then
			continue
		end

		-- create button
		local newSettingsButton = settingsButton:Clone()

		newSettingsButton.Parent = settingsMenu.Settings
		newSettingsButton.Visible = true
		newSettingsButton.LayoutOrder = index

		if settingTable.Type == "Boolean" then
			newSettingsButton.Button.MouseButton1Click:Connect(function()
				settingTable.Value = not settingTable.Value

				setBoolToValue(newSettingsButton, settingTable.Value)
				settingTable:OnChanged()
			end)

			newSettingsButton.SettingName.Text = settingTable.Name
			setBoolToValue(newSettingsButton, settingTable.Value)
		elseif settingTable.Type == "Slider" then
			newSettingsButton.Value.Text = math.round(settingTable.Value)
			newSettingsButton.SettingName.Text = settingTable.Name

			local barFrame: Frame = newSettingsButton.BarFrame

			barFrame.Bar.Size = UDim2.fromScale(settingTable.Value / settingTable.MaxValue, 1)

			local mouseDown = false

			barFrame.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end

				mouseDown = true

				settingTable.Value = setSliderToValue(barFrame, input, settingTable.MaxValue)
				settingTable:OnChanged()
			end)

			barFrame.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					mouseDown = false
				end
			end)

			barFrame.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then
					return
				end

				if not mouseDown then
					return
				end

				settingTable.Value = setSliderToValue(barFrame, input, settingTable.MaxValue)
				settingTable:OnChanged()
			end)
		end
	end
end

function module.openMap(player, ui, frame)
	if currentMenu == "Map" then
		return
	end

	currentMenu = "Map"

	hideAllMenus(frame)
	loadMap(player, frame)
	processCamera(frame)

	frame.LevelDisplay.Text = "Stage: "
		.. workspace:GetAttribute("Stage")
		.. "  "
		.. "Level: "
		.. workspace:GetAttribute("Level")

	frame.Map_Menu.Visible = true
	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	util.tween(frame.Map_Menu, ti, { GroupTransparency = 0 })
end

function module.openArsenal(player, ui, frame)
	if currentMenu == "Arsenal" then
		return
	end

	currentMenu = "Arsenal"

	hideAllMenus(frame)
	loadArsenal(frame)
	loadPerksList(frame)

	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	frame.Arsenal_Menu.Visible = true
	util.tween(frame.Arsenal_Menu, ti, { GroupTransparency = 0 })
end

function module.openCodex(player, ui, frame)
	if currentMenu == "Codex" then
		return
	end

	currentMenu = "Codex"
	hideAllMenus(frame)
	loadCodex(frame)
	loadCodexCatagory(frame, currentCatagory)

	showAttention(frame)

	frame.Codex_Menu.Visible = true
	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	util.tween(frame.Codex_Menu, ti, { GroupTransparency = 0 })
end

function module.openSettings(player, ui, frame)
	if currentMenu == "Settings" then
		return
	end

	currentMenu = "Settings"

	frame.ConfirmRestartFrame.Visible = false
	hideAllMenus(frame)
	loadSettings(frame)
	--loadCodexCatagory(frame, currentCatagory)

	frame.Settings_Menu.Visible = true
	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	util.tween(frame.Settings_Menu, ti, { GroupTransparency = 0 })
end

function module.Open(player, ui, frame)
	ui.HUD.OpenMenuPrompt_T.Visible = false

	RunService:BindToRenderStep("ProcessCursor", Enum.RenderPriority.Camera.Value, function()
		local mousePos = UserInputService:GetMouseLocation()
		frame.Cursor.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	end)

	frame.Gui.Enabled = true

	if acts:checkAct("EntryAdded") then
		module.openCodex(player, ui, frame)
	else
		module.openMap(player, ui, frame)
	end

	characterController.attemptPause("MenuPause")

	showAttention(frame)
end

function module.Close(player, ui, frame)
	hideAllMenus(frame)
	RunService:UnbindFromRenderStep("ProcessCursor")

	frame.Gui.Enabled = false

	local viewport = frame.MapViewport
	currentMenu = nil

	if viewport:FindFirstChild("Map") then
		viewport.Map:Destroy()
	end

	characterController.attemptResume("MenuPause")
end

function module.Toggle(player, ui, frame)
	if frame.Gui.Enabled then
		module.Close(player, ui, frame)
	else
		module.Open(player, ui, frame)
	end
end

return module
