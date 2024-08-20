local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

--// Modules
local signal = require(Globals.Packages.Signal)
local signals = require(Globals.Signals)
local codex = require(Globals.Shared.Codex)

--// Values

module.CodexEntries = {}
signals.AddEntry = signal.new()

function module.AddEntry(entryIndex, quiet)
	if module.CodexEntries[entryIndex] or not codex[entryIndex] then
		return
	end

	local isImportant = string.match(codex[entryIndex].Entry, '<font color="')

	module.CodexEntries[entryIndex] = codex[entryIndex]
	module.CodexEntries[entryIndex].Viewed = not isImportant

	if quiet then
		return
	end

	signals.DoUiAction:Fire("Notify", "AddEntry", true, entryIndex, isImportant)
end

signals.AddEntry:Connect(module.AddEntry)

function module:OnSpawn()
	module.AddEntry("Cleanse & Repent")
	module.AddEntry("The Iron Gate")
	module.AddEntry("Info & Tips")
end

return module
