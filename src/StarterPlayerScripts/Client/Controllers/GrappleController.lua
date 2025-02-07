--// Services
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local runService = game:GetService("RunService")

local uis = game:GetService("UserInputService")

--// Modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local util = require(Globals.Vendor.Util)
local viewModelService = require(Globals.Vendor.ViewmodelService)
local acts = require(Globals.Vendor.Acts)
local momentum = require(Globals.Client.Controllers.AirController)
local animationService = require(Globals.Vendor.AnimationService)
local Net = require(Globals.Packages.Net)
local GiftsService = require(Globals.Client.Services.GiftsService)
local signals = require(Globals.Signals)
local timer = require(Globals.Vendor.Timer)
local uiService = require(Globals.Client.Services.UIService)
local weapons = require(Globals.Client.Controllers.WeaponController)

--// Instances

local camera = workspace.CurrentCamera
local player = players.LocalPlayer
local assets = replicatedStorage.Assets

local sounds = assets.Sounds
local ViewModel

local grapplePart
local rope
local antiGrav
local onCooldown = false
local onInvCooldown = false
local keyDown = false

--// Connections
local InputEnded
local hitDetected

local module = {}

--// Values
local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
local ti1 = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local ti2 = TweenInfo.new(0.175, Enum.EasingStyle.Linear)
local ti3 = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function createRope(c, distance, a1)
	local newRope = Instance.new("RopeConstraint")
	newRope.Parent = player.Character

	newRope.Length = distance
	newRope.Attachment0 = player.Character.PrimaryPart.RootAttachment
	newRope.Attachment1 = a1
	newRope.Restitution = 0
	newRope.WinchEnabled = true
	newRope.WinchResponsiveness = 40
	newRope.WinchSpeed = 40
	newRope.WinchForce = 10000

	newRope.Visible = true

	newRope.Destroying:Once(function()
		print("END")
	end)

	return newRope
end

local function getMass(character)
	local mass = 0
	for _, v in ipairs(character:GetDescendants()) do
		if not v:IsA("BasePart") then
			continue
		end
		mass += v:GetMass()
	end

	return mass
end

local function createAntiGrav(c)
	local newG = Instance.new("VectorForce")

	newG.Attachment0 = c.PrimaryPart.RootAttachment
	newG.RelativeTo = Enum.ActuatorRelativeTo.World
	newG.Parent = c

	local r
	r = runService.RenderStepped:Connect(function()
		if not newG.Parent then
			r:Disconnect()
		end

		local md = module.h.MoveDirection * 600
		newG.Force = Vector3.new(md.X, 0, md.Z) -- workspace.Gravity * getMass(c)
	end)

	return newG
end

