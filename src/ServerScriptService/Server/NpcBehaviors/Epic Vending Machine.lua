local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local Spawners = require(Globals.Server.Services.Spawners)
local net = require(Globals.Packages.Net)
local actions = require(Globals.Server.NpcActions)
local checkChance = net:RemoteFunction("CheckChance")
local vfx = net:RemoteEvent("ReplicateEffect")

local elements = {
	"Electricity",
	"Fire",
	"Ice",
	"Soul",
}

local stats = {
	SpecialChance = 50,
	OtherStageWeaponChance = 100,
	AmmoChance = 75,
	MaxAmmoBoost = 100,
	ElementalChance = 50,
	Armor = 4,
}

local function explode(npc)
	local model = npc.Instance

	for _, v in ipairs(npc.Instance:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = 1
		end

		if v:IsA("Decal") then
			v:Destroy()
		end
	end

	local explosionPosition = model:GetPivot().Position

	net:RemoteEvent("CreateExplosion"):FireAllClients(explosionPosition, 20, 4, Players:FindFirstChildOfClass("Player"))
end

local function GiveObjects(npc)
	local character = actions.SearchForTarget(npc, math.huge)
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)

	local origin = npc.Instance:GetPivot() * CFrame.new(0, 0, -2.5)
	local goal: CFrame = origin * CFrame.new(0, -2, -5)

	local SpawnedWeapon: Model
	local totalLevel = workspace:GetAttribute("TotalLevel")

	if checkChance:InvokeClient(player, stats.OtherStageWeaponChance, true) then
		SpawnedWeapon = Spawners.placeNewObject(100, origin, "Weapon", nil, true)
	else
		SpawnedWeapon = Spawners.placeNewObject(totalLevel, origin, "Weapon", nil, true)
	end

	local ti = TweenInfo.new(0.65, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	local startTime = os.clock()

	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not SpawnedWeapon.Parent then
			connection:Disconnect()
			return
		end

		local currentTime = os.clock() - startTime
		local alpha = currentTime / ti.Time

		local lGoal = origin:Lerp(goal, alpha)

		local bouceAlpha = math.abs(TweenService:GetValue(alpha, ti.EasingStyle, ti.EasingDirection) - 1)

		lGoal *= CFrame.new(0, bouceAlpha * 3, 0)

		SpawnedWeapon:PivotTo(lGoal)

		if currentTime >= ti.Time then
			connection:Disconnect()
		end
	end)

	if checkChance:InvokeClient(player, stats.AmmoChance, true) then
		local ammoAdded = math.random(5, stats.MaxAmmoBoost)
		SpawnedWeapon:SetAttribute("ExtraAmmo", ammoAdded)

		local pickupUi = SpawnedWeapon:FindFirstChild("PickupUi")

		if pickupUi then
			pickupUi.ExtraAmmo.Visible = true
		end
	end

	local clientModel = ReplicatedStorage.Assets.Models.Weapons:FindFirstChild(SpawnedWeapon.Name)
	local weaponData = require(clientModel.Data)

	if not weaponData.Element and checkChance:InvokeClient(player, stats.ElementalChance, true) then
		local element = elements[math.random(1, #elements)]

		SpawnedWeapon:SetAttribute("Element", element)
		vfx:FireAllClients("AddElementalEffect", "Server", true, element, SpawnedWeapon)
	end

	for _ = 1, math.random(0, stats.Armor) do
		net:RemoteEvent("DropArmor"):FireAllClients(goal.Position)
	end
end

local function onSpawned(npc)
	task.delay(0.75, function()
		if not npc.Instance["PrimaryPart"] then
			return
		end
		npc.Instance.PrimaryPart.Anchored = true
	end)
end

local module = {
	OnDamaged = {
		{ Function = "Custom", Parameters = { GiveObjects } },
	},

	OnSpawned = {
		{ Function = "AddTag", Parameters = { "Hazard" } },
		{ Function = "AddTag", Parameters = { "VendingMachine" } },
		{ Function = "Custom", Parameters = { onSpawned } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { explode } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 0.1 } },
	},
}

return module
