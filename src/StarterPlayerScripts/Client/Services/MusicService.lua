local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local util = require(Globals.Vendor.Util)
local timer = require(Globals.Vendor.Timer):newQueue()
local soulsService = require(Globals.Client.Services.SoulsService)

local net = require(Globals.Packages.Net)

local assets = ReplicatedStorage.Assets
local music = assets.Music

local currentPlaying

local fallBackTrack = Instance.new("Sound")

local musicTimer = timer:new("PlayCalm", 5, function()
	soulsService.CalculateDropChance()
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	if not currentPlaying or not tonumber(currentPlaying.Name) then
		return
	end

	local calm = currentPlaying:FindFirstChild("Calm")
	local track = currentPlaying:FindFirstChild("Track")

	util.tween(calm, ti, { Volume = 0.25 })
	util.tween(track, ti, { Volume = 0 })
end)

local function switchTrack()
	if not currentPlaying or not tonumber(currentPlaying.Name) then
		return
	end

	local calm = currentPlaying:FindFirstChild("Calm")
	local track = currentPlaying:FindFirstChild("Track")

	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	local isCalm = workspace:GetAttribute("EnemiesInCombat") <= 1

	if isCalm then
		musicTimer:Run()
	else
		musicTimer:Cancel()
		soulsService.CalculateDropChance()

		local volume = track:GetAttribute("Volume") or 0.35

		util.tween(calm, ti, { Volume = 0 })
		util.tween(track, ti, { Volume = volume })
	end
end

function module.stopMusic(trackToStop)
	if not currentPlaying or (trackToStop and currentPlaying.Name ~= trackToStop) then
		return
	end

	local calm = currentPlaying:FindFirstChild("Calm") or fallBackTrack
	local track = currentPlaying:FindFirstChild("Track")

	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	util.tween(calm, ti, { Volume = 0 })
	util.tween(track, ti, { Volume = 0 }, false, function()
		calm:Stop()
		track:Stop()
	end, Enum.PlaybackState.Completed)
end

function module.playMusic(level)
	local ti = TweenInfo.new(0.05, Enum.EasingStyle.Linear)

	if not level then
		level = workspace:GetAttribute("TotalLevel") --lastLevel
	end

	module.stopMusic()

	currentPlaying = music:FindFirstChild(level)

	if not currentPlaying then
		return
	end

	local calm = currentPlaying:FindFirstChild("Calm") or fallBackTrack
	local track = currentPlaying:FindFirstChild("Track")

	calm:Play()
	track:Play()

	util.tween(calm, ti, { Volume = 0.25 })
	util.tween(track, ti, { Volume = 0 })

	switchTrack()
end

function module.playTrack(trackName, volume)
	module.stopMusic()

	currentPlaying = music:FindFirstChild(trackName)

	local track = currentPlaying:FindFirstChild("Track")

	track:Play()

	track.Volume = volume or 0.5
end

function module:OnSpawn()
	module.playMusic()
end

function module:OnDied()
	module.stopMusic()
end

workspace:GetAttributeChangedSignal("EnemiesInCombat"):Connect(switchTrack)
net:Connect("StopMusic", module.stopMusic)

return module
