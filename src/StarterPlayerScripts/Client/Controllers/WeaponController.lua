local module = {
	defaultMagSize = 16,

	critChances = {
		AR = 0,
		Pistol = 0,
		Shotgun = 0,
		Melee = 0,
	},
}

--// Services
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local assets = Globals.Assets
local reloadSounds = assets.Sounds.Reloading
local camera = workspace.CurrentCamera

local player = Players.LocalPlayer

local voiceSound = Instance.new("Sound")
voiceSound.Parent = script
voiceSound.Volume = 1.5

local defaultFireRate = 0.2

--// Modules
local signals = require(Globals.Signals)
local signal = require(Globals.Packages.Signal)
local viewmodelService = require(Globals.Vendor.ViewmodelService)
local animationService = require(Globals.Vendor.AnimationService)
local UiAnimationService = require(Globals.Vendor.UIAnimationService)
local acts = require(Globals.Vendor.Acts)
local util = require(Globals.Vendor.Util)
local spring = require(Globals.Vendor.Spring)
local GiftsService = require(Globals.Client.Services.GiftsService)
local dropService = require(Globals.Shared.DropService)
local Janitor = require(Globals.Packages.Janitor)
local RicoshotService = require(Globals.Client.Services.RicoshotService)
local BloodEffects = require(Globals.Shared.BloodEffects)
local ComboService = require(Globals.Client.Services.ComboService)
local WeakspotService = require(Globals.Client.Services.WeakspotService)
local explosionService = require(Globals.Client.Services.ExplosionService)
local UIService = require(Globals.Client.Services.UIService)
local soulsService = require(Globals.Client.Services.SoulsService)
local codexService = require(Globals.Client.Services.CodexService)

local projectileService = require(Globals.Client.Services.ClientProjectiles)

local Timer = require(Globals.Vendor.Timer)

local net = require(Globals.Packages.Net)
local ChanceService = require(Globals.Vendor.ChanceService)

local weaponTimer = require(Globals.Vendor.Timer):newQueue()
local weaponReloadTimer = weaponTimer:new("WeaponReload")

--// Values

local crosshairs = {
	Default = "rbxassetid://16453731677",
	Automatic = "rbxassetid://16453783301",
	Smart = "rbxassetid://16453798876",
	Accurate = "rbxassetid://16454145466",
	Melee = "rbxassetid://16453818021",
	Shotgun = "rbxassetid://16453839415",
}

local defaultIndex = 0
local viewmodel
local defaultWeapon

local currentAmmo = module.defaultMagSize
module.currentWeapon = nil
local weaponData

local mouseButton1Down = false
local canBlock = true

local consecutiveHits = 0
local Overcharge = 0
local lastDamageSource

local rng = Random.new()

local slots = {
	{
		Ammo = 0,
		CurrentWeapon = nil,
		WeaponData = nil,
		Element = nil,
	},

	{
		Ammo = 0,
		CurrentWeapon = nil,
		WeaponData = nil,
		Element = nil,
	},

	{
		Ammo = 0,
		CurrentWeapon = nil,
		WeaponData = nil,
		Element = nil,
	},
}

local currentSlot = 1
local hitHumanoids = {}

local lockTimer = weaponTimer:new("LockOn")
local lockGuis = {}

local fireTimer = Timer:new("FireDelay", 0)

--// Function

local recoilSpring = spring.new(Vector3.zero)
recoilSpring.Speed = 30
recoilSpring.Damper = 0.45

local function getObjectInCenter(player, blacklist)
	local inCenter
	local objectsOnScreen = {}
	local leastDistance = math.huge
	local getObject

	local list = {}

	for _, model in ipairs(CollectionService:GetTagged("Enemy")) do
		table.insert(list, model)
	end

	if GiftsService.CheckGift("Ricoshot") then
		for _, model in ipairs(CollectionService:GetTagged("ThrownWeapon")) do
			table.insert(list, model)
		end
	end

	for _, model in ipairs(list) do
		if blacklist and table.find(blacklist, model) then
			continue
		end

		local hasPart = model:FindFirstChildOfClass("Part")
		if not hasPart then
			continue
		end

		if
			not model:HasTag("ThrownWeapon")
			and (not model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("Humanoid").Health <= 0)
		then
			continue
		end

		local modelPosition = model:GetPivot().Position

		local trueCenter = camera.ViewportSize / 2

		local getPosition, onScreen = camera:WorldToScreenPoint(modelPosition)

		if getPosition.Z > 100 then
			continue
		end

		local onScreenPosition = Vector2.new(getPosition.X, getPosition.Y)
		local distanceToCenter = (trueCenter - onScreenPosition).Magnitude

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = { workspace.Map }

		local cameraPosition = camera.CFrame.Position
		local ray = workspace:Raycast(cameraPosition, modelPosition - cameraPosition, raycastParams)

		if ray or not onScreen then
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

local function checkOtherSlot(valueIndex, value)
	for index, slot in ipairs(slots) do
		if index == currentSlot or slot.CurrentWeapon then
			continue
		end

		return slot[valueIndex] == value, index
	end
end

local function setOtherSlot(valueIndex, value)
	for index, slot in ipairs(slots) do
		if index == currentSlot or slot.CurrentWeapon then
			continue
		end

		slot[valueIndex] = value
		return index
	end
end

function module.UpdateSlot()
	local slot = slots[currentSlot]

	slot.CurrentWeapon = module.currentWeapon
	slot.WeaponData = weaponData
	slot.Element = weaponData and weaponData.Element

	slot.Ammo = currentAmmo -- module.currentWeapon and currentAmmo or 0

	if slot.CurrentWeapon then
		return
	end

	setOtherSlot("Ammo", currentAmmo)
end

function module.UpdateAmmo(amount)
	if amount < currentAmmo and acts:checkAct("Overcharged") then
		return
	end

	amount = math.round(amount)
	currentAmmo = amount
	signals.DoUiAction:Fire("HUD", "UpdateAmmo", true, currentAmmo)

	module.UpdateSlot()
end

local function playVoiceLine()
	ChanceService.doWithChance(1, true, function()
		local voiceLines = assets.Sounds.VoiceLines
		local voiceLine = util.getRandomChild(voiceLines)

		voiceSound.SoundId = voiceLine.SoundId
		voiceSound:Play()
	end)
end

