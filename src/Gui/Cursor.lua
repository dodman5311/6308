local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local lastInput = UserInputService:GetLastInputType()
local scales = require(ReplicatedStorage.Vendor.Scales)
local cursorScale = scales.new("CursorScale")

local function checkForGamepad()
	for i = 1, 8 do
		if lastInput == Enum.UserInputType["Gamepad" .. i] then
			break
		end
	end

	return true
end

function module.Init(player, ui, frame)
	frame.Cursor.Visible = false

	RunService.RenderStepped:Connect(function()
		local mousePos = UserInputService:GetMouseLocation()
		frame.Cursor.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	end)

	-- UserInputService.InputBegan:Connect(function()
	-- 	lastInput = UserInputService:GetLastInputType()

	-- 	if checkForGamepad() then
	-- 		print("HAS GAMEPAD")
	-- 		frame.Cursor.Visible = false
	-- 		return
	-- 	end
	-- end)

	cursorScale.Changed:Connect(function(value)
		frame.Cursor.Visible = value
	end)
end

function module.Toggle(player, ui, frame, Value, index)
	if Value then
		cursorScale:Add(index)
	else
		cursorScale:Remove(index)
	end
end

return module
