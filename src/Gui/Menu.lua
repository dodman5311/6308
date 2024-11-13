local module = {}
--// Services
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds

local mapCamera = Instance.new("Camera")
local weaponCamera = Instance.new("Camera")

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
local mapInFocus = false
local currentMenu = "Map"
local currentCatagory = "Weapons"

local zoomDirection = 0
local zoomAmount = 0
local mouse2Down = false
local mouse1Down = false

local padDeltaLeft = Vector2.zero
local padDeltaRight = Vector2.zero

local lastMouseUp = os.clock()

--// Functions

local weaponIcons = {
	Shotgun = "rbxassetid://18298958678",
	Pistol = "rbxassetid://18298957212",
	Melee = "rbxassetid://18298955289",
	AR = "rbxassetid://18298954616",
}

local function Lerp(num, goal, i)
	return num + (goal - num) * i
end

local function map(n, start, stop, newStart, newStop, withinBounds)
	local value = ((n - start) / (stop - start)) * (newStop - newStart) + newStart

	-- Returning basic value.
	if not withinBounds then
		return value
	end

	-- Returns Values constrained to exact Range.
	if newStart < newStop then
		return math.max(math.min(value, newStop), newStart)
	else
		return math.max(math.min(value, newStart), newStop)
	end
end

local function setDownSelection(frame, downSelectionButton)
	for _, v in ipairs(frame.Main.Buttons:GetChildren()) do
		v.NextSelectionDown = downSelectionButton
	end
end

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

local function openCodexEntry(entry, entryIndex, frame)
	if not entry then
		return
	end

	frame.EntryText.Text = entry.Entry
	frame.EntryName.Text = entryIndex

	codexService.CodexEntries[entryIndex].Viewed = true

	showAttention(frame)
end

local function loadCodexCatagory(frame, catagory, setColor)
	for _, v in ipairs(frame.CodexList:GetChildren()) do
		if not v:IsA("ImageButton") then
			continue
		end

		v:Destroy()
	end

	frame.EntryText.Text = ""
	frame.EntryName.Text = ""

	if setColor then
		for _, button in ipairs(frame.Codex_Menu.Buttons:GetChildren()) do
			if button.Name == catagory then
				frame[button.Name .. "_Lbl"].ImageColor3 = Color3.fromRGB(255, 75, 75)
			else
				frame[button.Name .. "_Lbl"].ImageColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end

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
			openCodexEntry(entry, entryName, frame)
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

local function setBoolToValue(buttonFrame, value)
	local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quart)

	local endPos = value and UDim2.fromScale(0.11, 0) or UDim2.fromScale(0, 0)
	local endColor = value and Color3.fromRGB(160, 255, 175) or Color3.fromRGB(170, 70, 70)

	util.tween(buttonFrame.Switch, ti, { Position = endPos })
	util.tween(buttonFrame.ValueColor, ti, { ImageColor3 = endColor })

	buttonFrame.Value.Text = tostring(value)
end

local function setSliderToValue(barFrame, input, maxValue)
	local alphaValue = 0

	if typeof(input) == "number" then
		alphaValue = math.round(input * 100) / 100
	else
		local mousePosition = Vector2.new(input.Position.X, input.Position.Y)
		local xPosition = (mousePosition.X - barFrame.AbsolutePosition.X) / barFrame.AbsoluteSize.X
		alphaValue = math.round(xPosition * 100) / 100
	end

	if alphaValue >= 0.98 then
		alphaValue = 1
	elseif alphaValue <= 0.02 then
		alphaValue = 0
	end

	--local value = alphaValue * maxValue

	local value = Lerp(maxValue.Min, maxValue.Max, alphaValue)

	barFrame.Parent.Value.Text = math.round(value)
	barFrame.Bar.Size = UDim2.fromScale(alphaValue, 1)

	return value
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

function module.Init(player: Player, ui, frame)
	frame.Gui.Enabled = false

	if player:GetAttribute("furthestLevel") > 1 then
		ui.HUD.OpenMenuPrompt_T.Visible = false
	end

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
		if frame.ConfirmRestartFrame.Visible or frame.ConfirmReturnFrame.Visible then
			return
		end

		frame.ConfirmRestartFrame.Visible = true
	end)

	frame.Return.MouseButton1Click:Connect(function()
		if frame.ConfirmReturnFrame.Visible or frame.ConfirmRestartFrame.Visible then
			return
		end

		frame.ConfirmReturnFrame.Visible = true
	end)

	frame.ConfirmRestart.MouseButton1Click:Connect(function()
		frame.ConfirmRestartFrame.Visible = false
		module.Close(player, ui, frame)

		SoulsService.RemoveSoul(SoulsService.Souls)
		net:RemoteEvent("UpdatePlayerHealth"):FireServer(player:GetAttribute("MaxHealth"), 0, false)
	end)

	frame.CancelRestart.MouseButton1Click:Connect(function()
		frame.ConfirmRestartFrame.Visible = false
	end)

	frame.ConfirmReturn.MouseButton1Click:Connect(function()
		local loadingScreen = ReplicatedStorage.LoadingScreen:Clone()
		loadingScreen.Parent = player.PlayerGui

		loadingScreen.Background.BackgroundTransparency = 1
		util.tween(loadingScreen.Background, TweenInfo.new(0.5), { BackgroundTransparency = 0 })

		loadingScreen.Enabled = true

		TeleportService:SetTeleportGui(ReplicatedStorage.LoadingScreen)
		TeleportService:Teleport(17820071397, player)
	end)

	frame.CancelReturn.MouseButton1Click:Connect(function()
		frame.ConfirmReturnFrame.Visible = false
	end)

	local focusButton: TextButton = frame.FocusMap

	focusButton.MouseButton1Click:Connect(function()
		GuiService.SelectedObject = nil
		mapInFocus = true
	end)
