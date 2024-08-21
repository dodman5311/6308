local module = {
	CurrentStage = 1,
	CurrentLevel = 1,
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
local net = require(Globals.Packages.Net)
local arenas = require(Globals.Services.HandleArenas)

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

local function placeUnit(baseLink, unit, unitLink)
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

local function addRandomUnit(baseLink)
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

		return placeUnit(baseLink, unitToPlace, placeLink)
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

function module.generateUnit(linkList)
	for _, link in ipairs(linkList) do
		if not checkLink(link) then
			continue
		end

		local placedUnit = addRandomUnit(link)
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

	module.placeExit()

	local plusStage = (module.CurrentStage - 1) * 5
	local level = plusStage + module.CurrentLevel
	spawners.spawnEnemies(level)
	spawners.spawnWeapons(level)
	spawners.spawnHazards(level)

	for _, unit in ipairs(map:GetChildren()) do
		doUnitFunction("OnLoaded", unit)
	end

	module.GeneratedAt = os.clock()
end

function module.loadBossRoom()
	module.setupMap(true)

	local newRoom

	if module.CurrentLevel > 5 then
		newRoom = bossRoom:Clone()
	else
		newRoom = miniBossRoom:Clone()
	end

	newRoom.Parent = map

	doUnitFunction("OnPlaced", newRoom)

	while newRoom.Parent do
		local plusStage = (module.CurrentStage - 1) * 5
		local level = plusStage + module.CurrentLevel

		spawners.spawnWeapons(level)
		task.wait(10)
	end
end

local function spawnBoss(_, type)
	spawners.SpawnBoss(stageFolder:GetAttribute(type), map:FindFirstChildOfClass("Model"))
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

function module.proceedToNext(sender)
	for _, player in ipairs(Players:GetPlayers()) do -- Teleport players to spawn
		local character = player.Character
		if not character then
			return
		end

		local spawnLocation = workspace:FindFirstChild("SpawnLocation")

		if not spawnLocation then
			return
		end
		character:PivotTo(spawnLocation.CFrame * CFrame.new(0, 3, 0))

		character.Humanoid.Health = character.Humanoid.MaxHealth
	end

	if module.CurrentLevel == 5 or module.CurrentLevel == 2 then
		module.CurrentLevel += 0.5
	else
		module.CurrentLevel = math.floor(module.CurrentLevel + 1)
	end

	if module.CurrentLevel > 5.5 then
		module.CurrentLevel = 1
		module.CurrentStage += 1
	end

	workspace:SetAttribute("Level", module.CurrentLevel)
	workspace:SetAttribute("Stage", module.CurrentStage)

	if math.floor(module.CurrentLevel) ~= module.CurrentLevel then
		module.loadBossRoom()
		return
	end
	module.loadLinearMap(math.clamp(module.CurrentLevel * 4, 5, 25))
	--module.loadLinearMap(0)

	if not sender then
		return
	end
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

net:Connect("BossExit", module.bossExit)
net:Connect("MiniBossExit", module.exitMiniBoss)

local function detectHit(part: BasePart)
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	return humanoid
end

local lastTimeReset = os.clock()

RunService.Heartbeat:Connect(function()
	if os.clock() - lastTimeReset >= 0.25 or workspace:GetAttribute("GamePaused") then
		lastTimeReset = os.clock()
	else
		return
	end

	for _, damagePart in ipairs(collectionService:GetTagged("DamagePart")) do
		local detect = workspace:GetPartBoundsInBox(damagePart.CFrame, damagePart.Size + Vector3.new(1, 1, 1))

		local hit = {}

		for _, part in ipairs(detect) do
			local humanoid = detectHit(part)

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

return module
