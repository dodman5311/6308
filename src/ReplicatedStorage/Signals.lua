local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local signal = require(Globals.Packages.Signal)

local signals = {
	ToggleConsole = signal.new(),
	ToggleMenu = signal.new(),
	ThrowWeapon = signal.new(),
	SwitchWeapon = signal.new(),
	Parry = signal.new(),
	Shoot = signal.new(),
	Super = signal.new(),
	Movement = signal.new(),
	WeaponEquipped = signal.new(),
	AttemptGrab = signal.new(),
	Jump = signal.new(),
	Slide = signal.new(),
	AddArmor = signal.new(),
}

function signals:addSignal(index)
	self[index] = signal.new(index)
end

function signals:removeSignal(index)
	self[index] = nil
end

return signals
