local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TutorialService = game:GetService("TutorialService")

local gui = ReplicatedStorage.Assets.Gui

local Signal = require(ReplicatedStorage.Packages.Signal)
local mapIconsModule = {}

type LabelIconInstance = ImageLabel & { Icon: ImageLabel }
type InteractableIconInstance =
	ImageButton
	& { Icon: ImageLabel }
	& { PromptClippingFrame: Frame & { Prompt: Frame & { PromptMessage: TextLabel } } }
type MapIcon = {
	IconImage: string,
	FrameImage: string,
	Color: Color3,
	Transparency: number,
	Adornee: Model | BasePart?,
}

export type LabelMapIcon = MapIcon & {
	Instance: LabelIconInstance,
	Destroy: (self: InteractableMapIcon) -> any?,
}

export type InteractableMapIcon = MapIcon & {
	InteractTime: number?,
	InteractBegan: RBXScriptConnection,
	InteractEnded: RBXScriptConnection,
	InteractCompleted: Signal.Signal<>,
	MouseEntered: RBXScriptConnection,
	MouseLeft: RBXScriptConnection,
	Instance: InteractableIconInstance,
	Destroy: (self: InteractableMapIcon) -> any?,
}

local function cancelThread(thread: thread?)
	if not thread then
		return
	end
	task.cancel(thread)
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

local function processMapIcon(mapIcon: InteractableMapIcon): RBXScriptConnection
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
	end)
end

local function createMapIcon(icon: string?, adornee: Instance?): MapIcon
	icon = icon or ""
	adornee = adornee or nil

	local newMapIconBase: MapIcon = {
		IconImage = icon,
		FrameImage = "rbxassetid://110159171300777",
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Adornee = adornee,
	}

	return newMapIconBase
end

local function createMetaProxy(mapIcon: LabelMapIcon | InteractableMapIcon): LabelMapIcon | InteractableMapIcon
	local proxy = setmetatable({}, {
		__index = mapIcon,
		__newindex = function(_, key, value)
			local oldValue = mapIcon[key]
			if oldValue == value then
				return
			end -- No change detected
			mapIcon[key] = value

			print(key, value)

			local instance = mapIcon.Instance

			if key == "IconImage" then
				instance.Icon.Image = value
			elseif key == "FrameImage" then
				instance.Image = value
			elseif key == "Color" then
				instance.ImageColor3 = value
			elseif key == "Transparency" then
				instance.Transparency = value
				instance.Icon.Transparency = value
			end
		end,
		__metatable = "Locked", -- Prevent external access to the metatable
	})

	return proxy
end

function mapIconsModule.newLabelIcon(parent: Instance?, icon: string?, adornee: Instance?): LabelMapIcon
	local newMapIcon = createMapIcon(icon, adornee)
	local newInstance = gui.LabelMapIconInstance:Clone()
	newInstance.Icon.Image = newMapIcon.IconImage
	newInstance.Parent = parent
	newMapIcon.Instance = newInstance

	local processThread = processMapIcon(newMapIcon)

	newMapIcon.Destroy = function(self)
		if processThread then
			processThread:Disconnect()
		end
		self.Instance:Destroy()
	end

	return createMetaProxy(newMapIcon) :: LabelMapIcon
end

function mapIconsModule.newInteractableIcon(parent: Instance?, icon: string?, adornee: Instance?): InteractableMapIcon
	local newMapIcon = createMapIcon(icon, adornee) :: InteractableMapIcon
	local newInstance = gui.InteractableMapIconInstance:Clone()
	newInstance.Icon.Image = newMapIcon.IconImage

	newMapIcon.InteractTime = 1
	newMapIcon.InteractBegan = newInstance.MouseButton1Down
	newMapIcon.InteractEnded = newInstance.MouseButton1Up
	newMapIcon.InteractCompleted = Signal.new()
	newMapIcon.MouseEntered = newInstance.MouseEnter
	newMapIcon.MouseLeft = newInstance.MouseLeave

	local interactThread

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

	newMapIcon.Instance = newInstance
	newMapIcon.Instance.Parent = parent

	local processThread = processMapIcon(newMapIcon)

	newMapIcon.Destroy = function(self)
		if processThread then
			processThread:Disconnect()
		end
		self.Instance:Destroy()

		cancelThread(interactThread)
	end

	return createMetaProxy(newMapIcon) :: InteractableIconInstance
end

return mapIconsModule
