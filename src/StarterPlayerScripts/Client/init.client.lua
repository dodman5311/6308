local modules = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Globals = require(ReplicatedStorage.Shared.Globals)
local Promise = require(Globals.Packages.Promise)
local signals = require(Globals.Signals)
local net = require(Globals.Packages.Net)

local player = Players.LocalPlayer

local allSignals = { 
	"DoWeaponAction",
	"AddSoul",
	"RemoveSoul",
	"AddGift",
	"ClearGifts",
	"AddAmmo",
	"PauseGame",
	"ResumeGame",
	"AddTicket",
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

local function InitModules(...)
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
				:andThen(function(mod, ...)
					if typeof(mod) ~= "table" then
						return
					end

					if mod.GameInit then
						mod:GameInit(...)
					end

					table.insert(modules, mod)
				end)
				:catch(function(e)
					warn(module.Name .. " Failed to load")
					warn(e)
				end)
		)
	end

	if player.Character then
		for _, v in ipairs(modules) do
			connectOnSpawn(v, player.Character)
		end
	end

	player.CharacterAdded:Connect(function(character)
		for _, v in ipairs(modules) do
			connectOnSpawn(v, character)
		end
	end)

	signals.LoadSavedDataFromClient:Fire(...)

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

net:Connect("LoadData", function(...)
	while not player:GetAttribute("AssetsLoaded") do
		task.wait()
	end

	player:SetAttribute("DataLoaded", true)
	Promise.try(InitModules, ...):andThenCall(StartModules):catch(warn)
end)

local coreCall
do
	local MAX_RETRIES = 10

	local StarterGui = game:GetService("StarterGui")
	local RunService = game:GetService("RunService")

	function coreCall(method, ...)
		local result = {}
		for _ = 1, MAX_RETRIES do
			result = { pcall(StarterGui[method], StarterGui, ...) }
			if result[1] then
				break
			end
			RunService.Stepped:Wait()
		end
		return unpack(result)
	end
end

assert(coreCall("SetCore", "ResetButtonCallback", false))
