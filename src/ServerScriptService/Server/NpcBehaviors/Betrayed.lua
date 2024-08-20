local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)

local function onSpawn(npc)
	net:RemoteEvent("ReplicateEffect"):FireAllClients("emitObject", "Server", true, npc.Instance.Particle.Explode)

	util.PlaySound(util.getRandomChild(ReplicatedStorage.Assets.Sounds.RockHits), npc.Instance.PrimaryPart, 0.1)
	util.PlaySound(util.getRandomChild(npc.Instance.Screams), npc.Instance.PrimaryPart, 0.1)

	local getVisage = workspace:FindFirstChild("Visage Of False Hope")

	if not getVisage then
		return
	end

	local attachment = getVisage.Torso.BodyFrontAttachment

	local syphon = npc.Instance.VisageSyphon
	syphon.Attachment1 = attachment
end

local module = {
	OnSpawned = {
		{ Function = "Custom", Parameters = { onSpawn } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 0.05 } },
	},
}

return module
