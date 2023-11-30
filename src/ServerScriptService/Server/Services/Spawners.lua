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

local equipWeaponRemote = net:RemoteEvent("EquipWeapon")

local assets = Globals.Assets

local rng = Random.new()
local spawnChances = {
	Enemies = 50,
	Items = 50,
}

local objectTypes = {
	Enemy = {
		Folder = serverStorage.Enemies,
		OnSpawn = function(object)
			for _, scriptInstance in ipairs(object:GetChildren()) do
				if not scriptInstance:IsA("Script") then
					continue
				end
				scriptInstance.Enabled = true
			end
		end,
	},

	Weapon = {
		Folder = assets.Models.WeaponPickups,
		OnSpawn = function(object)
			for _, weapon in ipairs(CollectionService:GetTagged("Weapon")) do --- if spawned too close to another, then destroy
				if weapon == object then
					continue
				end
				local distance = (object:GetPivot().Position - weapon:GetPivot().Position).Magnitude

				if distance <= 2 then
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

			local newWeld = Instance.new("Weld")
			newWeld.Parent = newHitbox
			newWeld.Part1 = newHitbox
			newWeld.Part0 = object.Grip

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
		end,
	},
}

local function getRandomObjectOfType(type)
	local getType = objectTypes[type]

	local getObjects = getType.Folder:GetChildren()
	return getObjects[math.random(1, #getObjects)]
end

local function placeNewObject(position, type)
	local newObject = getRandomObjectOfType(type):Clone()

	newObject:AddTag(type)
	newObject.Parent = workspace
	newObject:PivotTo(CFrame.new(position))

	task.spawn(objectTypes[type].OnSpawn, newObject)
end

local function getSpawnPoint(unit: Model)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Whitelist
	rp.FilterDescendantsInstances = { map }

	local origin = unit:GetPivot()
	local raycast = workspace:Raycast(origin.Position, origin.UpVector * -200, rp)

	if not raycast then
		return
	end

	return raycast.Position
end

function module.spawnInUnit(unit, toSpawn, offset)
	local chance = rng:NextNumber(0, 100)
	if chance > spawnChances.Enemies then
		return
	end -- chance to spawn

	for _ = 1, math.random(1, 4) do
		local position = getSpawnPoint(unit)

		if not position then
			continue
		end
		placeNewObject(position + offset, toSpawn)
	end
end

function module.spawnEnemies()
	for _, unit in ipairs(map:GetChildren()) do
		module.spawnInUnit(unit, "Enemy", Vector3.new(0, 5, 0))
	end
end

function module.spawnWeapons()
	for _, unit in ipairs(map:GetChildren()) do
		module.spawnInUnit(unit, "Weapon", Vector3.new(0, 3, 0))
	end
end

return module
