local module = {
	tickets = 0,
	soulCost = 1,
}
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local UserInputService = game:GetService("UserInputService")

--// Instances
local Globals = require(ReplicatedStorage.Shared.Globals)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local sfx = sounds.Kiosk
local camera = workspace.CurrentCamera

--// Modules
local MouseOverModule = require(ReplicatedStorage.Vendor.MouseOverModule)
local Net = require(ReplicatedStorage.Packages.Net)
local Scales = require(ReplicatedStorage.Vendor.Scales)
local Signal = require(Globals.Packages.Signal)
local Signals = require(ReplicatedStorage.Shared.Signals)
local UIAnimationService = require(ReplicatedStorage.Vendor.UIAnimationService)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local util = require(ReplicatedStorage.Vendor.Util)

module.onHidden = Signal.new()
local runInfoBox

--// Values

local upgradeIndexOrder = {
	"Core",
	"Pistols",
	"Shotguns",
	"Rifles",
	"Melee",
	"Stage_1_Perks",
	"Stage_2_Perks",
	"Stage_3_Perks",
}
local currentTreeIndex = 1
local infoBoxScale = Scales.new("ShowInfoBox")

--// Functions

local function updateTree(tree)
	local acquiredFirstIndexTree = false
	local ti = TweenInfo.new(0.25)

	for _, buttonFrame in ipairs(tree:GetDescendants()) do
		if not buttonFrame:IsA("Frame") then
			continue
		end

		local folder = buttonFrame.Parent
		local category = folder.Name

		local tier = workspace:GetAttribute(category)

		if not tier then
			continue
		end

		if folder:HasTag("FirstIndex") then
			if tier >= 1 then
				acquiredFirstIndexTree = true
			end
		end
	end

	for _, buttonFrame in ipairs(tree:GetDescendants()) do
		if not buttonFrame:IsA("Frame") then
			continue
		end

		local folder = buttonFrame.Parent
		local category = folder.Name
		local index = tonumber(buttonFrame.Name)

		local tier = workspace:GetAttribute(category)

		if not tier then
			util.tween(buttonFrame.FrameImage, ti, { ImageTransparency = 0.75 })
			util.tween(buttonFrame.Icon, ti, { ImageTransparency = 0.75 })
			buttonFrame.Acquired.Visible = false
			buttonFrame.Button.Visible = false
			continue
		end

		if not folder:HasTag("FirstIndex") and not acquiredFirstIndexTree then
			tier -= 1
		end

		if index <= tier then
			-- acquired
			util.tween(buttonFrame.FrameImage, ti, { ImageTransparency = 0 })
			util.tween(buttonFrame.Icon, ti, { ImageTransparency = 0, ImageColor3 = Color3.fromRGB(0, 167, 139) })
			buttonFrame.Acquired.Visible = true
			buttonFrame.Button.Visible = false
		elseif index <= tier + 1 then
			-- can get
			util.tween(buttonFrame.FrameImage, ti, { ImageTransparency = 0 })
			util.tween(buttonFrame.Icon, ti, { ImageTransparency = 0, ImageColor3 = Color3.new(1, 1, 1) })
			buttonFrame.Acquired.Visible = false
			buttonFrame.Button.Visible = true
		else
			-- hide
			util.tween(buttonFrame.FrameImage, ti, { ImageTransparency = 0.75 })
			util.tween(buttonFrame.Icon, ti, { ImageTransparency = 0.75, ImageColor3 = Color3.new(1, 1, 1) })
			buttonFrame.Acquired.Visible = false
			buttonFrame.Button.Visible = false
		end
	end
end

local function setTreeIndex(frame, index: number, reverse: boolean?)
	reverse = reverse or false
	local ti = TweenInfo.new(0.25)

	for _, tree in ipairs(frame.Trees:GetChildren()) do
		if not tree:IsA("CanvasGroup") then
			continue
		end

		if tree.Name == upgradeIndexOrder[index] then
			updateTree(tree)

			local filigree = frame.Filigree:FindFirstChild(tree.Name)

			if filigree then
				util.tween(filigree, ti, { ImageTransparency = 0 })
			end

			tree.Visible = true
			tree.Position = UDim2.fromScale(reverse and 0.4 or 0.6, 0.5)

			util.tween(tree, ti, { GroupTransparency = 0 })
			util.tween(tree, ti, { Size = UDim2.fromScale(1, 1) })
			util.tween(tree, ti, { Position = UDim2.fromScale(0.5, 0.5) })
		else
			local filigree = frame.Filigree:FindFirstChild(tree.Name)

			if filigree then
				util.tween(filigree, ti, { ImageTransparency = 1 })
			end

			util.tween(tree, ti, { GroupTransparency = 1 }, false, function()
				tree.Visible = false
			end)
			util.tween(tree, ti, { Size = UDim2.fromScale(0.75, 0.75) })
			util.tween(tree, ti, { Position = UDim2.fromScale(reverse and 0.6 or 0.4, 0.5) })
		end
	end
