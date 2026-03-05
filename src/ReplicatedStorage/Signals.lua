local ReplicatedStorage = game:GetService("ReplicatedStorage")

local signal = require(ReplicatedStorage.Packages.Signal)

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
	AddLuck = signal.new(),
	AddSoul = signal.new(),
	LoadSavedDataFromClient = signal.new(),
	DoUiAction = signal.new(),

	DoWeaponAction = signal.new(),
	RemoveSoul = signal.new(),
	ClearGifts = signal.new(),
	AddAmmo = signal.new(),
	PauseGame = signal.new(),
	ResumeGame = signal.new(),
	AddTicket = signal.new(),

	GenerateMap = signal.new(),
	NpcHeartbeat = signal.new(),
	ProceedToNextLevel = signal.new(),
	StartArena = signal.new(),
}

return signals
