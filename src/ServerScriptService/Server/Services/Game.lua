local gameModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local globals = require(ReplicatedStorage.Shared.Globals)
local util = require(globals.Vendor.Util)
local net = require(globals.Packages.Net)
local acts = require(globals.Vendor.Acts):new()

local assets = globals.Assets

local broadcastEvent = net:RemoteEvent("BroadcastMessage")
local executeEvent = net:RemoteFunction("StartExecutionSequence")
local toggleConsole = net:RemoteEvent("ToggleConsole")
local enableVoting = net:RemoteEvent("EnableVoting")

local function broadcastMessage(message, messageTime, messageType, player, ending)
	if acts:checkAct("GameOver") and not ending then
		return
	end

	if player then
		broadcastEvent:FireClient(player, message, messageType)
	else
		broadcastEvent:FireAllClients(message, messageType)
	end

	if not messageTime then
		return
	end
	task.wait(messageTime)
end

function gameModule:startIntro(introTime)
	local t = (introTime - 2) / 2
	for _, player in ipairs(Players:GetPlayers()) do
		broadcastMessage("You are specimen #" .. player:GetAttribute("Id") .. ".", t, nil, player)
	end

	broadcastMessage("Please comply.", t)
	task.wait(2)
end

function gameModule:enableCommunication(communicationTime)
	if acts:checkAct("GameOver") then
		return
	end

	toggleConsole:FireAllClients(true, communicationTime)
	broadcastMessage("Proceed to the console.", communicationTime)
end

function gameModule:startMinigame(minigameTime)
	if acts:checkAct("GameOver") then
		return true
	end

	broadcastMessage("Proceed to the testing tablet.", minigameTime)
	return true
end

function gameModule:minigameFailed()
	broadcastMessage("Test failed.", 5)
	broadcastMessage("Auto selecting a specimen for <b>removal</b>.", 5)

	gameModule:executePlayer(util.getRandomChild(Players))
end

function gameModule:minigameSucceeded()
	broadcastMessage("Test completed.", 5)
end

local function getMostVotedPlayer()
	local selectedPlayer
	local mostVotes = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("Votes") < mostVotes then
			continue
		end

		selectedPlayer = player
		mostVotes = player:GetAttribute("Votes")
	end

	return selectedPlayer
end

function gameModule:enableVoting(votingTime)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Votes", 0)
	end

	enableVoting:FireAllClients(votingTime)
	broadcastMessage("Please select a specimen for <b>removal</b>.", votingTime)

	local playerToExecute = getMostVotedPlayer()
	if not playerToExecute then
		broadcastMessage("Auto selecting a specimen for <b>removal</b>.", 5)
		playerToExecute = util.getRandomChild(Players)
	end

	return playerToExecute
end

function gameModule:executePlayer(player)
	if acts:checkAct("GameOver") then
		return
	end

	acts:createAct("Executing")

	broadcastMessage("#" .. player:GetAttribute("Id") .. " is being <b>removed</b>.")

	local spared = executeEvent:InvokeClient(player)

	if spared then
		broadcastMessage("Removal has been <b>canceled</b>.", 7, "Spare")
	else
		TeleportService:Teleport(7760123853, player)

		repeat
			task.wait()
		until not player or not player.Parent
	end

	acts:removeAct("Executing")

	if #Players:GetPlayers() <= 1 then
		gameModule:endGame(Players:FindFirstChildOfClass("Player"))
	end

	return spared
end

function gameModule.playerQuit(player)
	local Room = player.Room.Value
	util.PlaySound(assets.Sounds.Revolver, Room.PrimaryPart, 0.15)
	task.wait(1)

	broadcastMessage("#" .. player:GetAttribute("Id") .. " has <b>left</b>.", 5)

	if #Players:GetPlayers() <= 1 then
		gameModule:endGame(Players:FindFirstChildOfClass("Player"))
	end
end

function gameModule:endGame(player)
	acts:waitForAct("Executing")
	acts:createAct("GameOver")

	broadcastMessage("#" .. player:GetAttribute("Id") .. " <b>Remains</b>.", 5, "Spare", player, true)
	broadcastMessage("Please proceed.", nil, "Spare", player, true)

	task.wait(math.huge)
end

function gameModule:createRoom(x, z)
	local newRoom = assets.Models.Room:Clone()
	newRoom.Parent = workspace.Rooms
	newRoom:PivotTo(CFrame.new(x * 30, 0, z * 30))
	newRoom:AddTag("EmptyRoom")
end

function gameModule:GameInit()
	for x = 0, 2 do
		for z = 0, 1 do
			gameModule:createRoom(x, z)
		end
	end
end

function gameModule:GameStart()
	repeat
		task.wait()
	until #Players:GetPlayers() > 0

	for _, player in ipairs(Players:GetPlayers()) do
		if not player.Character then
			player.CharacterAdded:Wait()
		end
	end

	task.wait(3)

	gameModule:startIntro(10)
	gameModule:enableCommunication(30)
	toggleConsole:FireAllClients(false)

	repeat
		local success = gameModule:startMinigame(20)

		if not success then
			gameModule:minigameFailed()
		else
			gameModule:minigameSucceeded()
		end

		gameModule:enableCommunication(60)

		local playerToExecute = gameModule:enableVoting(20)
		toggleConsole:FireAllClients(false)

		gameModule:executePlayer(playerToExecute)
	until #Players:GetPlayers() <= 1

	gameModule:endGame(Players:FindFirstChildOfClass("Player"))
end

Players.PlayerRemoving:Connect(gameModule.playerQuit)
TeleportService.TeleportInitFailed:Connect(function(player: Player)
	player:Kick("Teleport Failed, the game must continue.")
end)

return gameModule
