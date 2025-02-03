local module = {}

--// Services
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

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
local Acts = require(Globals.Vendor.Acts)
local weaponService = require(Globals.Client.Controllers.WeaponController)
local kiosk = require(ReplicatedStorage.Gui.Kiosk)

--// Values
local logHealth = 0
local collectedBlood = 0
local pauseAmnt = 0
local isPaused = false
local lastOnGroundPosition = Vector3.zero
local render
local mouse = Player:GetMouse()
local hasLookedAtMachine = false

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

function module.attemptPause(index)
	if not Acts:checkAct("DeathPause", "MenuPause", "RegPause", "EndPause") then
		signals.PauseGame:Fire()

		SoundService.Music.MuffleEffect.Enabled = true
	end

	Acts:createAct(index)
end

function module.attemptResume(index)
	Acts:removeAct(index)

	if Acts:checkAct("DeathPause", "MenuPause", "RegPause", "EndPause") then
		return
	end

	SoundService.Music.MuffleEffect.Enabled = false
	signals.ResumeGame:Fire()
end

local function progressTo(level)
	if level >= 1 then
		signals["AddGift"]:Fire("Master_Scouting")
	end

	if level >= 2 then
		local r = math.random(1, 3)

		if r == 1 then
			signals["AddGift"]:Fire("Brick_Hook")
		elseif r == 2 then
			signals["AddGift"]:Fire("Righteous_Motion")
		elseif r == 3 then
			signals["AddGift"]:Fire("Spiked_Sabatons")
		end
	end

	if level >= 3 then
		signals["AddGift"]:Fire("Overcharge")
	end
end

function module:OnSpawn(character, humanoid)
	if
		not giftService.CheckUpgrade("Anchovies")
		or workspace:GetAttribute("Level") == math.round(workspace:GetAttribute("Level"))
	then
		Player:SetAttribute("Anchovies", 4)

		ChanceService.luck = 0
		ChanceService.repetitionLuck = 0
	end

	signals.DoUiAction:Fire("HUD", "Cleanup", true, humanoid.Health, humanoid.MaxHealth)

	if giftService.CheckUpgrade("Order Wheel") then
		signals.AddGift:Fire("Speed_Demon")
		signals.AddGift:Fire("SpeedRunner")
	end

	if giftService.CheckUpgrade("Insurance") then
		signals.AddGift:Fire("Haven")
	end

	if giftService.CheckUpgrade("Quality Sauce") then
		signals.AddGift:Fire("Sauce_Is_Fuel")
	end

	if giftService.CheckUpgrade("Sister Location") then
		progressTo(2)
	end

	if giftService.CheckUpgrade("Pizza Chain") then
		progressTo(4)
	end

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

		signals.DoUiAction:Fire(
			"HUD",
			"UpdateGiftProgress",
			true,
			"Take_Two",
			health / Player:GetAttribute("MaxHealth")
		)

		if health < logHealth then
			if giftService.CheckGift("Haven") then
				signals.DoUiAction:Fire("HUD", "ShowInvincible", true)

				signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Haven")
				signals.DoUiAction:Fire("HUD", "CooldownGift", true, "Haven", 1)

				task.delay(1, function()
					signals.DoUiAction:Fire("HUD", "HideInvincible", true)
				end)
			end

			PlayHitEffect()
			comboService.ReduceCombo(2)
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
	local anchovies = Player:GetAttribute("Anchovies")
	if
		giftService.CheckUpgrade("Anchovies")
		and workspace:GetAttribute("Level") ~= math.round(workspace:GetAttribute("Level"))
		and anchovies
		and anchovies > 0
	then
		Player:SetAttribute("Anchovies", anchovies - 1)
	end

	sounds.Death:Play()
	module.attemptPause("DeathPause")

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

	module.attemptResume("DeathPause")
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

	if collectedBlood >= 20 then
		collectedBlood = 0
		util.PlaySound(assets.Sounds.BloodFuel, script, 0.1)
		net:RemoteEvent("Damage"):FireServer(Player.Character, -1)
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Sauce_Is_Fuel")
	end

	signals.DoUiAction:Fire("HUD", "UpdateGiftProgress", true, "Sauce_Is_Fuel", collectedBlood / 20)
end