local function getObjectInCenter(blacklist, whitelist, ignoreDistance)
	local inCenter
	local objectsOnScreen = {}
	local leastDistance = math.huge
	local getObject

	for _, model in ipairs(CollectionService:GetTagged(whitelist or "Pickup")) do
		if blacklist and table.find(blacklist, model) then
			continue
		end

		local modelPosition = model:GetPivot().Position

		local trueCenter = camera.ViewportSize / 2

		local getPosition, onScreen = camera:WorldToScreenPoint(modelPosition)

		if (not ignoreDistance and getPosition.Z > 100) or not onScreen then
			continue
		end

		local onScreenPosition = Vector2.new(getPosition.X, getPosition.Y)
		local distanceToCenter = (trueCenter - onScreenPosition).Magnitude

		local distanceUnit = distanceToCenter / camera.ViewportSize.Magnitude

		if distanceUnit >= 0.15 then
			continue
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = { workspace.Map }

		local cameraPosition = camera.CFrame.Position
		local ray = workspace:Raycast(cameraPosition, modelPosition - cameraPosition, raycastParams)

		if ray and ray.Instance.Parent ~= model then
			continue
		end

		if distanceToCenter < leastDistance then
			leastDistance = distanceToCenter
			getObject = model
		end
		objectsOnScreen[#objectsOnScreen + 1] = model
	end

	if getObject then
		inCenter = getObject
	else
		inCenter = nil
	end
	return inCenter, objectsOnScreen, leastDistance
end

local function startSwingGrapple(c, position)
	acts:createAct("grappling")
	module.h.PlatformStand = true

	local distance = (camera.CFrame.Position - position).Magnitude
	--grapplePoint = position

	local rope = createRope(c, distance, grapplePart.Attachment)
	local antiGrav = createAntiGrav(c)

	sounds.Grappling:Play()

	return rope, antiGrav
end

local function startGrapple(c, position, item)
	if item then
		local r
		local i = 0
		local distance = math.huge

		r = runService.RenderStepped:Connect(function()
			if distance <= 4 or not grapplePart or not grapplePart.Parent or not item or not item.Parent then
				Net:RemoteEvent("PickupWeapon"):FireServer(item)
				r:Disconnect()
				return
			end
			i = math.clamp(i + 0.1, 0, 1)

			item:PivotTo(item:GetPivot():Lerp(grapplePart.CFrame, i))
			distance = (grapplePart.Position - camera.CFrame.Position).Magnitude
		end)

		return
	end

	acts:createAct("grappling")
	module.h.PlatformStand = true

	local distance = (camera.CFrame.Position - position).Magnitude
	--grapplePoint = position

	module.c.PrimaryPart.AssemblyLinearVelocity = (
		(position - module.c:GetPivot().Position).Unit + (module.h.MoveDirection / 10)
	) * math.clamp(distance * 1.5, 75, 200)

	return
end

local function dealDamage(characterHit)
	if not characterHit then
		return
	end

	-- local humanoid = characterHit:FindFirstChildOfClass("Humanoid")

	-- local fakeRay = { Instance = characterHit.PrimaryPart, Position = characterHit:GetPivot().Position }

	-- local killData = util.getKillDataTS(player, fakeRay, "Majigh")
	-- local enemyHumanoid, dmgDelt = net:Invoke("processDamage", fakeRay, nil, data, true, nil, killData)

	-- if not enemyHumanoid then
	-- 	return
	-- end
	-- signals["registerHit"]:Fire(enemyHumanoid, dmgDelt)

	if onInvCooldown then
		return
	end

	onInvCooldown = true

	Net:RemoteEvent("SetInvincible")
	uiService.doUiAction("HUD", "ShowInvincible")

	uiService.doUiAction("HUD", "ActivateGift", "Brick_Hook")
	uiService.doUiAction("HUD", "CooldownGift", "Brick_Hook", 1)

	uiService.doUiAction("HUD", "GrappleCooldown", 1, 0)

	timer.wait(1)
	Net:RemoteEvent("SetInvincible", false)
	uiService.doUiAction("HUD", "HideInvincible")

	uiService.doUiAction("HUD", "GrappleCooldown", 1, 1)

	timer.wait(1)
	onInvCooldown = false
end

local function endGrapple()
	module.h.PlatformStand = false
	acts:removeAct("grappling")

	momentum.change()

	if InputEnded then
		InputEnded:Disconnect()
	end

	if hitDetected then
		hitDetected:Disconnect()
	end

	local barrel = ViewModel["Left Arm"].Barrel

	if rope then
		rope:Destroy()
		antiGrav:Destroy()
	end

	local ropeBeam = ViewModel.RopeBeam
	ropeBeam.CurveSize0 = 5
	ropeBeam.CurveSize1 = -10

	util.tween(ropeBeam, ti2, { CurveSize0 = 0, CurveSize1 = 0 })

	if not grapplePart then
		return
	end

	local hook = grapplePart.Parent
	grapplePart.Weld:Destroy()
	grapplePart.Anchored = true

	for i = 0, 1, 0.05 do
		hook:PivotTo(hook:GetPivot():Lerp(barrel.WorldCFrame, i))
		task.wait()
	end
	hook:Destroy()
	grapplePart = nil
end

local function detectHit(partHit, launchedPart, item, swing)
	local _, characterHit = util.checkForHumanoid(partHit)

	if not partHit:FindFirstAncestor("Map") then
		if not characterHit or characterHit == player.Character then
			return
		end
	end

	if
		not partHit.CanCollide
		or not partHit.CanQuery
		or partHit.Transparency >= 0.95
		or partHit:FindFirstAncestor("Camera")
		or not launchedPart
	then
		return
	end

	--task.spawn(dealDamage, characterHit, launchedPart)

	grapplePart.Weld.Part0 = partHit
	grapplePart.Anchored = true

	sounds.GrappleHit:Play()

	if swing then
		rope, antiGrav = startSwingGrapple(module.c, grapplePart.Position)
	else
		startGrapple(module.c, grapplePart.Position, item)
	end

	local ropeBeam = ViewModel.RopeBeam
	ropeBeam.Attachment1 = grapplePart.Attachment

	util.tween(ropeBeam, ti1, { CurveSize0 = 0, CurveSize1 = 0 })

	return true
end

local function firePart(item, endPoint)
	local newHook = assets.Models.Hook:Clone()
	grapplePart = newHook.PrimaryPart

	hitDetected = grapplePart.Touched:Connect(function(partHit)
		if detectHit(partHit, grapplePart, item, endPoint) then
			hitDetected:Disconnect()
		end
	end)

	local barrel = ViewModel["Left Arm"].Barrel

	newHook:PivotTo(barrel.WorldCFrame)

	local ropeBeam = ViewModel.RopeBeam
	ropeBeam.Attachment1 = grapplePart.Attachment
	ropeBeam.TextureSpeed = 0
	ropeBeam.CurveSize0 = 0
	ropeBeam.CurveSize1 = 0

	util.tween(ropeBeam, ti, { CurveSize0 = 5, CurveSize1 = -10 })

	newHook.Parent = workspace.Ignore
	grapplePart.AssemblyLinearVelocity = endPoint
			and CFrame.lookAt(newHook:GetPivot().Position, endPoint).LookVector * 800
		or camera.CFrame.LookVector * 800
end

local function onInputEnded(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonR1 then
		keyDown = false
	end
end

function module.AltActivate(endPoint)
	if not GiftsService.CheckGift("Brick_Hook") then
		return
	end

	module.c, module.h = player.Character, player.Character:WaitForChild("Humanoid")
	ViewModel = viewModelService.viewModels[1].Model

	keyDown = true
	InputEnded = uis.InputEnded:Connect(onInputEnded)

	acts:createTempAct("ability_invasive", function()
		local startTime = os.clock()
		local vm = ViewModel
		local animation = animationService:getAnimation(vm, "Grapple")

		sounds.GrappleActivate:Play()
		firePart(nil, endPoint)

		-- local keyReached = animation.KeyframeReached:Connect(function(keyName)
		-- 	if keyName == "Launch" then
		-- 		firePart(item)
		-- 	end
		-- end)

		animationService:playAnimation(vm, "Grapple", Enum.AnimationPriority.Action4.Value, false, 0, 2, 1)

		repeat
			task.wait()
		until animation.Length > 0 -- wait for anim to load

		task.wait(animation.Length - 0.1)
		animation:AdjustSpeed(0)

		local distance = math.huge

		repeat
			task.wait()
			if not grapplePart then
				continue
			end

			distance = (module.c:GetPivot().Position - grapplePart.Position).Magnitude
		until distance <= 10
			or module.c.PrimaryPart.AssemblyLinearVelocity.Magnitude <= 10
			or not keyDown
			or os.clock() - startTime >= 3
			or (os.clock() - startTime >= 10 and not grapplePart.Weld.Part0)

		-- task.spawn(function()
		-- 	endGrapple()
		-- end)

		-- animation:AdjustSpeed(1)

		-- animationService:playAnimation(vm, "DeactivateGrapple", Enum.AnimationPriority.Action4.Value, false, 0, 2, 1)

		-- timer.delay(animationService:getAnimation(vm, "DeactivateGrapple").Length - 0.01, function()
		-- 	animationService:stopAnimation(vm, "DeactivateGrapple", 0)
		-- end)

		-- animations["Deactivate"].Stopped:Wait()
		-- animations["Exit"]:Play(0, 2, 1)

		--keyReached:Disconnect()
	end)
end

function module.Activate(item)
	if not GiftsService.CheckGift("Brick_Hook") and (not GiftsService.CheckGift("Stuff_Hook") or not item) then
		return
	end

	module.c, module.h = player.Character, player.Character:WaitForChild("Humanoid")
	ViewModel = viewModelService.viewModels[1].Model

	acts:createTempAct("ability_invasive", function()
		local _, characterHit = weapons.FireBullet(0, 0, 300, nil, "Brick_Hook")

		task.spawn(dealDamage, characterHit)

		sounds.GrappleActivate:Play()
		local vm = ViewModel

		local animation = animationService:getAnimation(vm, "Grapple")

		firePart(item)

		-- local keyReached = animation.KeyframeReached:Connect(function(keyName)
		-- 	if keyName == "Launch" then
		-- 		firePart(item)
		-- 	end
		-- end)

		animationService:playAnimation(vm, "Grapple", Enum.AnimationPriority.Action4.Value, false, 0, 2, 1)
		animation.Stopped:Wait()

		timer.wait(0.125)

		task.spawn(function()
			endGrapple()
		end)

		animationService:playAnimation(vm, "DeactivateGrapple", Enum.AnimationPriority.Action4.Value, false, 0, 2, 1)

		timer.delay(animationService:getAnimation(vm, "DeactivateGrapple").Length - 0.01, function()
			animationService:stopAnimation(vm, "DeactivateGrapple", 0)
		end)

		-- animations["Deactivate"].Stopped:Wait()
		-- animations["Exit"]:Play(0, 2, 1)

		--keyReached:Disconnect()
	end)
end

local cooldown = 0.5

local function grappleMovement()
	if acts:checkAct("grappling", "ability_invasive") or workspace:GetAttribute("GamePaused") then
		return
	end

	onCooldown = true
	uiService.doUiAction("HUD", "SetGrappleIndicatorTransparency", 0.9)

	local point = getObjectInCenter(nil, "GrapplePoint", true)
	if point then
		module.AltActivate(point:GetPivot().Position)
	else
		module.Activate()
	end

	timer.wait(cooldown)

	onCooldown = false
	if GiftsService.CheckGift("Brick_Hook") then
		uiService.doUiAction("HUD", "SetGrappleIndicatorTransparency", 0)
	end
end

local function grapplePickup()
	if acts:checkAct("grappling", "ability_invasive") or workspace:GetAttribute("GamePaused") then
		return
	end

	local item = getObjectInCenter()

	if GiftsService.CheckGift("Stuff_Hook") and item then
		onCooldown = true
		uiService.doUiAction("HUD", "SetGrappleIndicatorTransparency", 0.9)

		module.Activate(item)

		timer.wait(cooldown)
		onCooldown = false

		if GiftsService.CheckGift("Stuff_Hook") then
			uiService.doUiAction("HUD", "SetGrappleIndicatorTransparency", 0)
		end
	end
end

uis.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent or onCooldown then
		return
	end

	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		grapplePickup()
	end

	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonR1 then
		grappleMovement()
	end
end)

signals.Movement:Connect(function()
	local character = player.Character
	if not character then
		return
	end

	grappleMovement()
end)

signals.AttemptGrab:Connect(function()
	local character = player.Character
	if not character then
		return
	end

	grapplePickup()
end)

GiftsService.OnGiftAdded:Connect(function(gift)
	if gift == "Brick_Hook" then
		uiService.doUiAction("HUD", "GrappleCooldown", 0.1, 1)
		uiService.doUiAction("HUD", "ToggleGrappleIndicator", true)
	end
end)

GiftsService.OnGiftRemoved:Connect(function(gift)
	if gift == "Brick_Hook" then
		uiService.doUiAction("HUD", "ToggleGrappleIndicator", false)
	end
end)

function module:OnSpawn()
	onCooldown = false
end

return module
