local CollectionService = game:GetService("CollectionService")

local rng = Random.new()

local function onSpawn(npc)
	npc.loggedEnemies = {}

	for _ = 0, 10 do
		local randomPos = npc.Instance:GetPivot().Position
			+ Vector3.new(rng:NextNumber(-5, 5), 0, rng:NextNumber(-5, 5))

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

local function makeImmortal(npc)
	local subject = npc.Instance

	local enemies = CollectionService:GetTagged("Enemy")

	if npc:GetState() == "Dead" then
		return
	end

	for _, enemy: Model in ipairs(enemies) do
		if enemy.Name == "Petrified" then
			continue
		end

		local humanoid = enemy:FindFirstChild("Humanoid")
		if not humanoid then
			continue
		end

		local distance = (subject:GetPivot().Position - enemy:GetPivot().Position).Magnitude

		if distance > 75 then
			humanoid:SetAttribute("Invincible", false)

			local enemyIndex = table.find(npc.loggedEnemies, enemy)
			if enemyIndex then
				table.remove(npc.loggedEnemies, enemyIndex)
			end

			continue
		end

		humanoid:SetAttribute("Invincible", true)

		local enemyIndex = table.find(npc.loggedEnemies, enemy)

		if not enemyIndex then
			table.insert(npc.loggedEnemies, enemy)
		end
	end
end

local function setAllToFalse(npc)
	for _, enemy: Model in ipairs(npc.loggedEnemies) do
		local humanoid = enemy:FindFirstChild("Humanoid")
		if not humanoid then
			continue
		end

		humanoid:SetAttribute("Invincible", false)
	end
end

local module = {
	OnStep = {
		{ Function = "Custom", Parameters = { makeImmortal } },
	},

	OnSpawned = {
		{ Function = "Custom", Parameters = { onSpawn } },
		{ Function = "PlayAnimation", Parameters = { "Idle", Enum.AnimationPriority.Core } },
		{ Function = "AddTag", Parameters = { "Enemy" } },
	},

	OnDied = {
		{ Function = "Custom", Parameters = { setAllToFalse } },
		{ Function = "SetCollision", Parameters = { "DeadBody" } },
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "Ragdoll" },
		{ Function = "RemoveWithDelay", Parameters = { 1, true } },
	},
}

return module
