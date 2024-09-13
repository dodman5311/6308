local module = {}
--// Services
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local SERVER_STORAGE = game:GetService("ServerStorage")
local RUN_SERVICE = game:GetService("RunService")
local PLAYERS = game:GetService("Players")
local DEBRIS = game:GetService("Debris")
local collectionService = game:GetService("CollectionService")

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
local giftService = require(Globals.Client.Services.GiftsService)

local rng = Random.new()

local splatters = {}
local lastSplat = os.clock()
local splatsInInstant = 0

--// Values

-- MAKE REMOVE BASED ON PART COUNT

local function checkLimit()
	if #splatters > 75 then
		local toRemove = splatters[1]
		toRemove:Destroy()

		table.remove(splatters, 1)
	end
end

function module.createSplatter(cframe, ignoreInstantLimit)
	if not ignoreInstantLimit then
		if os.clock() - lastSplat < 0.05 then
			splatsInInstant += 1
		else
			splatsInInstant = 0
		end

		if splatsInInstant > 4 then
			return
		end
	end

	local splatterTime = 10

	if giftService.CheckGift("Sauce_Is_Fuel") then
		splatterTime += 5
	end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include

	rp.FilterDescendantsInstances = { map }
	local FloorRay = workspace:Raycast(cframe.Position, CFrame.new(cframe.Position).UpVector * -10, rp)
	local wallRay = workspace:Raycast(cframe.Position, cframe.LookVector * 30, rp)

	if FloorRay then
		local getSplatter = util.callFromCache(util.getRandomChild(goreEffects.FloorSplatter))
		util.addToCache(getSplatter, splatterTime)

		getSplatter:AddTag("Blood")
		getSplatter.CollisionGroup = "Blood"
		getSplatter.Parent = map
		getSplatter.CFrame = cframe
		getSplatter.Position = FloorRay.Position
		getSplatter.Orientation *= Vector3.new(0, 1, 0)
		getSplatter.Size = Vector3.new(8 + rng:NextNumber(-2, 2), 0.001, 16 + rng:NextNumber(-2, 2))

		getSplatter.CFrame *= CFrame.new(0, 0, -(getSplatter.Size.Z / 2))

		table.insert(splatters, getSplatter)

		getSplatter.AncestryChanged:Connect(function()
			table.remove(splatters, table.find(splatters, getSplatter))
		end)

		checkLimit()
	end

	if wallRay then
		local getSplatter = util.callFromCache(util.getRandomChild(goreEffects.WallSplatter))
		util.addToCache(getSplatter, splatterTime)

		getSplatter:AddTag("Blood")
		getSplatter.CollisionGroup = "Blood"
		getSplatter.Parent = map
		getSplatter.CFrame = CFrame.new(wallRay.Position, wallRay.Position + wallRay.Normal)
			* CFrame.Angles(0, 0, math.rad(math.random(0, 360)))
		getSplatter.Size = Vector3.new(8 + rng:NextNumber(-2, 2), 8 + rng:NextNumber(-2, 2), 0.001)

		table.insert(splatters, getSplatter)

		getSplatter.AncestryChanged:Connect(function()
			table.remove(splatters, table.find(splatters, getSplatter))
		end)

		checkLimit()
	end

	lastSplat = os.clock()
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
		module.createSplatter(CFrame.new(position) * CFrame.Angles(0, math.rad(i), 0), true)
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
	if enemy:IsA("BasePart") then
		enemy = enemy:FindFirstAncestorOfClass("Model")
	end
	if not enemy then
		return
	end

	for _, part in ipairs(enemy:GetDescendants()) do
		if not part:IsA("BasePart") or part:FindFirstAncestor("CurrentWeapon") then
			continue
		end
		part.Transparency = 1
	end

	module.explosion(17, 18, enemy:GetPivot().Position, enemy.PrimaryPart, false, "Gib")
end

function module.clearBlood()
	for _, blood in ipairs(collectionService:GetTagged("Blood")) do
		blood:Destroy()
	end
end

net:Connect("ClearBlood", module.clearBlood)

return module