end

function module.ShowRequiemShop(_, ui, frame)
	Signals.DoUiAction:Fire("Cursor", "Toggle", true)
	frame.Gui.Enabled = true
	setTreeIndex(frame, currentTreeIndex)

	runInfoBox = RunService.RenderStepped:Connect(function()
		local mousePosition = UserInputService:GetMouseLocation()
		frame.InfoBox.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)

		local midPoint = camera.ViewportSize / 2

		local x = 0
		local y = 0

		if mousePosition.Y > midPoint.Y then
			y = 1
		else
			y = 0
		end

		if mousePosition.X > midPoint.X then
			x = 1
		else
			x = 0
		end

		util.tween(frame.InfoBox, TweenInfo.new(0.25), { AnchorPoint = Vector2.new(x, y) })
	end)
end

function module.Init(player, ui, frame)
	local ti = TweenInfo.new(0.25)

	infoBoxScale.Changed:Connect(function(value)
		frame.InfoBox.Visible = value
	end)

	frame.Next.MouseButton1Click:Connect(function()
		if currentTreeIndex >= #upgradeIndexOrder then
			currentTreeIndex = 1
		else
			currentTreeIndex += 1
		end

		setTreeIndex(frame, currentTreeIndex)
	end)

	frame.Prev.MouseButton1Click:Connect(function()
		if currentTreeIndex <= 1 then
			currentTreeIndex = #upgradeIndexOrder
		else
			currentTreeIndex -= 1
		end

		setTreeIndex(frame, currentTreeIndex, true)
	end)

	for _, tree in ipairs(frame.Trees:GetChildren()) do
		if not tree:IsA("CanvasGroup") then
			continue
		end
		for _, buttonFrame in ipairs(tree:GetDescendants()) do
			if not buttonFrame:IsA("Frame") then
				continue
			end

			local button: ImageButton = buttonFrame.Button
			button.MouseButton1Click:Connect(function()
				-- upgrade event
				local category = buttonFrame.Parent.Parent.Name
				local tierName = buttonFrame.Parent.Name
				local currentTier = workspace:GetAttribute(tierName)

				if currentTier < #Upgrades[category][tierName] then
					--workspace:SetAttribute(tierName, workspace:GetAttribute(tierName) + 1)
					local postPurchaseBalance = Net:RemoteFunction("PurchaseUpgrade")
						:InvokeServer(tierName, 0, workspace:GetAttribute(tierName) + 1)
				end

				updateTree(tree)
			end)
			local enter, leave = MouseOverModule.MouseEnterLeaveEvent(button)

			enter:Connect(function()
				local category = buttonFrame.Parent.Parent.Name
				local tierName = buttonFrame.Parent.Name
				local tierNumber = tonumber(buttonFrame.Name)
				local tier
				if not Upgrades[category][tierName] then
					infoBoxScale:Add()
					tier = Upgrades["None"]["None_Tier"][1]
				else
					tier = Upgrades[category][tierName][tierNumber]
				end

				local foundSplit = string.find(tier.Name, ":")
				if foundSplit then
					frame.InfoBox.Title.Text = string.sub(tier.Name, 1, foundSplit - 1)
					frame.InfoBox.Index.Text = string.sub(tier.Name, foundSplit + 2)
				else
					frame.InfoBox.Title.Text = tier.Name
					frame.InfoBox.Index.Text = ""
				end

				frame.InfoBox.Desc.Text = tier.Description
				frame.Icon.Image = buttonFrame.Icon.Image
				infoBoxScale:Add()
			end)

			leave:Connect(function()
				infoBoxScale:Remove()
			end)
		end
	end
end

function module.Cleanup(player, ui, frame) end

return module
