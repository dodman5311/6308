local module = {
	Souls = 0,
	MaxDistance = 15,
	DropChance = 25,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)
local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects

local Player = Players.LocalPlayer

--// Modules
local Signals = require(Globals.Shared.Signals)

--// Values

--// Functions

function module.CreateDrop(position, dropType)
	local newDrop = Effects:FindFirstChild(dropType):Clone()

	newDrop.Parent = workspace

	newDrop.CFrame = CFrame.new(position)
	newDrop.AssemblyLinearVelocity = Vector3.new(math.random(-30, 30), math.random(40, 50), math.random(-30, 30))

	newDrop.CollisionGroup = "Drop"
	newDrop:SetAttribute("DropType", dropType)
	task.delay(0.1, function()
		CollectionService:AddTag(newDrop, "Drop")
		CollectionService:AddTag(newDrop, "Pickup")
	end)

	return newDrop
end

local function checkForDrops()
	local character = Player.Character

	if not character then
		return
	end

	local characterCFrame = character:GetPivot()
	local characterPosition = characterCFrame.Position

	for _, drop in ipairs(CollectionService:GetTagged("Drop")) do
		local distance = (drop.Position - characterPosition).Magnitude

		local beyondMaxDistance = distance > module.MaxDistance

		drop.Anchored = not beyondMaxDistance
		drop.CanCollide = beyondMaxDistance

		if beyondMaxDistance then
			continue
		end

		if distance <= 3 then
			Signals["Add" .. drop:GetAttribute("DropType")]:Fire(1)
			drop:Destroy()
			return
		end

		drop.CFrame = drop.CFrame:Lerp(characterCFrame, 0.25)
	end
end

--// Main //--

RunService.RenderStepped:Connect(checkForDrops)

return module
