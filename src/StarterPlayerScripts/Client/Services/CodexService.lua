local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local signal = require(Globals.Packages.Signal)
local signals = require(Globals.Signals)
local codex = require(Globals.Shared.Codex)
local net = require(Globals.Packages.Net)

local UIService = require(Globals.Client.Services.UIService)

--// Values

module.CodexEntries = {}
signals.AddEntry = signal.new()

module.latestEntry = nil

function module.saveCurrentCodex()
	local codexToSave = {}

	for index, entry in pairs(module.CodexEntries) do
		codexToSave[index] = entry.Viewed
	end

	net:RemoteEvent("SaveData"):FireServer("PlayerCodex", codexToSave)
end

function module.AddEntry(entryIndex: string, quiet: boolean?, doNotSave: boolean?)
	if module.CodexEntries[entryIndex] or not codex[entryIndex] then
		return
	end

	local isImportant = string.match(codex[entryIndex].Entry, '<font color="')

	module.CodexEntries[entryIndex] = codex[entryIndex]
	module.CodexEntries[entryIndex].Viewed = not isImportant

	if quiet then
		return
	end

	if isImportant then
		module.latestEntry = entryIndex
	end

	if not doNotSave then
		module.saveCurrentCodex()
	end

	UIService.doUiAction("Notify", "AddEntry", entryIndex, isImportant)
end

signals.AddEntry:Connect(module.AddEntry)

signals.LoadSavedDataFromClient:Connect(function(upgradeIndex, gameState, gameSettings, savedCodex) -- load codex
	for entryIndex, viewed in pairs(savedCodex) do
		module.CodexEntries[entryIndex] = codex[entryIndex]
		module.CodexEntries[entryIndex].Viewed = viewed
	end

	module.AddEntry("Cleanse & Repent", false, true)
	module.AddEntry("The Iron Gate", false, true)
	module.AddEntry("Info & Tips", false, true)
end)

return module
