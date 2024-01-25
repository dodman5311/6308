local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local map = workspace.Map

local Globals = require(ReplicatedStorage.Shared.Globals)
local UiAnimationService = require(Globals.Vendor.UIAnimationService)
local net = require(Globals.Packages.Net)
local HandleNpcs = require(Globals.Server.HandleNpcs)

local equipWeaponRemote = net:RemoteEvent("EquipWeapon")

local assets = Globals.Assets

local rng = Random.new()

local function onWeaponSpawned(object)
	for _, weapon in ipairs(CollectionService:GetTagged("Weapon")) do --- if spawned too close to another, then destroy
		if weapon == object then
			continue
		end
		local distance = (object:GetPivot().Position - weapon:GetPivot().Position).Magnitude

		if distance < 25 then
			object:Destroy()
			return
		end
	end

	local rotate
	local pivotPoint = object.Grip.PivotPoint
	local newGui = assets.Gui.PickupUi:Clone()

	newGui.Parent = object
	newGui.Adornee = pivotPoint
	newGui.Enabled = true

	UiAnimationService.PlayAnimation(newGui.Frame, 0.045, true)

	local newHitbox = Instance.new("Part")
	newHitbox.Size = object:GetExtentsSize()

	newHitbox.Transparency = 1
	newHitbox.Parent = object
	newHitbox.Name = "Hitbox"
	newHitbox.CanCollide = false
	newHitbox.Anchored = true
	newHitbox.CFrame = object:GetPivot()

	object.WorldPivot = pivotPoint.WorldCFrame

	rotate = RunService.Heartbeat:Connect(function()
		object:PivotTo(object:GetPivot() * CFrame.Angles(0, math.rad(1), 0))
	end)

	newHitbox.Touched:Connect(function(partHit)
		local model = partHit:FindFirstAncestorOfClass("Model")
		if not model then
			return
		end

		local player = Players:GetPlayerFromCharacter(model)
		if not player then
			return
		end

		rotate:Disconnect()
		equipWeaponRemote:FireClient(player, object.Name)

		object:Destroy()
	end)
end

local objectTypes = {
	Enemy = {
		SpawnChance = 100,
		Folder = serverStorage.Enemies,
		OnSpawn = function()
			-- for _, scriptInstance in ipairs(object:GetChildren()) do
			-- 	if not scriptInstance:IsA("Script") then
			-- 		continue
			-- 	end
			-- 	scriptInstance.Enabled = true
			-- end
		end,
	},

	Weapon = {
		SpawnChance = 75,
		Folder = assets.Models.WeaponPickups,
		OnSpawn = onWeaponSpawned,
	},
}

local function getRandomObjectOfType(type)
	local getType = objectTypes[type]

	local getObjects = getType.Folder:GetChildren()
	return getObjects[math.random(1, #getObjects)]
end

local function placeNewObject(position, type)
	local selectedObject = getRandomObjectOfType(type)

	local newObject

	if type == "Enemy" then
		newObject = HandleNpcs:new(selectedObject.Name)
		newObject:Spawn(position)

		task.spawn(objectTypes[type].OnSpawn, newObject)
		return
	else
		newObject = selectedObject:Clone()
	end

	newObject:AddTag(type)
	newObject.Parent = workspace
	newObject:PivotTo(CFrame.new(position))

	task.spawn(objectTypes[type].OnSpawn, newObject)
end

local function getSpawnPoint(unit: Model, partToCastFrom)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Whitelist
	rp.FilterDescendantsInstances = { map }

	local origin = partToCastFrom and partToCastFrom.CFrame or unit:GetPivot()
	local raycast = workspace:Raycast(origin.Position, origin.UpVector * -200, rp)

	if not raycast then
		return
	end

	return raycast.Position
end

function module.spawnInUnit(unit, toSpawn, offset, lookForPart)
	local chance = rng:NextNumber(0, 100)
	if chance > objectTypes[toSpawn].SpawnChance then
		return
	end -- chance to spawn

	local getPart = lookForPart and unit:FindFirstChild(lookForPart, true)
	local position = getSpawnPoint(unit, getPart)

	if not position then
		return
	end

	placeNewObject(position + offset, toSpawn)
end

function module.spawnEnemies()
	for _, unit in ipairs(map:GetChildren()) do
		if unit.Name == "Start" then
			continue
		end

		local spawnAmount = math.round(math.clamp(unit:GetExtentsSize().Magnitude / 30, 2, 8))

		for _ = 1, math.random(spawnAmount - 1, spawnAmount) do
			module.spawnInUnit(unit, "Enemy", Vector3.new(0, 5, 0))
		end
	end
end

function module.spawnWeapons()
	for _, unit in ipairs(map:GetChildren()) do
		module.spawnInUnit(unit, "Weapon", Vector3.new(0, 3, 0), "WeaponSpawn")
	end
end

return module