end

UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoomAmount -= input.Position.Z
	end

	if mapInFocus and input.KeyCode == Enum.KeyCode.Thumbstick1 then
		if input.Position.Magnitude > 0.25 then
			padDeltaLeft = (input.Position * Vector3.new(1, -1)) * 2
		else
			padDeltaLeft = Vector2.zero
		end
	end

	if mapInFocus and input.KeyCode == Enum.KeyCode.Thumbstick2 then
		if input.Position.Magnitude > 0.25 then
			padDeltaRight = input.Position
		else
			padDeltaRight = Vector2.zero
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.ButtonA and mapInFocus then
		mapInFocus = false
		GuiService:Select(Players.LocalPlayer.PlayerGui)
	end

	if input.KeyCode == Enum.KeyCode.ButtonL2 then
		zoomDirection = 1
	end

	if input.KeyCode == Enum.KeyCode.ButtonR2 then
		zoomDirection = -1
	end

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
	if input.KeyCode == Enum.KeyCode.ButtonL2 then
		zoomDirection = 0
	end

	if input.KeyCode == Enum.KeyCode.ButtonR2 then
		zoomDirection = 0
	end

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

	RunService:BindToRenderStep("ProcessMapCamera", Enum.RenderPriority.Camera.Value, function(delta)
		if mapInFocus then
			zoomAmount += (zoomDirection * delta) * zoomSensitivity
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

		if UserInputService.GamepadEnabled then
			cameraOffset *= CFrame.new(padDeltaLeft.X * moveSensitivity, -padDeltaLeft.Y * moveSensitivity, 0)
			camAngleX += padDeltaRight.X * turnSensitivity
			camAngleY += padDeltaRight.Y * turnSensitivity
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
	mapInFocus = false
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

			frame.PerkInfo.PerkName.Text = string.gsub(gift, "_", " ")
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

	if gunStats["SplashDamage"] then
		damageNum.Text ..= " + " .. gunStats.SplashDamage
	end

	if gunStats.BulletCount > 1 then
		damageNum.Text ..= " x " .. gunStats.BulletCount
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
				settingTable:OnChanged(frame)
			end)

			newSettingsButton.SettingName.Text = settingTable.Name
			setBoolToValue(newSettingsButton, settingTable.Value)
		elseif settingTable.Type == "Slider" then
			newSettingsButton.Value.Text = math.round(settingTable.Value)
			newSettingsButton.SettingName.Text = settingTable.Name

			local barFrame: Frame = newSettingsButton.BarFrame
			barFrame.Bar.Size = UDim2.fromScale(
				map(settingTable.Value, settingTable.MaxValue.Min, settingTable.MaxValue.Max, 0, 1, false),
				1
			)

			local mouseDown = false

			barFrame.InputBegan:Connect(function(input)
				if
					input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				mouseDown = true

				settingTable.Value = setSliderToValue(barFrame, input, settingTable.MaxValue)
				settingTable:OnChanged(frame)
			end)

			barFrame.InputEnded:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					mouseDown = false
				end
			end)

			barFrame.InputChanged:Connect(function(input)
				if
					input.UserInputType ~= Enum.UserInputType.MouseMovement
					and input.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				if not mouseDown then
					return
				end

				settingTable.Value = setSliderToValue(barFrame, input, settingTable.MaxValue)
				settingTable:OnChanged(frame)
			end)

			local inputChanged
			local heartbeat

			newSettingsButton.SelectionGained:Connect(function()
				local position = Vector2.zero
				inputChanged = UserInputService.InputChanged:Connect(function(input, gpe)
					if input.KeyCode ~= Enum.KeyCode.Thumbstick2 then
						return
					end

					position = input.Position

					if input.Position.Magnitude > 0.25 then
						position = input.Position
					else
						position = Vector2.zero
					end
				end)

				heartbeat = RunService.Heartbeat:Connect(function(delta)
					settingTable.Value = setSliderToValue(
						barFrame,
						barFrame.Bar.Size.X.Scale + ((position.X * 1.5) * delta),
						settingTable.MaxValue
					)
					settingTable:OnChanged(frame)
				end)
			end)

			newSettingsButton.SelectionLost:Connect(function()
				inputChanged:Disconnect()
				heartbeat:Disconnect()
			end)
		end
	end
