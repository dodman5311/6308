local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local module = {}

function module.Init(player, ui, frame)
	frame.Cursor.Visible = false

	RunService.RenderStepped:Connect(function()
		if UserInputService.GamepadEnabled then
			frame.Cursor.Visible = false
			return
		end

		local mousePos = UserInputService:GetMouseLocation()
		frame.Cursor.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	end)
end

function module.Toggle(player, ui, frame, Value)
	frame.Cursor.Visible = Value
end

return module
