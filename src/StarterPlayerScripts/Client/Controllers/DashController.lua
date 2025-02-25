local module = {
	dashes = 3,
	canDash = true,
}

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local player = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

local cameraTilt
local cameraOffset
local beat

local signals = require(Globals.Shared.Signals)

--local net = require(rps.Net)

local acts = require(Globals.Vendor.Acts)
local util = require(Globals.Vendor.Util)
local giftService = require(Globals.Client.Services.GiftsService)
local momentum = require(Globals.Client.Controllers.AirController)
local uiService = require(Globals.Client.Services.UIService)

function module.fillDashes()
	module.canDash = true
	module.dashes = 3

	uiService.doUiAction("HUD", "UpdateGiftProgress", "Righteous_Motion", module.dashes / 3)
	uiService.doUiAction("HUD", "RefreshSideBar")
	--script.LoadedUI:Play()
end

function module.Dash(subject)
	if not module.canDash or not giftService.CheckGift("Righteous_Motion") then
		return
	end

	acts:createTempAct("dashing", function()
		local humanoid = subject:FindFirstChild("Humanoid")
		local primaryPart = subject.PrimaryPart

		if not humanoid or not primaryPart then
			return
		end

		module.dashes -= 1
		if module.dashes == 0 then
			module.canDash = false
		end

		util.PlaySound(ReplicatedStorage.Assets.Sounds.Dash, script, 0.1)

		local ti = TweenInfo.new(1)

		Lighting.DashBlur.Size = 10
		util.tween(Lighting.DashBlur, ti, { Size = 0 })

		util.tween(camera, TweenInfo.new(0.1), { FieldOfView = util.getSetting("Field of View").Value + 5 })
		task.delay(0.1, function()
			util.tween(camera, TweenInfo.new(1), { FieldOfView = util.getSetting("Field of View").Value })
		end)

		uiService.doUiAction("HUD", "UpdateGiftProgress", "Righteous_Motion", module.dashes / 3)

		uiService.doUiAction("HUD", "UpdateSideBar", module.dashes)

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

		local velocityAttachment = Instance.new("Attachment")
		velocityAttachment.Name = "VelocityAttachment"
		velocityAttachment.Parent = primaryPart

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.MaxForce = 200
		linearVelocity.ForceLimitsEnabled = false
		linearVelocity.Parent = primaryPart
		linearVelocity.Attachment0 = velocityAttachment

		local direction = primaryPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local goalVelocity = (camera.CFrame.Rotation * CFrame.new(direction * 100)).Position

		if direction.Z > 0 then
			goalVelocity = humanoid.MoveDirection * 100
		end

		linearVelocity.VectorVelocity = goalVelocity
		task.wait(0.2)
		linearVelocity:Destroy()
		velocityAttachment:Destroy()

		task.spawn(function()
			primaryPart.AssemblyLinearVelocity *= Vector3.new(1, 0.2, 1)
			momentum.change(true)
		end)

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end)

	for i = module.dashes, 3.1, 0.1 do
		task.wait(0.05)
		if acts:checkAct("dashing") or module.dashes == 3 then
			break
		end

		if i >= 3 then
			module.fillDashes()
		end
	end
end

local input
--local inputEnded

function module:OnSpawn(character)
	--	local tween

	input = uis.InputBegan:Connect(function(i, gpe)
		if gpe then
			return
		end

		if i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.ButtonR1 then
			module.Dash(character)
		end
	end)

	local humanoid = character:FindFirstChild("Humanoid")

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
end

signals.Movement:Connect(function()
	local character = player.Character
	if not character then
		return
	end

	module.Dash(character)
end)

giftService.OnGiftAdded:Connect(function(gift)
	if gift ~= "Righteous_Motion" then
		return
	end

	uiService.doUiAction("HUD", "ShowSideBar")
end)

local function assignRefill(object)
	object.PrimaryPart.Touched:Connect(function()
		if not object:GetAttribute("CanUse") then
			return
		end

		object:SetAttribute("CanUse", false)
		module.fillDashes()

		object.PointUi.Center.ImageTransparency = 0.95
		task.wait(5)
		object:SetAttribute("CanUse", true)
	end)
end

CollectionService:GetInstanceAddedSignal("DashRefill"):Connect(function(tagged: Instance)
	assignRefill(tagged)
end)

for _, object in ipairs(CollectionService:GetTagged("DashRefill")) do
	assignRefill(object)
end

function module:OnDied()
	input:Disconnect()
	uiService.doUiAction("HUD", "HideSideBar")
	--inputEnded:Disconnect()
end

return module
