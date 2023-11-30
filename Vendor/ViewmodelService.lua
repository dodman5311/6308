local module = {
	viewModels = {},
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

--// Instances
local globals = require(ReplicatedStorage.Shared.Globals)
local vendor = globals.Vendor

local assets = ReplicatedStorage.Assets
local camera = workspace.CurrentCamera

--// Modules
local spring = require(vendor.Spring)

--// Values
local currentCameraOffset = CFrame.new()

--// Functions
local function HandleBaseOffsets(viewModel, baseC0)
	local rootJoint = viewModel.Model.PrimaryPart.RootJoint
	rootJoint.C0 = baseC0

	for _, offset in pairs(viewModel.Offsets) do
		if offset.Type ~= "FromBase" then
			continue
		end
		rootJoint.C0 *= offset.CFrame
	end
end

local function PositionViewModel(viewModel)
	local delta = uis:GetMouseDelta()
	viewModel.SwaySpring.Target = delta * viewModel.SwayAmount

	local swaySpring = viewModel.SwaySpring
	viewModel.swayFrame = CFrame.new(
		math.rad(-swaySpring.Position.X * 2),
		math.rad(swaySpring.Position.Y * 2),
		math.rad(swaySpring.Position.Y)
	) * CFrame.Angles(math.rad(-swaySpring.Position.Y), math.rad(-swaySpring.Position.X), 0)
	if viewModel.LockSway then
		viewModel.swayFrame = CFrame.new()
	end

	local goal = camera.CFrame * viewModel.swayFrame

	for _, offset in pairs(viewModel.Offsets) do
		if offset.Type ~= "FromCamera" then
			continue
		end
		goal *= offset.CFrame
	end

	for _, spring in pairs(viewModel.Springs) do
		local frame = CFrame.new()
		local fullSpring = spring.Spring

		if spring.Type == "Position" then
			frame = CFrame.new(fullSpring.Position)
		elseif spring.Type == "Rotation" then
			frame = CFrame.new()
				* CFrame.Angles(
					math.rad(fullSpring.Position.X),
					math.rad(fullSpring.Position.Y),
					math.rad(fullSpring.Position.Z)
				)
		end

		goal *= frame
	end

	viewModel.Model:PivotTo(goal * currentCameraOffset:Inverse())
end

function module.new()
	local viewModel = {
		Model = assets.Models.ViewModel:Clone(),
		SwaySpring = spring.new(Vector2.new(0, 0)),
		SwayFrame = CFrame.new(),
		SwayAmount = 0.1,
		LockSway = false,

		CameraBoneDamper = {
			Pos = 3,
			Rot = 3,
		},

		Offsets = {},
		Springs = {},
	}

	local baseC0 = viewModel.Model.PrimaryPart.RootJoint.C0

	viewModel.SwaySpring.Speed = 10
	viewModel.SwaySpring.Damper = 0.65

	function viewModel:Run()
		viewModel.Model.Parent = camera

		table.insert(module.viewModels, self)
	end

	function viewModel:Destroy()
		table.remove(module.viewModels, table.find(module.viewModels, self))

		self.Model:Destroy()
	end

	function viewModel:Hide() end

	function viewModel:Show() end

	function viewModel:UpdatePosition()
		PositionViewModel(self)
	end

	function viewModel:SetOffset(Index, Type, Cframe: CFrame)
		self.Offsets[Index] = { ["Type"] = Type, ["CFrame"] = Cframe }

		HandleBaseOffsets(self, baseC0)
		return self.Offsets[Index]
	end

	function viewModel:UpdateOffset(Index, Cframe: CFrame)
		self.Offsets[Index].CFrame = Cframe

		HandleBaseOffsets(self, baseC0)
	end

	function viewModel:RemoveOffset(Index)
		self.Offsets[Index] = nil

		HandleBaseOffsets(self, baseC0)
	end

	function viewModel:SetSpring(Index, Type, Value, Speed, Damper)
		local newSpring = spring.new(Value)
		newSpring.Speed = Speed
		newSpring.Damper = Damper

		self.Springs[Index] = { ["Type"] = Type, ["Spring"] = newSpring }

		return self.Springs[Index]
	end

	function viewModel:UpdateSpring(Index, Property, Value)
		self.Springs[Index].Spring[Property] = Value
	end

	function viewModel:RemoveSpring(Index)
		self.Springs[Index] = nil
	end

	return viewModel
end

RunService:BindToRenderStep("RunViewmodels", Enum.RenderPriority.Character.Value, function()
	currentCameraOffset = CFrame.new()

	for _, viewmodel in ipairs(module.viewModels) do
		if viewmodel.Model:FindFirstChild("CameraBone") then
			local diffAng = (viewmodel.Model.CameraBone.Orientation - viewmodel.Model.PrimaryPart.Orientation)
				/ viewmodel.CameraBoneDamper.Rot
			local diffPos = (viewmodel.Model.CameraBone.Position - viewmodel.Model.PrimaryPart.Position)
				/ viewmodel.CameraBoneDamper.Pos

			currentCameraOffset *= CFrame.new(diffPos) * CFrame.Angles(
				math.rad(diffAng.X),
				math.rad(diffAng.Y),
				math.rad(diffAng.Z)
			)
		end

		PositionViewModel(viewmodel)
	end

	camera.CFrame *= currentCameraOffset
end)

--// Main //--

return module
