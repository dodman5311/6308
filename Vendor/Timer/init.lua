local module = {
	timerQueue = {},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Globals = require(ReplicatedStorage.Shared.Globals)

local RUN_SERVICE = game:GetService("RunService")
local signals = require(Globals.Shared.Signals)
local signal = require(script.signal)
local net = require(Globals.Packages.Net)

local isPaused = false

local pauseSignal = signal.new()
local resumeSignal = signal.new()

module.wait = function(sec, index)
	local waitTimer = module:new(index or "waitAt_" .. os.clock())
	waitTimer.WaitTime = sec or 0.01
	waitTimer:Run()
	waitTimer.OnEnded:Wait()
	waitTimer:Destroy()
end

module.new = function(self, timerName, waitTime, Function, ...)
	local queue = self

	local pausedAt = 0

	if not timerName then
		timerName = #queue + 1
	end

	if queue.timerQueue[timerName] then
		return queue.timerQueue[timerName]
	end

	local timer = {
		Connection = nil,
		CallTime = os.clock(),
		WaitTime = waitTime,
		["Function"] = Function,
		Parameters = { ... },
		Condition = nil,

		OnTimerStepped = signal.new(),
	}

	timer.OnPaused = pauseSignal:Connect(function()
		isPaused = true
		pausedAt = os.clock()
	end)

	timer.OnResumed = resumeSignal:Connect(function()
		timer:Delay(os.clock() - pausedAt)
		isPaused = false
	end)

	timer.OnEnded = signal.new()

	function timer:IsRunning()
		return self.Connection and true or false
	end

	function timer:Run()
		if self.Connection then
			return
		end

		self.CallTime = os.clock()

		self.Connection = RUN_SERVICE.Heartbeat:Connect(function()
			if isPaused then
				return
			end

			self.OnTimerStepped:Fire(os.clock() - self.CallTime)

			if (os.clock() - self.CallTime) < self.WaitTime then
				return
			end

			self.Connection:Disconnect()
			self.Connection = nil

			if self.Function then
				task.spawn(self.Function, table.unpack(self.Parameters))
			end

			timer.OnEnded:Fire()
		end)
	end

	function timer:Reset()
		self.CallTime = os.clock()
	end

	function timer:Delay(amount)
		self.CallTime += amount
	end

	function timer:Update(index, value)
		self[index] = value
	end

	function timer:UpdateFunction(value, ...)
		self["Function"] = value
		self["Parameters"] = ...
	end

	function timer:Cancel()
		if not self.Connection then
			return
		end
		self.Connection:Disconnect()
		self.Connection = nil
	end

	function timer:Destroy()
		if self.Connection then
			self.Connection:Disconnect()
			self.Connection = nil
		end

		self.OnPaused:Disconnect()
		self.OnResumed:Disconnect()

		queue.timerQueue[timerName] = nil
	end

	function timer:Complete()
		self.CallTime = -self.WaitTime
	end

	function timer:GetCurrentTime()
		return os.clock() - self.CallTime
	end

	queue.timerQueue[timerName] = timer
	return queue.timerQueue[timerName]
end

function module:newQueue()
	return {
		timerQueue = {},
		new = module["new"],

		DestroyAll = function(self)
			for _, timer in self.timerQueue do
				if not timer["Destroy"] then
					continue
				end
				timer:Destroy()
			end
		end,

		CancelAll = function(self)
			for _, timer in self.timerQueue do
				if not timer["Cancel"] then
					continue
				end
				timer:Cancel()
			end
		end,

		DoAll = function(self, functionName, ...)
			for _, timer in self.timerQueue do
				if not timer[functionName] then
					continue
				end
				timer[functionName](timer, ...)
			end
		end,

		DoFor = function(self, timers, functionName, ...)
			for _, timerName in timers do
				local timer = self.timerQueue[timerName]

				if not timer or not timer[functionName] then
					continue
				end
				timer[functionName](timer, ...)
			end
		end,
	}
end

function module:getTimer(timerName)
	return self.timerQueue[timerName]
end

if RunService:IsClient() then
	signals.PauseGame:Connect(function()
		pauseSignal:Fire()
		isPaused = true
	end)

	signals.ResumeGame:Connect(function()
		resumeSignal:Fire()
		isPaused = false
	end)
else
	net:Connect("PauseGame", function()
		pauseSignal:Fire()
		isPaused = true
	end)

	net:Connect("ResumeGame", function()
		resumeSignal:Fire()
		isPaused = false
	end)
end

return module
