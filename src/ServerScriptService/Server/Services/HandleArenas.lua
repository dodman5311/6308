local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverStorage = game:GetService("ServerStorage")
local debris = game:GetService("Debris")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)
local signals = require(Globals.Shared.Signals)
local util = require(Globals.Vendor.Util)
local promise = require(Globals.Packages.Promise)
local acts = require(Globals.Vendor.Acts)
local timer = require(Globals.Vendor.Timer)

local spawners = require(Globals.Services.Spawners)

local arenaBeginEvent = net:RemoteEvent("ArenaBegun")
local arenaEndEvent = net:RemoteEvent("ArenaEnd")
local runArenaPromise

local function closeGate(link)
	local newGate = serverStorage.ArenaGate:Clone()
	newGate.Parent = link
	newGate.CFrame = link.CFrame * CFrame.new(0, -10, 0)

	local ti = TweenInfo.new(0.375, Enum.EasingStyle.Bounce)
	util.tween(newGate, ti, { CFrame = newGate.CFrame * CFrame.new(0, 20, 0) })
	return newGate
end

local function clearEnemiesList(enemies)
	for _, enemy in ipairs(enemies) do
		enemy:Destroy()
	end
end

local function runArena(encounter, unit, level, isAmbush)
	encounter = require(encounter)

	local waveEnemies = {}
	local maxEnemies = 0

	timer.wait(1)

	for _, wave in ipairs(encounter) do
		timer.wait(1)

		for _, spawner in ipairs(unit:GetChildren()) do
			if spawner.Name ~= "WeaponSpawn" then
				continue
			end

			spawners.spawnInUnit(level, unit, "Weapon", Vector3.new(0, 3, 0), spawner, true)
		end

		for _, spawnData in ipairs(wave) do
			if spawnData.SpawnDelay > 0 then
				timer.wait(spawnData.SpawnDelay)
			end

			local spawnCFrame = unit:GetPivot() * spawnData.CFrameInUnit:Inverse()
			local enemyModel = spawners.placeNewObject(level, spawnCFrame, "Enemy", spawnData.Enemy)

			if not enemyModel then
				continue
			end

			net:RemoteEvent("ReplicateEffect"):FireAllClients("EnemySpawned", "Server", true, spawnCFrame.Position)

			local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				continue
			end

			maxEnemies += 1
			table.insert(waveEnemies, enemyModel)

			local onDestroyed

			onDestroyed = enemyModel.Destroying:Connect(function()
				table.remove(waveEnemies, table.find(waveEnemies, enemyModel))
				onDestroyed:Disconnect()
			end)
		end

		if wave.Condition == "Complete" then
			for _ = 0, 25, 0.1 do
				if #waveEnemies <= 0 then
					break
				end
				timer.wait(0.1)
			end

			if #waveEnemies / maxEnemies > 0.6 then
				clearEnemiesList(table.clone(waveEnemies))
				return "Failure"
			end

			clearEnemiesList(table.clone(waveEnemies))

			waveEnemies = {}
			maxEnemies = 0
		else
			timer.wait(wave.Condition)
		end
	end

	return "Success"
end

local function endArena(gates, result, isAmbush)
	if not isAmbush then
		arenaEndEvent:FireAllClients(result)
	end

	for _, gate in ipairs(gates) do
		local ti = TweenInfo.new(0.375, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		util.tween(gate, ti, { CFrame = gate.CFrame * CFrame.new(0, -20, 0) })
	end
end

local function startArena(unit, level, isAmbush)
	local encounter = unit.Modules:FindFirstChild("Encounter")
	if not encounter then
		return
	end

	acts:createAct("InArena")

	local gates = {}
	for _, link in ipairs(unit.Links:GetChildren()) do
		if link.Name ~= "Link" then
			continue
		end
		table.insert(gates, closeGate(link))
	end

	arenaBeginEvent:FireAllClients(isAmbush)

	runArenaPromise = promise.new(function(resolve, reject, onCancel)
		local result = runArena(encounter, unit, level)
		acts:removeAct("InArena")
		resolve(gates, result, isAmbush)
	end)

	runArenaPromise:andThen(endArena)
end

function module.cancelArenas()
	if not runArenaPromise then
		return
	end

	runArenaPromise:cancel()
end

signals.StartArena:Connect(startArena)

return module
