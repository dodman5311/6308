local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local module = {}

local players = game:GetService("Players")
local player = players.LocalPlayer

local rs = game:GetService("RunService")
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include

local airController = require(script.Parent.AirController)

local acts = require(Globals.Vendor.Acts)
local viewModel = require(Globals.Vendor.ViewmodelService)
local animationService = require(Globals.Vendor.AnimationService)

local util = require(Globals.Vendor.Util)

local function createRaycastRig()
	if not player.Character then
		return
	end

	module.topDown = Instance.new("Attachment")
	module.topDown.Parent = player.Character.PrimaryPart
	module.topDown.Position = Vector3.new(0, 2.5, 0)

	module.topAcross = CFrame.new(0, 2.5, 1)
end

local function grabLedge()
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
			0.75
		)

		primaryPart.Anchored = true
		primaryPart.AssemblyLinearVelocity = Vector3.zero
		airController.cancel()
		--airController.change()

		local goal = primaryPart.CFrame * module.topDown.CFrame * CFrame.new(0, 1.5, -1)

		util.tween(
			primaryPart,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = goal },
			true
		)
		primaryPart.Anchored = false
	end)
end

local function castRays()
	if not player.Character then
		return
	end
	if
		not player.Character:FindFirstChild("Humanoid")
		or player.Character.Humanoid.FloorMaterial ~= Enum.Material.Air
	then
		return
	end

	local primaryPart = player.Character.PrimaryPart
	rp.FilterDescendantsInstances = { workspace.Map }

	local catchRay =
		workspace:Spherecast(primaryPart.Position + Vector3.new(0, 1, 0), 1, primaryPart.CFrame.LookVector * 4, rp)

	if not catchRay then
		return
	end

	local upRay = workspace:Spherecast(primaryPart.Position, 2, primaryPart.CFrame.UpVector * 4, rp)
	if upRay then
		return
	end

	module.topDown.WorldPosition = catchRay.Position + Vector3.new(0, 4, 0)
	module.topDown.CFrame *= CFrame.new(0, 0, -0.05)

	local downRay = workspace:Raycast(module.topDown.WorldPosition, module.topDown.CFrame.UpVector * -4.5, rp)
	if not downRay then
		return
	end

	local crossCheck = workspace:Spherecast(
		(primaryPart.CFrame * CFrame.new(0, 5, 1)).Position,
		2.5,
		primaryPart.CFrame.LookVector * 6,
		rp
	)
	if crossCheck then
		return
	end

	grabLedge()
end

function module:OnSpawn()
	createRaycastRig()
	rs:BindToRenderStep("ledgeGrab", Enum.RenderPriority.Last.Value, castRays)
end

function module:OnDied()
	rs:UnbindFromRenderStep("ledgeGrab")
end

return module