end

function module.openMap(player, ui, frame)
	if currentMenu == "Map" then
		return
	end

	currentMenu = "Map"

	mapInFocus = false

	hideAllMenus(frame)
	loadMap(player, frame)
	processCamera(frame)

	frame.LevelDisplay.Text = "Stage: "
		.. workspace:GetAttribute("Stage")
		.. "  "
		.. "Level: "
		.. workspace:GetAttribute("Level")

	frame.Map_Menu.Visible = true

	setDownSelection(frame, frame.FocusMap)

	if workspace:GetAttribute("GlobalInputType") == "Keyboard" then
		frame.MapControls.Text = [[Scroll : Zoom
Left Click : Move
Right Click : Rotate]]
	elseif workspace:GetAttribute("GlobalInputType") == "Mobile" then
		frame.MapControls.Text = [[Pinch : Zoom
Tap : Move
Double Tap : Rotate]]
	else
		frame.MapControls.Text = [[Triggers : Zoom
Left Thumbstick : Move
Right Thumbstick : Rotate]]
	end

	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	util.tween(frame.Map_Menu, ti, { GroupTransparency = 0 })
	util.tween(frame.BackgroundFrame, ti, { BackgroundTransparency = 0 })
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

	setDownSelection(frame, frame.PerksList)

	util.tween(frame.Arsenal_Menu, ti, { GroupTransparency = 0 })
	util.tween(frame.BackgroundFrame, ti, { BackgroundTransparency = 0.25 })
end

function module.openCodex(player, ui, frame, openToLatest)
	if currentMenu == "Codex" then
		return
	end

	currentMenu = "Codex"
	hideAllMenus(frame)
	loadCodex(frame)

	local latestEntry

	if openToLatest and codexService.latestEntry then
		latestEntry = codexService.CodexEntries[codexService.latestEntry]
		currentCatagory = latestEntry.Catagory
	end

	loadCodexCatagory(frame, currentCatagory, true)
	showAttention(frame)
	openCodexEntry(latestEntry, codexService.latestEntry, frame)

	frame.Codex_Menu.Visible = true

	setDownSelection(frame, frame.CodexList)

	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	util.tween(frame.Codex_Menu, ti, { GroupTransparency = 0 })
	util.tween(frame.BackgroundFrame, ti, { BackgroundTransparency = 0.25 })
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

	setDownSelection(frame, frame.Settings)

	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	util.tween(frame.Settings_Menu, ti, { GroupTransparency = 0 })
	util.tween(frame.BackgroundFrame, ti, { BackgroundTransparency = 0.25 })
end

local function saveSettings(player)
	local settingsToSave = {}
	for _, value in ipairs(gameSettings) do
		if typeof(value) == "string" then
			continue
		end

		settingsToSave[value.Name] = value.Value
	end

	net:RemoteEvent("SaveData"):FireServer("PlayerSettings", settingsToSave)
end

local function saveCodex()
	codexService.saveCurrentCodex()
end

function module.Open(player, ui, frame)
	ui.HUD.OpenMenuPrompt_T.Visible = false
	mapInFocus = false
	Signals.DoUiAction:Fire("Cursor", "Toggle", true, true)
	Signals["SetMobileControlsVisible"]:Fire(false)

	setDownSelection(frame)

	frame.Gui.Enabled = true
	Lighting.PauseBlur.Enabled = true

	local logCurrentMenu = currentMenu
	currentMenu = nil

	if acts:checkAct("EntryAdded") then
		module.openCodex(player, ui, frame, true)
	else
		module["open" .. logCurrentMenu](player, ui, frame)
		--module.openMap(player, ui, frame)
	end

	characterController.attemptPause("MenuPause")

	showAttention(frame)

	--GuiService.GuiNavigationEnabled = true

	if UserInputService.GamepadEnabled then
		GuiService:Select(frame.Main.Buttons)
	end
end

function module.Close(player, ui, frame)
	hideAllMenus(frame)
	Signals["SetMobileControlsVisible"]:Fire(true)

	Signals.DoUiAction:Fire("Cursor", "Toggle", true, false)

	Lighting.PauseBlur.Enabled = false
	frame.Gui.Enabled = false
	mapInFocus = false

	local viewport = frame.MapViewport

	if viewport:FindFirstChild("Map") then
		viewport.Map:Destroy()
	end

	characterController.attemptResume("MenuPause")

	if UserInputService.GamepadEnabled then
		GuiService:Select(player.PlayerGui)
	end

	saveSettings(player)
	saveCodex()
end

function module.Toggle(player, ui, frame)
	if frame.Gui.Enabled then
		module.Close(player, ui, frame)
	else
		module.Open(player, ui, frame)
	end
end

return module
