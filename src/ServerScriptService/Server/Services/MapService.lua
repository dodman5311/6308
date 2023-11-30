local module = {}
--// services
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")

local Globals = require(replicatedStorage.Shared.Globals)

--// requirements
local util = require(Globals.Vendor.Util)
local spawners = require(Globals.Server.Services.Spawners)

--// instances
local map = workspace.Map
local startUnit = serverStorage.Start
local units = serverStorage.Units
local caps = serverStorage.Caps

--// values
local showHitboxes = false
local newStart = startUnit:Clone()
local links = {}

local unitModules = {}

--// library functions
local function doUnitFunction(functionName, unit, ...)
	local moduleTable = unitModules[unit.Name]
	if not moduleTable then
		return
	end

	for _, module in ipairs(moduleTable) do
		if not module[functionName] then
			continue
		end

		task.spawn(module[functionName], unit, ...)
	end
end

local function loadModules()
	for _, unit in ipairs(collectionService:GetTagged("Unit")) do
		local modules = unit.Modules
		local moduleTable = {}

		for _, module in ipairs(modules:GetChildren()) do
			table.insert(moduleTable, require(module))
		end

		unitModules[unit.Name] = moduleTable
	end
end

local function calculatePlacePosition(baseLink, newUnit, newLink)
	local newPos = newUnit:GetPivot()

	local g1 = baseLink.CFrame * CFrame.Angles(0, math.rad(180), 0)
	local g2 = newPos:ToObjectSpace(newLink.CFrame):Inverse()
	return g1 * g2
end

local function addLink(unit)
	for _, link in ipairs(unit.Links:GetChildren()) do
		table.insert(links, link)
	end
end

local function removeLink(unit)
	for _, link in ipairs(unit.Links:GetChildren()) do
		local index = table.find(links, link)

		if not index then
			continue
		end
		table.remove(links, index)
	end
end

local function checkLink(link)
	return link.LinkedTo.Value == nil or link.LinkedTo.Value.Parent == nil
end

local function showHitbox(cframe, size)
	local hitbox = Instance.new("Part")
	hitbox.Parent = workspace

	hitbox.Anchored = true
	hitbox.CFrame = cframe
	hitbox.Size = size

	hitbox.Color = Color3.new(1, 0, 0)
	hitbox.Transparency = 0.8

	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = false

	return hitbox
	--task.delay(3.5, function()
	--	hitbox:Destroy()
	--end)
end

-----------------------------------------// Important Functions //-----------------------------------------

--// Unit functions
local function setLinks(baseLink, unit)
	for _, link in ipairs(unit.Links:GetChildren()) do
		link.Transparency = 1
		link:FindFirstChild("LineHandleAdornment"):Destroy()

		local distance = (link.Position - baseLink.Position).Magnitude
		if distance > 0.1 then
			continue
		end

		baseLink.LinkedTo.Value = link
		link.LinkedTo.Value = baseLink
	end
end

local function placeUnit(baseLink, unit, unitLink)
	local newUnit = unit:Clone()
	local unitPosition = calculatePlacePosition(baseLink, newUnit, unitLink)
	newUnit:PivotTo(unitPosition)
	newUnit.Parent = map

	setLinks(baseLink, newUnit)

	doUnitFunction("OnPlaced", newUnit)

	return newUnit
end

local function placeCap(baseLink)
	local getCaps = caps:GetChildren()
	local cap = getCaps[math.random(1, #getCaps)]:Clone()
	cap.Parent = baseLink.Parent
	cap:PivotTo(baseLink.CFrame * CFrame.Angles(0, math.rad(180), 0))

	baseLink.LinkedTo.Value = cap.PrimaryPart
end

local function checkPlacable(baseLink, unit, unitLink)
	local leeway = 4

	local size = unit:GetExtentsSize() - (Vector3.new(1, 1, 1) * leeway)
	local pos = calculatePlacePosition(baseLink, unit, unitLink)

	local hitbox = showHitboxes and showHitbox(pos, size)
	local hitboxResult = workspace:GetPartBoundsInBox(pos, size)

	local canPlace = true
	for _, part in ipairs(hitboxResult) do
		if part.Parent ~= unit and part:FindFirstAncestor(map.Name) then
			canPlace = false

			if hitbox then
				hitbox:Destroy()
			end
			break
		end
	end

	return canPlace
end

local function addRandomUnit(baseLink)
	local unitToPlace = util.getRandomChild(units)
	local placeLink = util.getRandomChild(unitToPlace.Links)

	if checkPlacable(baseLink, unitToPlace, placeLink) then -- if the unit can be placed, then return
		return placeUnit(baseLink, unitToPlace, placeLink)
	end

	unitToPlace = nil
	for _, unit in ipairs(units:GetChildren()) do -- if the unit cannot be placed, then loop through units until one can be.
		if unit == unitToPlace then
			continue
		end

		for _, link in ipairs(unit.Links:GetChildren()) do
			if not checkLink(link) then
				continue
			end
			if checkPlacable(baseLink, unit, link) then
				unitToPlace = unit
				placeLink = link
			end
		end

		if unitToPlace then
			break
		end
	end

	if unitToPlace then
		return placeUnit(baseLink, unitToPlace, placeLink)
	else
		placeCap(baseLink)
	end
end

local function placeCaps()
	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant.Name ~= "Link" then
			continue
		end

		if descendant.LinkedTo.Value then
			continue
		end

		placeCap(descendant)
	end
end

--// Main function
function module.generateUnitsForLinks()
	for _, link in ipairs(links) do
		if not checkLink(link) then
			continue
		end

		local addedUnit = addRandomUnit(link)
		if not addedUnit then
			return
		end
	end
end

function module.generateUnit()
	for _, link in ipairs(links) do
		if not checkLink(link) then
			continue
		end

		addRandomUnit(link)
		return
	end
end

function module.loadMap(size)
	for _ = 1, size do
		module.generateUnit()
	end

	placeCaps()
	spawners.spawnEnemies()
	spawners.spawnWeapons()

	for _, unit in ipairs(map:GetChildren()) do
		doUnitFunction("OnLoaded", unit)
	end
end

-------------------------------------------------------------------
for _, v in ipairs(units:GetDescendants()) do
	if not v:IsA("BasePart") then
		continue
	end
	v.CollisionGroup = "Map"
end

loadModules()

map.ChildAdded:Connect(addLink)
map.ChildRemoved:Connect(removeLink)

newStart.Parent = map
doUnitFunction("OnPlaced", newStart)

module.loadMap(10)

return module
