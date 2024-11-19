local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local module = {}

local lastInput = UserInputService:GetLastInputType()

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
end

function module.Toggle(player, ui, frame, Value)
	frame.Cursor.Visible = Value
end

return module
