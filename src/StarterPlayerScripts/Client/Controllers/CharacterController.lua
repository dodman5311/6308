local module = {}

--// Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lighting = game:GetService("Lighting")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds

--// Modules
local signals = require(Globals.Signals)
local giftService = require(Globals.Client.Services.GiftsService)
local cameraShaker = require(Globals.Packages.CameraShaker)
local comboService = require(Globals.Client.Services.ComboService)
local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)
local UIService = require(Globals.Client.Services.UIService)
local soulsService = require(Globals.Client.Services.SoulsService)
local ViewmodelService = require(Globals.Vendor.ViewmodelService)
local ChanceService = require(Globals.Vendor.ChanceService)
local MusicService = require(Globals.Client.Services.MusicService)
local codexService = require(Globals.Client.Services.CodexService)

--// Values
local logHealth = 0
local collectedBlood = 0
local isPaused = false
local lastOnGroundPosition = Vector3.zero
local render
local mouse = Player:GetMouse()

local mouseTarget = Instance.new("ObjectValue")

--// Fucntions

local function ShakeCamera(shakeCf)
	if not isPaused then
		module.shakeCFrame = shakeCf
	end

	camera.CFrame = camera.CFrame * shakeCf
end

module.camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value + 3, ShakeCamera)
module.camShake:Start()

local function PlayHitEffect()
	signals.DoUiAction:Fire("HUD", "DamagePulse")
	module.camShake:Shake(cameraShaker.Presets["Hit"])
end

function module:OnSpawn(character, humanoid)
	ChanceService.luck = 0
	ChanceService.repetitionLuck = 0

	signals.DoUiAction:Fire("HUD", "Cleanup", true, humanoid.Health, humanoid.MaxHealth)

	signals.DoUiAction:Fire("Kiosk", "resetCost", true)
	signals.DoUiAction:Fire("HUD", "UpdatePlayerHealth", true, humanoid.Health, humanoid.MaxHealth)
	signals.DoUiAction:Fire(
		"HUD",
		"UpdatePlayerHealth",
		true,
		humanoid:GetAttribute("Armor"),
		humanoid:GetAttribute("MaxArmor"),
		true
	)

	local rootPart = character:WaitForChild("HumanoidRootPart")
	rootPart:WaitForChild("Died"):Destroy()
	rootPart:WaitForChild("Running"):Destroy()
	rootPart:WaitForChild("Jumping"):Destroy()
	rootPart:WaitForChild("Landing"):Destroy()
	rootPart:WaitForChild("FreeFalling"):Destroy()
	rootPart:WaitForChild("Climbing"):Destroy()
	rootPart:WaitForChild("GettingUp"):Destroy()
	rootPart:WaitForChild("Swimming"):Destroy()

	logHealth = humanoid.Health

	humanoid:GetAttributeChangedSignal("Armor"):Connect(function()
		signals.DoUiAction:Fire(
			"HUD",
			"UpdatePlayerHealth",
			true,
			humanoid:GetAttribute("Armor"),
			humanoid:GetAttribute("MaxArmor"),
			true
		)
	end)

	humanoid.HealthChanged:Connect(function(health)
		signals.DoUiAction:Fire("HUD", "UpdatePlayerHealth", true, health, humanoid.MaxHealth)

		if health == 1 then
			signals.DoUiAction:Fire("HUD", "UpdateGiftProgress", true, "Take_Two", 1)
		else
			signals.DoUiAction:Fire("HUD", "CooldownGift", true, "Take_Two", 0)
		end

		if health < logHealth then
			if giftService.CheckGift("Haven") then
				signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Haven")
				signals.DoUiAction:Fire("HUD", "CooldownGift", true, "Haven", 1)
			end

			PlayHitEffect()
			comboService.ReduceCombo(3)
		end

		logHealth = health
	end)

	if giftService.CheckGift("SpeedRunner") then
		humanoid.WalkSpeed += 3
	end

	if giftService.CheckGift("SpeedDemon") then
		humanoid.WalkSpeed += 6
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

	-- local newAlign = Instance.new("AlignOrientation")
	-- newAlign.MaxTorque = 100000000
	-- newAlign.MaxAngularVelocity = 100000000
	-- newAlign.Responsiveness = 200
	-- newAlign.RigidityEnabled = true
	-- newAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
	-- newAlign.Attachment0 = character.PrimaryPart:FindFirstChildOfClass("Attachment")
	-- newAlign.Parent = character.PrimaryPart

	-- render = RunService.RenderStepped:Connect(function()
	-- 	newAlign.CFrame = camera.CFrame
	-- end)
