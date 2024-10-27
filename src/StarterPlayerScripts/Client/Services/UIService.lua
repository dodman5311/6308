local module = {
	fullUi = {},
	isLoaded = false,
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")

--// Instances
local assets = ReplicatedStorage.Assets

local Globals = require(ReplicatedStorage.Shared.Globals)

local guiFolder = assets.Gui
local modulesFolder = ReplicatedStorage.Gui
local player = players.LocalPlayer

--// Modules
local signals = require(Globals.Signals)
local acts = require(Globals.Vendor.Acts)
local net = require(Globals.Packages.Net)

--// Values
local uiMods = {}
local clonedUis = {}

local function loadUi(parent)
	local playerGui = player:WaitForChild("PlayerGui")

	for _, ui in ipairs(parent:GetChildren()) do
		if not ui:IsA("ScreenGui") and not ui:IsA("BillboardGui") and not ui:IsA("SurfaceGui") then
			continue
		end

		local newUi = ui:Clone()
		newUi.Parent = playerGui

		table.insert(clonedUis, newUi)
	end
end

function module.getFullUi()
	for _, ui in ipairs(clonedUis) do
		module.fullUi[ui.Name] = { Gui = ui }

		for _, uiElement in ipairs(ui:GetDescendants()) do
			module.fullUi[ui.Name][uiElement.Name] = uiElement
		end
	end

	module.isLoaded = true
end

function module.doUiAction(uiName, action, doWithoutAct, ...)
	local getModule = uiMods[uiName]
	if not getModule then
		warn("No ui module by the name of ", uiName, " was found.")
		return
	end

	if not getModule[action] then
		warn(uiName, " has no action by the name of ", action)
		return
	end

	local args = { ... }

	--if doWithoutAct then
	return getModule[action](player, module.fullUi, module.fullUi[uiName], ...)
	-- else
	-- 	return acts:createTempAct(uiName .. "_" .. action, function()
	-- 		return getModule[action](player, module.fullUi, module.fullUi[uiName], table.unpack(args))
	-- 	end)
	-- end
end

function module.CleanUp(uiToClean)
	if not uiToClean then
		for _, uiModule in ipairs(guiFolder:GetChildren()) do
			module.doUiAction(uiModule.Name, "Cleanup")
		end
	else
		module.doUiAction(uiToClean, "Cleanup")
	end
end

function module.GameInit()
	loadUi(guiFolder)
	module.getFullUi()

	for _, uiModule in ipairs(modulesFolder:GetChildren()) do
		uiMods[uiModule.Name] = require(uiModule)

		task.spawn(module.doUiAction, uiModule.Name, "Init")
	end

	-- for _, object in ipairs(starterGui:GetChildren()) do
	-- 	object:Clone().Parent = player:WaitForChild("PlayerGui")
	-- end
end

--// Main //--

starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
signals.DoUiAction:Connect(module.doUiAction)
net:Connect("DoUiAction", module.doUiAction)

return module
