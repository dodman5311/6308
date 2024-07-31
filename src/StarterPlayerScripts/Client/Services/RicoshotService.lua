local module = {
	MaxDistance = 1000,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Assets = ReplicatedStorage.Assets

--// Modules
local Signals = require(Globals.Shared.Signals)
local net = require(Globals.Packages.Net)
local UiAnimationService = require(Globals.Vendor.UIAnimationService)
local GiftsService = require(Globals.Client.Services.GiftsService)

--// Values

--// Functions

function module.checkRicoshot(raycast)
	if not raycast then
		return
	end

	local instance = raycast.Instance
	local model = instance:FindFirstAncestorOfClass("Model")

	if not model or not model:HasTag("ThrownWeapon") then
		return
	end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }

	local groundCast = workspace:Raycast(raycast.Position, Vector3.new(0, -3, 0), rp)
	if groundCast then
		return
	end

	return model
end

local function checkBetweenCast(position, endPosition)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }

	return workspace:Raycast(position, endPosition - position, rp)
end

local function createEffect(position, endPosition)
	local distance = (position - endPosition).Magnitude

	local partClone = Assets.Effects.RicoPart:Clone()
	partClone.Parent = workspace.Ignore
	partClone.CFrame = CFrame.lookAt(position, endPosition)
	partClone.Hit.Position = Vector3.new(0, 0, -distance)
	partClone.Beam.Enabled = true

	task.spawn(function()
		for i = 0.5, 1, 0.05 do
			task.wait(0.05)
			partClone.Beam.Transparency = NumberSequence.new(i)
		end
		partClone:Destroy()
	end)
end

local function getNearestEnemy(position, position2)
	local closestDistance, closestEnemy = math.huge

	local list = {}

	for _, model in ipairs(CollectionService:GetTagged("Enemy")) do
		table.insert(list, model)
	end

	for _, model in ipairs(CollectionService:GetTagged("ThrownWeapon")) do
		table.insert(list, model)
	end

	for _, enemy in ipairs(list) do
		if enemy:GetAttribute("RicoHit") then
			continue
		end

		if not enemy:HasTag("ThrownWeapon") and (enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health <= 0) then
			continue
		end

		local endPosition = enemy:GetPivot().Position
		local distance = (position - endPosition).Magnitude

		if distance > module.MaxDistance then
			continue
		end

		local blocked = checkBetweenCast(position2, endPosition)

		if blocked then
			continue
		end

		if enemy:HasTag("ThrownWeapon") then
			return enemy
		end

		if distance < closestDistance then
			closestDistance = distance
			closestEnemy = enemy
		end
	end

	return closestEnemy
end

function module.doRicoshot(weapon, character)
	local weaponPosition = weapon.Grip.Position
	local characterPosition = character:GetPivot().Position

	weapon:SetAttribute("RicoHit", true)

	local ricoHitbox = weapon.RicoHitbox

	UiAnimationService.PlayAnimation(ricoHitbox.Ui.Shoot, 0.045)
	ricoHitbox.Ui.Shoot.Image.ImageColor3 = Color3.new(1)
		:Lerp(Color3.fromRGB(255, 235, 185), weapon:GetAttribute("Health") / 5)

	local result = getNearestEnemy(characterPosition, weaponPosition)

	if not result then
		return
	else
		result:SetAttribute("RicoHit", true)
		task.delay(0.05, function()
			result:SetAttribute("RicoHit", false)
		end)
	end

	local target = result:FindFirstChild("Weakspot") or result.PrimaryPart or result:FindFirstChildOfClass("BasePart")

	if not target then
		return
	end

	local endPosition = target:GetPivot().Position

	createEffect(weaponPosition, endPosition)

	return {
		Instance = target,
		Position = target:GetPivot().Position,
	}
end

--// Main //--

return module
