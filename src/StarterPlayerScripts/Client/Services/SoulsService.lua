local module = {
	Souls = 0,
	MaxDistance = 15,
	DropChance = 25,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local Signals = require(Globals.Shared.Signals)
local dropService = require(Globals.Shared.DropService)
local net = require(Globals.Packages.Net)

--// Values
local rng = Random.new()

--// Functions

function module.CalculateDropChance(chanceModifier)
	chanceModifier = chanceModifier or 1

	local soulReduction = (module.Souls + 1) * 1.25
	local chance = (module.DropChance / soulReduction) * chanceModifier
	chance = math.clamp(chance, 0, 90)

	return chance
end

function module.DropSoul(position, chanceModifier)
	chanceModifier = chanceModifier or 1

	local chance = module.CalculateDropChance(chanceModifier)
	if chance < rng:NextNumber(0, 100) then
		return
	end

	dropService.CreateDrop(position, "Soul").Sound:Play()
end

local function checkProtected()
	net:RemoteEvent("CheckProtected"):FireServer(module.Souls)
end

function module.AddSoul(amount)
	module.Souls += math.round(amount)
	Signals.DoUiAction:Fire("HUD", "UpdateSouls", true, module.Souls)

	checkProtected()
end

function module.RemoveSoul(amount)
	if module.Souls <= 0 then
		return
	end

	module.Souls -= math.round(amount)
	Signals.DoUiAction:Fire("HUD", "UpdateSouls", true, module.Souls)

	checkProtected()
end

--// Main //--

Signals.AddSoul:Connect(module.AddSoul)
Signals.RemoveSoul:Connect(module.RemoveSoul)

net:Connect("DropSoul", module.DropSoul)

net:Connect("CheckProtected", function()
	Signals.RemoveSoul:Fire(1)
end)

return module
