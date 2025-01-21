local stats = {
	AttackDistance = 30,
	ViewDistance = 400,
	NpcType = "Enemy",
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Globals = require(ReplicatedStorage.Shared.Globals)
local animationService = require(Globals.Vendor.AnimationService)
local util = require(Globals.Vendor.Util)

local function getTimer(npc, timerName)
	local foundTimer = npc.Timers[timerName]

	if not foundTimer then
		npc.Timers[timerName] = npc.Timer:new(timerName)
		return npc.Timers[timerName]
	end

	return foundTimer
end

local function endTolling(npc)
	getTimer(npc, "StopToll"):Cancel()

	local model = npc.Instance
	local toll = model.Toll
	local damagePart = toll.DamagePart
	local aoeEffect = damagePart.AoeEffect

	aoeEffect.Enabled = false

	animationService:stopAnimation(model, "Attack")
	local tollAnim = animationService:playAnimation(model, "PlaceToll", Enum.AnimationPriority.Action4, false, 0, 1, -1)

	local a
	a = tollAnim.Stopped:Connect(function()
		a:Disconnect()
		model.PrimaryPart.Anchored = false
		npc.Acts:removeAct("Tolling")
	end)
end

local function startTolling(npc)
	local model = npc.Instance
	local toll = model.Toll
	local damagePart = toll.DamagePart

	local tollingAnim = animationService:playAnimation(model, "Attack", Enum.AnimationPriority.Action4, true)

	local hitToll = tollingAnim:GetMarkerReachedSignal("CreateAoe"):Connect(function()
		util.PlaySound(model.PrimaryPart.Toll_Hit, model.PrimaryPart, 0.1)
		util.PlaySound(model.PrimaryPart.Toll_Ring, model.PrimaryPart, 0.05)
		damagePart.HitParticle:Emit(300)

		local hitParts = workspace:GetPartsInPart(damagePart)

		local playersHit = {}

		for _, part in ipairs(hitParts) do -- Deal damage to player
			local hitModel = part:FindFirstAncestorOfClass("Model")
			if not hitModel then
				continue
			end

			local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
			if not hitPlayer then
				continue
			end

			if table.find(playersHit, hitPlayer) then
				continue
			end

			local humanoid = hitModel:FindFirstChild("Humanoid")
			if not humanoid then
				continue
			end
			table.insert(playersHit, hitPlayer)

			humanoid:TakeDamage(4)
		end
	end)

	local stopTimer = getTimer(npc, "StopToll")

	stopTimer.WaitTime = 5
	stopTimer.Function = function(Npc)
		local target = Npc.Target.Value
		if not target then
			hitToll:Disconnect()
			endTolling(Npc)
			return
		end

		local position = target:GetPivot().Position
		local distance = (model:GetPivot().Position - position).Magnitude

		if distance > stats.AttackDistance + 5 then
			hitToll:Disconnect()
			endTolling(Npc)
			return
		end

		stopTimer:Run()
	end

	stopTimer.Parameters = { npc }

	stopTimer:Run()
end

local function useToll(npc)
	if npc.Acts:checkAct("Tolling") then
		return
	end

	npc.Acts:createAct("Tolling")

	local model = npc.Instance
	local toll = model.Toll
	local damagePart = toll.DamagePart
	local aoeEffect = damagePart.AoeEffect

	local ti = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

	model.PrimaryPart.Anchored = true

	local tollAnim = animationService:playAnimation(model, "PlaceToll", Enum.AnimationPriority.Action3)

	task.delay(0.5, util.PlaySound, model.PrimaryPart.Toll_Down, model.PrimaryPart, 0.1)

	tollAnim.Stopped:Once(function()
		aoeEffect.Enabled = true

		startTolling(npc)

		repeat
			util.tween(aoeEffect.Image, ti, { Rotation = 90 }, true)
			if not aoeEffect.Parent or not aoeEffect.Image then
				return
			end
			aoeEffect.Image.Rotation = 0
		until not aoeEffect.Enabled
	end)
end

local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { "Player", stats.ViewDistance } },
		{ Function = "LookAtTarget" },

		{ Function = "GetToDistance", Parameters = { 5, true } },
		{ Function = "PlayWalkingAnimation" },
	},

	AtDistance = {
		{ Function = "Custom", Parameters = { useToll } },
		Parameters = { 10 },
	},

	TargetFound = {
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
		{ Function = "MoveTowardsTarget" },
	},

	TargetLost = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "MoveTowardsTarget" },
	},

	OnSpawned = {
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
