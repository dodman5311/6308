local module = {}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local sounds = ReplicatedStorage.Assets.Sounds

local util = require(Globals.Vendor.Util)

local ComboService = require(Globals.Client.Services.ComboService)
local explosionService = require(Globals.Client.Services.ExplosionService)

function module.doWeakspotHit(part: BasePart)
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

		if part:HasTag("OpenWound") then
			part:RemoveTag("OpenWound")
		end
	elseif spotType == "ExplodeOnDeath" then
		local humanoid = util.checkForHumanoid(part)

		if humanoid and humanoid.Health - Damage <= 0 then
			explosionService.createExplosion(
				part.Position,
				part:GetAttribute("SplashSize"),
				part:GetAttribute("SplashDamage"),
				Players.LocalPlayer
			)
		end
	end

	part.Effect:Emit(part.Effect:GetAttribute("EmitCount"))

	ComboService.RestartTimer()

	return Damage or 0
end

return module
