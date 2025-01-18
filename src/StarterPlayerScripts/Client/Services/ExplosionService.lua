local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects

--// Modules
local Net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)
local signals = require(Globals.Shared.Signals)
local signal = require(Globals.Packages.Signal)
local CameraController = require(Globals.Client.Controllers.CameraController)
local chanceService = require(Globals.Vendor.ChanceService)

--// Values

module.explosiveHit = signal.new()

local function hitEnemy(subject, damage, magnitude, sender, source, element)
	task.wait(0.05)

	if element and not chanceService.checkChance(50, true) then
		element = nil
	end

	local serverHumanoid, preHealth, postHealth = Net:RemoteFunction("Damage")
		:InvokeServer(subject, damage or 1, element)

	local hitPlayer = Players:GetPlayerFromCharacter(subject)
	if hitPlayer then
		--CameraController.ShakeCamera("Explosion", magnitude)
	end

	if not serverHumanoid or not sender or not sender:IsA("Player") then
		return
	end

	module.explosiveHit:Fire(subject, preHealth, postHealth, math.clamp(damage, 0, math.huge), source)
end

local elementalExplosions = {
	Electricity = function(position, size, color)
		local lightTi = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local newEffect = Effects.ElectricExplode:Clone()

		Debris:AddItem(newEffect, 5)

		newEffect.Center.Electricity.Color = ColorSequence.new(color or Color3.fromRGB(188, 239, 255))

		newEffect.Parent = workspace.Ignore
		newEffect.Position = position

		newEffect.Center.Electricity:Emit(150)
		util.tween(newEffect.Light, lightTi, { Brightness = 0 })

		return newEffect
	end,

	Fire = function(position, size, color)
		local lightTi = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local newEffect = Effects.FireExplode:Clone()

		Debris:AddItem(newEffect, 5)

		newEffect.Center.Fire.Color = ColorSequence.new(color or Color3.fromRGB(255, 255, 255))

		newEffect.Parent = workspace.Ignore
		newEffect.Position = position

		newEffect.Center.Fire:Emit(150)
		util.tween(newEffect.Light, lightTi, { Brightness = 0 })

		local rp = RaycastParams.new()
		rp.FilterDescendantsInstances = { workspace.Map }
		rp.FilterType = Enum.RaycastFilterType.Include

		local cast = workspace:Raycast(position, CFrame.new(position + Vector3.new(0, 1, 0)).UpVector * -size, rp)

		if not cast then
			return newEffect
		end

		local linger = Effects.FireLinger:Clone()
		Debris:AddItem(linger, 5)
		linger.Parent = workspace
		linger.Position = cast.Position
		linger.Fire.Enabled = true

		local beat
		local i = 0

		beat = RunService.Heartbeat:Connect(function(deltaTime)
			if not linger or not linger.Parent then
				beat:Disconnect()
			end

			i += deltaTime

			if i >= 0.5 then
				i = 0
			else
				return
			end

			local partsHit = workspace:GetPartsInPart(linger)

			for _, part in ipairs(partsHit) do
				Net:RemoteEvent("Damage"):FireServer(part, 0, "Fire")
			end
		end)

		return newEffect
	end,
}

local function emitObject(part)
	for _, emitter in ipairs(part:GetChildren()) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		local emitCount = emitter:GetAttribute("EmitCount")
		local emitDelay = emitter:GetAttribute("EmitDelay")

		if emitDelay > 0 then
			task.delay(emitDelay, function()
				emitter:Emit(emitCount)
			end)
		else
			emitter:Emit(emitCount)
		end
	end
end

local function explodeNormal(position, size, color)
	local lightTi = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local newEffect

	if size < 15 then
		newEffect = Effects.Explosions.Small_Explosion
	elseif size <= 30 then
		newEffect = Effects.Explosions.Medium_Explosion
	else
		newEffect = Effects.Explosions.Large_Explosion
	end

	newEffect = newEffect:Clone()
	newEffect.Position = position
	newEffect.Parent = workspace
	Debris:AddItem(newEffect, 5)

	emitObject(newEffect)
	util.tween(newEffect.PointLight, lightTi, { Brightness = 0 })

	return newEffect
end

function module.createExplosion(position, size, damage, sender, color, source, element, chance)
	if chance and not chanceService.checkChance(chance, true) then
		return
	end

	local effect

	if element then
		effect = elementalExplosions[element](position, size, color)
	else
		effect = explodeNormal(position, size, color)
	end

	local sound

	if size < 15 then
		sound = Assets.Sounds.Small_Explosion
	elseif size <= 30 then
		sound = Assets.Sounds.Medium_Explosion
	else
		sound = Assets.Sounds.Large_Explosion
	end

	util.PlaySound(sound, effect, 0.1)

	local list = {}

	list = collectionService:GetTagged("Npc")

	if not sender or not sender:IsA("Player") then
		for _, v in ipairs(Players:GetPlayers()) do
			table.insert(list, v.Character)
		end
	end

	if sender and Players.LocalPlayer ~= sender then
		return
	end

	local rp = RaycastParams.new()

	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }

	for _, target in ipairs(list) do
		if string.match(target.Name, "Vending Machine") then
			continue
		end

		local targetPosition = target:GetPivot().Position
		local direction = targetPosition - position

		local distance = direction.Magnitude
		if distance > size then
			continue
		end

		if workspace:Raycast(position, direction, rp) then
			continue
		end

		local distancePercentage = math.abs((distance / size) - 1)
		task.spawn(
			hitEnemy,
			target,
			math.ceil(damage * distancePercentage),
			distancePercentage,
			sender,
			source,
			element
		)
	end
end

Net:Connect("CreateExplosion", module.createExplosion)

return module
