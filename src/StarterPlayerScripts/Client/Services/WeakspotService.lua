local module = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local sounds = ReplicatedStorage.Assets.Sounds

local util = require(Globals.Vendor.Util)

local ComboService = require(Globals.Client.Services.ComboService)

function module.doWeakspotHit(part)
	if part.Name ~= "Weakspot" then
		return 0
	end

	local sound = part:GetAttribute("Sound") and sounds:FindFirstChild(part:GetAttribute("Sound")) or sounds.HitWeakspot

	util.PlaySound(sound, script, 0.05)

	local spotType = part:GetAttribute("Type")
	local Damage = part:GetAttribute("Damage")

	if spotType == "Destroy" then
		for _, v in ipairs(part:GetChildren()) do
			if v:IsA("Texture") then
				v.Transparency = 1
				continue
			end

			if v:IsA("BillboardGui") then
				v.Enabled = false
				continue
			end

			if not v:IsA("BasePart") then
				continue
			end

			v.CanCollide = false
			v.CanQuery = false
			v.CanTouch = false
			v.Transparency = 1
		end

		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
	end

	part.Effect:Emit(part.Effect:GetAttribute("EmitCount"))

	ComboService.RestartTimer()

	return Damage or 0
end

return module
