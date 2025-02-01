local CollectionService = game:GetService("CollectionService")

local rng = Random.new()

local function onSpawn(npc)
	for _ = 0, 10 do
		local randomPos = npc.Instance:GetPivot().Position
			+ Vector3.new(rng:NextNumber(-20, 20), 0, rng:NextNumber(-20, 20))

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { workspace.Map }

		local check = workspace:Raycast(randomPos, CFrame.new().UpVector * -25, rp)

		if check then
			npc.Instance:PivotTo(CFrame.new(check.Position + Vector3.new(0, 8, 0)))
			break
		end
	end
end

local module = {
	OnSpawned = {
		{ Function = "Custom", Parameters = { onSpawn } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
		{ Function = "AddTag", Parameters = { "ImmortalTotem" } },
	},

	OnDied = {
		--{ Function = "Custom", Parameters = { setAllToFalse } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
