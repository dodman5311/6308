local module = {}
--// Services
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local SERVER_STORAGE = game:GetService("ServerStorage")
local RUN_SERVICE = game:GetService("RunService")
local PLAYERS = game:GetService("Players")
local DEBRIS = game:GetService("Debris")

--// Instances
local assets = REPLICATED_STORAGE.Assets

local player = PLAYERS.LocalPlayer
local goreEffects = assets.GoreEffects
local sounds = goreEffects.Sounds

local Globals = require(REPLICATED_STORAGE.Shared.Globals)

local map = workspace.Map

--// Modules
local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)

--// Values

-- MAKE REMOVE BASED ON PART COUNT

function module.createSplatter(cframe)
	local splatterTime = 120

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include

	rp.FilterDescendantsInstances = { map }
	local FloorRay =
		workspace:Raycast(cframe.Position, (cframe * CFrame.Angles(math.rad(-45), 0, 0)).LookVector * 10, rp)
	local wallRay = workspace:Raycast(cframe.Position, cframe.LookVector * 12, rp)

	if FloorRay then
		local getSplatter = util.callFromCache(util.getRandomChild(goreEffects.FloorSplatter))
		util.addToCache(getSplatter, splatterTime)

		getSplatter.Parent = map
		getSplatter.CFrame = cframe
		getSplatter.Position = FloorRay.Position -- + Vector3.new(0,-0.5,0)
		getSplatter.Size = Vector3.new(4.25 + math.random(-500, 500) / 100, 0.001, 8.75 + math.random(-500, 500) / 100)
	end

	if wallRay then
		local getSplatter = util.callFromCache(util.getRandomChild(goreEffects.WallSplatter))
		util.addToCache(getSplatter, splatterTime)

		getSplatter.Parent = map
		getSplatter.CFrame = CFrame.new(wallRay.Position, wallRay.Position + wallRay.Normal)
			* CFrame.Angles(0, 0, math.rad(math.random(0, 360)))
		getSplatter.Size = Vector3.new(5.25 + math.random(-100, 100) / 100, 5.25 + math.random(-100, 100) / 100, 0.001)
	end
end

function module.bloodSploof(cframe, pos)
	local newBloodEffect = util.callFromCache(goreEffects.BloodPuff)
	newBloodEffect.Parent = workspace
	newBloodEffect.CFrame = cframe
	newBloodEffect.Position = pos
	util.addToCache(newBloodEffect, 2)

	for _, particle in ipairs(newBloodEffect:GetChildren()) do
		particle.Enabled = true
		task.delay(0.075, function()
			particle.Enabled = false
		end)
	end
end

function module.bloodsplosion(position, explosionType)
	local newBloodEffect =
		util.callFromCache((explosionType and goreEffects:FindFirstChild(explosionType)) or goreEffects.Bloodsplosion)
	newBloodEffect.Parent = workspace
	newBloodEffect.Position = position
	util.addToCache(newBloodEffect, 2)

	for _, particle in ipairs(newBloodEffect:GetChildren()) do
		particle.Enabled = true
		task.delay(0.1, function()
			particle.Enabled = false
		end)
	end

	for i = 0, 360, 15 do
		module.createSplatter(CFrame.new(position) * CFrame.Angles(0, math.rad(i), 0))
	end
end

local function createBit(velocity, position, isSkull)
	local bit
	if isSkull then
		bit = util.callFromCache(goreEffects.Skull)
	else
		bit = util.callFromCache(util.getRandomChild(goreEffects.Bits))
	end
	bit.CanCollide = false
	bit.Parent = workspace.Ignore
	bit.Position = position
	bit.Velocity = Vector3.new(
		math.random(-velocity, velocity),
		math.random(velocity * 1.75, velocity * 3),
		math.random(-velocity, velocity)
	)

	util.addToCache(bit, 3.25)

	task.delay(0.1, function()
		bit.CanCollide = true
	end)
end

function module.explosion(bitCount, velocity, position, part, noSkull, explosionType)
	module.bloodsplosion(position, explosionType)
	for i = 1, bitCount do
		createBit(velocity, position, i == 1 and not noSkull)
	end

	local bloodSounds = sounds.Bloodsplosion
	local bloodSound = util.getRandomChild(bloodSounds)

	util.PlaySound(bloodSound, part, 0.1)
	util.PlaySound(sounds.SkullCrack, part, 0.1, 0.5)
end

function module.gibEnemy(enemy)
	for _, part in ipairs(enemy:GetDescendants()) do
		if not part:IsA("BasePart") or part:FindFirstAncestor("CurrentWeapon") then
			continue
		end
		part.Transparency = 1
	end

	module.explosion(17, 18, enemy:GetPivot().Position, enemy.PrimaryPart, false, "Gib")
end

return module
