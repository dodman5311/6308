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
	humanoid:TakeDamage(amount)

	return humanoid, amount
end

net:Handle("Damage", module.dealDamage)

return module
