local module = {
	inSlide = false,
}

local bound = false

local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local util = require(Globals.Vendor.Util)

local player = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

local cameraTilt
local cameraOffset
local beat

--local net = require(rps.Net)

local acts = require(Globals.Vendor.Acts)
local viewModelService = require(Globals.Vendor.ViewmodelService)
local util = require(Globals.Vendor.Util)
local signals = require(Globals.Signals)
local giftService = require(Globals.Client.Services.GiftsService)

local debounce = false

local logPhysics

local function startDebounce()
	debounce = true
	task.delay(0.3, function()
		debounce = false
	end)
end

function module.Slide()
	if not giftService.CheckGift("Wax_On") then
		return
	end

	local filter = { "wallrunning", "dashing", "ledgeGrab", "ability_invasive" }
	if acts:checkAct(filter) or debounce then
		return
	end
	startDebounce()

	module.inSlide = not module.inSlide
	local character = module.Character
	if not character then
		return
	end
	local humanoid = character:WaitForChild("Humanoid")
	if humanoid.Health <= 0 then
		return
	end

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	local ti2 = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	if module.inSlide then
		acts:createAct("slide")
		--script.Slide:Play()

		local slidePhysics = PhysicalProperties.new(0.01, 0.01, 0.5, 100, 1)
		logPhysics = game:GetService("StarterPlayer").StarterCharacter.PrimaryPart.CustomPhysicalProperties

		for _, v in ipairs(character:GetDescendants()) do
			if not v:IsA("BasePart") then
				continue
			end
			v.CustomPhysicalProperties = slidePhysics
		end

		--humanoid.JumpPower += 10
		humanoid.WalkSpeed -= 20
		--effects.CreateEffect("Speed")
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			character.PrimaryPart.AssemblyLinearVelocity = humanoid.MoveDirection * 50
		end

		util.tween(cameraOffset, ti, { Value = Vector3.new(0, -1, 0) })
		util.tween(cameraTilt, ti, { Value = -10 })
		util.tween(camera, ti, { FieldOfView = util.getSetting("Field of View").Value + 10 })
		--effects.CreateEffect("QuickBlur")

		--ui.toggleCrosshair(false)
		repeat
			task.wait()
		until not character
			or not character.PrimaryPart
			or character.PrimaryPart.AssemblyLinearVelocity.Magnitude <= 20
			or acts:checkAct(filter)
			or not module.inSlide
			or character:GetAttribute("LockSlide")
		module.inSlide = false
		acts:removeAct("slide")

		util.tween(cameraOffset, ti2, { Value = Vector3.new(0, 0, 0) })
		util.tween(cameraTilt, ti2, { Value = 0 })
		util.tween(camera, ti2, { FieldOfView = util.getSetting("Field of View").Value })

		for _, v in ipairs(character:GetDescendants()) do
			if not v:IsA("BasePart") then
				continue
			end
			v.CustomPhysicalProperties = logPhysics
		end

		--humanoid.JumpPower -= 10
		humanoid.WalkSpeed += 20
	end
end

local input
local inputEnd

function module:OnSpawn(character)
	if logPhysics then
		for _, v in ipairs(character:GetDescendants()) do
			if not v:IsA("BasePart") then
				continue
			end
			v.CustomPhysicalProperties = logPhysics
		end
	end

	local viewmodel = viewModelService.viewModels[1]

	cameraTilt = Instance.new("NumberValue")
	cameraOffset = Instance.new("Vector3Value")

	module.Character = player.Character

	rs:BindToRenderStep("slideCamera", Enum.RenderPriority.Character.Value + 10, function()
		camera.CFrame *= CFrame.new(cameraOffset.Value)

		local goal = CFrame.new(0, -cameraTilt.Value / 10, cameraTilt.Value / 8)
			* CFrame.Angles(0, math.rad(-cameraTilt.Value * 1.5), 0)
		viewmodel:SetOffset("SlideOffset", "FromBase", goal)

		camera.CFrame *= CFrame.Angles(0, 0, math.rad(cameraTilt.Value))
	end)

	local humanoid = module.Character:WaitForChild("Humanoid")

	-- humanoid.StateChanged:Connect(function(new)
	-- 	if new ~= Enum.HumanoidStateType.Jumping then
	-- 		if beat then
	-- 			beat:Disconnect()
	-- 		end
	-- 		return
	-- 	end

	-- 	if not acts:checkAct("slide") then
	-- 		return
	-- 	end

	-- 	module.inSlide = false

	-- 	local logVel = (humanoid.MoveDirection * 45) + Vector3.new(0, humanoid.JumpPower + 8, 0)

	-- 	module.Character.PrimaryPart.AssemblyLinearVelocity = logVel

	-- 	beat = rs.Heartbeat:Connect(function()
	-- 		local primaryPart = module.Character.PrimaryPart

	-- 		local rp = RaycastParams.new()
	-- 		rp.FilterType = Enum.RaycastFilterType.Include
	-- 		rp.FilterDescendantsInstances = { workspace.Map }
	-- 		rp.RespectCanCollide = true

	-- 		local rayCast
	-- 		local direction

	-- 		if logVel.Magnitude > 0 then
	-- 			direction = logVel.Unit * 3
	-- 			rayCast = workspace:Spherecast(primaryPart.Position, 1, direction, rp)
	-- 		end

	-- 		if rayCast then
	-- 			local reflectedDirection = direction
	-- 				- (2 * direction:Dot(rayCast.Normal) * rayCast.Normal)
	-- 					* (primaryPart.AssemblyLinearVelocity.Magnitude / 10)
	-- 			logVel = reflectedDirection
	-- 		end

	-- 		local v = Vector3.new(logVel.X, primaryPart.AssemblyLinearVelocity.Y, logVel.Z)
	-- 		primaryPart.AssemblyLinearVelocity = v
	-- 	end)
	-- end)

	input = uis.InputBegan:Connect(function(i, gpe)
		if gpe then
			return
		end

		if humanoid.MoveDirection.Magnitude == 0 or module.Character:GetAttribute("LockSlide") then
			return
		end

		if
			i.KeyCode == Enum.KeyCode.C
			or i.KeyCode == Enum.KeyCode.LeftControl
			or i.KeyCode == Enum.KeyCode.ButtonL3
		then
			module.Slide()
		end
	end)

	inputEnd = uis.InputEnded:Connect(function(i)
		if
			i.KeyCode == Enum.KeyCode.C
			or i.KeyCode == Enum.KeyCode.LeftControl
			or i.KeyCode == Enum.KeyCode.ButtonL3
		then
			module.inSlide = false
		end
	end)
end

signals.Slide:Connect(function(value)
	if value then
		module.Slide()
	else
		module.inSlide = false
	end
end)

function module:OnDied()
	local viewmodel = viewModelService.viewModels[1]

	rs:UnbindFromRenderStep("slideCamera")
	viewmodel:RemoveOffset("SlideOffset")
	input:Disconnect()
	inputEnd:Disconnect()
	module.inSlide = false

	acts:removeAct("slide")

	cameraTilt:Destroy()
	cameraOffset:Destroy()
end

return module
