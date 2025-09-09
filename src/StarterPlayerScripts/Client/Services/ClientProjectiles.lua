local module = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local collectionService = game:GetService("CollectionService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects

--// Modules
local Net = require(Globals.Packages.Net)
local signal = require(Globals.Packages.Signal)
local signals = require(Globals.Shared.Signals)
local util = require(Globals.Vendor.Util)

local chanceService = require(Globals.Vendor.ChanceService)
local explosionService = require(Globals.Client.Services.ExplosionService)
local giftService = require(Globals.Client.Services.GiftsService)

local damageRemote = Net:RemoteEvent("Damage")

--// Values
local Projectiles = {}
local isPaused = false
module.projectileHit = signal.new()

export type Projectile = {
	["Instance"]: Instance,
	["Speed"]: number,
	["LifeTime"]: number,
	["Age"]: number,
	["Sender"]: Instance,
	["Info"]: table,
	["Damage"]: number,
	["Piercing"]: number,
}

module.Presets = {
	SmartProjectile = {
		Speed = 200,
		LifeTime = 5,
		Info = { Seeking = 0, SeekProgression = 0.2, Size = 0 },
		Damage = 1,
		Piercing = 0,
		Model = "SmartProjectile",
	},

	DetonatingSmartProjectile = {
		Speed = 200,
		LifeTime = 5,
		Info = { Seeking = 0, SeekProgression = 0.2, Size = 0, Detonating = true },
		Damage = 1,
		Piercing = 0,
		Model = "SmartProjectile",
	},

	HeavyBolt = {
		Speed = 2000,
		LifeTime = 1,
		Info = { Size = 1 },
		Damage = 2,
		Piercing = 0,
		Model = "HeavyProjectile",
	},

	ElectricBolt = {
		Speed = 2000,
		LifeTime = 1,
		Info = { Size = 1 },
		Damage = 2,
		Piercing = 0,
		Model = "HeavyElectricProjectile",
	},

	SmartSawBlade = {
		Speed = 100,
		LifeTime = 5,
		Info = {
			SeekProgression = 0.01,
			Seeking = 0.1,
			Dropping = 0.5,
			Bouncing = true,
			Size = 2,
		},
		Damage = 1,
		Piercing = 3,
		Model = "BladeProjectile",
	},

	ThermaCan = {
		Speed = 150,
		LifeTime = 5,
		Info = {
			Dropping = 0.5,
			Size = 2,
			SplashRange = 15,
			SplashDamage = 1,
			SplashElement = "Fire",
		},
		Damage = 1,
		Model = "ThermaProjectile",
	},

	SmartPellet = {
		Speed = 200,
		LifeTime = 5,
		Info = { Seeking = 0, SeekProgression = 0.025, Size = 0 },
		Damage = 1,
		Piercing = 1,
		Model = "SmartProjectile",
	},

	SmartLockingProjectile = {
		Speed = 300,
		LifeTime = 5,
		Info = { Seeking = 0, SeekProgression = 0.1, Locked = nil },
		Damage = 1,
		Piercing = 0,
		Model = "SmartProjectile",
	},

	Bullet = {
		Speed = 500,
		LifeTime = 5,
		Info = {},
		Damage = 1,
		Piercing = 0,
		Model = "PlayerProjectile",
	},

	ElectricBullet = {
		Speed = 500,
		LifeTime = 5,
		Info = {},
		Damage = 1,
		Piercing = 0,
		Model = "ElectricProjectile",
	},

	Plasma = {
		Speed = 400,
		LifeTime = 5,
		Info = { Size = 2, SplashRange = 8, SplashDamage = 1, ExplosiveColor = Color3.fromRGB(255, 82, 226) },
		Damage = 1,
		Piercing = 0,
		Model = "PlasmaProjectile",
	},

	LargePlasma = {
		Speed = 400,
		LifeTime = 5,
		Info = { Size = 2, SplashRange = 16, SplashDamage = 1, ExplosiveColor = Color3.fromRGB(255, 82, 226) },
		Damage = 1,
		Piercing = 0,
		Model = "PlasmaProjectile",
	},

	AssaultProjectile = {
		Speed = 500,
		LifeTime = 5,
		Info = {},
		Damage = 1,
		Piercing = 0,
		Model = "PlayerProjectile",
	},

	Harpoon = {
		Speed = 250,
		LifeTime = 5,
		Info = { Dropping = 0.25, Size = 2 },
		Damage = 2,
		Piercing = 2,
		Model = "HarpoonProjectile",
	},

	FastHarpoon = {
		Speed = 500,
		LifeTime = 5,
		Info = { Dropping = 0.25, Size = 2 },
		Damage = 2,
		Piercing = 2,
		Model = "HarpoonProjectile",
	},

	Trident = {
		Speed = 500,
		LifeTime = 5,
		Info = { Dropping = 0.25, Size = 2 },
		Damage = 2,
		Piercing = 2,
		Model = "HarpoonProjectile",
	},

	ShotgunProjectile = {
		Speed = 400,
		LifeTime = 6,
		Info = {},
		Damage = 1,
		Piercing = 1,
		Model = "PlayerProjectile",
	},

	Smart_Grenade = {
		Speed = 100,
		Damage = 1,
		LifeTime = 10,
		Piercing = 0,
		Info = {
			Seeking = 0,
			SeekProgression = 0.01,
			Size = 2,
			SplashDamage = 8,
			SplashRange = 35,
			Slowing = 0.35,
			Dropping = 0.5,
		},
		Model = "RocketProjectile",
	},

	ExplosivePellet = {
		Speed = 200,
		LifeTime = 8,
		Info = { SplashRange = 10, SplashDamage = 1 },
		Damage = 1,
		Piercing = 0,
		Model = "RocketProjectile",
	},

	FastExplosivePellet = {
		Speed = 400,
		LifeTime = 8,
		Info = { SplashRange = 10, SplashDamage = 1 },
		Damage = 1,
		Piercing = 0,
		Model = "RocketProjectile",
	},

	DreadPellet = {
		Speed = 400,
		LifeTime = 8,
		Info = { SplashRange = 10, SplashDamage = 1, Seeking = 0, SeekDistance = 250, SeekProgression = 0.0075 },
		Damage = 1,
		Piercing = 0,
		Model = "RocketProjectile",
	},

	Rocket = {
		Speed = 400,
		LifeTime = 10,
		Info = { Size = 2, SplashRange = 20, SplashDamage = 1 },
		Damage = 1,
		Piercing = 0,
		Model = "RocketProjectile",
	},

	FastRocket = {
		Speed = 600,
		LifeTime = 10,
		Info = { Size = 2, SplashRange = 20, SplashDamage = 1 },
		Damage = 1,
		Piercing = 0,
		Model = "RocketProjectile",
	},

	LargeFastRocket = {
		Speed = 600,
		LifeTime = 10,
		Info = { Size = 2, SplashRange = 40, SplashDamage = 1 },
		Damage = 1,
		Piercing = 0,
		Model = "RocketProjectile",
	},

	ConcussionRocket = {
		Speed = 600,
		LifeTime = 10,
		Info = { Size = 2, SplashRange = 40, SplashDamage = 1 },
		Damage = 1,
		Piercing = 0,
		Model = "RocketProjectile",
	},
}

--// Functions
local function checkPlayer(subject)
	if not subject then
		return
	end
	local model = subject

	if not subject:IsA("Model") then
		model = subject:FindFirstAncestorOfClass("Model")
	end

	if not model then
		return
	end

	if not Players:GetPlayerFromCharacter(model) and not model:HasTag("OnTeam_Player") then
		return
	end

	return model
end

function module.createFromPreset(cframe, spread, presetName, DamageOverride, infoAddition, sender, source)
	local getPreset = module.Presets[presetName]
	if not getPreset then
		warn("There is no such projectile preset by the name of: ", presetName)
		return
	end

	local damage = DamageOverride or getPreset.Damage
	local info = table.clone(getPreset.Info)

	if infoAddition then
		for i, v in pairs(infoAddition) do
			info[i] = v
		end
	end

	return module.createProjectile(
		getPreset.Speed,
		cframe,
		spread,
		damage,
		getPreset.LifeTime,
		getPreset.Piercing,
		info,
		sender,
		getPreset.Model,
		source
	)
end

function module.createProjectile(speed, cframe, spread, dmg, LifeTime, piercing, extraInfo, sender, model, source)
	spread *= 1.2

	local offset = CFrame.Angles(util.randomAngle(spread), util.randomAngle(spread), util.randomAngle(spread))

	local newInstance = model and Effects:FindFirstChild(model):Clone() or Effects.Projectile:Clone()
	newInstance.Parent = workspace.Ignore
	newInstance.CFrame = cframe * offset

	local localScript = newInstance:FindFirstChildOfClass("LocalScript")
	if localScript then
		localScript.Enabled = true
	end

	local newProjectile = {
		Instance = newInstance,
		Speed = speed,
		LifeTime = LifeTime or 5,
		Age = 0,
		Sender = sender,
		Info = extraInfo or {},
		Damage = dmg or 1,
		Piercing = piercing or 0,
		Source = source,
		RecentHits = {},
	}

	table.insert(Projectiles, newProjectile)
	return newProjectile
end

local function checkRaycast(projectile, raycastDistance)
	if raycastDistance > 1000 then
		return { Instance = nil }
	end

	local cframe = projectile.Instance.CFrame

	local rp = RaycastParams.new()

	local filter = { workspace.CurrentCamera, projectile.Sender }

	for _, value in ipairs(projectile.RecentHits) do
		table.insert(filter, value)
	end

	rp.FilterDescendantsInstances = filter
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.CollisionGroup = "Bullet"

	if projectile.Sender then
		for _, team: Team in ipairs(Teams:GetTeams()) do
			if
				not projectile.Sender:HasTag("OnTeam_" .. team.Name)
				or (projectile.Sender:IsA("Player") and projectile.Sender.Team == team)
			then
				continue
			end

			for _, teamMember: Model in ipairs(collectionService:GetTagged("OnTeam_" .. team.Name)) do
				table.insert(rp.FilterDescendantsInstances, teamMember)
			end

			for _, teamMember: Player in ipairs(team:GetPlayers()) do
				if teamMember.Character then
					table.insert(rp.FilterDescendantsInstances, teamMember.Character)
				end
			end
		end
	end

	local newRaycast
	local ignoreMap = false

	local size = projectile.Info["Size"]

	newRaycast = workspace:Raycast(cframe.Position, cframe.LookVector * raycastDistance, rp)

	if not newRaycast and size and size > 0 then
		ignoreMap = true
		newRaycast = workspace:Spherecast(cframe.Position, size or 0.25, cframe.LookVector * raycastDistance, rp)
	end

	return newRaycast, ignoreMap
end

local function fireBeam(npc, damage, cframe, distance, spread, size)
	local offset = CFrame.Angles(util.randomAngle(spread), util.randomAngle(spread), util.randomAngle(spread))
	cframe *= offset

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { npc }
	raycastParams.CollisionGroup = "Bullet"

	local raycast = workspace:Spherecast(cframe.Position, size or 0.75, cframe.LookVector * distance, raycastParams)

	if not raycast then
		return
	end

	damageRemote:FireServer(raycast.Instance, damage)
end

--// Main //--

Net:Connect("CreateProjectile", module.createProjectile)
Net:Connect("CreateBeam", fireBeam)

local lastRenderStep = os.clock()

local function processStep(distanceToMove, projectile: Projectile)
	projectile.Instance.CFrame *= CFrame.new(0, 0, -(distanceToMove + 0.1))

	--- extra ---

	if projectile.Info["Dropping"] then
		local angle = projectile.Instance.CFrame:ToOrientation()
		if angle > -1.4 then
			projectile.Instance.CFrame *= CFrame.Angles(-math.rad(projectile.Info["Dropping"]), 0, 0)
		end
	end

	if projectile.Info["Slowing"] then
		projectile.Speed = math.clamp(projectile.Speed - projectile.Info["Slowing"], 0, math.huge)
	end

	if projectile.Info["Seeking"] then
		local list

		if projectile.Sender and projectile.Sender:IsA("Player") then
			list = collectionService:GetTagged("Enemy")
		else
			list = {}
			for _, plr in ipairs(Players:GetPlayers()) do
				table.insert(list, plr.Character)
			end
		end

		local nearestEnemy, distanceToMove, position

		if projectile.Info["Locked"] then
			nearestEnemy = projectile.Info["Locked"]
			position = nearestEnemy:GetPivot().Position
		else
			nearestEnemy, distanceToMove, position =
				util.getNearestEnemy(projectile.Instance.Position, projectile.Info["SeekDistance"] or 40, list)
		end

		if nearestEnemy then
			local rp = RaycastParams.new()

			rp.FilterType = Enum.RaycastFilterType.Include
			rp.FilterDescendantsInstances = { workspace.Map }

			local projectilePosition = projectile.Instance.Position

			if workspace:Raycast(projectilePosition, position - projectilePosition, rp) then
				return distanceToMove
			end

			projectile.Instance.CFrame = projectile.Instance.CFrame:Lerp(
				CFrame.lookAt(projectilePosition, position),
				math.clamp(projectile.Info["Seeking"], 0, 1)
			)

			projectile.Info["Seeking"] += projectile.Info["SeekProgression"] or 0

			if projectile.Info["SeekSpeeding"] then
				projectile.Speed = math.clamp(projectile.Speed + projectile.Info["SeekSpeeding"], 0, math.huge)
			end
		end
	end

	return distanceToMove
end

local function removeProjectileInstance(projectile)
	projectile.Instance.Transparency = 1

	for _, effect in ipairs(projectile.Instance:GetDescendants()) do
		if not (effect:IsA("PointLight") or effect:IsA("ParticleEmitter") or effect:IsA("Trail")) then
			continue
		end

		effect.Enabled = false
	end

	task.delay(projectile.Instance:GetAttribute("RemoveDelay") or 0, function()
		projectile.Instance:Destroy()
	end)
end

function module.reflectProjectile(projectile, result)
	if not projectile.Instance then
		return
	end

	local cframe = projectile.Instance.CFrame
	local direction = cframe.LookVector
	local reflectedDirection = direction - (2 * direction:Dot(result.Normal) * result.Normal)
	local newCFrame = CFrame.new(cframe.Position, cframe.Position + reflectedDirection)

	projectile.Instance.CFrame = newCFrame
end

RunService.Heartbeat:Connect(function()
	if isPaused then
		return
	end

	for _, projectile: Projectile in ipairs(Projectiles) do
		if projectile.Age >= projectile.LifeTime then
			if projectile.Info["SplashRange"] then
				explosionService.createExplosion(
					projectile.Instance.Position,
					projectile.Info.SplashRange,
					projectile.Info["SplashDamage"] or 1,
					projectile.Sender,
					projectile.Info.ExplosiveColor,
					projectile.Source
				)
			end

			projectile.Instance:Destroy()
			table.remove(Projectiles, table.find(Projectiles, projectile))
			continue
		end

		local timePassed = os.clock() - lastRenderStep
		projectile.Age += timePassed

		local distanceToMove = timePassed * projectile.Speed
		local raycast, ignoreMap = checkRaycast(projectile, distanceToMove + 0.1)

		processStep(distanceToMove, projectile)

		if not raycast or not raycast.Instance then
			continue
		end

		local isMap = raycast.Instance:FindFirstAncestor("Map")

		if projectile.Info["Bouncing"] and isMap then
			module.reflectProjectile(projectile, raycast)
			continue
		end

		if ignoreMap and isMap then
			continue
		end

		local hitModel = checkPlayer(raycast.Instance)

		if projectile.Sender and projectile.Sender:IsA("Player") then
			hitModel = raycast.Instance:FindFirstAncestorOfClass("Model")

			if hitModel and (hitModel:HasTag("Commrad") or Players:GetPlayerFromCharacter(hitModel)) then
				continue
			end

			module.projectileHit:Fire(raycast, projectile)
		elseif hitModel then
			if giftService.CheckUpgrade("Insurance") and chanceService.checkChance(25, false) then
				projectile.Damage += 1
			end

			damageRemote:FireServer(hitModel, projectile.Damage)
		end

		if projectile.Info["SplashRange"] then
			explosionService.createExplosion(
				raycast.Position,
				projectile.Info.SplashRange,
				projectile.Info["SplashDamage"] or 1,
				projectile.Sender,
				projectile.Info.ExplosiveColor,
				projectile.Source,
				projectile.Info["SplashElement"]
			)
		end

		table.insert(projectile.RecentHits, hitModel)

		if not hitModel or isMap then
			projectile.Piercing -= 1
		end

		if projectile.Piercing > 0 then
			projectile.Piercing -= 1
			continue
		end

		removeProjectileInstance(projectile)
		table.remove(Projectiles, table.find(Projectiles, projectile))
	end

	lastRenderStep = os.clock()
end)

signals.PauseGame:Connect(function()
	isPaused = true
end)

signals.ResumeGame:Connect(function()
	isPaused = false
end)

return module
