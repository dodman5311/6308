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

function module.Init(player, ui, frame) end

function module.Pulse(player, ui, frame, color: Color3, fadeTime: number, Damping)
	local pulse = frame.Pulse
	local ti = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)

	pulse.BackgroundColor3 = color
	pulse.BackgroundTransparency = Damping or 0

	util.tween(pulse, ti, { BackgroundTransparency = 1 })
end

return module
