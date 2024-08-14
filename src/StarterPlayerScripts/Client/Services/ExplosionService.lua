local Players = game:GetService("Players")
local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects
local ExplodeEffect = Effects.ExplodeEffect

--// Modules
local Net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)
local signals = require(Globals.Shared.Signals)
local signal = require(Globals.Packages.Signal)
local CameraController = require(Globals.Client.Controllers.CameraController)

--// Values

module.explosiveHit = signal.new()

local function hitEnemy(subject, damage, magnitude, sender, source)
	task.wait(0.05)

	local serverHumanoid, preHealth, postHealth = Net:RemoteFunction("Damage"):InvokeServer(subject, damage or 1)

	local hitPlayer = Players:GetPlayerFromCharacter(subject)
	if hitPlayer then
		--CameraController.ShakeCamera("Explosion", magnitude)
	end

	if not serverHumanoid or not sender or not sender:IsA("Player") then
		return
	end

	module.explosiveHit:Fire(subject, preHealth, postHealth, math.clamp(damage, 0, math.huge), source)
end

function module.createExplosion(position, size, damage, sender, color, source)
	local lightTi = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local newEffect = ExplodeEffect:Clone()
	newEffect.Explosion.Color = ColorSequence.new(color or Color3.new(1, 1, 1))

	newEffect.Parent = workspace.Ignore
	newEffect.Position = position

	newEffect.Explosion.Size = NumberSequence.new(size / 1.5)
	newEffect.Shockwave.Size = NumberSequence.new(size)

	newEffect.Explosion:Emit(1)
	newEffect.Shockwave:Emit(1)
	util.tween(newEffect.Light, lightTi, { Brightness = 0 })

	local sound

	if size < 15 then
		sound = Assets.Sounds.Small_Explosion
	elseif size <= 30 then
		sound = Assets.Sounds.Medium_Explosion
	else
		sound = Assets.Sounds.Large_Explosion
	end

	util.PlaySound(sound, newEffect, 0.1)

	local list = {}

	list = collectionService:GetTagged("Npc")

	if not sender or not sender:IsA("Player") then
		for _, v in ipairs(Players:GetPlayers()) do
			table.insert(list, v.Character)
		end
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
		task.spawn(hitEnemy, target, math.ceil(damage * distancePercentage), distancePercentage, sender, source)
	end
end

Net:Connect("CreateExplosion", module.createExplosion)

return module
