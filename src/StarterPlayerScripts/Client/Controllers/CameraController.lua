local module = {
	shakeCFrame = CFrame.new(),
	globalSway = Vector2.new(),
}

local players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local player = players.LocalPlayer
local camera = workspace.CurrentCamera

local Globals = require(ReplicatedStorage.Shared.Globals)

local cameraShaker = require(Globals.Packages.CameraShaker)
local util = require(Globals.Vendor.Util)
local spring = require(Globals.Vendor.Spring)
local ViewmodelService = require(Globals.Vendor.ViewmodelService)

local maxTiltAngle = 50

local swaySpring = spring.new(Vector2.new(0, 0))
swaySpring.Speed = 20
swaySpring.Damper = 0.6

-- Viewmodel bobbing
local damp = 1
local i = 0
local p = Vector3.new()
local r = Vector3.new()
local lastBobStep = os.clock()

local isWalking = false

local function ShakeCamera(shakeCf)
	module.shakeCFrame = shakeCf
	camera.CFrame = camera.CFrame * shakeCf
end

module.camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value + 2, ShakeCamera)
module.camShake:Start()
local currentVelocityTilt = Vector3.new()

local function calculateViewmodelWalkSway()
	local dt = os.clock() - lastBobStep
	lastBobStep = os.clock()

	if isWalking then
		i += dt * 45
		p += Vector3.new(math.sin(i / 4) * 0.8, math.sin(i / 2 - 0.4)) / 8 / damp / 10
		r += Vector3.new(math.sin(i / 2) / 5, math.cos(i / 4 - 0.3) / 4, math.sin(i / 4 - 0.4) / 3) / 20 / (damp * 5)
	else
		i = 0
		p = Vector3.new()
		r = Vector3.new()
	end

	local viewmodel = ViewmodelService.viewModels[1]
	viewmodel:UpdateSpring("bobbingPositionSpring", "Target", p)
	viewmodel:UpdateSpring("bobbingRotationSpring", "Target", r * 1.25)
end

local function bobbing()
	if isWalking then
		module.camShake:ShakeSustain(cameraShaker.Presets["WalkBobbing"])
	else
		module.camShake:StopSustained(0.2)
	end
end

local function checkWalking()
	if not player.Character then
		return
	end

	local humanoid = player.Character:WaitForChild("Humanoid")
	local moving = humanoid.MoveDirection.Magnitude > 0

	if moving then
		if humanoid.FloorMaterial == Enum.Material.Air then
			if not isWalking then
				return
			end
			isWalking = false
			bobbing()
		else
			if isWalking then
				return
			end
			isWalking = true
			bobbing()
		end
	else
		if not isWalking then
			return
		end
		isWalking = false
		bobbing()
	end
end

local function runCameraSway()
	local delta = uis:GetMouseDelta() / 15
	swaySpring.Target = Vector2.new(math.clamp(delta.X, -15, 15), math.clamp(delta.Y, -15, 15))

	module.globalSway = swaySpring.Position
end

local function runCameraTilt()
	if not player.Character then
		return
	end

	local root = player.Character.PrimaryPart
	if not root then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	currentVelocityTilt = currentVelocityTilt:Lerp(camera.CFrame:VectorToObjectSpace(velocity / 7.5), 0.1)

	local sway = swaySpring.Position * 2

	local tilt = math.rad(math.clamp(sway.X + -currentVelocityTilt.X, -maxTiltAngle, maxTiltAngle))
	camera.CFrame *= CFrame.new() * CFrame.Angles(0, 0, tilt)
end

local function runCamera(dt)
	runCameraSway()
	runCameraTilt()

	checkWalking()
	calculateViewmodelWalkSway(dt)
end

function module:OnSpawn()
	local viewmodel = ViewmodelService.viewModels[1]

	viewmodel:SetSpring("bobbingRotationSpring", "Rotation", Vector3.zero, 20, 0.4)
	viewmodel:SetSpring("bobbingPositionSpring", "Position", Vector3.zero, 20, 0.6)

	RunService:BindToRenderStep("runCamera", Enum.RenderPriority.Camera.Value + 1, runCamera)

	player.CameraMode = Enum.CameraMode.LockFirstPerson
	camera.FieldOfView = 90
end

function module:OnDied()
	RunService:UnbindFromRenderStep("runCamera")
end

return module
