local module = { animations = {} }

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local janitor = require(Globals.Packages.Janitor)

--// Functions
function module:loadAnimations(subject, animationsFolder)
	local animationController = subject:FindFirstChildOfClass("Humanoid")
		or subject:FindFirstChildOfClass("AnimationController")
	if not animationController then
		return
	end

	local subjectJanitor = janitor.new()
	subjectJanitor:LinkToInstance(subject)

	if not self.animations[subject] then
		self.animations[subject] = {}
	end

	local animsList = animationsFolder:GetChildren()

	for _, animation in ipairs(animsList) do
		self.animations[subject][animation.Name] = animationController.Animator:LoadAnimation(animation)
	end

	subjectJanitor:Add(function()
		self.animations[subject] = nil
	end)
end

function module:getAnimation(subject, animationName)
	local animList = self.animations[subject]
	if not animList then
		return
	end
	local animation = animList[animationName]
	return animation
end

function module:playAnimation(subject, animationName, priority, noReplay, ...)
	local animation = self:getAnimation(subject, animationName)

	if not animation or (noReplay and animation.IsPlaying) then
		return animation
	end
	animation.Priority = priority or animation.Priority
	animation:Play(...)

	return animation
end

function module:stopAnimation(subject, animationName, ...)
	local animation = self:getAnimation(subject, animationName)

	if not animation then
		return
	end
	self:getAnimation(subject, animationName):Stop(...)
	return animation
end

--// Main //--

return module
