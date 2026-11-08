local CardService = {
	CurrentHand = {},
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = Players.LocalPlayer.PlayerScripts.Client
local Gifts = require(ReplicatedStorage.Shared.Gifts)
local Signals = require(ReplicatedStorage.Shared.Signals)
local UIService = require(Client.Services.UIService)

function CardService:CheckCardStack(cardName: string)
	local cardCount = 0

	for _, card in ipairs(self.CurrentHand) do
		if card.Name == cardName then
			cardCount += 1
		end
	end

	return cardCount
end

function CardService:RemoveCard(cardIndex: number)
	UIService.doUiAction("HUD", "RemoveCard", self.CurrentHand[cardIndex])
	table.remove(self.CurrentHand, cardIndex)
	UIService.doUiAction("HUD", "UpdateHand", self.CurrentHand)
end

function CardService:AddCard(cardName: string)
	local gift = Gifts.Upgrades[cardName] or Gifts.Perks[cardName]

	if not gift then
		print(cardName)
	end

	local newCard = UIService.doUiAction("HUD", "AddCard", cardName, gift.Icon)
	table.insert(self.CurrentHand, newCard)
	UIService.doUiAction("HUD", "UpdateHand", self.CurrentHand)

	if #self.CurrentHand > 5 then
		self:RemoveCard(1)
	end
end

function CardService:ClearCards()
	for _ = 1, #self.CurrentHand do
		self:RemoveCard(1)
	end
end

function CardService:GameInit()
	--Prestart Code
	Signals.AddCard:Connect(function(cardName)
		self:AddCard(cardName)
	end)
end

function CardService:GameStart()
	--Start Code
end

return CardService
