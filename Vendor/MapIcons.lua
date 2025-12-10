local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local gui = ReplicatedStorage.Assets.Gui

local Signal = require(ReplicatedStorage.Packages.Signal)
local mapIconsModule = {}

type IconInstance =
	ImageButton
	& { Icon: ImageLabel }
	& { PromptClippingFrame: Frame & { Prompt: Frame & { PromptMessage: TextLabel } } }
	& { PreciseSelection: Frame }
export type MapIcon = {
	IconImage: string,
	FrameImage: string,
	PromptMessage: string,
	Color: Color3,
	Transparency: number,
	Adornee: Model | BasePart?,
	InteractTime: number?,
	InteractBegan: RBXScriptSignal<number, number>,
	InteractEnded: RBXScriptSignal<number, number>,
	InteractCompleted: Signal.Signal<>,
	MouseEntered: RBXScriptSignal<number, number>,
	MouseLeft: RBXScriptSignal<number, number>,
	PreciseMouseEntered: RBXScriptSignal<number, number>,
	PreciseMouseLeft: RBXScriptSignal<number, number>,
	Instance: IconInstance,
	Destroy: (self: MapIcon) -> any?,
}

local function cancelThread(thread: thread?)
	if not thread then
		return
	end
	pcall(task.cancel, thread)
end

local function fixAspect(xCoordinate: number, cameraViewportSize: Vector2, absoluteViewportSize: Vector2)
	local viewportAspect = absoluteViewportSize.Y / absoluteViewportSize.X
	local cameraAspect = cameraViewportSize.X / cameraViewportSize.Y
	local aspectModification = viewportAspect / cameraAspect
	xCoordinate -= 0.5
	xCoordinate *= aspectModification
	xCoordinate += 0.5
	return xCoordinate
end

local function processMapIcon(mapIcon: MapIcon): RBXScriptConnection
	return RunService.RenderStepped:Connect(function()
		if not mapIcon.Adornee then
			return
		end
		local viewportFrame = mapIcon.Adornee:FindFirstAncestorOfClass("ViewportFrame")
		if not viewportFrame then
			return
		end
		local viewportCamera = viewportFrame.CurrentCamera
		if not viewportCamera then
			return
		end

		local iconPosition = viewportCamera:WorldToViewportPoint(mapIcon.Adornee:GetPivot().Position)

		local cameraViewportSize = viewportCamera.ViewportSize

		mapIcon.Instance.Position = UDim2.fromScale(
			fixAspect(iconPosition.X, cameraViewportSize, viewportFrame.AbsoluteSize) / cameraViewportSize.X,
			iconPosition.Y / cameraViewportSize.Y
		)

		local size = 50 / iconPosition.Z
		mapIcon.Instance.Size = UDim2.fromScale(size, size * 1.3333333333333334)
		mapIcon.Instance.ZIndex = math.ceil(size * 100)
	end)
end

local function createMetaProxy(mapIcon: MapIcon): MapIcon
	local proxy = setmetatable({}, {
		__index = mapIcon,
		__newindex = function(_, key, value)
			local oldValue = mapIcon[key]
			if oldValue == value then
				return
			end -- No change detected
			mapIcon[key] = value

			local instance = mapIcon.Instance

			if key == "IconImage" then
				instance.Icon.Image = value
			elseif key == "FrameImage" then
				instance.Image = value
			elseif key == "Color" then
				instance.ImageColor3 = value
			elseif key == "PromptMessage" then
				instance.PromptClippingFrame.Prompt.PromptMessage.Text = value
			elseif key == "Transparency" then
				instance.Transparency = value
				instance.Icon.Transparency = value
			end
		end,
		__metatable = "Locked", -- Prevent external access to the metatable
	})

	return proxy
end

function mapIconsModule.new(parent: Instance?, icon: string?, adornee: Instance?): MapIcon
	icon = icon or ""
	adornee = adornee or nil

	local isDestroying = false

	local newInstance = gui.InteractableMapIconInstance:Clone()
	local interactThread
	local processThread

	local newMapIcon: MapIcon = {
		IconImage = icon,
		FrameImage = "rbxassetid://110159171300777",
		PromptMessage = "",
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Adornee = adornee,
		Instance = newInstance,
		InteractTime = 1,
		InteractBegan = newInstance.MouseButton1Down,
		InteractEnded = newInstance.MouseButton1Up,
		InteractCompleted = Signal.new(),
		MouseEntered = newInstance.MouseEnter,
		MouseLeft = newInstance.MouseLeave,

		PreciseMouseEntered = newInstance.PreciseSelection.MouseEnter,
		PreciseMouseLeft = newInstance.PreciseSelection.MouseLeave,
		Destroy = function(self)
			if processThread then
				processThread:Disconnect()
			end
			if not isDestroying then
				self.Instance:Destroy()
			end

			cancelThread(interactThread)
			self.InteractCompleted:Destroy()
		end,
	}

	newInstance.Icon.Image = newMapIcon.IconImage
	newInstance.Parent = parent

	newInstance.MouseButton1Down:Connect(function()
		interactThread = task.delay(newMapIcon.InteractTime, function()
			newMapIcon.InteractCompleted:Fire()
		end)
	end)

	newInstance.MouseButton1Up:Connect(function()
		cancelThread(interactThread)
	end)

	newInstance.MouseLeave:Connect(function()
		cancelThread(interactThread)
	end)

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart)
	local prompt = newMapIcon.Instance.PromptClippingFrame.Prompt

	newMapIcon.MouseEntered:Connect(function()
		if newMapIcon.PromptMessage == "" then
			return
		end

		TweenService:Create(prompt, ti, { Position = UDim2.fromScale(0, 0) }):Play()
	end)

	newMapIcon.MouseLeft:Connect(function()
		TweenService:Create(prompt, ti, { Position = UDim2.fromScale(-1, 0) }):Play()
	end)

	processThread = processMapIcon(newMapIcon)

	newMapIcon.Instance.Destroying:Connect(function()
		isDestroying = true
		newMapIcon:Destroy()
	end)

	return createMetaProxy(newMapIcon) :: MapIcon
end

return mapIconsModule
