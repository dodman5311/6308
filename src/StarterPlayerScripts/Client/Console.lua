--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Globals = require(ReplicatedStorage.Shared.Globals)

--// Instances
local guiInstance = ReplicatedStorage.Console
local objects = guiInstance.Objects
local player = Players.LocalPlayer

--// Modules
local commands = require(Globals.Shared.Commands)
local util = require(Globals.Vendor.Util)
local net = require(Globals.Packages.Net)

--// Values

local fullGui = {}
local buttonSignals = {}
local inGui = false
local inCommand

local module = {}

local doCommandEvent = net:RemoteEvent("DoCommand")

--// Functions

local function displayZeros(number)
	local Zeros = {}
	local dif = 3 - string.len(number)

	for i = 0, dif, 1 do
		Zeros[i] = "0"
	end

	return table.concat(Zeros) .. number
end

local function doCommand(commandIndex, ...)
	doCommandEvent:FireServer(commandIndex, ...)

	local command = commands[commandIndex]

	if not command["ExecuteClient"] then
		return
	end
	command.ExecuteClient(...)
end

local function setUpGui()
	local newGui = guiInstance:Clone()
	newGui.Parent = player:WaitForChild("PlayerGui")

	for _, guiObject in ipairs(newGui:GetDescendants()) do
		fullGui[guiObject.Name] = guiObject
	end
	fullGui.Gui = newGui
end

local function reset()
	for index, commandFrame in pairs(fullGui.Commands:GetChildren()) do
		if not commandFrame:IsA("Frame") or not commandFrame:FindFirstChild("ParamsFrame") then
			continue
		end
		commandFrame.ParamsFrame:Destroy()
	end

	inCommand = nil
end

local function disconnectButtons(signals)
	for _, signal in ipairs(signals) do
		signal:Disconnect()
	end
end

local function createOptionButton(parent, option)
	local newOptionButton = objects.Option:Clone()
	newOptionButton.Parent = parent
	newOptionButton.Visible = true

	if typeof(option) == "string" then
		newOptionButton.Button.Text = option
	elseif typeof(option) == "boolean" then
		newOptionButton.Button.Text = option and "True" or "False"
	elseif typeof(option) == "Instance" then
		newOptionButton.Button.Text = option.Name
	end

	return newOptionButton
end

local function createInputOptionButton(parent)
	local newOptionButton = objects.InputOption:Clone()
	newOptionButton.Parent = parent
	newOptionButton.Visible = true

	return newOptionButton
end

local function animateParametersFrameEntry(frame, optionCount)
	local ti = TweenInfo.new(0.05)

	frame.Line1.Size = UDim2.new(0, 0, 0, 1)
	frame.Line2.Size = UDim2.new(0, 1, 0, 0)
	frame.Title.Visible = false

	util.flickerUi(frame.Title, 0.025, 4, true)

	local lineSize = ((optionCount * 2) - 1) / 10

	util.tween(frame.Line1, ti, { Size = UDim2.new(0.1, 0, 0, 1) }, true)
	util.tween(frame.Line2, ti, { Size = UDim2.new(0, 1, lineSize, 0) }, true)
end

local function animateParameterButtonEntry(button)
	local ti = TweenInfo.new(0.05)

	button.Line1.Size = UDim2.new(0, 0, 0, 1)
	button.Button.Visible = false

	button.Numbers.Text = "OPT_" .. displayZeros(math.random(0, 999))

	util.tween(button.Line1, ti, { Size = UDim2.new(0.2, 0, 0, 1) }, false, function()
		if not button:FindFirstChild("Button") then
			return
		end
		util.flickerUi(button.Button, 0.025, 4, true)
	end)
end

local function createParameterFrame(parent, command, parameter)
	local signals = {}
	local selectedParameter
	local selectedParameterButton

	local newParamsFrame = objects.ParamsFrame:Clone()
	newParamsFrame.Parent = parent
	newParamsFrame.Visible = true

	newParamsFrame.Title.Text = string.upper(parameter.Name)

	animateParametersFrameEntry(newParamsFrame, #parameter.Options)

	for _, option in ipairs(parameter.Options) do
		if option == "_Input" then
			local newOption = createInputOptionButton(newParamsFrame.Params)
			animateParameterButtonEntry(newOption)

			local textBox = newOption.Button

			signals[#signals + 1] = textBox.FocusLost:Connect(function()
				if not inCommand then
					return
				end

				local logText = textBox.Text

				selectedParameter = logText
				selectedParameterButton = newOption

				textBox.Changed:Connect(function()
					textBox.Text = logText
				end)
			end)
		else
			local newOption = createOptionButton(newParamsFrame.Params, option)
			animateParameterButtonEntry(newOption)

			signals[#signals + 1] = newOption.Button.MouseButton1Click:Connect(function()
				selectedParameter = option
				selectedParameterButton = newOption
			end)
		end
	end

	repeat
		task.wait()
	until selectedParameter ~= nil

	disconnectButtons(signals)

	return selectedParameter, selectedParameterButton
end

local function enterCommand(parent, index, command)
	if inCommand then
		reset()

		if inCommand == parent then
			return
		end
	end

	inCommand = parent

	local parameters = {}

	local currentParent = parent

	for index, parameter in ipairs(command.Parameters) do
		local value

		value, currentParent = createParameterFrame(currentParent, command, parameter)
		table.insert(parameters, value)
	end

	doCommand(index, table.unpack(parameters))

	parent.ParamsFrame.Visible = true
	util.flickerUi(parent.ParamsFrame, 0.025, 4)
	parent.ParamsFrame:Destroy()

	inCommand = nil
end

local function createcommandButton(index, command)
	local newButton = objects.Command:Clone()
	newButton.Parent = fullGui.Commands
	newButton.Visible = true

	local button = newButton.CommandButton.Button
	local name = string.gsub(index, "_", " ")

	newButton.CommandButton.Numbers.Text = "CMD_" .. displayZeros(math.random(0, 999))
	button.Text = string.upper(name)

	return newButton
end

local function loadCommandButtons()
	for _, button in ipairs(fullGui.Commands:GetChildren()) do
		if not button:IsA("Frame") then
			continue
		end
		button:Destroy()
	end

	local signals = {}

	for index, command in pairs(commands) do
		local newButton = createcommandButton(index, commands)
		local button = newButton.CommandButton.Button

		table.insert(
			signals,
			button.MouseButton1Click:Connect(function()
				enterCommand(newButton, index, command)
			end)
		)
	end

	return signals
end

local function openGui()
	if player.UserId ~= 72859198 then
		return
	end

	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Quad)
	buttonSignals = loadCommandButtons()

	fullGui.Gui.Enabled = true
	fullGui.Frame.Position = UDim2.fromScale(0.5, -1)

	util.tween(fullGui.Frame, ti, { Position = UDim2.fromScale(0.5, 0.025) })
end

local function closeGui()
	local ti = TweenInfo.new(0.1, Enum.EasingStyle.Quad)

	disconnectButtons(buttonSignals)

	util.tween(fullGui.Frame, ti, { Position = UDim2.fromScale(0.5, -1) }, false, function()
		fullGui.Gui.Enabled = false
	end)

	reset()
end

--// Main //--

function module:GameInit()
	print("Init Console")
	setUpGui()
	closeGui()
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then
		return
	end

	if input.KeyCode == Enum.KeyCode.Backquote then
		if inGui then
			closeGui()
		else
			openGui()
		end

		inGui = not inGui
		UserInputService.MouseIconEnabled = inGui
	end
end)

return module
