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

		if distance < 1 then
			object:Destroy()
			return
		end
	end

	object:AddTag("Pickup")

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

	local newPrompt = Instance.new("ProximityPrompt")
	newPrompt.Parent = pivotPoint
	newPrompt.RequiresLineOfSight = false

	object.Destroying:Connect(function()
		rotate:Disconnect()
	end)

	newPrompt.Triggered:Connect(function(player)
		equipWeaponRemote:FireClient(
			player,
			object.Name,
			"FromWorld",
			object:GetAttribute("Element"),
			object:GetAttribute("ExtraAmmo")
		)

		object:Destroy()
	end)
end

local objectTypes = {
	Enemy = {
		SpawnChance = 100,
		Folder = ReplicatedStorage.Enemies,
		OnSpawn = function() end,
	},

	Npc = {
		SpawnChance = 100,
		Folder = ReplicatedStorage.Enemies.Npcs,
		OnSpawn = function() end,
	},

	VendingMachine = {
		SpawnChance = 25,
		Folder = ReplicatedStorage.Enemies.Npcs.VendingMachine,
		OnSpawn = function() end,
	},

	Weapon = {
		SpawnChance = 75,
		Folder = assets.Models.WeaponPickups,
		OnSpawn = onWeaponSpawned,
	},
}

local function getList(currentLevel, type, noChance)
	local getType = objectTypes[type]
	local List = {}

	local getObjects = getType.Folder:GetChildren()

	for _, object in ipairs(getObjects) do
		if not object:IsA("Model") and not object:IsA("BasePart") then
			continue
		end

		local chance = object:GetAttribute("SpawnChance")
		if not noChance and chance and rng:NextNumber(0, 100) > chance then
			continue
		end

		local level = object:GetAttribute("Level")
		if level then
			if currentLevel < level.Min or currentLevel > level.Max then
				continue
			end
		end

		table.insert(List, object)
	end

	return List
end

local function getRandomObjectOfType(currentLevel, type, noChance)
	local getObjects = getList(currentLevel, type, noChance)
	if #getObjects == 0 then
		return
	end
	return getObjects[math.random(1, #getObjects)]
end

function module.placeNewObject(currentLevel, cframe, type, objectName, noChance)
	local selectedObject

	if not objectName then
		selectedObject = getRandomObjectOfType(currentLevel, type, noChance)
	else
		local getType = objectTypes[type]
		local object = getType.Folder:FindFirstChild(objectName)

		local level = object:GetAttribute("Level")
		if level and (currentLevel < level.Min or currentLevel > level.Max) then
			selectedObject = getRandomObjectOfType(currentLevel, type, noChance)
		else
			selectedObject = object
		end
	end

	if not selectedObject then
		return
	end

	local newObject

	if type == "Enemy" or type == "Npc" or type == "VendingMachine" then
		newObject = HandleNpcs.new(selectedObject.Name)
		newObject:Spawn(cframe)

		task.spawn(objectTypes[type].OnSpawn, newObject)
		return newObject.Instance
	else
		newObject = selectedObject:Clone()
	end

	newObject:AddTag(type)
	newObject.Parent = workspace

	if typeof(cframe) == "Vector3" then
		newObject:PivotTo(CFrame.new(cframe))
	else
		newObject:PivotTo(cframe)
	end

	task.spawn(objectTypes[type].OnSpawn, newObject)
	return newObject
end

local function getSpawnPoint(castFrom)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { map }

	local origin = castFrom:GetPivot()
	local raycast = workspace:Raycast(origin.Position, origin.UpVector * -200, rp)

	if not raycast then
		return
	end

	local distance = (raycast.Position - origin.Position).Magnitude

	return origin * CFrame.new(0, -distance, 0)
end

function module.spawnInUnit(currentLevel, unit, toSpawn, offset, partToSpawnOn, alwaysSpawn)
	local chance = rng:NextNumber(0, 100)
	if chance > objectTypes[toSpawn].SpawnChance and not alwaysSpawn then
		return
	end -- chance to spawn

	local getPart = partToSpawnOn
	local cframe = getSpawnPoint(getPart or unit)

	if not cframe then
		return
	end

	module.placeNewObject(currentLevel, cframe + offset, toSpawn)
	return true
end

function module.spawnEnemies(currentLevel)
	module.EnemiesSpawned = 0

	for _, spawner in ipairs(map:GetDescendants()) do
		if spawner.Name ~= "EnemySpawn" then
			continue
		end

		local unit = spawner.Parent

		if string.match(unit.Name, "Start") or string.match(unit.Name, "Arena") then
			continue
		end

		local spawnAmount = math.round(math.clamp(unit:GetExtentsSize().Magnitude / 30, 2, 6))

		for _ = 1, math.random(spawnAmount - 1, spawnAmount) do
			if module.spawnInUnit(currentLevel, unit, "Enemy", Vector3.new(0, 5, 0), spawner) then
				module.EnemiesSpawned += 1
			end
		end
	end
end

function module.spawnWeapons(currentLevel)
	module.WeaponsSpawned = 0

	for _, spawner in ipairs(map:GetDescendants()) do
		if spawner.Name ~= "WeaponSpawn" then
			continue
		end

		if module.spawnInUnit(currentLevel, nil, "Weapon", Vector3.new(0, 3, 0), spawner) then
			module.WeaponsSpawned += 1
		end
	end
end

function module.SpawnBoss(bossToSpawn, unit)
	local newObject = HandleNpcs.new(bossToSpawn)
	newObject:Spawn(unit:FindFirstChild("EnemySpawn"):GetPivot())

	newObject.Instance:AddTag("Enemy")
	newObject.Parent = workspace
end

function module.spawnHazards(currentLevel)
	for _, spawner in ipairs(map:GetDescendants()) do
		if spawner.Name ~= "HazardSpawn" then
			continue
		end

		local cframe = getSpawnPoint(spawner)
		local hazardToSpawn = spawner:GetAttribute("HazardType")

		if hazardToSpawn == "VendingMachine" then
			module.placeNewObject(currentLevel, cframe, "VendingMachine")
		else
			module.placeNewObject(currentLevel, cframe, "Npc", hazardToSpawn)
		end
	end
end

net:Connect("PickupWeapon", function(player, object)
	if not object or not object:HasTag("Weapon") then
		return
	end

	equipWeaponRemote:FireClient(player, object.Name, "FromWorld")

	object:Destroy()
end)

return module