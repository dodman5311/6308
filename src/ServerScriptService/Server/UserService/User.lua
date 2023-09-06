local Players = game:GetService("Players")

local User = {}

function User.new(player, profileStore)
	local self = {}

	local profile = User.LoadData(player, profileStore)

	return {
		player = player,
		profile = profile,
	}
end

function User.LoadData(player, profileStore)
	if not profileStore then
		warn("Tried to load data before ProfileTemplate was finished loading.")
		return
	end
	local profile = profileStore:LoadProfileAsync(`Player_{player.UserId}`)

	if not profile then
		player:Kick()
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		profile = nil
		player:Kick()
	end)

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	return profile
end

function User.Remove(user)
	user.profile:Release()
end

return User