function module.EquipWeapon(weaponName, pickupType, element, extraAmmo)
	signals.DoUiAction:Fire("HUD", "hideReload", true)

	lockTimer:Cancel()
	acts:waitForAct("Throwing", "Equipping")

	acts:createAct("Equipping")

	if pickupType ~= "SlotSwitch" then
		signals.DoUiAction:Fire("Notify", "ShowWeapon", true, weaponName)
	end

	if pickupType ~= "SlotSwitch" and module.currentWeapon then
		local slotIsEmpty, emptySlot = checkOtherSlot("CurrentWeapon", nil)

		if GiftsService.CheckGift("Mule_Bags") and slotIsEmpty then
			module.SwitchToSlot(emptySlot)
		else
			module.Throw()
		end
	end

	local weapon = assets.Models.Weapons:FindFirstChild(weaponName)

	print(weaponName, weapon)

	if not weapon then
		acts:removeAct("Equipping")
		return
	end

	signals.AddEntry:Fire(weaponName)

	defaultWeapon.Parent = game

	local newWeapon = weapon:Clone()

	-- if pickupType == "FromWorld" then
	-- 	pickupFromPoint(newWeapon, pickupCFrame)
	-- end

	newWeapon.Parent = viewmodel.Model

	weaponData = require(newWeapon.Data)

	signals.DoUiAction:Fire("HUD", "SetCrosshair", true, crosshairs[weaponData.Crosshair])

	local newM6d = Instance.new("Motor6D")
	newM6d.Parent = newWeapon
	newM6d.Part0 = viewmodel.Model.RightGrip
	newM6d.Part1 = newWeapon.Grip

	local lGrip = newWeapon:FindFirstChild("LGrip", true)

	if lGrip then
		local LM6d = Instance.new("Motor6D")
		LM6d.Parent = newWeapon
		LM6d.Part0 = viewmodel.Model.LeftGrip
		LM6d.Part1 = lGrip
		LM6d.Name = "LM6D"
	end

	animationService:stopAnimation(viewmodel.Model, "Equip", 0)
	animationService:stopAnimation(viewmodel.Model, "DefaultIdle", 0)
	animationService:stopAnimation(viewmodel.Model, "DefaultEquip", 0)

	animationService:loadAnimations(viewmodel.Model, newWeapon.Animations)

	if newWeapon.Animations:FindFirstChild("Equip") then
		animationService:playAnimation(viewmodel.Model, "Equip", Enum.AnimationPriority.Action4.Value, false, 0)
	end

	animationService:playAnimation(viewmodel.Model, "Idle", Enum.AnimationPriority.Idle.Value, false, 0)

	local ammoToAdd = weaponData.Ammo

	if GiftsService.CheckGift("Hoarder") then
		ammoToAdd += weaponData.Ammo * 0.25
	end

	if GiftsService.CheckGift("War_Drums") then
		ammoToAdd += weaponData.Ammo * 0.75
	end

	if extraAmmo then
		ammoToAdd += weaponData.Ammo * (extraAmmo / 100)
	end

	module.currentWeapon = newWeapon

	animationService:stopAnimation(viewmodel.Model, "Reload", 0)
	animationService:stopAnimation(viewmodel.Model, "ReloadOut", 0)

	weaponData.Element = element

	if element then
		if weaponData.Type == "Melee" then
			for _, effect in ipairs(assets.Effects.WeaponElements:GetChildren()) do
				if effect.Name ~= element then
					continue
				end

				effect:Clone().Parent = newWeapon.HitBox
			end
		else
			for _, effect in ipairs(assets.Effects.BarrelElements:GetChildren()) do
				if effect.Name ~= element then
					continue
				end

				effect:Clone().Parent = newWeapon.FirePart
			end
		end
	end

	if pickupType ~= "SlotSwitch" then
		module.UpdateAmmo(ammoToAdd)
		module.UpdateSlot()
	end

	acts:removeAct("Equipping")
	signals.WeaponEquipped:Fire(weaponName, weaponData["BlockTime"])
end

local function EquipDefault(ignoreAmmo)
	signals.DoUiAction:Fire("HUD", "hideReload", true)
	animationService:stopAnimation(viewmodel.Model, "Equip", 0)
	animationService:playAnimation(viewmodel.Model, "DefaultIdle", Enum.AnimationPriority.Core.Value, false, 0)

	animationService:playAnimation(viewmodel.Model, "DefaultEquip", Enum.AnimationPriority.Action3.Value, false, 0)

	signals.DoUiAction:Fire("HUD", "SetCrosshair", true, crosshairs.Default, true)

	--fireTimer:Complete()
	defaultWeapon.Parent = viewmodel.Model

	if ignoreAmmo then
		return
	end

	module.UpdateAmmo(module.defaultMagSize)
	signals.WeaponEquipped:Fire("Cleanse & Repent")
end

local function Recoil(recoilVector, randomVector, magnitude, speed)
	local randomizedVector = Vector3.new(
		rng:NextNumber(recoilVector.X + -randomVector.X, recoilVector.X + randomVector.X) * 100,
		rng:NextNumber(recoilVector.Y + -randomVector.Y, recoilVector.Y + randomVector.Y) * 100,
		rng:NextNumber(recoilVector.Z + -randomVector.Z, recoilVector.Z + randomVector.Z) * 100
	) * magnitude

	recoilSpring.Speed = 30 * speed

	recoilSpring:Impulse(randomizedVector)
end

local function showMuzzleFlash(flashPart, offset)
	if not offset then
		offset = CFrame.new()
	end

	for _, effect in ipairs(flashPart:GetChildren()) do
		if not string.match(effect.Name, "FireEffect") then
			continue
		end
		effect:Emit(5)
	end

	flashPart.FireLight.Enabled = true
	task.delay(0.05, function()
		if not flashPart.Parent then
			return
		end
		flashPart.FireLight.Enabled = false
	end)

	if module.currentWeapon ~= nil then
		return
	end

	local partClone = assets.Effects.smokePart:Clone()
	partClone.Parent = workspace.Ignore
	partClone.CFrame = flashPart.CFrame * offset
	partClone.Hit.Position = Vector3.new(0, 0, -100)
	partClone.Beam.Enabled = true

	task.spawn(function()
		for i = 0.5, 1, 0.05 do
			task.wait(0.05)
			partClone.Beam.Transparency = NumberSequence.new(i)
		end
		partClone:Destroy()
	end)
end

