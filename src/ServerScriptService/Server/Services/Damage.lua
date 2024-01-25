local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)

local function findHumanoid(subject)
	local model = subject

	if not subject:IsA("Model") then
		model = subject:FindFirstAncestorOfClass("Model")
	end

	if not model then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	return humanoid
end

function module.dealDamage(_, subject, amount)
	if not subject then
		return
	end

	local humanoid = findHumanoid(subject)

	if not humanoid then
		return
	end

	local preHealth = humanoid.Health
	humanoid:TakeDamage(amount)

	if preHealth > 0 and humanoid.Health <= 0 then -- kill awarded
		net:RemoteEvent("DropSoul"):FireAllClients(subject:GetPivot().Position, math.clamp(humanoid.MaxHealth, 1, 7.5))
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
