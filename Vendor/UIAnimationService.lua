local module = {}

local RunService = game:GetService("RunService")
local acts = require(script.Parent.Acts)

local animations = {}

export type Animation2D = {
	NextFrame: (self: Animation2D) -> nil,
	SetToFrame: (self: Animation2D, frameNumber: number) -> nil,
	RunAnimation: (self: Animation2D) -> nil,
	Pause: (self: Animation2D) -> nil,
	Resume: (self: Animation2D) -> nil,
	Stop: (self: Animation2D) -> nil,
	OnEnded: RBXScriptSignal,
	OnStepped: RBXScriptSignal,
	OnFrameReached: (self: Animation2D, Frame: number) -> RBXScriptSignal,
}

function module.PlayAnimation(
	frame: GuiObject,
	frameDelay: number,
	loop: boolean?,
	stayOnLastFrame: boolean?,
	startOnFrame: number?
): Animation2D?
	if animations[frame] then
		animations[frame]:Stop()
	end

	local image = frame:FindFirstChild("Image")
	if not image then
		return
	end

	image.Position = UDim2.fromScale(0, 0)

	local lastFrameStep = os.clock()

	local x = 0
	local y = 0

	local frames = image:GetAttribute("Frames") or image.Size.X.Scale * image.Size.Y.Scale
	local currentFrames = image:GetAttribute("Frames") or image.Size.X.Scale * image.Size.Y.Scale
	local currentFrame = 0
	local paused = false
	local framesToHit = {}

	local onEndedInstance = Instance.new("BindableEvent")
	local onSteppedInstance = Instance.new("BindableEvent")
	local frameReachedSignals = {}

	local newAnimation: Animation2D = {
		NextFrame = function(self: Animation2D)
			x += 1
			currentFrames -= 1
			currentFrame += 1

			if x > image.Size.X.Scale - 1 then
				y += 1
				x = 0
			end
		end,

		SetToFrame = function(self: Animation2D, frameNumber: number)
			x = 0
			y = 0
			for _ = 1, frameNumber do
				self:NextFrame()
			end
			image.Position = UDim2.fromScale(-x, -y)
		end,

		RunAnimation = function(self)
			if paused or acts:checkAct("Paused") then
				lastFrameStep = os.clock()
				return
			end

			if not frame or not frame.Parent then
				self:Stop()
				return
			end

			if os.clock() - lastFrameStep < frameDelay then
				return
			end

			self:NextFrame()
			onSteppedInstance:Fire(currentFrame)

			if currentFrames <= 0 then
				currentFrames = frames
				currentFrame = 0
				x = 0
				y = 0

				if not loop then
					onEndedInstance:Fire()

					if not stayOnLastFrame then
						image.Position = UDim2.fromScale(x, y)
					end

					self:Stop()
					return
				end
			end

			image.Position = UDim2.fromScale(-x, -y)

			for _, v in ipairs(framesToHit) do
				if currentFrame ~= v[1] then
					continue
				end
				v[2]:Fire(currentFrame, image.Position)
			end

			lastFrameStep = os.clock()
		end,

		OnEnded = onEndedInstance.Event,

		OnStepped = onSteppedInstance.Event,

		OnFrameReached = function(self: Animation2D, Frame: number): RBXScriptSignal
			local onFrameReachedInstance = Instance.new("BindableEvent")

			table.insert(frameReachedSignals, onFrameReachedInstance)

			local reachedSignal = onFrameReachedInstance
			table.insert(framesToHit, { Frame, reachedSignal })

			return reachedSignal.Event
		end,

		Pause = function(self: Animation2D)
			paused = true
		end,

		Resume = function(self: Animation2D)
			paused = false
		end,

		Stop = function(self: Animation2D)
			if not module.CheckPlaying(frame) then
				return
			end

			------ Destroy
			onEndedInstance:Destroy()
			onSteppedInstance:Destroy()
			for _, signal in ipairs(frameReachedSignals) do
				signal:Destroy()
			end

			animations[frame] = nil
			------

			if not image or not image.Parent then
				return
			end

			if not stayOnLastFrame then
				image.Position = UDim2.fromScale(0, 0)
			end
		end,
	}

	if startOnFrame then
		newAnimation:SetToFrame(startOnFrame)
	end

	animations[frame] = newAnimation
	return newAnimation
end

function module.StopAnimation(frame)
	local animation: Animation2D = animations[frame]
	if animation then
		animation:Stop()
	end
end

function module.CheckPlaying(frame) -- returns the animation if it's playing
	if animations[frame] then
		return animations[frame]
	end
	return
end

RunService.Heartbeat:Connect(function()
	for _, animation in pairs(animations) do
		animation:RunAnimation()
	end
end)

return module
