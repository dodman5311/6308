local module = {
	defaultMagSize = 16,
}

--// Services
local CollectionService = game:GetService("CollectionService")
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
local acts = require(Globals.Vendor.Acts)
local util = require(Globals.Vendor.Util)
local spring = require(Globals.Vendor.Spring)

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

--// Function

local recoilSpring = spring.new(Vector3.zero)
recoilSpring.Speed = 30
recoilSpring.Damper = 0.45

function module.UpdateAmmo(amount)
	currentAmmo = amount
	signals.DoUiAction:Fire("HUD", "UpdateAmmo", true, currentAmmo)
end

function module.EquipWeapon(weaponName)
	if acts:checkAct("Throwing") then
		return
	end

	if currentWeapon then
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
	animationService:playAnimation(viewmodel.Model, "Idle", Enum.AnimationPriority.Idle.Value)

	module.UpdateAmmo(weaponData.Ammo)

	currentWeapon = newWeapon
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
end

local function dealDamage(subject, damage)
	local humanoid, returnedDamage = net:RemoteFunction("Damage"):InvokeServer(subject, damage)

	if not humanoid then
		return
	end

	signals.DoUiAction:Fire("HUD", "ShowHit", true)
	return humanoid
end

function module.FireRaycast()
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { camera, player.Character }

	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * 300

	local raycast = workspace:Raycast(origin, direction, raycastParams)

	if not raycast or not util.checkForHumanoid(raycast.Instance) then
		raycast = workspace:Spherecast(origin, 1.5, direction, raycastParams)
	end

	return raycast
end

function module.FireBullet(damage)
	local result = module.FireRaycast()
	if not result then
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

	module.FireBullet(1)

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

	module.FireBullet(weaponData.Damage)

	module.UpdateAmmo(currentAmmo - 1)

	util.PlaySound(currentWeapon.FirePart.Fire, script, 0.15)

	showMuzzleFlash(currentWeapon.FirePart)

	if currentAmmo == 0 then
		animationService:playAnimation(viewmodel.Model, "FireOut", Enum.AnimationPriority.Action3.Value, false, 0, 2, 1)
	else
		animationService:playAnimation(viewmodel.Model, "Fire", Enum.AnimationPriority.Action2.Value, false, 0, 2, 1)
	end

	Recoil(
		weaponData.Recoil.RecoilVector,
		weaponData.Recoil.RandomVector,
		weaponData.Recoil.Magnitude,
		weaponData.Recoil.Speed
	)

	task.wait(weaponData.FireDelay)

	if currentAmmo <= 0 then
		module.Throw()
	end
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

	currentWeapon:Destroy()
	currentWeapon = nil

	weaponClone.Motor6D:Destroy()
	weaponClone.Parent = workspace
	weaponClone.HitBox.CanCollide = true

	grip.CFrame = viewmodel.Model.RightGrip.CFrame
	grip.Velocity = (camera.CFrame.LookVector * 100) + Vector3.new(0, 20, 0)
	grip.RotVelocity = Vector3.new(math.random(-10, 10), math.random(15, 20), math.random(-10, 10))

	onHit = RunService.Heartbeat:Connect(function()
		if grip.Velocity.Magnitude < 30 then
			onHit:Disconnect()
			return
		end

		local hits = workspace:GetPartBoundsInBox(weaponClone.HitBox.CFrame, weaponClone.HitBox.Size, overlapParams)

		for _, hit in ipairs(hits) do
			if hasHitTarget or not dealDamage(hit, 2) then
				continue
			end

			hasHitTarget = true
			onHit:Disconnect()
			return
		end
	end)

	repeat
		task.wait()
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

return module