local function ReloadDefault()
	local reloadTime = GiftsService.CheckGift("Fast_Mags") and 1.5 or 1

	if currentAmmo <= 0 then
		animationService:playAnimation(
			viewmodel.Model,
			"ReloadOut",
			Enum.AnimationPriority.Action3.Value,
			false,
			0,
			1,
			reloadTime
		)

		local reloadAnimation: AnimationTrack = animationService:getAnimation(viewmodel.Model, "ReloadOut")
		UIService.doUiAction("HUD", "reload", true, reloadAnimation.Length / reloadTime)

		reloadAnimation.Stopped:Wait()
	else
		animationService:playAnimation(
			viewmodel.Model,
			"Reload",
			Enum.AnimationPriority.Action3.Value,
			false,
			0,
			1,
			reloadTime
		)
		local reloadAnimation: AnimationTrack = animationService:getAnimation(viewmodel.Model, "Reload")
		UIService.doUiAction("HUD", "reload", true, reloadAnimation.Length / reloadTime)

		reloadAnimation.Stopped:Wait()
	end

	if module.currentWeapon then
		return
	end

	module.UpdateAmmo(module.defaultMagSize)

	module.UpdateSlot()
end

local function completeReload(magSize)
	task.spawn(function()
		for i = 1, 0, -0.1 do
			task.wait()
			viewmodel:UpdateOffset("ReloadOffset", CFrame.new(i, -i * 3, i))
		end
	end)

	assets.Sounds.Reload:Stop()
	weaponData.HasReloaded = true

	local ammoToSet = magSize

	if GiftsService.CheckGift("Hoarder") then
		ammoToSet += magSize * 0.25
	end

	if GiftsService.CheckGift("War_Drums") then
		ammoToSet += magSize * 0.75
	end

	module.UpdateAmmo(ammoToSet)
	module.UpdateSlot()

	acts:removeAct("Reloading")
end

local function reload(infiniteReloads)
	if acts:checkAct("Throwing", "Reloading") or not module.currentWeapon then
		return
	end

	if weaponData.HasReloaded and not infiniteReloads then
		return
	end

	acts:createAct("Reloading")

	local defWeapon = assets.Models.Weapons:FindFirstChild(module.currentWeapon.Name)
	local defWeaponData = require(defWeapon.Data)
	local magSize = defWeaponData.Ammo

	local reloadMult = GiftsService.CheckGift("Fast_Mags") and 1.5 or 1
	local reloadTime = (magSize * 0.1) / reloadMult

	local reloadSound: Sound = assets.Sounds.Reload

	---reloadSound.PlaybackSpeed = reloadSound.TimeLength / reloadTime
	reloadSound:Play()

	task.spawn(function()
		for i = 0, 1, 0.1 do
			task.wait()
			viewmodel:UpdateOffset("ReloadOffset", CFrame.new(i, -i * 3, i))
		end
	end)

	UIService.doUiAction("HUD", "reload", true, reloadTime)

	weaponReloadTimer.WaitTime = reloadTime
	weaponReloadTimer.Function = completeReload
	weaponReloadTimer.Parameters = { magSize }

	weaponReloadTimer:Run()
end

local function checkDeadshot()
	if not GiftsService.CheckGift("Deadshot") or not ChanceService.checkChance(10, true) then
		return 0
	end
	return 1
end

local function showDeadshot(position)
	local newEffect = assets.Effects.Deadshot:Clone()
	newEffect.Parent = workspace
	Debris:AddItem(newEffect, 1)

	newEffect.Position = position
	newEffect.UI.Enabled = true

	UiAnimationService.PlayAnimation(newEffect.UI.Frame, 0.05, false, true)
end

local function dropAmmo(position)
	if
		not module.currentWeapon
		or not GiftsService.CheckGift("Scavenger")
		or not ChanceService.checkChance(10, true)
	then
		return
	end

	local ammoDrop = dropService.CreateDrop(position, "Ammo")
	UiAnimationService.PlayAnimation(ammoDrop.UI.Frame, 0.045, true)
end

local function addToCombo(amount)
	ComboService.AddToCombo(amount)
end

local function findHumanoid(subject)
	local model = subject

	if not subject:IsA("Model") then
		model = subject:FindFirstAncestorOfClass("Model")
	end

	if not model then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	return humanoid, model
end

local function activateOvercharge()
	Overcharge = 0
	acts:createAct("Overcharged")

	local overchargeEffect: ColorCorrectionEffect = Lighting.Overcharge

	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quart)
	local ti_0 = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

	overchargeEffect.Brightness = 0
	overchargeEffect.Contrast = 0
	overchargeEffect.Saturation = 0
	overchargeEffect.TintColor = Color3.new(1, 1, 1)

	util.tween(
		overchargeEffect,
		ti,
		{ Brightness = 0.8, Contrast = 2, Saturation = -1, TintColor = Color3.fromRGB(255, 185, 85) }
	)
	signals.DoUiAction:Fire("HUD", "EmptyOvercharge", true, 3)
	task.delay(3, function()
		acts:removeAct("Overcharged")

		util.tween(
			overchargeEffect,
			ti_0,
			{ Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }
		)
	end)
end

local overchargeDebounce = false

local function addToConsecutive(hit)
	if not hit or not GiftsService.CheckGift("Boring_Bullets") then
		consecutiveHits = 0
	else
		consecutiveHits += 1
	end

	if not overchargeDebounce and hit and GiftsService.CheckGift("Overcharge") and not acts:checkAct("Overcharged") then
		-- make pistol exlusive

		if not module.currentWeapon or weaponData.Type == "Pistol" then
			if Overcharge < 20 then
				Overcharge += 1
				overchargeDebounce = true

				signals.DoUiAction:Fire("HUD", "UpdateOvercharge", true, Overcharge / 20)

				task.delay(0.01, function()
					overchargeDebounce = false
				end)
			end
		else
			if Overcharge >= 20 then
				activateOvercharge()
			end
		end
	end

	signals.DoUiAction:Fire("HUD", "UpdateGiftProgress", true, "Overcharge", Overcharge / 20)
	signals.DoUiAction:Fire("HUD", "UpdateGiftProgress", true, "Boring_Bullets", consecutiveHits / 10)
end

