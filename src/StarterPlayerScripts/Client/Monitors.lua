local monitors = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local globals = require(ReplicatedStorage.Shared.Globals)
local assets = globals.Assets
local player = Players.LocalPlayer

local util = require(globals.Vendor.Util)
local net = require(globals.Packages.Net)
local acts = require(globals.Vendor.Acts)

local guis = {}
local rng = Random.new()
local executeEvent = net:RemoteFunction("StartExecutionSequence")

local function doForRoomUi(action)
	for _, ui in ipairs(guis) do
		action(ui)
	end
end

function monitors.broadcastMessage(message, messageType)
	doForRoomUi(function(ui)
		ui.Message.TextColor3 = Color3.fromRGB(0, 255, 94)
		ui.Background.BackgroundColor3 = Color3.fromRGB(0, 12, 11)
	end)

	if messageType == "Execute" then
		util.PlaySound(assets.Sounds.Execute, script)
		doForRoomUi(function(ui)
			ui.Message.TextColor3 = Color3.fromRGB(255, 0, 0)
			ui.Background.BackgroundColor3 = Color3.fromRGB(12, 0, 0)
		end)
	elseif messageType == "Spare" then
		util.PlaySound(assets.Sounds.Spare, script)
	elseif messageType ~= "Silent" then
		if acts:checkAct("Executing") then
			return
		end
		util.PlaySound(assets.Sounds.Message, script)
	end

	doForRoomUi(function(ui)
		ui.Message.Visible = true
		ui.Message.Text = string.upper(message)
	end)
end

local function toggleLights(value)
	for _, light in ipairs(CollectionService:GetTagged("Light")) do
		light.Transparency = value and 0.8 or 0
		light.PointLight.Enabled = value
		light.LensFlare.Enabled = value
	end
end

local function setLightColor(color)
	for _, light in ipairs(CollectionService:GetTagged("Light")) do
		light.Color = color
		light.PointLight.Color = color
		light.LensFlare.FlareTexture.ImageColor3 = color
	end
end

function monitors.startExecutionSequence()
	acts:createAct("Executing")

	local room = player:FindFirstChild("Room").Value
	if not room then
		return
	end

	toggleLights(false)
	setLightColor(Color3.new(1))
	monitors.broadcastMessage("", "Silent")

	task.wait(1)

	for _ = 1, 4 do
		monitors.broadcastMessage("Stay Calm.", "Execute")
		toggleLights(true)
		task.wait(1)
		toggleLights(false)
		task.wait(1)

		monitors.broadcastMessage("Follow procedure.", "Execute")
		toggleLights(true)
		task.wait(1)
		toggleLights(false)
		task.wait(1)
	end

	setLightColor(Color3.new(1, 1, 1))
	toggleLights(true)

	local chance = rng:NextNumber(0, 100)

	acts:removeAct("Executing")

	if chance < 20 or #Players:GetPlayers() <= 1 then
		return true
	end
end

function monitors.loadGuis()
	guis = {}
	local room = player:WaitForChild("Room").Value

	for _, monitor in ipairs(room.Monitors:GetChildren()) do
		local newGui = assets.Gui.MonitorGui:Clone()
		newGui.Parent = monitor.Screen
		newGui.Adornee = monitor.Screen
		newGui.Message.Visible = false

		table.insert(guis, newGui)
	end
end

function monitors:GameInit()
	monitors.loadGuis()
end

function monitors:GameStart()
	--Start Code
end

net:Connect("BroadcastMessage", monitors.broadcastMessage)
executeEvent.OnClientInvoke = monitors.startExecutionSequence

return monitors
