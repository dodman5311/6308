local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local Net = require(Globals.Packages.Net)
local Signal = require(Globals.Packages.Signal)

local LOCAL_PLAYER = Players.LocalPlayer

local UserController = {}
UserController.playerLoaded = false
UserController.playerLoadedEvent = Signal.new()

local Users = {}

function UserController:GetLocalUser()
	local localUser = Users[LOCAL_PLAYER]

	if localUser then
		return localUser
	end

	if not UserController.playerLoaded then
		UserController.playerLoadedEvent:Wait()
	end

	return Users[LOCAL_PLAYER]
end

function UserController:GameInit()
	Net:Connect("UserAdded", function(user)
		print("User Added Event")
		Users[user.player] = user

		if self.playerLoaded then
			return
		end

		if user.player == LOCAL_PLAYER then
			-- local player loaded.
			self.playerLoaded = true
			UserController.playerLoadedEvent:Fire()
		end
	end)
end

function UserController:GameStart() end

return UserController
