local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local Signal = require(Globals.Packages.Signal)
local Net = require(Globals.Packages.Net)
local User = require(script.User)

local ProfileTemplate = {}

local UserService = {}
UserService.UserAdded = Signal.new()
UserService.UserAddedRemote = Net:RemoteEvent("UserAdded")

local Users = {}

local function PlayerAdded(player)
	-- make sure there is not already a user for player
	local checkUser = UserService:GetUser(player)
	if checkUser then
		return
	end

	local user = User.new(player, UserService.ProfileStore)
	Users[player] = user

	UserService.UserAdded:Fire(user)
	UserService.UserAddedRemote:FireAllClients(UserService:SerializeUser(user))
end

function UserService:InitializeProfileTemplate()
	for _, module in script.UserData:GetChildren() do
		local controller = require(module)

		if not controller.GetDefault then
			continue
		end

		local data = controller:GetDefault()
		if not data then
			error(`Data controller '{module.Name}' doesn't return anything from GetDefault`)
			continue
		end

		ProfileTemplate[controller.dataId] = data
	end
end

function UserService:SerializeUser(user)
	return {
		player = user.player,
		Data = user.profile.Data,
	}
end

function UserService:GetUsers()
	local userArray = {}

	for _, user in Users do
		table.insert(userArray, user)
	end

	return userArray
end

function UserService:GetUser(player: Player): {}
	return Users[player]
end

function UserService:GameInit()
	self:InitializeProfileTemplate()
	self.ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)
end

function UserService:GameStart()
	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in Players:GetPlayers() do
		PlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local user = UserService:GetUser(player)
		User.Remove(user)
		Users[player] = nil
	end)
end

return UserService
