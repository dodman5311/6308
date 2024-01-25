local modules = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Globals = require(ReplicatedStorage.Shared.Globals)
local Promise = require(Globals.Packages.Promise)
local signals = require(Globals.Signals)

local player = Players.LocalPlayer

local allSignals = {
	"DoUiAction",
	"DoWeaponAction",
	"AddSoul",
	"RemoveSoul",
	"AddGift",
	"AddAmmo",
}

for _, signal in ipairs(allSignals) do
	signals:addSignal(signal)
end

local function connectOnSpawn(mod, character)
	local humanoid = character:WaitForChild("Humanoid")

	if mod["OnSpawn"] then
		mod:OnSpawn(character, humanoid)
	end

	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		if not mod["OnDied"] then
			return
		end
		mod:OnDied(character)
	end)
end

local function InitModules()
	local inits = {}

	for _, module in script:GetDescendants() do
		if not module:IsA("ModuleScript") then
			continue
		end

		table.insert(
			inits,
			Promise.try(function()
				return require(module)
			end)
				:andThen(function(mod)
					if typeof(mod) ~= "table" then
						return
					end

					if mod.GameInit then
						mod:GameInit()
					end

					if player.Character then
						connectOnSpawn(mod, player.Character)
					end

					player.CharacterAdded:Connect(function(character)
						connectOnSpawn(mod, character)
					end)

					table.insert(modules, mod)
				end)
				:catch(function(e)
					warn(module.Name .. " Failed to load")
					warn(e)
				end)
		)
	end

	return Promise.allSettled(inits)
end

local function StartModules()
	local starts = {}

	for _, mod in modules do
		if mod.GameStart then
			table.insert(
				starts,
				Promise.try(function()
					mod:GameStart()
				end):catch(warn)
			)
		end
	end

	return Promise.allSettled(starts)
end

Promise.try(InitModules):andThenCall(StartModules):catch(warn)
