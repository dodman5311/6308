local module = {
	CurrentStage = 2,
	CurrentLevel = 3,
	GeneratedAt = 0,
}
--// services
local RunService = game:GetService("RunService")
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Globals = require(replicatedStorage.Shared.Globals)

--// requirements
local spawners = require(Globals.Services.Spawners)
local signals = require(Globals.Signals)
local signal = require(Globals.Packages.Signal)
local net = require(Globals.Packages.Net)
local arenas = require(Globals.Services.HandleArenas)

module.onLevelPassed = signal.new()
--// instances

local map = workspace.Map
local startUnit
local units
local caps
local exit
local kiosk
local sky
local bossRoom
local miniBossRoom
local stageFolder

local storedMap

--// values
local showHitboxes = false
local newStart
local links = {}

local leeway = 6
--local unitModules = {}
local blacklistedUnits = {}

local clearBloodEvent = net:RemoteEvent("ClearBlood")
net:RemoteEvent("StartExitSequence")
net:RemoteEvent("ProceedToNextLevel")
net:RemoteEvent("SpawnBoss")
net:RemoteEvent("MiniBossExit")

local function doUnitFunction(functionName, unit, ...)
	-- local moduleTable = unitModules[unit.Name]
	-- if not moduleTable then
	-- 	return
	-- end

	-- for _, unitModule in ipairs(moduleTable) do
	-- 	if not unitModule[functionName] then
	-- 		continue
	-- 	end

	-- 	task.spawn(unitModule[functionName], unit, module, ...)
	-- end

	local modules = unit:FindFirstChild("Modules")
	if not modules then
		return
	end

	for _, unitModule in ipairs(modules:GetChildren()) do
		local required = require(unitModule)

		if not required[functionName] then
			continue
		end

		task.spawn(required[functionName], unit, module, ...)
	end
end

-- local function loadModules()
-- 	-- for _, unit in ipairs(collectionService:GetTagged("Unit")) do
-- 	-- 	local modules = unit.Modules
-- 	-- 	local moduleTable = {}

-- 	-- 	for _, module in ipairs(modules:GetChildren()) do
-- 	-- 		table.insert(moduleTable, require(module))
-- 	-- 	end

-- 	-- 	unitModules[unit.Name] = moduleTable
-- 	-- end
-- end

local function calculatePlacePosition(baseLink, newUnit, newLink)
	local newPos = newUnit:GetPivot()

	local g1 = baseLink.CFrame * CFrame.Angles(0, math.rad(180), 0)
	local g2 = newPos:ToObjectSpace(newLink.CFrame):Inverse()
	return g1 * g2
end

local function addLink(unit)
	if not unit:IsA("Model") then
		return
	end

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
	if not link:FindFirstChild("LinkedTo") then
		return
	end
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

