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

function module.GhoulTeleport(position)
	local effect = effects.GhoulTeleport:Clone()
	effect.Parent = workspace
	effect.Position = position
	effect.ParticleEmitter:Emit(effect.ParticleEmitter:GetAttribute("EmitCount"))
	DEBRIS:AddItem(effect, 2)
end

function module.ElectrifyPart(part)
	part.Smoke.Enabled = true
	task.wait(1.1)
	part.Electricity.Enabled = true
	task.wait(5)
	part.Electricity.Enabled = false
	part.Smoke.Enabled = false
end

function module.EnemySpawned(position)
	local spawnEffect = effects.SpawnEnemy:Clone()
	DEBRIS:AddItem(spawnEffect, 5)

	spawnEffect.Parent = workspace
	spawnEffect.Position = position + Vector3.new(0, -5, 0)

	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
	util.tween(spawnEffect.Beam, ti, { Width1 = 0 })

	util.PlaySound(sounds.Teleport, spawnEffect, 0.15)
	util.PlaySound(sounds.Voices, spawnEffect, 0.1)
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

function module.AddElementalEffect(elementName, npcModel: Model)
	if npcModel:FindFirstChild(elementName) then
		return
	end

	local newEffect = assets.Effects.Elements:FindFirstChild(elementName):Clone()
	newEffect.Parent = npcModel
	newEffect.Name = elementName

	local primaryPart = npcModel.PrimaryPart or npcModel:FindFirstChild("Hitbox")

	if not primaryPart then
		newEffect.Anchored = true
		newEffect.CFrame = npcModel:GetPivot()
		return
	end

	local newWeld = Instance.new("Weld")
	newWeld.Parent = newEffect
	newWeld.Part0 = primaryPart
	newWeld.Part1 = newEffect

	newEffect.Size = npcModel:GetExtentsSize()
end

function module.RemoveElementalEffect(elementName, npcModel)
	local element = npcModel:FindFirstChild(elementName)

	if not element then
		return
	end

	element.Name = "EffectMarkedForRemoval"
	DEBRIS:AddItem(element, 5)

	for _, particle in ipairs(element:GetChildren()) do
		if not particle:IsA("ParticleEmitter") then
			continue
		end

		particle.Enabled = false
	end
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
