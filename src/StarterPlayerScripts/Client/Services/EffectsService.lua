local module = {}

--// Services
local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local DEBRIS = game:GetService("Debris")

--// Instances
local player = PLAYERS.LocalPlayer
local assets = REPLICATED_STORAGE.Assets
local sounds = assets.Sounds
local camera = workspace.CurrentCamera

local effects = assets.Effects

local Globals = require(REPLICATED_STORAGE.Shared.Globals)

--// Modules
local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)
local cameraShaker = require(Globals.Packages.CameraShaker)

local replicateRemote = net:RemoteEvent("ReplicateEffect")

local function ShakeCamera(shakeCf)
	camera.CFrame = camera.CFrame * shakeCf
end

-- Create CameraShaker instance:
local renderPriority = Enum.RenderPriority.Last.Value + 10
local camShake = cameraShaker.new(renderPriority, ShakeCamera)
camShake:Start()

-- Apply explosion shakes every 5 seconds:

local function emitObject(part)
	for _, emitter in ipairs(part:GetChildren()) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		local emitCount = emitter:GetAttribute("EmitCount")
		local emitDelay = emitter:GetAttribute("EmitDelay")

		if emitDelay > 0 then
			task.delay(emitDelay, function()
				emitter:Emit(emitCount)
			end)
		else
			emitter:Emit(emitCount)
		end
	end
end

function module.Dash(subject, goal)
	local newEffect = effects.DashEffect:Clone()
	newEffect.Parent = workspace
	local position = (subject:GetPivot().Position:Lerp(goal, 0.5))
	newEffect.CFrame = CFrame.lookAt(position, goal)

	DEBRIS:AddItem(newEffect, 3)

	newEffect.RightSmoke:Emit(30)
	newEffect.LeftSmoke:Emit(30)
	newEffect.Smoke:Emit(45)

	newEffect.Fire.Enabled = true
	newEffect.Fire2.Enabled = true
	newEffect.Fire3.Enabled = true
	newEffect.Fire4.Enabled = true

	newEffect.Attachment.Beam:Emit(35)

	task.delay(0.5, function()
		newEffect.Fire.Enabled = false
		newEffect.Fire2.Enabled = false
		newEffect.Fire3.Enabled = false
		newEffect.Fire4.Enabled = false
	end)
end

function module.shakeFromExplosion(position, size)
	local subject = player.Character
	if not subject then
		return
	end

	local distance = (subject:GetPivot().Position - position).Magnitude

	local maxDistance = 45
	local magnitude = math.abs(math.clamp(distance, 0, maxDistance) - maxDistance) / maxDistance

	local explosion = cameraShaker.Presets[size .. "_Explosion"]
	explosion.Magnitude *= magnitude

	camShake:Shake(explosion)
end

function module.Explode(position, size)
	local explosionPart = effects:FindFirstChild(size .. "_Explosion")
	if not explosionPart then
		return
	end

	explosionPart = explosionPart:Clone()
	explosionPart.Position = position
	explosionPart.Parent = workspace
	DEBRIS:AddItem(explosionPart, 3)

	util.PlaySound(sounds:FindFirstChild(size .. "_Explosion"), explosionPart, 0.15)
	emitObject(explosionPart)
	explosionPart.PointLight.Enabled = true
	task.delay(0.075, function()
		explosionPart.PointLight.Enabled = false
	end)

	module.shakeFromExplosion(position, size)
end

function module.createEffect(effectName, sender, replicated, ...)
	if sender == player and replicated then
		return
	end

	if not replicated then
		replicateRemote:FireServer(effectName, ...)
	end

	module[effectName](...)
end

net:Connect("ReplicateEffect", module.createEffect)

return module
