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
	Lighting.PauseBlur.Enabled = value
	frame.Gui.Enabled = value
end

return module
