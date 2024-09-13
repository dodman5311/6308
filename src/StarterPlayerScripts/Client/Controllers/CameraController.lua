local module = {
	shakeCFrame = CFrame.new(),
	globalSway = Vector2.new(),
	viewBobbingEnabled = true,
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
local signals = require(Globals.Signals)

local Acts = require(Globals.Vendor.Acts)

local maxTiltAngle = 50

local swaySpring = spring.new(Vector2.new(0, 0))
swaySpring.Speed = 20
swaySpring.Damper = 0.6

-- Viewmodel bobbing
local damp = 1
local i = 0
local p = Vector3.new()
local r = Vector3.new()

local isWalking = false
local isPaused = false
local pauseStep

local function ShakeCamera(shakeCf)
	if not isPaused then
		module.shakeCFrame = shakeCf
	end
	camera.CFrame = camera.CFrame * shakeCf
end

module.camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value + 2, ShakeCamera)
module.camShake:Start()
local currentVelocityTilt = Vector3.new()

local function calculateViewmodelWalkSway()
	if isWalking and not Acts:checkAct("slide") then
		i = time() * 35
		p = Vector3.new(math.sin(i / 4) * 1, math.sin(i / 2 - 0.4)) / -19
		r = Vector3.new(math.sin(i / 2) / 5, math.cos(i / 4 - 0.3) / 4, math.sin(i / 4 - 0.4) / 3) / 20 / (damp * 5)
	else
		i = 0
		p = Vector3.new()
		r = Vector3.new()
	end

	local magnitude = 1.25

	local viewmodel = ViewmodelService.viewModels[1]
	viewmodel:UpdateSpring("bobbingPositionSpring", "Target", p * magnitude)
	viewmodel:UpdateSpring("bobbingRotationSpring", "Target", (r * 2) * magnitude)
end

-- function module.ShakeCamera(presetName)
-- 	local preset = cameraShaker.Presets[presetName]

-- 	module.camShake:Shake()
-- end

local function bobbing()
	if isWalking and module.viewBobbingEnabled then
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

local function runCamera()
	runCameraSway()
	runCameraTilt()

	checkWalking()
	calculateViewmodelWalkSway()
end

function module:OnSpawn(character)
	local viewmodel = ViewmodelService.viewModels[1]

	viewmodel:SetSpring("bobbingRotationSpring", "Rotation", Vector3.zero, 20, 0.4)
	viewmodel:SetSpring("bobbingPositionSpring", "Position", Vector3.zero, 20, 0.6)

	RunService:BindToRenderStep("runCamera", Enum.RenderPriority.Camera.Value + 1, runCamera)

	player.CameraMode = Enum.CameraMode.LockFirstPerson
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = character:WaitForChild("Humanoid")

	camera.FieldOfView = 100
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Exponential)

	util.tween(camera, ti, { FieldOfView = 70 })
end

function module:OnDied()
	RunService:UnbindFromRenderStep("runCamera")
end

signals.PauseGame:Connect(function()
	if pauseStep then
		return
	end

	local logCFrame = camera.CFrame
	isPaused = true
	camera.CameraType = Enum.CameraType.Scriptable

	pauseStep = RunService.RenderStepped:Connect(function()
		camera.CFrame = logCFrame
	end)
end)

signals.ResumeGame:Connect(function()
	if not pauseStep then
		return
	end

	isPaused = false
	camera.CameraType = Enum.CameraType.Custom
	pauseStep:Disconnect()
	pauseStep = nil
end)

return module
