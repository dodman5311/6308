local module = {}

--// Services
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Scales = require(ReplicatedStorage.Vendor.Scales)
local Timer = require(ReplicatedStorage.Vendor.Timer)

--// Modules
local dataStore = require(script.Parent.DataStore)
local mapService = require(Globals.Services.MapService)
local net = require(Globals.Packages.Net)
local signals = require(Globals.Signals)
local spawners = require(Globals.Services.Spawners)
local upgrades = require(Globals.Shared.Upgrades)

local getBlockedNerd = net:RemoteEvent("GetBlockedNerd")
net:RemoteEvent("CreateShield")

--// Values

local invincibilityScale = Scales.new("Invincibility")

local checkProtectedEvent = net:RemoteEvent("CheckProtected")
net:RemoteEvent("OnPlayerDied")

local function addInvincibility(plr, index: string, expireTime: number)
	invincibilityScale:Add(index)
	local iTimer = Timer:new(index, expireTime, function()
		invincibilityScale:Remove(index)
	end)

	iTimer:Reset()
	iTimer:Run()
end

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

invincibilityScale.Changed:Connect(function(enabled)
	setInvincible(Players:GetPlayers()[1], enabled)
end)

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

		local logHealth = humanoid.Health

		humanoid.HealthChanged:Connect(function(health)
			local change = health - logHealth

			local resistance = 1 + humanoid:GetAttribute("Resistance")
			local armor = humanoid:GetAttribute("Armor")

			if health < logHealth then
				if humanoid:GetAttribute("IsBlocking") then
					humanoid.Health = logHealth
					getBlockedNerd:FireClient(player)
				end

				if humanoid:GetAttribute("Invincible") then
					humanoid.Health = logHealth
				end

				if armor > 0 then
					humanoid.Health = logHealth

					if not humanoid:GetAttribute("IsBlocking") then
						local newArmorAmnt = armor + (change / resistance)
						humanoid:SetAttribute("Armor", math.floor(newArmorAmnt * 100000) / 100000)
					end
				end

				-- elseif character:GetAttribute("HasHaven") then
				-- 	setInvincible(player, true)
				-- 	task.delay(1, function()
				-- 		setInvincible(player, false)
				-- 	end)
				-- end
			end

			logHealth = humanoid.Health

			if humanoid.Health > 0 then
				return
			end

			if character:GetAttribute("Protected") then
				humanoid.Health = humanoid.MaxHealth
				checkProtectedEvent:FireClient(player)

				setInvincible(player, true)
				task.delay(1, function()
					setInvincible(player, false)
				end)
			else
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			end
		end)
	end)

	print("Save data loaded in", dataStore.LoadGameData(player))
	player:LoadCharacterAsync()
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

	local toReq = false

	workspace:SetAttribute("LogDeathCount", workspace:GetAttribute("DeathCount"))
	workspace:SetAttribute("LogTotalScore", workspace:GetAttribute("TotalScore"))

	if workspace:GetAttribute("TotalScore") >= (workspace:GetAttribute("DeathCount") + 1) * 400 then -- req check
		toReq = true
		mapService.CurrentLevel = math.floor(mapService.CurrentLevel)
		workspace:SetAttribute("DeathCount", workspace:GetAttribute("DeathCount") + 1)
		workspace:SetAttribute("IsInReq", true)

		--dataStore.saveGameState(player, dataStore.stageState)
	else
		mapService.CurrentStage = 1
		mapService.CurrentLevel = 1
		workspace:SetAttribute("SaveStage", 1)

		workspace:SetAttribute("TotalScore", 0)
		workspace:SetAttribute("StoredScore", math.ceil(workspace:GetAttribute("StoredScore") / 2))
		workspace:SetAttribute("DeathCount", 0)

		for _, category in pairs(upgrades) do
			for upgradeName, _ in pairs(category) do
				workspace:SetAttribute(upgradeName, 0)
			end
		end

		dataStore.saveGameState(player, { Level = 1 })
		dataStore.SaveData(player, "ShopUpgrades", {})
	end

	dataStore.SaveData(player, "PlayerDeathCount", workspace:GetAttribute("DeathCount"))

	player.CharacterAdded:Once(function()
		task.wait()
		signals["ProceedToNextLevel"]:Fire(nil, true, toReq)
	end)

	for _, enemy in ipairs(collectionService:GetTagged("Enemy")) do
		enemy:Destroy()
	end

	local character = player.Character
	local spawnLocation = workspace:WaitForChild("SpawnLocation")

	if spawnLocation then
		character:PivotTo(spawnLocation:GetPivot() * CFrame.new(0, 3, 0))
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

local function addArmor(player, amount)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	humanoid:SetAttribute("Armor", humanoid:GetAttribute("Armor") + amount)
end

net:Connect("CheckProtected", checkProtected)
net:Connect("SetBlocking", setBlocking)
net:Connect("SetInvincible", addInvincibility)
net:Connect("OnPlayerDied", onDied)
net:Connect("SetArmor", setArmor)
net:Connect("AddArmor", addArmor)

net:Connect("GiftAdded", function(player, gift)
	if gift == "Haven" then
		player.Character:SetAttribute("HasHaven", true)
	end

	local humanoid = player.Character:WaitForChild("Humanoid")
	local resistance = humanoid:GetAttribute("Resistance")

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
	--workspace:SetAttribute("StoredScore", 0)
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

return module
