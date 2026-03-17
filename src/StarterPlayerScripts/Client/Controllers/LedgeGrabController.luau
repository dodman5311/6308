local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local module = {}

local players = game:GetService("Players")
local player = players.LocalPlayer

local rs = game:GetService("RunService")

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { workspace:WaitForChild("Map") }

local airController = require(script.Parent.AirController)

local acts = require(Globals.Vendor.Acts)
local animationService = require(Globals.Vendor.AnimationService)
local viewModel = require(Globals.Vendor.ViewmodelService)

local util = require(Globals.Vendor.Util)

local function grabLedge(goalCFrame)
	if acts:checkAct("ledgeGrab") or not player.Character then
		return
	end

	local primaryPart = player.Character.PrimaryPart

	acts:createTempAct("ledgeGrab", function()
		animationService:playAnimation(
			viewModel.viewModels[1].Model,
			"LedgeGrab",
			Enum.AnimationPriority.Action4,
			false,
			0,
			0.75,
			0.85
		)

		primaryPart.Anchored = true
		--primaryPart.AssemblyLinearVelocity = Vector3.zero
		--airController.cancel()

		util.tween(
			primaryPart,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = goalCFrame },
			true
		)
		primaryPart.Anchored = false
	end)
end

local function run()
	if
		not player.Character
		or not player.Character.PrimaryPart
		or not player.Character:FindFirstChild("Humanoid")
		or player.Character.Humanoid.FloorMaterial ~= Enum.Material.Air
	then
		return
	end

	local rootCFrame = player.Character:GetPivot()
	local _, yAngle = rootCFrame:ToEulerAngles(Enum.RotationOrder.YXZ)
	local startCF = CFrame.fromEulerAnglesYXZ(0, yAngle, 0) + rootCFrame.Position

	local frontRay = workspace:Raycast(startCF * Vector3.new(0, 2.5, 1), 7 * startCF.LookVector, rp)
	if frontRay then
		return false
	end

	local upRay = workspace:Raycast(startCF.Position, 4 * Vector3.yAxis, rp)
	if upRay then
		return false
	end

	local catchRay = workspace:Raycast(startCF.Position, 4 * startCF.LookVector, rp)
	if not catchRay then
		return false
	end

	local downOrigin = catchRay.Position + 2.5 * Vector3.yAxis + 0.05 * startCF.LookVector
	--local downRay = workspace:Raycast(downOrigin, -3.5 * Vector3.yAxis, rp)

	local goalCF = startCF.Rotation * CFrame.new(0, 1, -0.5) + downOrigin

	local endPositionCheckRay =
		workspace:Spherecast((goalCF * CFrame.new(0, -2.5, 0)).Position, 1, Vector3.new(0, 5, 0), rp)
	if endPositionCheckRay then
		return false
	end

	--instances.AlignPosition.Position = goalCF.Position
	--instances.ControllerManager.FacingDirection = startCF.LookVector

	grabLedge(goalCF)
	return true
end

rs.Heartbeat:Connect(run) --castRays)

return module
