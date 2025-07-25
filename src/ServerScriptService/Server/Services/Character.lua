local module = {
	Anchovies = 0,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local signals = require(Globals.Signals)
local mapService = require(Globals.Services.MapService)
local net = require(Globals.Packages.Net)
local dataStore = require(script.Parent.DataStore)

local getBlockedNerd = net:RemoteEvent("GetBlockedNerd")
net:RemoteEvent("CreateShield")

--// Values

local checkProtectedEvent = net:RemoteEvent("CheckProtected")
net:RemoteEvent("OnPlayerDied")

local function checkProtected(player, souls, ironWill)
	local character = player.Character
	if not character then
		return
	end

	character:SetAttribute("Protected", souls > 0 or ironWill)
end

local function setBlocking(player, value)
	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:SetAttribute("IsBlocking", value)
end

local function setInvincible(player, value)
	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:SetAttribute("Invincible", value)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character)
		AnalyticsService:LogProgressionStartEvent(
			player,
			"Campaign",
			workspace:GetAttribute("Level"),
			tostring(workspace:GetAttribute("Stage"))
		)

		local humanoid: Humanoid = character:WaitForChild("Humanoid")
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

		humanoid.MaxHealth = player:GetAttribute("MaxHealth")
		humanoid.Health = player:GetAttribute("MaxHealth")

		for _, part in ipairs(character:GetDescendants()) do
			if not part:IsA("BasePart") then
				continue
			end

			part.CollisionGroup = "Player"
		end

		humanoid:SetAttribute("LogHealth", humanoid.Health)

		humanoid.HealthChanged:Connect(function(health)
			local LogHealth = humanoid:GetAttribute("LogHealth")

			if health < LogHealth then
				if humanoid:GetAttribute("IsBlocking") then
					humanoid.Health = LogHealth
					getBlockedNerd:FireClient(player)
				end

				if humanoid:GetAttribute("Invincible") then
					humanoid.Health = LogHealth
				elseif character:GetAttribute("HasHaven") then
					setInvincible(player, true)
					task.delay(1, function()
						setInvincible(player, false)
					end)
				end
			end

			humanoid:SetAttribute("LogHealth", humanoid.Health)

			if humanoid.Health > 0 then
				return
			end

			if character:GetAttribute("Protected") then
				humanoid.Health = humanoid.MaxHealth
				checkProtectedEvent:FireClient(player)
			else
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			end
		end)

		if mapService.CurrentLevel == math.round(mapService.CurrentLevel) then
			module.Anchovies = 4
		end
	end)

	print("Save data loaded in", dataStore.LoadGameData(player))
	player:LoadCharacter()
end)

local function onDied(player: Player)
	local closestDistance, closestEnemy = math.huge, nil
	for _, enemy in ipairs(collectionService:GetTagged("Enemy")) do
		local distance = (player.Character:GetPivot().Position - enemy:GetPivot().Position).Magnitude

		if distance < closestDistance then
			closestEnemy = enemy
		end
	end

	AnalyticsService:LogProgressionFailEvent(
		player,
		"Campaign",
		workspace:GetAttribute("Level"),
		tostring(workspace:GetAttribute("Stage"))
	)

	if closestEnemy then
		AnalyticsService:LogProgressionEvent(
			player,
			"DiedNearEnemy",
			Enum.AnalyticsProgressionType.Custom,
			closestDistance,
			closestEnemy.Name
		)
	end

	--if mapService.CurrentLevel == math.round(mapService.CurrentLevel) then
	print(mapService.CurrentStage)

	workspace:SetAttribute("SaveStage", dataStore.stageState.Stage or 1)

	print((workspace:GetAttribute("DeathCount") + 1) * 200, workspace:GetAttribute("TotalScore"))
	if workspace:GetAttribute("TotalScore") > (workspace:GetAttribute("DeathCount") + 1) * 200 then -- req check
		mapService.CurrentStage = 0
		workspace:SetAttribute("DeathCount", workspace:GetAttribute("DeathCount") + 1)

		dataStore.saveGameState(player, dataStore.stageState)
	else
		mapService.CurrentStage = 1
		workspace:SetAttribute("TotalScore", 0)
		workspace:SetAttribute("DeathCount", 0)

		dataStore.saveGameState(player, {})
	end

	mapService.CurrentLevel = 1

	dataStore.SaveData(player, "PlayerDeathCount", workspace:GetAttribute("DeathCount"))

	local character = player.Character
	local spawnLocation = workspace:FindFirstChild("SpawnLocation")

	if spawnLocation then
		character:PivotTo(spawnLocation.CFrame * CFrame.new(0, 3, 0))
	end

	player.CharacterAdded:Once(function()
		signals["ProceedToNextLevel"]:Fire(nil, true)
	end)

	--end

	for _, enemy in ipairs(collectionService:GetTagged("Enemy")) do
		enemy:Destroy()
	end
end

local function setArmor(player, amount)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	humanoid:SetAttribute("Armor", amount)
end

net:Connect("CheckProtected", checkProtected)
net:Connect("SetBlocking", setBlocking)
net:Connect("SetInvincible", setInvincible)
net:Connect("OnPlayerDied", onDied)
net:Connect("SetArmor", setArmor)

net:Connect("GiftAdded", function(player, gift)
	if gift == "Haven" then
		player.Character:SetAttribute("HasHaven", true)
	end

	local resistance = 0

	local humanoid = player.Character:WaitForChild("Humanoid")

	if gift == "Tough_Shell" then
		resistance += 1
	end

	if gift == "Unearthly_Metal" then
		resistance += 2
	end

	humanoid:SetAttribute("Resistance", resistance)
end)

net:Connect("GiftRemoved", function(player, gift)
	if gift == "Haven" then
		player.Character:SetAttribute("HasHaven", false)
	end

	local humanoid = player.Character:WaitForChild("Humanoid")

	local resistance = humanoid:GetAttribute("Resistance")

	if gift == "Tough_Shell" then
		resistance -= 1
	end

	if gift == "Unearthly_Metal" then
		resistance -= 2
	end

	humanoid:SetAttribute("Resistance", resistance)
end)

net:Connect("UpdatePlayerHealth", function(player, maxHealth, health, protected)
	local humanoid = player.Character.Humanoid

	if protected ~= nil then
		player.Character:SetAttribute("Protected", protected)
	end

	if health then
		player.Character.Humanoid.Health = health
	end

	if maxHealth then
		humanoid.MaxHealth = maxHealth

		humanoid.Health = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
	end
end)

net:Connect("Restart", function(player)
	local humanoid = player.Character.Humanoid

	workspace:SetAttribute("TotalScore", 0)
	humanoid:SetAttribute("Armor", 0)
	humanoid.Health = 0
end)

net:Connect("CreateShield", function(player)
	local character = player.Character
	if not character then
		return
	end

	if character:FindFirstChild("PlayerShield") then
		character.PlayerShield:Destroy()
	end

	local newShield = ReplicatedStorage.Assets.Models.PlayerShield:Clone()
	newShield.PrimaryPart.AlignPosition.Attachment0 = character.PrimaryPart.RootAttachment
	newShield.Parent = character

	require(newShield.RemoveShield).OnSpawned()
end)

signals.ActivateUpgrade:Connect(function(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.MaxHealth = player:GetAttribute("MaxHealth")
	humanoid.Health = player:GetAttribute("MaxHealth")
end)

return module
