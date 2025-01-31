local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local module = {}

local players = game:GetService("Players")
local player = players.LocalPlayer

local rs = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include

local acts = require(Globals.Vendor.Acts)
local viewModel = require(Globals.Vendor.ViewmodelService)
local animationService = require(Globals.Vendor.AnimationService)

local util = require(Globals.Vendor.Util)
local spaceDown = false

local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local primaryPart = char.PrimaryPart
	return char, humanoid, primaryPart
end

local function createRaycastRig()
	module.topDown = Instance.new("Attachment")
	module.topDown.Parent = module.p
	module.topDown.Position = Vector3.new(0, 2.5, 0)

	module.topAcross = CFrame.new(0, 2.5, 1)
end

local function grabLedge()
	if acts:checkAct("ledgeGrab") then
		return
	end
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
		module.p.Anchored = true
		local goal = module.p.CFrame * module.topDown.CFrame * CFrame.new(0, 1, -0.5)

		util.tween(
			module.p,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = goal },
			true
		)
		module.p.Anchored = false
	end)
end

local function castRays()
	if module.h.FloorMaterial ~= Enum.Material.Air then
		return
	end

	local primaryPart = module.p
	rp.FilterDescendantsInstances = { workspace.Map }

	local catchRay =
		workspace:Spherecast(module.p.Position + Vector3.new(0, 1, 0), 1, module.p.CFrame.LookVector * 4, rp)

	if not catchRay then
		return
	end

	local upRay = workspace:Spherecast(module.p.Position, 2, module.p.CFrame.UpVector * 4, rp)
	if upRay then
		return
	end

	module.topDown.WorldPosition = catchRay.Position + Vector3.new(0, 4, 0)
	module.topDown.CFrame *= CFrame.new(0, 0, -0.05)

	local downRay = workspace:Raycast(module.topDown.WorldPosition, module.topDown.CFrame.UpVector * -4.5, rp)
	if not downRay then
		return
	end

	local crossCheck =
		workspace:Spherecast((module.p.CFrame * CFrame.new(0, 5, 1)).Position, 2.5, module.p.CFrame.LookVector * 6, rp)
	if crossCheck then
		return
	end

	grabLedge()
end

function module:OnSpawn()
	module.c, module.h, module.p = getCharacter()

	createRaycastRig()
	rs:BindToRenderStep("ledgeGrab", Enum.RenderPriority.Last.Value, castRays)
end

function module:OnDied()
	rs:UnbindFromRenderStep("ledgeGrab")
end

return module
