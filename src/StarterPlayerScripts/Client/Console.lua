local consoles = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local globals = require(ReplicatedStorage.Shared.Globals)
local assets = globals.Assets
local player = Players.LocalPlayer

local util = require(globals.Vendor.Util)
local net = require(globals.Packages.Net)

local gui
local football = true
local sendMessage = net:RemoteEvent("SendMessage")
local sendVote = net:RemoteEvent("SendVote")

local connections = {}

local debounceTime = 5
local currentVote

local function startCooldown()
	local frame = gui.Frame
	local textBar = frame.TextBar.Frame
	local cooldownBar = textBar.Cooldown

	football = false

	task.delay(debounceTime, function()
		football = true
	end)

	cooldownBar.Bar.Size = UDim2.fromScale(1, 0)
	util.tween(cooldownBar.Bar, TweenInfo.new(debounceTime, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
end

function consoles.sendMessage()
	if not football then
		return
	end
	--startCooldown()

	local frame = gui.Frame
	local textBar = frame.TextBar.Frame
	local textBox = textBar.TextBox

	sendMessage:FireServer(textBox.Text)

	textBox.Text = ""
end

function consoles.recieveMessage(player, message)
	util.PlaySound(assets.Sounds.NewMessage, script)

	local messages = gui.Frame.Messages
	local newMessage = gui.Message:Clone()

	if #messages:GetChildren() >= 9 then
		messages:FindFirstChildOfClass("Frame"):Destroy()
	end

	newMessage.Parent = messages

	newMessage.MessageText.Text = message
	newMessage.Sender.Text = "#" .. player:GetAttribute("Id")
	newMessage.Visible = true
end

function voteForPlayer(player)
	if currentVote == player then
		return
	end
	if currentVote then
		sendVote:FireServer(currentVote, -1)
	end

	currentVote = player
	sendVote:FireServer(currentVote, 1)
end

function consoles.addVoteButton(player)
	local messages = gui.Frame.Messages
	local votingButton = gui.Vote:Clone()

	votingButton.Parent = messages

	votingButton.PlayerId.Text = "#" .. player:GetAttribute("Id")
	votingButton.Name = player.Name
	votingButton.Visible = true

	votingButton.Button.MouseButton1Click:Connect(function()
		voteForPlayer(player)
	end)

	return player:GetAttributeChangedSignal("Votes"):Connect(function()
		votingButton.VotesBar.Size = UDim2.fromScale(player:GetAttribute("Votes") / #Players:GetPlayers(), 0.1)
	end)
end

local function clearMessages()
	local messages = gui.Frame.Messages
	for _, child in ipairs(messages:GetChildren()) do
		if not child:IsA("Frame") then
			continue
		end
		child:Destroy()
	end
end

function consoles.ToggleConsole(value, time)
	gui.Enabled = value

	local frame = gui.Frame
	local textBar = frame.TextBar.Frame
	local votingPrompt = frame.TextBar.Prompt
	local textBox = textBar.TextBox

	for _, v in ipairs(connections) do
		v:Disconnect()
	end

	if value then
		clearMessages()
		textBox.Text = ""
		gui.Fade.BackgroundTransparency = 0

		textBar.Visible = true
		votingPrompt.Visible = false

		util.tween(gui.Fade, TweenInfo.new(1, Enum.EasingStyle.Linear), { BackgroundTransparency = 1 })
	else
		textBox:ReleaseFocus()
	end
end

function consoles.switchToVoting(time)
	currentVote = nil
	local frame = gui.Frame
	local textBar = frame.TextBar.Frame
	local votingPrompt = frame.TextBar.Prompt
	local textBox = textBar.TextBox

	clearMessages()

	util.flickerUi(votingPrompt, 0.025, 8, true)
	util.flickerUi(textBar, 0.025, 8, false)

	textBox.Text = ""
	textBox:ReleaseFocus()

	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(connections, consoles.addVoteButton(player))
		task.wait(0.1)
	end

	return connections
end

function consoles.loadGuis()
	local room = player:WaitForChild("Room").Value
	local console = room.Console

	local newGui = assets.Gui.ConsoleGui:Clone()
	newGui.Parent = console.Screen
	newGui.Adornee = console.Screen

	gui = newGui

	local frame = gui.Frame
	local textBar = frame.TextBar.Frame
	local textBox = textBar.TextBox
	local topBar = frame.TopBar
	local sendButton = textBar.SendButton
	local playerId = topBar.PlayerId

	playerId.Text = "#" .. player:GetAttribute("Id")

	sendButton.MouseButton1Click:Connect(consoles.sendMessage)

	textBox.Changed:Connect(function()
		textBox.Text = textBox.Text:sub(1, 20)
	end)

	consoles.ToggleConsole(false)
end

function consoles:GameInit()
	consoles.loadGuis()
end

function consoles:GameStart()
	--Start Code
end

net:Connect("SendMessage", consoles.recieveMessage)
net:Connect("ToggleConsole", consoles.ToggleConsole)
net:Connect("EnableVoting", consoles.switchToVoting)

return consoles
