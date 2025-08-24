local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Globals = require(ReplicatedStorage.Shared.Globals)
local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local Signal = require(Globals.Packages.Signal)
local Net = require(Globals.Packages.Net)
local User = require(script.User)

local assignedIds = {}
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

	local id = math.random(0, 999)
	while table.find(assignedIds, id) do
		id = math.random(0, 999)
	end

	player:SetAttribute("Id", id)
	table.insert(assignedIds, id)

	local assignedRoom = Instance.new("ObjectValue")
	assignedRoom.Name = "Room"
	assignedRoom.Parent = player

	for _, room in ipairs(CollectionService:GetTagged("EmptyRoom")) do
		assignedRoom.Value = room
		room:RemoveTag("EmptyRoom")
		break
	end

	if player.Character then
		player.Character:PivotTo(assignedRoom.Value:GetPivot())
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		character:PivotTo(assignedRoom.Value:GetPivot())
	end)
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
