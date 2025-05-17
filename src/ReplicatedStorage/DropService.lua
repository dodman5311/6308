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
	newDrop:SetAttribute("OriginY", position.Y - 5)

	newDrop:PivotTo(CFrame.new(position))
	newDrop.PrimaryPart.AssemblyLinearVelocity =
		Vector3.new(math.random(-30, 30), math.random(40, 50), math.random(-30, 30))

	newDrop.PrimaryPart.CollisionGroup = "Drop"
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
		local dropPosition = drop:GetPivot().Position
		local distance = (dropPosition - characterPosition).Magnitude

		local beyondMaxDistance = distance > module.MaxDistance

		drop.PrimaryPart.Anchored = not beyondMaxDistance
		drop.PrimaryPart.CanCollide = beyondMaxDistance

		if dropPosition.Y <= drop:GetAttribute("OriginY") then
			drop.PrimaryPart.Anchored = true
		end

		if beyondMaxDistance then
			continue
		end

		if distance <= 5 then
			Signals["Add" .. drop:GetAttribute("DropType")]:Fire(1)
			drop:Destroy()
			return
		end

		drop:PivotTo(drop:GetPivot():Lerp(characterCFrame, 0.25))
	end
end

--// Main //--

RunService.RenderStepped:Connect(checkForDrops)

return module
