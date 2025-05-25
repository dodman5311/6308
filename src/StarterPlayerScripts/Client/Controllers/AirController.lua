local module = {
	airControl = 7.5,
	onWall = false,
}
local players = game:GetService("Players")
local player = players.LocalPlayer
local UIS = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)

local runService = game:GetService("RunService")

local isFalling = false
local t = false
local logVel = nil
local beat

local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local primaryPart = char.PrimaryPart
	return char, humanoid, primaryPart
end

LockedFrames = 1 / 60
local function Locked_swait()
	local T = tick()
	while true do
		game:GetService("RunService").RenderStepped:Wait()
		if tick() - T >= LockedFrames then
			break
		end
	end
end

function module.change(dash)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:WaitForChild("Humanoid")
	local primaryPart = character.PrimaryPart

	if not primaryPart then
		return
	end

	if not isFalling then
		return
	end

	if dash == true then
		logVel = humanoid.MoveDirection * humanoid.WalkSpeed
	else
		logVel = primaryPart.AssemblyLinearVelocity
	end

	while isFalling do
		if t or acts:checkAct("grappling") then
			break
		end

		Locked_swait()

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { workspace.Map }
		rp.RespectCanCollide = true

		local rayCast
		local direction

		if logVel.Magnitude > 0 then
			direction = logVel.Unit * 3
			rayCast = workspace:Spherecast(primaryPart.Position, 1, direction, rp)
		end

		if rayCast then
			local reflectedDirection = direction
				- (2 * direction:Dot(rayCast.Normal) * rayCast.Normal)
					* math.clamp(primaryPart.AssemblyLinearVelocity.Magnitude / 15, 0, 25)
			logVel = reflectedDirection
		end

		local v = Vector3.new(logVel.X, primaryPart.AssemblyLinearVelocity.Y, logVel.Z)
		local a = Vector3.new(
			(humanoid.MoveDirection.X * module.airControl),
			0,
			(humanoid.MoveDirection.Z * module.airControl)
		)

		local vector = v + a

		local clampedVector = Vector3.new(
			math.clamp(vector.X, -115, 115),
			math.clamp(vector.Y, -115, 115),
			math.clamp(vector.Z, -115, 115)
		)

		primaryPart.AssemblyLinearVelocity = clampedVector
	end
end

function module.cancel()
	t = true
	task.wait(0.1)
	t = false
end

function module.switchFalling(x)
	isFalling = x
	module.change()
end

function module:OnSpawn(character)
	module.c, module.h, module.p = getCharacter()

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.FreeFalling:Connect(module.switchFalling)
end

function module:OnDied() end

return module
