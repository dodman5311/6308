local module = {
	jumpLock = false,
}

local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local player = players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local giftService = require(Globals.Client.Services.GiftsService)
local momentum = require(Globals.Client.Controllers.AirController)
local acts = require(Globals.Vendor.Acts)
local signals = require(Globals.Shared.Signals)

local doubleJump = false
local wallJump = false

local input

local function DoubleJump()
	local character = player.Character
	if not character then
		return
	end

	local primaryPart = character.PrimaryPart
	local humanoid = character.Humanoid

	if
		humanoid:GetState() == Enum.HumanoidStateType.Freefall
		and module.jumpLock == false
		and not acts:checkAct("wallrunning")
	then
		if doubleJump or wallJump then
			if not doubleJump then
				wallJump = false
			end
			doubleJump = false

			local currentVel = (primaryPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
			primaryPart.AssemblyLinearVelocity = Vector3.new(0, 25, 0) + (humanoid.MoveDirection * currentVel)
			momentum.switchFalling(true)

			--util.PlaySound(script.Jump, script, 5)
			repeat
				task.wait()
			until humanoid:GetState() == Enum.HumanoidStateType.Landed
				or humanoid.Health <= 0
				or acts:checkAct("wallrunning")
				or not player.Character

			if giftService.CheckGift("Master_Scouting") then
				doubleJump = true
			end
		end
	end
end

function module:OnSpawn()
	doubleJump = false
	input = uis.InputBegan:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.Space or Input.KeyCode == Enum.KeyCode.ButtonA then
			DoubleJump()
		end
	end)
end

signals.Jump:Connect(DoubleJump)

function module:OnDied()
	input:Disconnect()
end

giftService.OnGiftAdded:Connect(function(gift)
	if gift ~= "Master_Scouting" then
		return
	end

	doubleJump = true
end)

acts.OnActAdded:Connect(function(act)
	if act ~= "wallrunning" or not giftService.CheckGift("Spiked_Sabatons") then
		return
	end

	wallJump = true
end)

return module
