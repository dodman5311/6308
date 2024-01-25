local module = {
	defaultMagSize = 16,
}

--// Services
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local assets = Globals.Assets
local reloadSounds = assets.Sounds.Reloading
local camera = workspace.CurrentCamera

local player = Players.LocalPlayer

--// Modules
local signals = require(Globals.Signals)
local viewmodelService = require(Globals.Vendor.ViewmodelService)
local animationService = require(Globals.Vendor.AnimationService)
local UiAnimationService = require(Globals.Vendor.UIAnimationService)
local acts = require(Globals.Vendor.Acts)
local util = require(Globals.Vendor.Util)
local spring = require(Globals.Vendor.Spring)
local souls = require(Globals.Client.Services.SoulsService)
local GiftsService = require(Globals.Client.Services.GiftsService)
local dropService = require(Globals.Shared.DropService)
local Janitor = require(Globals.Packages.Janitor)
local RicoshotService = require(Globals.Client.Services.RicoshotService)

local net = require(Globals.Packages.Net)

--// Values

local defaultIndex = 0
local viewmodel
local defaultWeapon

local currentAmmo = module.defaultMagSize
local currentWeapon
local weaponData

local mouseButton1Down = false

local rng = Random.new()

local slots = {
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

local currentSlot = 1

--// Function

local recoilSpring = spring.new(Vector3.zero)
recoilSpring.Speed = 30
recoilSpring.Damper = 0.45

function module.UpdateSlot()
	local slot = slots[currentSlot]

	slot.CurrentWeapon = currentWeapon
	slot.WeaponData = weaponData

	slot.Ammo = currentAmmo -- currentWeapon and currentAmmo or 0

	if slot.CurrentWeapon then
		return
	end

	for index, slot in ipairs(slots) do
		if index == currentSlot or slot.CurrentWeapon then
			continue
		end

		slot.Ammo = currentAmmo
	end
end

function module.UpdateAmmo(amount)
	amount = math.round(amount)
	currentAmmo = amount
	signals.DoUiAction:Fire("HUD", "UpdateAmmo", true, currentAmmo)

	module.UpdateSlot()
end

function module.EquipWeapon(weaponName, slotSwitch)
	if acts:checkAct("Throwing") then
		return
	end

	if not slotSwitch and currentWeapon then
		module.Throw()
	end

	local weapon = assets.Models.Weapons:FindFirstChild(weaponName)
	if not weapon then
		return
	end

	defaultWeapon.Parent = game

	local newWeapon = weapon:Clone()
	newWeapon.Parent = viewmodel.Model
	weaponData = require(newWeapon.Data)

	local newM6d = Instance.new("Motor6D")
	newM6d.Parent = newWeapon
	newM6d.Part0 = viewmodel.Model.RightGrip
	newM6d.Part1 = newWeapon.Grip

	animationService:stopAnimation(viewmodel.Model, "Reload", 0)
	animationService:stopAnimation(viewmodel.Model, "ReloadOut", 0)

	animationService:loadAnimations(viewmodel.Model, newWeapon.Animations)
	animationService:playAnimation(viewmodel.Model, "Idle", Enum.AnimationPriority.Idle.Value, false, 0)

	local ammoToAdd = weaponData.Ammo
	if GiftsService.CheckGift("Hoarder") then
		ammoToAdd *= 1.5
	end

	currentWeapon = newWeapon

	if not slotSwitch then
		module.UpdateAmmo(ammoToAdd)
		module.UpdateSlot()
	end
end

local function EquipDefault()
	defaultWeapon.Parent = viewmodel.Model

	module.UpdateAmmo(module.defaultMagSize)
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

local function showMuzzleFlash(flashPart)
	for _, v in ipairs(flashPart:GetChildren()) do
		if not string.match(v.Name, "FlashFX") then
			continue
		end
		v.Enabled = true
		task.spawn(function()
			task.wait(0.03)
			v.Enabled = false
		end)
	end

	if currentWeapon ~= nil then
		return
	end

	local partClone = assets.Effects.smokePart:Clone()
	partClone.Parent = workspace.Ignore
	partClone.CFrame = flashPart.CFrame
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
	if currentAmmo <= 0 then
		animationService:playAnimation(viewmodel.Model, "ReloadOut", Enum.AnimationPriority.Action3.Value)
		animationService:getAnimation(viewmodel.Model, "ReloadOut").Stopped:wait()
	else
		animationService:playAnimation(viewmodel.Model, "Reload", Enum.AnimationPriority.Action3.Value)
		animationService:getAnimation(viewmodel.Model, "Reload").Stopped:wait()
	end

	if currentWeapon then
		return
	end

	module.UpdateAmmo(module.defaultMagSize)

	module.UpdateSlot()
end

local function checkDeadshot()
	if not GiftsService.CheckGift("Deadshot") or rng:NextNumber(0, 100) > 10 then
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
	if not currentWeapon or not GiftsService.CheckGift("Scavenger") or rng:NextNumber(0, 100) > 15 then
		return
	end

	local ammoDrop = dropService.CreateDrop(position, "Ammo")
	UiAnimationService.PlayAnimation(ammoDrop.UI.Frame, 0.045, true)
end

local function dealDamage(subject, damage)
	if not subject then
		return
	end

	local deadshotDamage = checkDeadshot()
	local subjectPosition = subject:GetPivot().Position
	local humanoid, preHealth, postHealth = net:RemoteFunction("Damage"):InvokeServer(subject, damage + deadshotDamage)

	if not humanoid then
		return
	end

	if deadshotDamage > 0 then
		showDeadshot(subjectPosition)
	end

	if preHealth > 0 and postHealth <= 0 then -- kill awarded
		dropAmmo(subjectPosition)
	end

	signals.DoUiAction:Fire("HUD", "ShowHit", true)
	return humanoid
end

local function placeHitEffect(position)
	local newEffect = assets.Effects.HitEffect:Clone()
	newEffect.Parent = workspace.Ignore
	newEffect.Position = position

	for _, v in ipairs(newEffect:GetChildren()) do
		v:Emit(8)
	end

	Debris:AddItem(newEffect, 0.5)
end

function module.FireRaycast(spread)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { camera, player.Character }

	local offset = CFrame.Angles(util.randomAngle(spread), util.randomAngle(spread), util.randomAngle(spread))
	local cf = camera.CFrame * offset

	local origin = camera.CFrame.Position
	local direction = cf.LookVector * 300

	local raycast = workspace:Raycast(origin, direction, raycastParams)

	if not raycast or not util.checkForHumanoid(raycast.Instance) then
		raycast = workspace:Spherecast(origin, 1.5, direction, raycastParams)
	end

	return raycast
end

function module.FireBullet(damage, spread)
	local result = module.FireRaycast(spread)
	if not result then
		return
	end

	placeHitEffect(result.Position)

	local hitWeapon = RicoshotService.checkRicoshot(result)
	if GiftsService.CheckGift("Ricoshot") and hitWeapon then
		local hit = RicoshotService.doRicoshot(hitWeapon, player.Character)
		dealDamage(hit, damage + 3)
		return
	end

	task.spawn(function()
		dealDamage(result.Instance, damage)
	end)
end

local function FireDefault()
	if currentAmmo <= 0 then
		task.wait()
		return
	end

	module.FireBullet(1, 0)

	local default = viewmodel.Model.Default

	module.UpdateAmmo(currentAmmo - 1)

	util.PlaySound(assets.Sounds.Fire, script, 0.15)

	local recoilVector = Vector3.new(0, 0.3, 0)

	if defaultIndex == 0 then
		showMuzzleFlash(default.Right.FirePart)
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
		showMuzzleFlash(default.Left.FirePart)
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

	task.wait(0.2)

	if currentAmmo <= 0 then
		ReloadDefault()
	end
end

function module.Fire()
	if not currentWeapon then
		FireDefault()
		return
	end

	for _ = 1, weaponData.BulletCount do
		module.FireBullet(weaponData.Damage, weaponData.BulletCount - 1)
	end

	module.UpdateAmmo(currentAmmo - 1)

	util.PlaySound(currentWeapon.FirePart.Fire, script, 0.15)

	showMuzzleFlash(currentWeapon.FirePart)

	local playingAnimation
	if currentAmmo == 0 then
		playingAnimation = animationService:playAnimation(
			viewmodel.Model,
			"FireOut",
			Enum.AnimationPriority.Action3.Value,
			false,
			0,
			2,
			1
		)
	else
		playingAnimation = animationService:playAnimation(
			viewmodel.Model,
			"Fire",
			Enum.AnimationPriority.Action2.Value,
			false,
			0,
			2,
			1
		)
	end

	Recoil(
		weaponData.Recoil.RecoilVector,
		weaponData.Recoil.RandomVector,
		weaponData.Recoil.Magnitude,
		weaponData.Recoil.Speed
	)

	if currentAmmo <= 0 then
		playingAnimation.Stopped:Wait()
		module.Throw()
		return
	end

	task.wait(weaponData.FireDelay)
end

local function ThrowWeapon()
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local weaponClone = currentWeapon:Clone()
	local grip = weaponClone.Grip
	local hasHitTarget = false
	local onHit

	local overlapParams = OverlapParams.new()

	overlapParams.FilterDescendantsInstances = { CollectionService:GetTagged("Enemy") }
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	local weaponJanitor = Janitor:new()
	weaponJanitor:LinkToInstance(weaponClone)

	currentWeapon:Destroy()
	currentWeapon = nil
	slots[currentSlot].currentWeapon = nil

	weaponClone:AddTag("ThrownWeapon")

	local newAttachment = Instance.new("Attachment")
	newAttachment.Parent = weaponClone.Grip

	local newForce = Instance.new("VectorForce")
	newForce.Parent = weaponClone.Grip
	newForce.Attachment0 = newAttachment
	newForce.RelativeTo = Enum.ActuatorRelativeTo.World
	newForce.Force = Vector3.new(0, 150, 0)

	weaponClone.Motor6D:Destroy()
	weaponClone.Parent = workspace
	weaponClone.HitBox.CanCollide = true

	grip.CFrame = viewmodel.Model.RightGrip.CFrame

	grip.Velocity = (camera.CFrame.LookVector * 80)
	grip.RotVelocity = Vector3.new(math.random(-20, 20), math.random(10, 20), math.random(-20, 20)) * 0.8

	onHit = RunService.Heartbeat:Connect(function()
		if grip.Velocity.Magnitude < 30 or hasHitTarget then
			onHit:Disconnect()
			return
		end

		if not weaponClone.Parent then
			return
		end

		local hits = workspace:GetPartBoundsInBox(weaponClone.HitBox.CFrame, weaponClone.HitBox.Size, overlapParams)

		for _, hit in ipairs(hits) do
			if not dealDamage(hit, 2) then
				continue
			end

			hasHitTarget = true
			onHit:Disconnect()
			return
		end
	end)

	weaponJanitor:Add(onHit, "Disconnect")

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
	task.wait(1)

	weaponClone:Destroy()
end

function module.Unequip()
	animationService:stopAnimation(viewmodel.Model, "Idle", 0)
	animationService:stopAnimation(viewmodel.Model, "Fire", 0)
	animationService:stopAnimation(viewmodel.Model, "FireOut", 0)

	currentWeapon:Destroy()
	currentWeapon = nil
end

function module.SwitchToSlot(slotNumber)
	acts:waitForAct("Throwing")

	if currentSlot == slotNumber then
		return
	end

	currentSlot = slotNumber

	local slot = slots[slotNumber]

	if currentWeapon then
		module.Unequip()
	end

	if slot.CurrentWeapon then
		module.EquipWeapon(slot.CurrentWeapon.Name, true)
	else
		defaultWeapon.Parent = viewmodel.Model
	end

	module.UpdateAmmo(slot.Ammo)
end

function module.Throw()
	if acts:checkAct("Throwing") then
		return
	end

	acts:createAct("Throwing")

	animationService:stopAnimation(viewmodel.Model, "Idle", 0)
	animationService:stopAnimation(viewmodel.Model, "Fire", 0)
	animationService:stopAnimation(viewmodel.Model, "FireOut", 0)

	local animation = animationService:playAnimation(viewmodel.Model, "Throw", Enum.AnimationPriority.Action4.Value)

	animation.Ended:Wait()
	EquipDefault()

	acts:removeAct("Throwing")
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
	viewmodel:Run()

	defaultWeapon = viewmodel.Model.Default

	animationService:loadAnimations(viewmodel.Model, viewmodel.Model.Animations)

	for _, animation in pairs(animationService.animations[viewmodel.Model]) do
		animation:GetMarkerReachedSignal("Event"):Connect(actOnAnimation)
	end
end

function module:OnSpawn()
	module.UpdateAmmo(module.defaultMagSize)

	animationService:playAnimation(viewmodel.Model, "DefaultIdle", Enum.AnimationPriority.Core.Value)
end

--//Main//--

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseButton1Down = true
	end

	if input.KeyCode == Enum.KeyCode.R and not currentWeapon then
		local conditions = acts.Condition.blacklist("Firing", "Throwing")

		acts:createTempAct("Reloading", ReloadDefault, conditions)
	end

	if input.KeyCode == Enum.KeyCode.X and currentWeapon then
		module.Throw()
	end

	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.Two then
		if not GiftsService.CheckGift("MuleBags") then
			return
		end

		if currentSlot == 1 then
			module.SwitchToSlot(2)
		else
			module.SwitchToSlot(1)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseButton1Down = false
	end
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

	local conditions = acts.Condition.blacklist("Reloading", "Throwing")
	acts:createTempAct("Firing", module.Fire, conditions)
end)

net:Connect("EquipWeapon", module.EquipWeapon)

signals.DoWeaponAction:Connect(function(actionName, ...)
	return module[actionName](...)
end)

signals.AddAmmo:Connect(function()
	module.UpdateAmmo(currentAmmo + (weaponData.Ammo * 0.25))
end)

return module