local function createFakeWeakpoint(subject, part, position)
	for _, partInSubject in ipairs(subject:GetChildren()) do
		if partInSubject.Name ~= "Weakspot" then
			continue
		end

		if partInSubject:HasTag("OpenWound") then
			return
		end
	end

	signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Open_Wounds")
	local newWeakpoint = assets.Models.Weakspot:Clone()

	newWeakpoint.Parent = subject
	newWeakpoint.Position = position
	newWeakpoint.CFrame = CFrame.lookAt(newWeakpoint.Position, player.Character:GetPivot().Position)
	newWeakpoint.CFrame *= CFrame.new(0, 0, -0.5)

	newWeakpoint:AddTag("OpenWound")

	local newWeld = Instance.new("WeldConstraint")
	newWeld.Parent = newWeakpoint
	newWeld.Part0 = part
	newWeld.Part1 = newWeakpoint
end

local function awardKill(model, position)
	addToCombo(1)
	dropAmmo(position)
	signals.AddEntry:Fire(model.Name)

	if
		GiftsService.CheckGift("Aggressive_Forgery")
		and ComboService.CurrentCombo >= 5
		and ChanceService.checkChance(10, true)
	then
		dropService.CreateDrop(position, "Armor")
	end
end

function module.dealDamage(cframe, subject, damage, source, element)
	if not subject or Players:GetPlayerFromCharacter(subject) then
		return
	end

	local humanoid, model = findHumanoid(subject)

	if not humanoid then
		return
	end

	local isVendingMachine = string.match(model.Name, "Vending Machine")
	if isVendingMachine and source ~= "ThrownWeapon" then
		return
	end

	local siuDamage = 0
	if source ~= lastDamageSource and GiftsService.CheckGift("Switch_It_Up") then
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Switch_It_Up")
		siuDamage = 1
	end

	local critMult = 1

	if module.currentWeapon and source == module.currentWeapon.Name then
		if ChanceService.checkChance(module.critChances[weaponData.Type], true) then
			critMult = 2

			util.PlaySound(assets.Sounds.Crit, script, 0.05)
		end
	elseif source == "Default" then
		if ChanceService.checkChance(module.critChances.Pistol, true) then
			critMult = 2

			util.PlaySound(assets.Sounds.Crit, script, 0.05)
		end
	end

	local soulElementDamage = model:GetAttribute("Soul") and 1 or 0
	local weakspotDamage = WeakspotService.doWeakspotHit(subject)
	local deadshotDamage = checkDeadshot()
	local boringDamage = consecutiveHits >= 5 and 1 or 0
	local subjectPosition = subject:GetPivot().Position

	if GiftsService.CheckGift("Open_Wounds") then
		ChanceService.doWithChance(10, true, createFakeWeakpoint, model, subject, cframe.Position)
	end

	local totalDamage = damage + deadshotDamage + weakspotDamage + boringDamage + siuDamage + soulElementDamage

	lastDamageSource = source

	totalDamage *= critMult

	if isVendingMachine then
		totalDamage = 1
	end

	task.spawn(function()
		if not humanoid:HasTag("Souless") then
			BloodEffects.createSplatter(cframe)
			BloodEffects.bloodSploof(cframe, cframe.Position)
		end

		if deadshotDamage > 0 then
			showDeadshot(subjectPosition)
		end

		if humanoid.Health > 0 then
			signals.DoUiAction:Fire("HUD", "ShowHit", true, critMult > 1)
		end

		if element and not ChanceService.checkChance(60, true) then
			element = nil
		else
			codexService.AddEntry("Elements")
		end

		local sourceIsWeapon = module.currentWeapon and source == module.currentWeapon.Name
			or source == "Default"
			or source == "Ricoshot"

		if GiftsService.CheckGift("Burn_Hell") and ChanceService.checkChance(50, true) then
			if not sourceIsWeapon and source ~= "ThrownWeapon" then
				net:RemoteEvent("Damage"):FireServer(model, 1, "Fire")
			end
		end

		local serverHumanoid, preHealth, postHealth = net:RemoteFunction("Damage")
			:InvokeServer(model, totalDamage, element)

		if not serverHumanoid then
			return
		end

		if preHealth > 0 and postHealth <= 0 then -- kill awarded
			awardKill(model, subjectPosition)
		end
	end)

	if GiftsService.CheckGift("Gambler's_Fallacy") then
		ChanceService.repetitionLuck = math.clamp(ChanceService.repetitionLuck + 1, 0, 20)
		signals.DoUiAction:Fire(
			"HUD",
			"UpdateGiftProgress",
			true,
			"Gambler's_Fallacy",
			ChanceService.repetitionLuck / 20
		)
	end

	if soulsService.Souls <= 0 and GiftsService.CheckGift("Life_Steal") and ChanceService.checkChance(5, true) then
		net:RemoteEvent("Damage"):FireServer(player.Character, -1)
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Life_Steal")
	end

	return humanoid, subject, totalDamage
end

local function HitPart(rayResult)
	if not rayResult then
		return
	end

	local newHitEffect = util.callFromCache(assets.Effects.BulletHole)
	util.addToCache(newHitEffect, 3)

	newHitEffect.Hole.Transparency = 0
	newHitEffect.Parent = workspace
	newHitEffect.CFrame = CFrame.new(rayResult.Position, rayResult.Position + rayResult.Normal)
	newHitEffect.CFrame *= CFrame.Angles(math.rad(-90), 0, 0)

	for _, p in ipairs(newHitEffect:GetChildren()) do
		if not p:IsA("ParticleEmitter") then
			continue
		end
		p:Emit(8)
	end

	task.delay(1.5, function()
		for i = 0, 1, 0.1 do
			task.wait(0.1)
			newHitEffect.Hole.Transparency = i
		end
	end)

	return newHitEffect
end

local function placeHitEffect(position)
	local newEffect = assets.Effects.HitEffect:Clone()
	newEffect.Parent = workspace.Ignore
	newEffect.Position = position

	for _, v in ipairs(newEffect:GetChildren()) do
		v:Emit(8)
	end

	Debris:AddItem(newEffect, 0.5) -- Change
end

local function checkForGibs()
	for humanoid, data in pairs(hitHumanoids) do
		if weaponData and weaponData.AntiGib then
			break
		end

		if humanoid:HasTag("Souless") then
			continue
		end

		if humanoid.MaxHealth - data.Damage > -3 then
			continue
		end

		BloodEffects.gibEnemy(data.Model)
		playVoiceLine()
	end
end

local function addToGib(humanoid, subject, damage)
	if not humanoid then
		return
	end

	if not hitHumanoids[humanoid] then
		hitHumanoids[humanoid] = { Model = subject, Damage = 0 }
	end

	hitHumanoids[humanoid].Damage += damage
