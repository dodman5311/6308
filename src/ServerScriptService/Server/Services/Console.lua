local console = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local globals = require(ReplicatedStorage.Shared.Globals)
local net = require(globals.Packages.Net)

local sendMessage = net:RemoteEvent("SendMessage")

function console.replicateMessage(player, message)
	sendMessage:FireAllClients(player, message)
end

function console.updatePlayerVote(_, playerToVote, amount)
	playerToVote:SetAttribute("Votes", playerToVote:GetAttribute("Votes") + amount)
end

net:Connect("SendMessage", console.replicateMessage)
net:Connect("SendVote", console.updatePlayerVote)

function console:GameInit()
	--Prestart Code
end

function console:GameStart()
	--Start Code
end

return console
