local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects

--// Modules
local Net = require(Globals.Packages.Net)
local util = require(Globals.Vendor.Util)

local damageRemote = Net:RemoteEvent("Damage")

--// Values
local Projectiles = {}

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

	if not Players:GetPlayerFromCharacter(model) then
		return
	end

	return model
end

local function createProjectile(speed, cframe, spread)
	local offset = CFrame.Angles(util.randomAngle(spread), util.randomAngle(spread), util.randomAngle(spread))

	local newInstance = Effects.EnemyBullet:Clone()
	newInstance.Parent = workspace.Ignore
	newInstance.CFrame = cframe * offset

	local newProjectile = {
		Instance = newInstance,
		Speed = speed,
		LifeTime = 5,
		Age = 0,
	}

	table.insert(Projectiles, newProjectile)
end

local function checkRaycast(projectile, raycastDistance)
	if raycastDistance > 1000 then
		return { Instance = nil }
	end

	local cframe = projectile.Instance.CFrame

	local rp = RaycastParams.new()
	rp.CollisionGroup = "NpcBullet"

	local newRaycast = workspace:Spherecast(cframe.Position, 0.5, cframe.LookVector * raycastDistance, rp)

	return newRaycast
end

--// Main //--

Net:Connect("CreateProjectile", createProjectile)

local lastRenderStep = os.clock()

RunService.RenderStepped:Connect(function()
	for _, projectile in ipairs(Projectiles) do
		if projectile.Age >= projectile.LifeTime then
			projectile.Instance:Destroy()
			table.remove(Projectiles, table.find(Projectiles, projectile))
			continue
		end

		local timePassed = lastRenderStep - os.clock()

		projectile.Age += timePassed

		local distanceMoved = -timePassed * projectile.Speed
		projectile.Instance.CFrame *= CFrame.new(0, 0, -(distanceMoved + 0.1))

		local raycast = checkRaycast(projectile, distanceMoved)

		if not raycast then
			continue
		end

		local hitModel = checkPlayer(raycast.Instance)
		if hitModel then
			damageRemote:FireServer(hitModel, 1)
		end

		projectile.Instance:Destroy()
		table.remove(Projectiles, table.find(Projectiles, projectile))
	end

	lastRenderStep = os.clock()
end)

return module