end

function module.FireRaycast(spread, distance)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { camera, player.Character }
	raycastParams.CollisionGroup = "Bullet"

	local offset = CFrame.Angles(util.randomAngle(spread), util.randomAngle(spread), util.randomAngle(spread))
	local cf = camera.CFrame * offset

	local origin = camera.CFrame.Position
	local direction = cf.LookVector * distance

	local raycast = workspace:Raycast(origin, direction, raycastParams)

	if not raycast or not util.checkForHumanoid(raycast.Instance) then
		raycast = workspace:Spherecast(origin, 1.5, direction, raycastParams)
	end

	return raycast, offset
end

function module.FireHitbox(size, cframe)
	local character = player.Character

	local hitboxResult = workspace:GetPartBoundsInBox(cframe, size)

	local targetsHit = {}
	for _, part in ipairs(hitboxResult) do
		local target = util.checkForHumanoid(part)
		if
			not target
			or target == character
			or target:FindFirstAncestor(character.Name)
			or table.find(targetsHit, target)
			or part:FindFirstAncestor("Camera")
		then
			continue
		end

		return { Instance = part, Position = part.Position }
	end
end

function module.FireProjectile(projectileType, spread, damage, bulletIndex, element)
	local subjectCFrame = camera.CFrame
	local offset = Vector3.zero

	if module.currentWeapon:FindFirstChild("FirePart") then
		offset = subjectCFrame:VectorToObjectSpace(module.currentWeapon.FirePart.Position - subjectCFrame.Position)
	end
	local origin = (subjectCFrame * CFrame.new(offset))

	local locked = nil
	if weaponData.LockedOn then
		locked = weaponData.LockedOn[bulletIndex]
	end

	local info = { Locked = locked, Element = element }

	if weaponData["SplashDamage"] then
		info.SplashDamage = weaponData.SplashDamage
	end

	projectileService.createFromPreset(
		origin,
		spread,
		projectileType,
		damage,
		info,
		player,
		module.currentWeapon and module.currentWeapon.Name or "Default"
	)
end

projectileService.projectileHit:Connect(function(result, projectile)
	local hitHumanoid, subject, damageResult =
		module.FireBullet(projectile.Damage, 0, nil, result, projectile.Source, projectile.Info["Element"])

	if not hitHumanoid then
		return
	end

	addToGib(hitHumanoid, subject, damageResult)
	addToConsecutive(hitHumanoid)
	checkForGibs()
end)

function module.FireBullet(damage, spread, distance, result, source, element)
	spread *= 1.2
	local spreadResult

	if not result then
		if typeof(distance) == "Vector3" then
			result = module.FireHitbox(distance, camera.CFrame * CFrame.new(0, 0, -distance.Z / 1.25))
		else
			result, spreadResult = module.FireRaycast(spread, distance)
		end
	end

	if not result then
		return nil, nil, nil, spreadResult
	end

	placeHitEffect(result.Position)

	local hitWeapon = RicoshotService.checkRicoshot(result)
	local hitCframe = CFrame.new(result.Position) * camera.CFrame.Rotation

	if hitWeapon then
		hitWeapon:SetAttribute("Health", hitWeapon:GetAttribute("Health") - 1)

		if hitWeapon:GetAttribute("Health") <= 0 then
			task.delay(0.05, function()
				hitWeapon:Destroy()
			end)
		end

		if GiftsService.CheckGift("Ricoshot") then
			local hit = RicoshotService.doRicoshot(hitWeapon, player.Character)

			return module.FireBullet(damage + 4, 0, 0, hit, "Ricoshot", element)

			--return dealDamage(hitCframe, hit, damage + 3, "Ricoshot")
		end
	end

	local hitHumanoid, subject, damageResult = module.dealDamage(hitCframe, result.Instance, damage, source, element)

	if not hitHumanoid then
		HitPart(result)
	end

	return hitHumanoid, subject, damageResult, spreadResult
end

local function FireDefault(extraBullet)
	local default = viewmodel.Model.Default
	local bulletCount = 1 + extraBullet

	if currentAmmo <= 0 then
		task.wait()
		return
	end

	for _ = 1, bulletCount do
		local hitHumanoid, subject, damage, spreadResult = module.FireBullet(1, bulletCount - 1, 500, nil, "Default")

		addToGib(hitHumanoid, subject, damage)
		addToConsecutive(hitHumanoid)

		if defaultIndex == 0 then
			showMuzzleFlash(default.Right.FirePart, spreadResult)
		else
			showMuzzleFlash(default.Left.FirePart, spreadResult)
		end
	end
	checkForGibs()

	module.UpdateAmmo(currentAmmo - 1)

	util.PlaySound(assets.Sounds.Fire, script, 0.15)

	local recoilVector = Vector3.new(0, 0.3, 0)

	if defaultIndex == 0 then
		signals.DoUiAction:Fire("HUD", "PumpCrosshair", true)
		task.wait(0.03)
		animationService:playAnimation(
			viewmodel.Model,
			"FireRight",
			Enum.AnimationPriority.Action2.Value,
			false,
			0,
			2,
			1
		)

		Recoil(recoilVector + Vector3.new(-1.75), Vector3.new(0.2, 0.1, 4), 1, 0.75)

		defaultIndex = 1
	else
		signals.DoUiAction:Fire("HUD", "PumpCrosshair", true, true)
		task.wait(0.03)
		animationService:playAnimation(
			viewmodel.Model,
			"FireLeft",
			Enum.AnimationPriority.Action2.Value,
			false,
			0,
			2,
			1
		)

		Recoil(recoilVector + Vector3.new(1.75), Vector3.new(0.2, 0.1, 4), 1, 0.75)

		defaultIndex = 0
	end

	fireTimer.WaitTime = acts:checkAct("Overcharged") and defaultFireRate / 1.5 or defaultFireRate
	fireTimer:Run()

	fireTimer.OnEnded:Wait()

	if currentAmmo <= 0 then
		ReloadDefault()
	end
end

