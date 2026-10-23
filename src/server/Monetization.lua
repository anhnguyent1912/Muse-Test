-- Monetization.lua - Ban Robux trong game.
-- Game Pass x2 Cash (mua 1 lan) + Developer Product mua Cash (mua lap lai).
-- Tao san pham trong Creator Hub > Monetization, roi dien ID vao Config.lua.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Monetization = {}
local passCache = {} -- [UserId] = true/false

function Monetization.OwnsDoubleCash(player)
	if Config.DoubleCashGamePassId == 0 then
		return false
	end
	if passCache[player.UserId] ~= nil then
		return passCache[player.UserId]
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.DoubleCashGamePassId)
	end)
	passCache[player.UserId] = ok and owns or false
	return passCache[player.UserId]
end

function Monetization.Init(tycoonManager)
	-- Nhan tien x2 tu Game Pass khi thu vat pham
	tycoonManager.CashMultiplierFn = function(player)
		if Monetization.OwnsDoubleCash(player) then
			return 2
		end
		return 1
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if passId == Config.DoubleCashGamePassId and purchased then
			passCache[player.UserId] = true
		end
	end)

	-- Xu ly mua Developer Product: chi dat ProcessReceipt o 1 noi duy nhat.
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local amount = Config.CashProducts[receiptInfo.ProductId]
		if not amount then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local leaderstats = player:FindFirstChild("leaderstats")
		local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
		if not cashValue then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		cashValue.Value = cashValue.Value + amount
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	Players.PlayerRemoving:Connect(function(player)
		passCache[player.UserId] = nil
	end)
end

return Monetization
