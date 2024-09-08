local module = {}
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds

--// Modules
local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)
local Signals = require(Globals.Shared.Signals)
--// Values

--// Functions

function module.Init(player, ui, frame)
	frame.Gui.Enabled = false
end

function module.Pause(player, ui, frame, value)
	frame.Gui.Enabled = value

	if value == false and ui.Menu.Gui.Enabled then
		return
	end

	Lighting.PauseBlur.Enabled = value
end

return module
