local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Vendor.Util)
local DestructableService = {}
function DestructableService.DestroyObject(subject)
	local model: Model = subject:IsA("Model") and subject or subject:FindFirstAncestorOfClass("Model")

	local emitter = Instance.new("Part")
	emitter.Transparency = 1
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false

	emitter.Anchored = true
	emitter.CFrame = model:GetPivot()
	emitter.Size = model:GetExtentsSize()
	emitter.Parent = workspace

	local soundName = model:GetAttribute("Sound")
	local sound = soundName and ReplicatedStorage.Assets.Sounds.DestructableSounds:FindFirstChild(soundName)
	if sound then
		Util.PlaySound(sound, emitter, 0.1)
	end

	for _, particle in (model:GetDescendants()) do
		if particle.Name ~= "ParticleEmitter" then
			continue
		end

		particle.Parent = emitter
		particle:Emit(30)
	end

	Debris:AddItem(emitter, 6)

	model:RemoveTag("Destructable")
	model:Destroy()
end

function DestructableService.DetectObject(subject)
	local model = subject:IsA("Model") and subject or subject:FindFirstAncestorOfClass("Model")
	if not model or not model:HasTag("Destructable") then
		return false
	end

	return true
end

return DestructableService