local function LockOn()
	local lockAmnt = weaponData.LockAmount
	local lockTime = weaponData.LockIncrement

	if not weaponData["LockedOn"] then
		weaponData.LockedOn = {}
	end

	if not lockTimer or lockTimer.Connection or #weaponData.LockedOn >= lockAmnt then
		return
	end

	lockTimer.WaitTime = lockTime
	lockTimer.Function = function()
		local target = getObjectInCenter(player, weaponData.LockedOn)
		if not target then
			return
		end

		local newGui = assets.Gui.LockGui:Clone()
		newGui.Parent = target
		newGui.Enabled = true

		UiAnimationService.PlayAnimation(newGui.Frame, 0.045, false, true)

		table.insert(lockGuis, newGui)
		table.insert(weaponData.LockedOn, target)

		assets.Sounds.Lock.PlaybackSpeed = (#weaponData.LockedOn + 1) / 2
		assets.Sounds.Lock:Play()
	end

	lockTimer:Run()
end

function module.Fire()
	if acts:checkAct("IsBlocking", "Reloading") then
		return
	end

	hitHumanoids = {}

	for _, v in ipairs(lockGuis) do
		v:Destroy()
	end

	lockTimer:Cancel()

	local extraBullet = 0

	if GiftsService.CheckGift("Double_Shot") and ChanceService.checkChance(5, true) then
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Double_Shot")
		extraBullet = 1
	end

	if not module.currentWeapon then
		FireDefault(extraBullet)
		return
	end

	signals.DoUiAction:Fire("HUD", "PumpCrosshair", true)

	local bulletDamage = weaponData.Damage
	local bulletCount = weaponData.BulletCount

	bulletCount += extraBullet

	if weaponData.LockedOn then
		bulletCount = math.clamp(#weaponData.LockedOn, 1, 100)
		bulletDamage -= math.ceil(bulletCount / 2) - 1
	end

	local equipAnimation = animationService:getAnimation(viewmodel.Model, "Equip")
	if equipAnimation and equipAnimation.IsPlaying then
		animationService:stopAnimation(viewmodel.Model, "Equip", 0)
	end

	if string.match(module.currentWeapon.Name, " Shot") and GiftsService.CheckGift("1994") then
		signals.DoUiAction:Fire("HUD", "ActivateGift", true, "1994")
		bulletCount += 2
	end

	local maxDistance = weaponData.MaxDistance or 500

	for index = 1, bulletCount do
		local spread = index == 1 and 0 or index

		if weaponData.Projectile then
			module.FireProjectile(weaponData.Projectile, spread, bulletDamage, index, weaponData["Element"])
			continue
		end

		local hitHumanoid, subject, damage =
			module.FireBullet(bulletDamage, spread, maxDistance, nil, module.currentWeapon.Name, weaponData["Element"])

		addToGib(hitHumanoid, subject, damage)
		addToConsecutive(hitHumanoid)
	end

	if weaponData.LockedOn then
		weaponData.LockedOn = {}
	end

	checkForGibs()

	module.UpdateAmmo(currentAmmo - 1)

	util.PlaySound(module.currentWeapon.FirePart.Fire, script, 0.15)

	showMuzzleFlash(module.currentWeapon.FirePart)

	local playingAnimation
	if currentAmmo == 0 then
		playingAnimation = animationService:playAnimation(
			viewmodel.Model,
			"FireOut",
			Enum.AnimationPriority.Action3.Value,
			false,
			0,
			5,
			1
		)
	else
		playingAnimation = animationService:playAnimation(
			viewmodel.Model,
			"Fire",
			Enum.AnimationPriority.Action2.Value,
			false,
			0,
			5,
			1
		)
	end

	local enabled = playingAnimation:GetMarkerReachedSignal("EnableEffect"):Connect(function(effectName)
		local effect = module.currentWeapon:FindFirstChild(effectName, true)
		if not effect then
			return
		end
		effect.Enabled = true
	end)

	local disabled = playingAnimation:GetMarkerReachedSignal("DisableEffect"):Connect(function(effectName)
		local effect = module.currentWeapon:FindFirstChild(effectName, true)
		if not effect then
			return
		end

		effect.Enabled = false
	end)

	local onStopped
	onStopped = playingAnimation.Stopped:Connect(function()
		enabled:Disconnect()
		disabled:Disconnect()
		onStopped:Disconnect()
	end)

	Recoil(
		weaponData.Recoil.RecoilVector,
		weaponData.Recoil.RandomVector,
		weaponData.Recoil.Magnitude,
		weaponData.Recoil.Speed
	)

	if currentAmmo <= 0 then
		if acts:checkAct("Throwing") then
			return
		end

		if GiftsService.CheckGift("TactiAwesome") then
			playingAnimation.Stopped:Wait()
			reload(true)
			return
		end

		acts:createAct("Throwing")

		playingAnimation.Stopped:Wait()
		module.Throw(true)
		return
	end

	fireTimer.WaitTime = acts:checkAct("Overcharged") and weaponData.FireDelay / 1.5 or weaponData.FireDelay
	fireTimer:Run()

	fireTimer.OnEnded:Wait()
end

local function ThrowWeapon()
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local weaponClone = module.currentWeapon:Clone()
	local grip = weaponClone.Grip
	local hasHitTarget = false

	local overlapParams = OverlapParams.new()

	local canHit = {}

	for _, v in ipairs(CollectionService:GetTagged("Enemy")) do
		table.insert(canHit, v)
	end

	for _, v in ipairs(CollectionService:GetTagged("Hazard")) do
		table.insert(canHit, v)
	end

	overlapParams.FilterDescendantsInstances = canHit
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	local weaponJanitor = Janitor:new()
	weaponJanitor:LinkToInstance(weaponClone)

	module.currentWeapon:Destroy()
	module.currentWeapon = nil
	slots[currentSlot].CurrentWeapon = nil

	weaponClone:AddTag("ThrownWeapon")

	for _, part in ipairs(weaponClone:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end
		part.CollisionGroup = "Weapons"
	end

	local newAttachment = Instance.new("Attachment")
	newAttachment.Parent = weaponClone.Grip

	local newForce = Instance.new("VectorForce")
	newForce.Parent = weaponClone.Grip
	newForce.Attachment0 = newAttachment
	newForce.RelativeTo = Enum.ActuatorRelativeTo.World
	newForce.Force = Vector3.new(0, 150, 0)

	weaponClone:SetAttribute("Health", 5)
	weaponClone.Motor6D:Destroy()

	if weaponClone:FindFirstChild("LM6D") then
		weaponClone.LM6D:Destroy()
	end

	weaponClone.Parent = workspace

	local ricoHitbox = assets.Effects.RicoHitbox:Clone()
	ricoHitbox.Parent = weaponClone

	local weld = Instance.new("Weld")
	weld.Parent = ricoHitbox
	weld.Part0 = weaponClone.HitBox
	weld.Part1 = ricoHitbox

	weaponClone.PrimaryPart = weaponClone.HitBox

	weaponClone.HitBox.CanCollide = true

	grip.CFrame = viewmodel.Model.RightGrip.CFrame

	grip.AssemblyLinearVelocity = (camera.CFrame.LookVector * 80) + Vector3.new(0, 10, 0)
	grip.RotVelocity = Vector3.new(math.random(-20, 20), math.random(10, 20), math.random(-20, 20)) * 0.8

	if GiftsService.CheckGift("Ricoshot") then
		ricoHitbox.Ui.Enabled = true
	end

	task.spawn(function()
		repeat
			RunService.Heartbeat:Wait()

			if not weaponClone.Parent then
				continue
			end

			local hits =
				workspace:GetPartBoundsInBox(weaponClone.HitBox.CFrame, weaponClone.HitBox.Size * 2, overlapParams)

			for _, hit in ipairs(hits) do
				local hitCframe = CFrame.new(hit.Position) * camera.CFrame.Rotation

				local humanoid = module.dealDamage(hitCframe, hit, 2, "ThrownWeapon")

				if not humanoid or humanoid.Health <= 0 then
					continue
				end

				grip.AssemblyLinearVelocity = (hit.CFrame.LookVector * 10) + Vector3.new(0, 65, 0)

				hasHitTarget = true
				return
			end
		until grip.AssemblyLinearVelocity.Magnitude < 30 or hasHitTarget
	end)

	--weaponJanitor:Add(onHit, "Disconnect")

	repeat
		task.wait()

		if not weaponClone.Parent then
			return
		end
	until grip.Velocity.Magnitude <= 5

	for _, part in ipairs(weaponClone:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		util.tween(part, ti, { Transparency = 1 })
	end

	Debris:AddItem(weaponClone, 3)
end

function module.Unequip()
	animationService:stopAnimation(viewmodel.Model, "Idle", 0)
	animationService:stopAnimation(viewmodel.Model, "Fire", 0)
	animationService:stopAnimation(viewmodel.Model, "FireOut", 0)

	module.currentWeapon:Destroy()
	module.currentWeapon = nil
end

function module.SwitchToSlot(slotNumber)
	acts:waitForAct("Throwing")

	if currentSlot == slotNumber then
		return
	end

	currentSlot = slotNumber

	local slot = slots[slotNumber]

	if module.currentWeapon then
		module.Unequip()
	end

	if slot.CurrentWeapon then
		module.EquipWeapon(slot.CurrentWeapon.Name, "SlotSwitch", slot.Element)
	else
		EquipDefault(true)
	end

	module.UpdateAmmo(slot.Ammo)
end

function module.Throw(outOfAmmo)
	if not outOfAmmo and acts:checkAct("Throwing") then
		return
	end

	weaponReloadTimer:Cancel()
	completeReload(0)

	acts:createAct("Throwing")

	animationService:stopAnimation(viewmodel.Model, "Idle", 0)
	animationService:stopAnimation(viewmodel.Model, "Fire", 0)
	animationService:stopAnimation(viewmodel.Model, "FireOut", 0)

	local animation = animationService:playAnimation(viewmodel.Model, "Throw", Enum.AnimationPriority.Action4.Value)

	animation.Ended:Wait()
	EquipDefault()

	acts:removeAct("Throwing")
end

function module.Block()
	local punch = GiftsService.CheckGift("Ultra_Slayer")
	if not canBlock or not punch and (not module.currentWeapon or not weaponData.BlockTime) then
		return
	end

	local blockTime = punch and 0.5 or weaponData.BlockTime

	acts:createAct("IsBlocking")
	canBlock = false

	local playingAnimation

	if punch then
		playingAnimation = animationService:playAnimation(
			viewmodel.Model,
			"Punch",
			Enum.AnimationPriority.Action4.Value,
			false,
			0,
			2,
			1
		)
	else
		playingAnimation = animationService:playAnimation(
			viewmodel.Model,
			"Block",
			Enum.AnimationPriority.Action4.Value,
			false,
			0,
			2,
			1
		)
	end

	if punch then
		module.FireBullet(2, 0, Vector3.new(5, 5, 10), nil, "Punch")

		Recoil(Vector3.new(0, 0, 0), Vector3.new(0.5, 0.5, 3), 1, 0.5)
	end

	net:RemoteEvent("SetBlocking"):FireServer(true)
	task.wait(blockTime)

	playingAnimation.Priority = Enum.AnimationPriority.Action.Value

	net:RemoteEvent("SetBlocking"):FireServer(false)

	acts:removeAct("IsBlocking")

	task.wait(0.25)

	canBlock = true
end

function module.OnBlock()
	-- if module.currentWeapon and weaponData.BlockTime then
	-- 	module.UpdateAmmo(currentAmmo + 1)
	-- end

	module.FireBullet(1, 0, 300, nil, "Parry")

	util.PlaySound(assets.Sounds.BlockedMetal, script, 0.1)
	util.PlaySound(assets.Sounds.Blocked, script, 0.05)
	util.PlaySound(util.getRandomChild(assets.Sounds.Ricochets), script, 0.1)

	if GiftsService.CheckGift("Martial_Grace") then
		ChanceService.doWithChance(30, true, function()
			assets.Sounds.MartialHeal:Play()

			signals.DoUiAction:Fire("HUD", "ActivateGift", true, "Martial_Grace")
			net:RemoteEvent("Damage"):FireServer(player.Character, -1)
		end)
	end

	if GiftsService.CheckGift("Ultra_Slayer") then
		viewmodel.Model.BlockPart.Blocked:Emit(20)

		return
	end

	if not module.currentWeapon or not module.currentWeapon:FindFirstChild("BlockPart") then
		return
	end

	module.currentWeapon.BlockPart.Blocked:Emit(20)
end

local function actOnAnimation(parameter)
	if parameter == "MagOut" then
		util.PlaySound(reloadSounds.MagOut, script, 0.1, 1)
	end
	if parameter == "MagIn" then
		util.PlaySound(reloadSounds.MagIn, script, 0.1, 0.9)
	end
	if parameter == "BoltForward" then
		util.PlaySound(reloadSounds.BoltForward, script, 0.1)
	end
	if parameter == "Throw" then
		ThrowWeapon()
	end
end

function module:GameInit()
	viewmodel = viewmodelService.new()
	viewmodel:SetOffset("BaseOffset", "FromCamera", CFrame.new(0, -1.25, 0))
	viewmodel:SetOffset("ReloadOffset", "FromCamera", CFrame.new(0, 0, 0))
	viewmodel:Run()

	defaultWeapon = viewmodel.Model.Default

	animationService:loadAnimations(viewmodel.Model, viewmodel.Model.Animations)

	for _, animation in pairs(animationService.animations[viewmodel.Model]) do
		animation:GetMarkerReachedSignal("Event"):Connect(actOnAnimation)
	end
end

function module:OnSpawn()
	consecutiveHits = 0

	if module.currentWeapon then
		module.Unequip()
	end

	slots = {
		{
			Ammo = 0,
			CurrentWeapon = nil,
			WeaponData = nil,
		},

		{
			Ammo = 0,
			CurrentWeapon = nil,
			WeaponData = nil,
		},
	}

	module.critChances = {
		AR = 0,
		Pistol = 0,
		Shotgun = 0,
		Melee = 0,
	}

	EquipDefault()

	animationService:playAnimation(viewmodel.Model, "DefaultIdle", Enum.AnimationPriority.Core.Value)
end

function module.OnDied()
	mouseButton1Down = false
	Overcharge = 0
	UIService.doUiAction("HUD", "HideOvercharge")
end

--//Main//--

local function switchWeapon()
	if not GiftsService.CheckGift("Mule_Bags") then
		return
	end

	if currentSlot == 1 then
		module.SwitchToSlot(2)
	else
		module.SwitchToSlot(1)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		mouseButton1Down = true
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
		module.Block()
	end

	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
		local conditions = acts.Condition.blacklist("Firing", "Throwing")

		if module.currentWeapon then
			if GiftsService.CheckGift("TactiAwesome") then
				reload(true)
			elseif GiftsService.CheckGift("Tacticool") then
				reload()
			end
		else
			acts:createTempAct("Reloading", ReloadDefault, conditions)
		end
	end

	if (input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.ButtonB) and module.currentWeapon then
		module.Throw()
	end

	if
		input.KeyCode == Enum.KeyCode.Q
		or input.KeyCode == Enum.KeyCode.One
		or input.KeyCode == Enum.KeyCode.Two
		or input.KeyCode == Enum.KeyCode.ButtonY
	then
		switchWeapon()
	end
end)

local function releaseTrigger(gpe)
	if module.currentWeapon and weaponData["LockAmount"] and not gpe and mouseButton1Down then
		local conditions = acts.Condition.blacklist("Reloading", "Throwing")
		task.spawn(acts.createTempAct, acts, "Firing", module.Fire, conditions)
	end

	mouseButton1Down = false
end

UserInputService.InputEnded:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		releaseTrigger(gpe)
	end
end)

UserInputService.TouchEnded:Connect(function(touch, gpe)
	releaseTrigger(gpe)
end)

task.spawn(function()
	repeat
		task.wait()
	until UIService.isLoaded
end)

local logRecoil = CFrame.new()

RunService.RenderStepped:Connect(function()
	local recoilCFrame = CFrame.Angles(
		math.rad(recoilSpring.Position.Y),
		math.rad(recoilSpring.Position.X),
		math.rad(recoilSpring.Position.Z)
	)

	camera.CFrame *= logRecoil:Inverse()

	camera.CFrame *= recoilCFrame

	logRecoil = recoilCFrame

	if not mouseButton1Down then
		return
	end

	if module.currentWeapon and weaponData["LockAmount"] then
		LockOn()
		return
	end

	local conditions = acts.Condition.blacklist("Reloading", "Throwing")
	acts:createTempAct("Firing", module.Fire, conditions)
end)

net:Connect("EquipWeapon", module.EquipWeapon)
net:Connect("GetBlockedNerd", module.OnBlock)

signals.Shoot:Connect(function(value)
	if not value then
		return
	end
	mouseButton1Down = true
end)

signals.Parry:Connect(module.Block)
signals.SwitchWeapon:Connect(switchWeapon)
signals.ThrowWeapon:Connect(function()
	if module.currentWeapon then
		module.Throw()
	else
		local conditions = acts.Condition.blacklist("Firing", "Throwing")

		acts:createTempAct("Reloading", ReloadDefault, conditions)
	end
end)

signals.DoWeaponAction:Connect(function(actionName, ...)
	return module[actionName](...)
end)

signals.AddAmmo:Connect(function(bigMag)
	local amount
	local baseAmmo

	if weaponData then
		baseAmmo = weaponData.Ammo
	else
		baseAmmo = 16
	end

	if bigMag then
		amount = baseAmmo * 0.5
	else
		amount = baseAmmo * 0.25
	end

	module.UpdateAmmo(currentAmmo + amount)
end)

net:Connect("StartExitSequence", function()
	mouseButton1Down = false
end)

signals.PauseGame:Connect(function()
	mouseButton1Down = false

	for _, anim in pairs(animationService:getLoadedAnimations(viewmodel.Model)) do
		anim:AdjustSpeed(0)
	end
end)

signals.ResumeGame:Connect(function()
	for _, anim in pairs(animationService:getLoadedAnimations(viewmodel.Model)) do
		anim:AdjustSpeed(1)
	end
end)

explosionService.explosiveHit:Connect(function(subject, preHealth, postHealth, damageDelt, source)
	local sourceIsWeapon = module.currentWeapon and source == module.currentWeapon.Name or source == "Default"

	if preHealth > 0 then
		signals.DoUiAction:Fire("HUD", "ShowHit", true)

		if GiftsService.CheckGift("Burn_Hell") and ChanceService.checkChance(50, true) then
			if not sourceIsWeapon and source ~= "ThrownWeapon" then
				net:RemoteEvent("Damage"):FireServer(subject, 1, "Fire")
			end
		end
	end

	if preHealth > 0 and postHealth <= 0 then -- kill awarded
		awardKill(subject.Name, subject:GetPivot().Position)
	end

	addToGib(subject:FindFirstChild("Humanoid"), subject, damageDelt)
	checkForGibs()
end)

GiftsService.OnGiftAdded:Connect(function(gift)
	if gift ~= "Overcharge" then
		return
	end

	UIService.doUiAction("HUD", "ShowOvercharge")
end)

return module
