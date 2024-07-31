local modules = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local Promise = require(Globals.Packages.Promise)

local Signals = require(Globals.Signals)
local net = require(Globals.Packages.Net)

local allSignals = {
	"GenerateMap",
	"NpcHeartbeat",
	"ProceedToNextLevel",
	"StartArena",
}

net:RemoteEvent("ReplicateEffect")
net:RemoteEvent("Damage")
net:RemoteEvent("DropSoul")
net:RemoteEvent("SetBlocking")
net:RemoteEvent("SetInvincible")
net:RemoteEvent("CreateBeam")
net:RemoteFunction("GetMaxCombo")
net:RemoteEvent("StopMusic")
net:RemoteEvent("BossExit")
net:RemoteEvent("UpdatePlayerHealth")

net:RemoteEvent("PauseGame")
net:RemoteEvent("ResumeGame")

net:RemoteEvent("GiftAdded")
net:RemoteEvent("GiftRemoved")
net:RemoteEvent("DoUiAction")
net:RemoteEvent("OpenKiosk")
net:RemoteEvent("SetArmor")
net:RemoteEvent("CreateExplosion")

net:RemoteEvent("DropArmor")
net:RemoteEvent("PickupWeapon")

net:RemoteFunction("CheckChance")

for _, signal in ipairs(allSignals) do
	Signals:addSignal(signal)
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