end

local function deathEffect()
	sounds.Death:Play()
	signals.PauseGame:Fire()

	local viewModel = ViewmodelService.viewModels[1].Model
	local impactCorrection = lighting.ImpactCorrection

	local highlight = viewModel.Highlight
	highlight.FillColor = Color3.new(0)
	highlight.FillTransparency = 0

	impactCorrection.TintColor = Color3.new(1)
	impactCorrection.Enabled = true
	task.wait(0.075)

	impactCorrection.TintColor = Color3.new(0)
	highlight.FillColor = Color3.new(1)
	task.wait(0.075)

	highlight.FillTransparency = 1
	impactCorrection.Enabled = false

	signals.ResumeGame:Fire()
end

function module:OnDied()
	if render then
		render:Disconnect()
	end

	deathEffect()
	UIService.doUiAction("HUD", "HideBossBar", true)
	signals.DoUiAction:Fire("DeathScreen", "ShowDeathScreen")
	net:RemoteEvent("OnPlayerDied"):FireServer()
end

local function onGiftAdded(gift)
	if not Player.Character then
		return
	end

	local humanoid = Player.Character:WaitForChild("Humanoid")
	if not humanoid then
		return
	end

	if gift == "SpeedRunner" then
		humanoid.WalkSpeed += 3.75
	end

	if gift == "SpeedDemon" then
		humanoid.WalkSpeed += 6.25
	end
end

local function checkForHeal()
	collectedBlood += 1

	if collectedBlood >= 25 then
		collectedBlood = 0
		util.PlaySound(assets.Sounds.BloodFuel, script, 0.1)
		net:RemoteEvent("Damage"):FireServer(Player.Character, -1)
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Sauce_Is_Fuel")
	end

	signals.DoUiAction:Fire("HUD", "UpdateGiftProgress", true, "Sauce_Is_Fuel", collectedBlood / 30)
end

mouseTarget.Changed:Connect(function(value)
	if not value then
		return
	end

	local model = value:FindFirstAncestorOfClass("Model")

	if not model then
		return
	end

	if model:HasTag("VendingMachine") then
		signals.AddEntry:Fire("Vending Machines")
	end

	if model.Name == "Kiosk" then
		signals.AddEntry:Fire("The Kiosk")
	end
end)

RunService.Heartbeat:Connect(function()
	mouseTarget.Value = mouse.Target

	if not Player.Character then
		return
	end

	local humanoid = Player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	if giftService.CheckGift("Heavenly_Fortune") and humanoid.FloorMaterial == Enum.Material.Air then
		ChanceService.airluck = true
	else
		ChanceService.airluck = false
	end

	local playerPivot = Player.Character:GetPivot()

	local inDamageZone = false
	for _, damagePart in ipairs(CollectionService:GetTagged("DamageZone")) do
		local distance = ((playerPivot.Position * Vector3.new(1, 0, 1)) - (damagePart.Position * Vector3.new(1, 0, 1))).Magnitude
		if distance > damagePart.Size.Z / 2 then
			continue
		end

		inDamageZone = true
	end

	if inDamageZone then
		signals.DoUiAction:Fire("HUD", "showDanger")
	else
		signals.DoUiAction:Fire("HUD", "hideDanger")
	end

	if playerPivot.Position.Y < -150 and workspace:GetAttribute("Stage") ~= 2 then
		Player.Character:PivotTo(CFrame.new(lastOnGroundPosition))
	end

	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = { Player.Character }
	rp.RespectCanCollide = true

	local raycast = workspace:Raycast(playerPivot.Position, playerPivot.UpVector * -3, rp)
	if raycast then
		lastOnGroundPosition = playerPivot.Position
	end

	if not giftService.CheckGift("Sauce_Is_Fuel") then
		return
	end

	local rp_0 = RaycastParams.new()
	rp_0.CollisionGroup = "Blood"

	local bloodcast = workspace:Raycast(playerPivot.Position, playerPivot.UpVector * -4, rp_0)
	if not bloodcast then
		return
	end

	local hitBlood = bloodcast.Instance

	if not hitBlood:HasTag("Blood") then
		return
	end

	local Blood = hitBlood:FindFirstChildOfClass("Decal")

	if not Blood then
		return
	end

	hitBlood.CollisionGroup = "Default"

	checkForHeal()

	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
	util.tween(Blood, ti, { Transparency = 1 }, true)
	hitBlood:Destroy()
end)