local function Shuffle(tabl)
	local newTable = table.clone(tabl)

	for i = 1, #newTable - 1 do
		local ran = math.random(i, #newTable)
		newTable[i], newTable[ran] = newTable[ran], newTable[i]
	end

	return newTable
end

local function getAssets()
	stageFolder = serverStorage:FindFirstChild("Stage_" .. module.CurrentStage)
	startUnit = stageFolder:FindFirstChild("Start_" .. module.CurrentStage)
	units = stageFolder.Units
	caps = stageFolder.Caps
	exit = stageFolder.Exit
	kiosk = stageFolder.Kiosk
	sky = stageFolder.Sky
	bossRoom = stageFolder:FindFirstChild("BossRoom_" .. module.CurrentStage)
	miniBossRoom = stageFolder:FindFirstChild("MiniBossRoom_" .. module.CurrentStage)
end

-----------------------------------------// Important Functions //-----------------------------------------

--// Unit functions

local function clearMap()
	if storedMap then
		storedMap:Destroy()
	end

	blacklistedUnits = {}

	for _, unit in ipairs(map:GetChildren()) do
		-- if unit.Name == "Start" or not unit:IsA("Model") then
		-- 	continue
		-- end

		if unit:IsA("Model") then
			removeLink(unit)
		end

		unit:Destroy()
	end

	local skyBox = Lighting:FindFirstChild("Sky")

	if skyBox then
		skyBox:Destroy()
	end

	map:ClearAllChildren()

	for _, Npc in ipairs(collectionService:GetTagged("Npc")) do
		Npc:Destroy()
	end

	for _, weapon in ipairs(collectionService:GetTagged("Weapon")) do
		weapon:Destroy()
	end

	clearBloodEvent:FireAllClients()
	arenas.cancelArenas()
end

local function setLinks(baseLink, unit)
	for _, link in ipairs(unit.Links:GetChildren()) do
		link.Transparency = 1
		link.CanCollide = false
		link.CanQuery = false
		link.CanTouch = false
		link:FindFirstChild("LineHandleAdornment"):Destroy()

		local distance = (link.Position - baseLink.Position).Magnitude
		if distance > 0.1 then
			continue
		end

		baseLink.LinkedTo.Value = link
		link.LinkedTo.Value = baseLink
	end
end

local function placeUnit(baseLink: Part | CFrame, unit, unitLink, forInterior)
	if forInterior then
		local newDoor = replicatedStorage.Assets.Models.Door:Clone()
		newDoor.Parent = map.Interior
		newDoor:PivotTo(baseLink.CFrame)
	end

	local newUnit = unit:Clone()
	local unitPosition = calculatePlacePosition(baseLink, newUnit, unitLink)
	newUnit:PivotTo(unitPosition)
	newUnit.Parent = map

	for _, part in ipairs(newUnit:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.Transparency = 1

		if part.Name ~= "Hitbox" then
			continue
		end
		part.CollisionGroup = "PathfindingHitbox"
	end

	newUnit:AddTag("Unit")

	setLinks(baseLink, newUnit)

	doUnitFunction("OnPlaced", newUnit)

	return newUnit
end

local function placeCap(baseLink)
	local partsTouching = workspace:GetPartsInPart(baseLink)
	for _, part in ipairs(partsTouching) do
		if part.Name ~= "Link" then
			continue
		end

		baseLink.LinkedTo.Value = part
		return
	end

	local getCaps = caps:GetChildren()
	local cap = getCaps[math.random(1, #getCaps)]:Clone()
	cap:AddTag("Cap")
	cap.Parent = baseLink.Parent
	cap:PivotTo(baseLink.CFrame * CFrame.Angles(0, math.rad(180), 0))

	if not cap.PrimaryPart then
		cap.PrimaryPart = cap:FindFirstChild("CapLink", true)
	end

	baseLink.LinkedTo.Value = cap.PrimaryPart
end

local function checkPlacable(baseLink, unit, unitLink)
	local size = unit:GetExtentsSize() - (Vector3.new(1, -1, 1) * leeway)
	local pos = calculatePlacePosition(baseLink, unit, unitLink)

	local hitbox = showHitboxes and showHitbox(pos, size)
	local hitboxResult = workspace:GetPartBoundsInBox(pos, size)

	local canPlace = true
	for _, part in ipairs(hitboxResult) do
		if part.Parent ~= unit and part:FindFirstAncestor(map.Name) then
			canPlace = false

			break
		end
	end

	if hitbox then
		task.wait(0.1)
		hitbox:Destroy()
	end

	return canPlace
end

local function checkUnit(baseLink, unit)
	local getLinks = Shuffle(unit.Links:GetChildren())

	for _, link in ipairs(getLinks) do
		if not checkLink(link) then
			continue
		end
		if checkPlacable(baseLink, unit, link) then
			return unit, link
		end
	end
end

local function addRandomUnit(baseLink, forInterior)
	local unitToPlace
	local placeLink

	local getUnits = Shuffle(units:GetChildren())

	for _, blacklistedUnit in ipairs(blacklistedUnits) do
		local unitIndex = table.find(getUnits, blacklistedUnit)
		if not unitIndex then
			continue
		end
		table.remove(getUnits, unitIndex)
	end

	for _, unit in ipairs(getUnits) do -- if the unit cannot be placed, then loop through units until one can be.
		if unit == unitToPlace then
			return
		end

		unitToPlace, placeLink = checkUnit(baseLink, unit)

		if unitToPlace then
			break
		end
	end

	if unitToPlace then
		if string.match(unitToPlace.Name, "Arena") then
			table.insert(blacklistedUnits, unitToPlace)
		end

		if string.match(unitToPlace.Name, "Ambush") then
			for _, v in ipairs(units:GetChildren()) do
				if string.match(v.Name, "Ambush") then
					table.insert(blacklistedUnits, v)
				end
			end
		end

		return placeUnit(baseLink, unitToPlace, placeLink, forInterior)
		--else
		--placeCap(baseLink)
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

function module.generateUnit(linkList, forInterior)
	for _, link in ipairs(linkList) do
		if not checkLink(link) then
			continue
		end

		local placedUnit = addRandomUnit(link, forInterior)
		if not placedUnit then
			continue
		end

		return placedUnit
	end
end

local function getFurthestCap()
	local furthestDistance, furthestCap = 0, nil

	for _, cap in ipairs(collectionService:GetTagged("Cap")) do
		local distance = (newStart:GetPivot().Position - cap:GetPivot().Position).Magnitude

		if distance <= furthestDistance then
			continue
		end

		furthestDistance = distance
		furthestCap = cap
	end

	return furthestCap, furthestDistance
end

function module.placeExit()
	--loadModules()

	local cap = getFurthestCap()

	if not cap then
		warn("Exit not placed (no caps found)")
		return
	end

	local newExit = exit:Clone()
	newExit.Parent = cap.Parent

	newExit:PivotTo(cap:GetPivot())

	cap:Destroy()

	local r = require(exit.Modules.ExitSequence)
	r.OnPlaced(newExit, module)

	--doUnitFunction("OnPlaced", newExit)
end

function module.placeStartUnit()
	newStart = startUnit:Clone()
	newStart.Parent = map
end

function module.setupMap(ignoreStart)
	clearMap()
	--loadModules()
	getAssets()

	sky:Clone().Parent = Lighting

	for _, v in ipairs(units:GetDescendants()) do
		if not v:IsA("BasePart") then
			continue
		end
		v.CollisionGroup = "Map"
	end

	if ignoreStart then
		return
	end

	module.placeStartUnit()
	doUnitFunction("OnPlaced", newStart)
end

local function placeKiosk()
	local randomLinks = Shuffle(links)

	for _, link in ipairs(randomLinks) do
		local _, placeLink = checkUnit(link, kiosk)
		if not placeLink then
			continue
		end

		return placeUnit(link, kiosk, placeLink)
	end
end

function module.loadMap(size)
	module.setupMap()

	for _ = 1, size do
		module.generateUnit(links)
	end

	placeKiosk()

	placeCaps()
	module.placeExit()

	spawners.spawnEnemies(module.CurrentLevel)
	spawners.spawnWeapons(module.CurrentLevel)

	for _, unit in ipairs(map:GetChildren()) do
		doUnitFunction("OnLoaded", unit)
	end

	module.GeneratedAt = os.clock()
end

function module.loadLinearMap(size)
	module.setupMap()

	local currentUnit = newStart

	for _ = 1, math.ceil(size / 2) do
		if not currentUnit then
			continue
		end
		currentUnit = module.generateUnit(currentUnit.Links:GetChildren())
	end

	for _, unit in ipairs(map:GetChildren()) do
		module.generateUnit(unit.Links:GetChildren())
	end

	placeKiosk()

	placeCaps()

	--repeat
	module.placeExit()
	--task.wait()
	--until map:FindFirstChild("Exit", true)

	local plusStage = (module.CurrentStage - 1) * 5
	local level = plusStage + module.CurrentLevel
	spawners.spawnEnemies(level)
	spawners.spawnWeapons(level)
	spawners.spawnHazards(level)

	if module.CurrentStage == 3 then
		spawners.SpawnMovementPoints()
	end

	for _, unit in ipairs(map:GetChildren()) do
		doUnitFunction("OnLoaded", unit)
	end

	module.GeneratedAt = os.clock()
end

function module.loadInterior(size)
	if map:FindFirstChild("Interior") then
		map.Interior:Destroy()
	end

	local interiorFolder = Instance.new("Folder")
	interiorFolder.Parent = map
	interiorFolder.Name = "Interior"
	interiorFolder:AddTag("Exclude")

	units = stageFolder.Interior

	local currentUnit = Shuffle(units:GetChildren())[1]
	currentUnit = currentUnit:Clone()
	currentUnit.Parent = interiorFolder
	currentUnit:PivotTo(CFrame.new(0, 10000, 0))

	for _, part in ipairs(currentUnit:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.Transparency = 1

		if part.Name ~= "Hitbox" then
			continue
		end
		part.CollisionGroup = "PathfindingHitbox"
	end

	for _ = 1, math.ceil(size) do
		if not currentUnit then
			continue
		end
		currentUnit = module.generateUnit(currentUnit.Links:GetChildren(), true)
		if currentUnit then
			currentUnit.Parent = interiorFolder
		end
	end

	local plusStage = (module.CurrentStage - 1) * 5
	local level = plusStage + module.CurrentLevel
	spawners.spawnEnemies(level, interiorFolder)
	spawners.spawnWeapons(level, interiorFolder)
	spawners.spawnHazards(level, interiorFolder)

	for _, unit in ipairs(interiorFolder:GetChildren()) do
		doUnitFunction("OnLoaded", unit)
	end

	module.GeneratedAt = os.clock()
end

function module.loadBossRoom()
	module.setupMap(true)

	local newRoom

	if module.CurrentLevel > 5.25 then
		newRoom = bossRoom:Clone()
	else
		newRoom = miniBossRoom:Clone()
	end

	newRoom.Parent = map

	doUnitFunction("OnPlaced", newRoom)

	task.spawn(function()
		while newRoom.Parent do
			local plusStage = (module.CurrentStage - 1) * 5
			local level = plusStage + module.CurrentLevel

			spawners.spawnWeapons(level)
			task.wait(10)
		end
	end)
end

local function spawnBoss(_, type)
	spawners.SpawnBoss(stageFolder:GetAttribute(type), map:FindFirstChildOfClass("Model"))
	workspace:SetAttribute("LastBoss", stageFolder:GetAttribute(type))
end

-------------------------------------------------------------------

map.ChildAdded:Connect(addLink)
map.ChildRemoved:Connect(removeLink)

--module.loadLinearMap(module.CurrentLevel * 5)
--module.loadLinearMap(module.CurrentLevel * 5)

signals["GenerateMap"]:Connect(function(Style, Size)
	if not Style or not Size or not tonumber(Size) then
		return
	end
	if Style == "Linear" then
		module.loadLinearMap(Size)
	else
		module.loadMap(Size)
	end
end)

local function createStoredMap()
	if storedMap then
		storedMap:Destroy()
	end

	local newStoredMap = workspace.Map:Clone() :: Model
	newStoredMap.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	newStoredMap.Parent = replicatedStorage
	return newStoredMap
end

function module.proceedToNext(_, onlyLoadMap)
	local hasCheese = false
	for _, player in ipairs(Players:GetPlayers()) do -- Teleport players to spawn
		if player:GetAttribute("UpgradeName") == "Aged Cheese" then
			hasCheese = true
		end

		local character = player.Character
		if not character then
			continue
		end

		local spawnLocation = workspace:FindFirstChild("SpawnLocation")

		if not spawnLocation then
			return
		end
		character:PivotTo(spawnLocation.CFrame * CFrame.new(0, 3, 0))

		character.Humanoid.Health = character.Humanoid.MaxHealth
	end

	if not onlyLoadMap then
		if module.CurrentLevel == 5 or module.CurrentLevel == (hasCheese and 5.25 or 2) then
			module.CurrentLevel += (hasCheese and 0.25 or 0.5)
		else
			module.CurrentLevel = math.floor(module.CurrentLevel + 1)
		end

		if module.CurrentLevel > 5.5 then -- amount of levels in a stage
			module.CurrentLevel = 1
			module.CurrentStage += 1
		end

		if module.CurrentStage == 0 then
			module.CurrentStage = workspace:GetAttribute("SaveStage") or 1
			module.CurrentLevel = 1
		elseif module.CurrentLevel == 1 then
			workspace:SetAttribute("SaveStage", module.CurrentStage)
			module.CurrentStage = 0
			module.CurrentLevel = 1
		end
	end

	if module.CurrentStage == 5 then
		module.CurrentStage = 1
	end

	workspace:SetAttribute("Level", module.CurrentLevel)
	workspace:SetAttribute("Stage", module.CurrentStage)
	workspace:SetAttribute("TotalLevel", ((module.CurrentStage - 1) * 5) + module.CurrentLevel)

	if module.CurrentStage == 3 then
		Lighting.Atmosphere.Density = 0.45
	else
		Lighting.Atmosphere.Density = 0.55
	end

	if math.floor(module.CurrentLevel) ~= module.CurrentLevel then
		module.loadBossRoom()
		storedMap = createStoredMap()
		return
	end

	local mapSize = math.clamp(module.CurrentLevel * 4, 5, 25)

	if module.CurrentStage == 3 then
		mapSize /= 2
	end

	if module.CurrentStage == 0 then
		net:RemoteEvent("DoUiAction"):FireAllClients("HUD", "ShowRCoins")
	end

	module.loadLinearMap(mapSize)
	storedMap = createStoredMap()
end

signals["ProceedToNextLevel"]:Connect(module.proceedToNext)

net:Connect("ProceedToNextLevel", module.proceedToNext)
net:Connect("SpawnBoss", spawnBoss)

function module.bossExit()
	local room = map:FindFirstChild("BossRoom_" .. module.CurrentStage)
	local exitSequence = room.Modules:FindFirstChild("BossExitSequence")

	local exitModule = require(exitSequence)

	exitModule.ExitSequence(room, module)
end

function module.exitMiniBoss()
	local room = map:FindFirstChild("MiniBossRoom_" .. module.CurrentStage)
	local exitSequence = room.Modules:FindFirstChild("MinibossExitSequence")

	local exitModule = require(exitSequence)

	exitModule.ExitSequence(room, module)
end

local function detectHit(part: BasePart)
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	return humanoid, model
end

local lastTimeReset = os.clock()

RunService.Heartbeat:Connect(function()
	if workspace:GetAttribute("GamePaused") then
		return
	end

	if os.clock() - lastTimeReset >= 0.5 then
		lastTimeReset = os.clock()
	else
		return
	end

	for _, damagePart in ipairs(collectionService:GetTagged("DamagePart")) do
		if not damagePart:FindFirstAncestor("Workspace") then
			continue
		end

		local detect = workspace:GetPartBoundsInBox(damagePart.CFrame, damagePart.Size + Vector3.new(1, 1, 1))

		local hit = {}

		for _, part in ipairs(detect) do
			local humanoid, model = detectHit(part)

			if model and model.Name == "Visage Of False Hope" then
				continue
			end

			if table.find(hit, humanoid) then
				continue
			end

			if not humanoid then
				continue
			end
			table.insert(hit, humanoid)
			humanoid:TakeDamage(1)
		end
	end
end)

net:Connect("BossExit", module.bossExit)
net:Connect("MiniBossExit", module.exitMiniBoss)

return module
