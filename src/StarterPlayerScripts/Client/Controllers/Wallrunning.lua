--// Essentials
local client = script:FindFirstAncestorOfClass("LocalScript")
local module = {
	draw = 20,
	speed = 35,
	maxUpForce = 40,
	onWall = false,
}

--// Services
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local cas = game:GetService("ContextActionService")

local Globals = require(replicatedStorage.Shared.Globals)

--// Modules
local util = require(Globals.Vendor.Util)
local acts = require(Globals.Vendor.Acts)
local airMomentum = require(Globals.Client.Controllers.AirController)
local giftService = require(Globals.Client.Services.GiftsService)

--// Instances
local rp = RaycastParams.new()
local player = players.LocalPlayer
local camera = workspace.CurrentCamera

--// Values
local logOnWall
local d = 0
local wallPosition
local debounce = false

--// Functions
local function createPhysics(yDistance)
	local character = player.Character
	if not character then
		return
	end

	local primaryPart = character.PrimaryPart

	module.velocityAttachment = Instance.new("Attachment")
	module.velocityAttachment.Name = "VelocityAttachment"
	module.velocityAttachment.Parent = primaryPart

	module.linearVelocity = Instance.new("LinearVelocity")
	module.linearVelocity.MaxForce = 100010
	module.linearVelocity.Parent = primaryPart
	module.linearVelocity.Attachment0 = module.velocityAttachment

	-- shift velocity up/down
	local iti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local ti = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	local y = math.clamp(primaryPart.AssemblyLinearVelocity.Y + 5.75, -15, module.maxUpForce)
	util.tween(module.vectorMod, iti, { Value = Vector3.new(0, math.clamp(y, -math.huge, yDistance), 0) })
	task.delay(0.25, function()
		util.tween(module.vectorMod, ti, { Value = Vector3.new(0, -10, 0) })
	end)
end

local function removePhysics()
	if not acts:checkAct("wallrunning") then
		return
	end

	module.linearVelocity:Destroy()
	module.velocityAttachment:Destroy()
	cas:UnbindAction("Jump_Off_Wall") -- remove jumping key
	airMomentum.onWall = false
	module.onWall = false
end

local function startDebounce()
	debounce = true
	task.delay(0.5, function()
		debounce = false
	end)
end

local function jumpOffWall(_, state)
	local character = player.Character
	if not character then
		return
	end

	local primaryPart = character.PrimaryPart
	local humanoid = character.Humanoid

	if state ~= Enum.UserInputState.Begin then
		return
	end

	startDebounce()
	--script.End:Play()

	removePhysics()
	primaryPart.Velocity = (primaryPart.CFrame.RightVector * (-25 * d) + Vector3.new(0, 40, 0))
		+ (humanoid.MoveDirection * module.speed)
	airMomentum.switchFalling(true)
end

local function wallrun(distanceToCeiling)
	if acts:checkAct("ledgeGrab", "grappling") then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local primaryPart = character.PrimaryPart
	local humanoid = character.Humanoid

	if not acts:checkAct("wallrunning") then
		acts:createAct("wallrunning")
		acts:createAct("wallrun" .. d)
		createPhysics(distanceToCeiling)
		cas:BindAction("Jump_Off_Wall", jumpOffWall, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA) -- create key for jumping

		airMomentum.onWall = true
		module.onWall = true
		--script.Start:Play()
	end

	local pullVector = (wallPosition - primaryPart.Position)
		+ ((primaryPart.CFrame * CFrame.new(d * -3.5, 0, 0)).Position - primaryPart.Position)
	module.linearVelocity.VectorVelocity = (humanoid.MoveDirection * module.speed)
		+ module.vectorMod.Value
		+ (pullVector * module.draw)
end

local function onRender()
	if not giftService.CheckGift("Spiked_Sabatons") then
		return
	end
	local character = player.Character
	if not character then
		return
	end

	local primaryPart = character.PrimaryPart
	local humanoid = character.Humanoid

	rp.FilterDescendantsInstances = { character, camera }
	local leftRay = workspace:Raycast(primaryPart.Position, primaryPart.CFrame.RightVector * -6, rp)
	local rightRay = workspace:Raycast(primaryPart.Position, primaryPart.CFrame.RightVector * 6, rp)
	local upRay = workspace:Raycast(primaryPart.Position, primaryPart.CFrame.UpVector * 1000, rp)
	local inAir = humanoid.FloorMaterial == Enum.Material.Air

	local upDistance = upRay and (upRay.Position - character:GetPivot().Position).Magnitude or math.huge
	local withinUpDistance = upDistance > 3

	if withinUpDistance and inAir and leftRay and not debounce then -- get direction
		d = -1
		wallPosition = leftRay.Position
	elseif withinUpDistance and inAir and rightRay and not debounce then
		d = 1
		wallPosition = rightRay.Position
	else
		d = 0
	end

	if logOnWall ~= d and d == 0 then
		startDebounce()
	end
	logOnWall = d

	-- shift camera with velocity

	util.tween(module.direction, TweenInfo.new(0.5), { Value = d })
	camera.CFrame *= CFrame.Angles(0, 0, math.rad((module.vectorMod.Value.Y / 10) + 10) * module.direction.Value)

	if d ~= 0 and not debounce and not acts:checkAct("grappling") then
		wallrun(upDistance)
	else
		removePhysics()
		acts:removeAct("wallrunning")
		acts:removeAct("wallrun-1")
		acts:removeAct("wallrun1")
	end
end

function module:OnSpawn()
	module.vectorMod = Instance.new("Vector3Value")
	module.direction = Instance.new("NumberValue")
	rs:BindToRenderStep("onRender[WallRunning]", Enum.RenderPriority.Character.Value, onRender)
end

function module:OnDied()
	rs:UnbindFromRenderStep("onRender[WallRunning]")

	module.onWall = false
	cas:UnbindAction("Jump_Off_Wall")

	module.vectorMod:Destroy()
	module.direction:Destroy()
end

--// Actions
rp.FilterType = Enum.RaycastFilterType.Exclude

return module
