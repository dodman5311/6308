local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)
local elementService = require(Globals.Services.ElementalService)

local function findHumanoid(subject)
	local model = subject

	if not subject:IsA("Model") then
		model = subject:FindFirstAncestorOfClass("Model")
	end

	if not model then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	return humanoid, model
end

function module.dealDamage(_, subject, amount, element)
	if not subject then
		return
	end

	local humanoid
	if subject:IsA("Humanoid") then
		humanoid = subject
		subject = humanoid:FindFirstAncestorOfClass("Model")
	else
		humanoid, subject = findHumanoid(subject)
	end

	if not humanoid or humanoid.Health <= 0 or humanoid:GetAttribute("Invincible") then
		return
	end

	elementService.applyElement(_, subject, element)

	local preHealth = humanoid.Health

	if subject:GetAttribute("Soul") or subject:GetAttribute("SoulFire") then
		amount += 1
	end

	local fHealth = humanoid.Health - amount

	if fHealth <= humanoid.MaxHealth then
		humanoid:TakeDamage(amount)
	end

	if
		not humanoid:HasTag("Souless")
		and preHealth > 0
		and humanoid.Health <= 0
		and not subject:GetAttribute("Soul")
	then -- kill awarded
		local fireChance = subject:GetAttribute("Fire") and 35 or 0

		if fireChance > 0 then
			local explosionPosition = subject:GetPivot().Position

			net:RemoteEvent("CreateExplosion")
				:FireAllClients(explosionPosition, 25, 3, Players:FindFirstChildOfClass("Player"), nil, "Elemental")
		end

		if subject:GetAttribute("Electricity") then
			local explosionPosition = subject:GetPivot().Position

			net:RemoteEvent("CreateExplosion"):FireAllClients(
				explosionPosition,
				30,
				1,
				Players:FindFirstChildOfClass("Player"),
				nil,
				"Elemental",
				"Electricity",
				15
			)
		end

		if subject:GetAttribute("Ice") then
			net:RemoteEvent("DropArmor"):FireAllClients(subject:GetPivot().Position, 25)
		end

		net:RemoteEvent("DropSoul"):FireAllClients(subject:GetPivot().Position, humanoid.MaxHealth / 2.5 + fireChance)
	end

	return humanoid, preHealth, humanoid.Health
end

function module.dealDamageToSubject(subject, damage)
	local humanoid = findHumanoid(subject)
	if not humanoid or humanoid:GetAttribute("Invincible") then
		return
	end

	humanoid:TakeDamage(damage)
	return { Health = humanoid.Health, Humanoid = humanoid, Damage = damage, Model = humanoid.Parent }
end

net:Handle("Damage", module.dealDamage)
net:Connect("Damage", module.dealDamage)

return module
