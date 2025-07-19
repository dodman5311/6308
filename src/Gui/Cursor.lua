local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local lastInput = UserInputService:GetLastInputType()
local scales = require(Globals.Vendor.Scales)
local cursorScale = scales.new("CursorScale")

local function checkForGamepad()
	for i = 1, 8 do
		if lastInput == Enum.UserInputType["Gamepad" .. i] then
			return true
		end
	end
end

function module.Init(player, ui, frame)
	frame.Cursor.Visible = false

	RunService.RenderStepped:Connect(function()
		local mousePos = UserInputService:GetMouseLocation()
		frame.Cursor.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	end)

	UserInputService.InputBegan:Connect(function()
		lastInput = UserInputService:GetLastInputType()

		if checkForGamepad() then
			frame.Cursor.Visible = false
			return
		end
	end)

	cursorScale.Reached:Connect(function()
		frame.Cursor.Visible = true
	end)

	cursorScale.Lost:Connect(function()
		frame.Cursor.Visible = false
	end)
end

function module.Toggle(player, ui, frame, Value)
	if Value then
		cursorScale:Add()
	else
		cursorScale:Remove()
	end
end

return module
