local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)

local function onSpawn(npc)
	task.delay(0.1, function()
		net:RemoteEvent("ReplicateEffect"):FireAllClients("emitObject", "Server", true, npc.Instance.Particle.Explode)
	end)

	util.PlaySound(util.getRandomChild(ReplicatedStorage.Assets.Sounds.RockHits), npc.Instance.PrimaryPart, 0.1)
	util.PlaySound(npc.Instance.Spawn, npc.Instance.PrimaryPart, 0.1)

	local ricoHitbox = ReplicatedStorage.Assets.Effects.RicoHitbox:Clone()
	ricoHitbox.Parent = npc.Instance
	ricoHitbox.Anchored = true
	ricoHitbox.CFrame = npc.Instance:GetPivot()
	ricoHitbox.Ui.Enabled = true
	ricoHitbox.CanQuery = false
end

local module = {
	OnSpawned = {
		{ Function = "Custom", Parameters = { onSpawn } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
		{ Function = "AddTag", Parameters = { "Ricoshot" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 0.05 } },
	},
}

return module