local function exitS2(extraSouls, totalLevel, level, stageBoss, miniBoss, stage)
	Player.Character.PrimaryPart.Anchored = false
	soulsService.AddSoul(extraSouls)

	if giftService.CheckGift("Paladin's_Faith") then
		net:RemoteEvent("CreateShield"):FireServer()
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Paladin's_Faith")
	end

	if stage == 1 then
		codexService.AddEntry("The Suburbs")
	elseif stage == 2 then
		codexService.AddEntry("The Sewers")
	end

	if level == 5 then
		MusicService.stopMusic()
		local onBiHidden = UIService.doUiAction("BossIntro", "ShowIntro", true, stageBoss)

		onBiHidden:Once(function()
			net:RemoteEvent("SpawnBoss"):FireServer("MainBoss")
			if soulsService.Souls < 3 then
				soulsService.AddSoul(3 - soulsService.Souls)
				UIService.doUiAction("HUD", "UpdateSouls", true, 3)
			end
		end)
	elseif level == 2 then
		net:RemoteEvent("SpawnBoss"):FireServer("MiniBoss")
		if soulsService.Souls < 1 then
			soulsService.AddSoul(1)
			UIService.doUiAction("HUD", "UpdateSouls", true, 1)
		end

		MusicService.playTrack(miniBoss)
	else
		task.delay(0.5, function()
			MusicService.playMusic(math.floor(totalLevel + 1))
		end)
	end

	camera.FieldOfView = 120
	local ti = TweenInfo.new(1, Enum.EasingStyle.Exponential)

	util.tween(camera, ti, { FieldOfView = 70 })
end

local function ExitSequence(levelData, level, stageBoss, miniBoss, stage)
	local plusStage = (stage - 1) * 5
	local totalLevel = plusStage + level

	Player.Character.PrimaryPart.Anchored = true

	local extraSouls = UIService.doUiAction("LevelEnd", "ShowLevelEnd", true, levelData)
	local onHidden

	if level <= 5 and level ~= 2.5 then
		onHidden = UIService.doUiAction("DeliveryUi", "ShowScreen", true, soulsService.Souls)

		onHidden:Once(function()
			exitS2(extraSouls, totalLevel, level, stageBoss, miniBoss, stage)
			UIService.doUiAction("HUD", "HideBossBar", true)
		end)
	else
		UIService.doUiAction("DeliveryUi", "fakeScreen", true)
		task.delay(1, exitS2, extraSouls, totalLevel, level, stageBoss, miniBoss, stage)
	end

	net:RemoteEvent("ProceedToNextLevel"):FireServer()
end

signals.PauseGame:Connect(function()
	local character = Player.Character

	if not character then
		return
	end

	for _, part in ipairs(character:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.Anchored = true
	end

	for _, particle in ipairs(CollectionService:GetTagged("Particle")) do
		particle.TimeScale = 0
	end
end)

signals.ResumeGame:Connect(function()
	local character = Player.Character

	if not character then
		return
	end

	for _, part in ipairs(character:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.Anchored = false
	end

	for _, particle in ipairs(CollectionService:GetTagged("Particle")) do
		particle.TimeScale = 1
	end
end)

signals.AddGift:Connect(onGiftAdded)
net:Connect("StartExitSequence", ExitSequence)

net:Connect("ArenaBegun", function(isAmbush)
	print(isAmbush)
	if isAmbush then
		UIService.doUiAction("Notify", "AmbushBegun", true)
	else
		UIService.doUiAction("Notify", "ArenaBegun", true)
	end
end)

net:Connect("ArenaEnd", function(result)
	UIService.doUiAction("Notify", "ArenaComplete", true, ChanceService.checkChance(15, true), result)
end)

signals.PauseGame:Connect(function()
	if isPaused then
		return
	end

	net:RemoteEvent("PauseGame"):FireServer()
	isPaused = true
end)

signals.ResumeGame:Connect(function()
	if not isPaused then
		return
	end

	net:RemoteEvent("ResumeGame"):FireServer()
	isPaused = false
end)

local UserInputService = game:GetService("UserInputService")

net:Connect("OpenKiosk", function()
	-- if not isPaused then
	-- 	signals.PauseGame:Fire()
	-- end

	UIService.doUiAction("Kiosk", "ShowScreen", true, soulsService.Souls)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.Tab then
		signals.DoUiAction:Fire("Menu", "Toggle", false)
	end
end)

signals.ToggleMenu:Connect(function()
	signals.DoUiAction:Fire("Menu", "Toggle", false)
end)

return module
