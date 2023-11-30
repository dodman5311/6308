local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local signal = require(Globals.Packages.Signal)

local signals = {}

function signals:addSignal(index)
	self[index] = signal.new(index)
end

function signals:removeSignal(index)
	self[index] = nil
end

return signals
