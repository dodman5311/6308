local ReplicatedStorage = game:GetService("ReplicatedStorage")
local signal = require(ReplicatedStorage.Packages.Signal)

export type Scale = {
	Contents: {},
	Threshold: number, -- 1 Default
	Check: (self: Scale) -> boolean,
	Add: (self: Scale, index: string | number?, value: any?) -> boolean,
	Remove: (self: Scale, index: string | number?) -> boolean,
	Reached: signal.Signal,
	Lost: signal.Signal,
}

local scales = {
	activeScales = {},
}

local function getSize(list: {})
	local count = 0
	for _, _ in pairs(list) do
		count += 1
	end
	return count
end

function scales.new(index: string?): Scale
	local scale: Scale = {
		Contents = {},
		Threshold = 1,
		Check = function(self: Scale)
			local weight = getSize(self.Contents)
			local isOverThreshold = weight >= self.Threshold

			if isOverThreshold then
				self.Reached:Fire()
			else
				self.Lost:Fire()
			end

			return isOverThreshold
		end,
		Add = function(self: Scale, index: string | number?, value: any?)
			if index then
				self.Contents[index] = value or true
			else
				table.insert(self.Contents, value or true)
			end

			return self:Check()
		end,
		Remove = function(self: Scale, index: string | number?)
			if not index then
				table.remove(self.Contents, 1)
				return self:Check()
			end

			if tonumber(index) then
				table.remove(self.Contents, index)
			else
				self.Contents[index] = nil
			end

			return self:Check()
		end,

		Reached = signal.new(),
		Lost = signal.new(),
	}

	if index then
		scales.activeScales[index] = scale
	end

	return scale
end

return scales
