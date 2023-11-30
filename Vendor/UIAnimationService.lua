local module = {}

local RunService = game:GetService("RunService")

local animations = {}

function module.PlayAnimation(frame, frameDelay, loop, stayOnLastFrame)
	if animations[frame] then
		animations[frame].Connection:Disconnect()
		animations[frame] = nil
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

	local newAnimation = {
		Connection = nil,

		RunAnimation = function(self)
			if os.clock() - lastFrameStep < frameDelay then
				return
			end

			x += 1
			currentFrames -= 1

			if x > image.Size.X.Scale - 1 then
				y += 1
				x = 0
			end

			if currentFrames <= 0 then
				currentFrames = frames
				x = 0
				y = 0

				if not loop then
					if self.OnEnded.func then
						task.spawn(self.OnEnded.func, self)
					end

					if not stayOnLastFrame then
						image.Position = UDim2.fromScale(x, y)
					end

					animations[frame].Connection:Disconnect()
					animations[frame] = nil
					return
				end
			end

			image.Position = UDim2.fromScale(-x, -y)

			lastFrameStep = os.clock()
		end,

		OnEnded = {
			func = nil,
			Connect = function(self, callBack)
				self.func = callBack
			end,
		},
	}

	newAnimation.Connection = RunService.Heartbeat:Connect(function()
		newAnimation:RunAnimation()
	end)

	animations[frame] = newAnimation
	return animations[frame]
end

function module.StopAnimation(frame)
	if not animations[frame] then
		return
	end
	frame.Image.Position = UDim2.fromScale(0, 0)

	animations[frame].Connection:Disconnect()
	animations[frame] = nil
end

return module