mouseTarget.Changed:Connect(function(value)
	if not value then
		return
	end

	local model = value:FindFirstAncestorOfClass("Model")

	if not model then
		return
	end

	local throwWeaponGui = Player.PlayerGui.ThrowWeaponGui

	if weaponService.HasHitMachine or not weaponService.currentWeapon then
		throwWeaponGui.Enabled = false
	end

	if model:HasTag("VendingMachine") then
		signals.AddEntry:Fire("Vending Machines")

		if not weaponService.HasHitMachine and weaponService.currentWeapon then
			throwWeaponGui.Enabled = true
			throwWeaponGui.Adornee = model.PrimaryPart

			if workspace:GetAttribute("GlobalInputType") == "Xbox" then
				throwWeaponGui.TextLabel.Text = "B to throw weapon"
			elseif workspace:GetAttribute("GlobalInputType") == "Ps4" then
				throwWeaponGui.TextLabel.Text = "Circle to throw weapon"
			else
				throwWeaponGui.TextLabel.Text = "X to throw weapon"
			end
		end
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

	local rainPart = workspace:FindFirstChild("RainPart")
	if workspace:GetAttribute("Stage") == 3 then
		if not rainPart then
			rainPart = assets.Effects.RainPart:Clone()
			rainPart.Parent = workspace
		end

		local characterPosition = Player.Character:GetPivot()
		rainPart.CFrame = characterPosition * CFrame.new(0, 25, 0)

		local raycast =
			workspace:Raycast(characterPosition.Position + Vector3.new(0, 5, 0), characterPosition.UpVector * 500)

		if raycast then
			rainPart.Emitter1.Enabled = false
			rainPart.Emitter2.Enabled = false
		else
			rainPart.Emitter1.Enabled = true
			rainPart.Emitter2.Enabled = true
		end
	elseif rainPart then
		rainPart:Destroy()
	end

	if giftService.CheckGift("Heavenly_Fortune") and humanoid.FloorMaterial == Enum.Material.Air then
		ChanceService.airluck = true
	else
		ChanceService.airluck = false
	end

	local playerPivot = Player.Character:GetPivot()

	local inDamageZone = nil
	for _, damagePart in ipairs(CollectionService:GetTagged("DamageZone")) do
		local distance = ((playerPivot.Position * Vector3.new(1, 0, 1)) - (damagePart.Position * Vector3.new(1, 0, 1))).Magnitude
		if distance > damagePart.Size.Z / 2 then
			continue
		end

		inDamageZone = damagePart.Color
	end

	if inDamageZone then
		signals.DoUiAction:Fire("HUD", "showDanger", true, inDamageZone)
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
	module.attemptResume("EndPause")

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

		local gameState = {
			Stage = workspace:GetAttribute("Stage"),
			Level = workspace:GetAttribute("Level"),
			Souls = soulsService.Souls,

			critChances = weaponService.critChances,

			Luck = ChanceService.luck,
			PerkTickets = kiosk.tickets,

			PerkList = giftService.AquiredGifts,
		}

		net:RemoteEvent("SaveGameState"):FireServer(gameState)
		--signals.DoUiAction:Fire("Notify", "GameSaved", false)
	end

	net:RemoteEvent("SaveFurthestLevel"):FireServer()

	camera.FieldOfView = 1000
	local ti = TweenInfo.new(1, Enum.EasingStyle.Exponential)

	util.tween(camera, ti, { FieldOfView = util.getSetting("Field of View").Value })
end

local function ExitSequence(levelData, level, stageBoss, miniBoss, stage)
	local plusStage = (stage - 1) * 5
	local totalLevel = plusStage + level

	module.attemptPause("EndPause")

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

signals.LoadSavedDataFromClient:Connect(function(upgradeIndex, gameState)
	if not Player.Character then
		Player.CharacterAdded:Wait()
	end

	soulsService.AddSoul(gameState["Souls"] or 0)

	if gameState["critChances"] then
		weaponService.critChances = gameState.critChances
	end
	ChanceService.luck = gameState["Luck"] or 0
	kiosk.tickets = gameState["PerkTickets"] or 0

	for _, perkName in ipairs(gameState["PerkList"] or {}) do
		signals.AddGift:Fire(perkName)
	end

	giftService.UpgradeIndex = upgradeIndex
end)

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

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then
		return
	end

	if
		input.KeyCode == Enum.KeyCode.Tab
		or input.KeyCode == Enum.KeyCode.M
		or input.KeyCode == Enum.KeyCode.ButtonSelect
	then
		GuiService.SelectedObject = nil
		signals.DoUiAction:Fire("Menu", "Toggle", true)
	end
end)

signals.ToggleMenu:Connect(function()
	signals.DoUiAction:Fire("Menu", "Toggle", true)
end)

GuiService.MenuOpened:Connect(function()
	StarterGui:SetCore("ResetButtonCallback", false)

	module.attemptPause("RegPause")
	UIService.doUiAction("Paused", "Pause", true, true)
end)

GuiService.MenuClosed:Connect(function()
	module.attemptResume("RegPause")
	UIService.doUiAction("Paused", "Pause", true, false)
end)

return module
