-- HUD.client.lua - Giao dien nguoi choi: hien Cash, thong bao va nut mua.
-- Toan bo GUI duoc tao bang code nen khong can dung san trong Studio.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local gui = Instance.new("ScreenGui")
gui.Name = "TycoonHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(0, 240, 0, 44)
cashLabel.Position = UDim2.new(0, 16, 0, 16)
cashLabel.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
cashLabel.BackgroundTransparency = 0.25
cashLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextScaled = true
cashLabel.Text = "$0"
cashLabel.Parent = gui

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(0, 520, 0, 40)
messageLabel.Position = UDim2.new(0.5, -260, 0, 70)
messageLabel.BackgroundTransparency = 1
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextScaled = true
messageLabel.Text = ""
messageLabel.Parent = gui

local function showMessage(text)
	messageLabel.Text = text
	task.delay(3, function()
		if messageLabel.Text == text then
			messageLabel.Text = ""
		end
	end)
end

local remote = ReplicatedStorage:WaitForChild("TycoonMessage")
remote.OnClientEvent:Connect(showMessage)

-- Cap nhat so Cash theo leaderstats
local function bindCash()
	local leaderstats = player:WaitForChild("leaderstats")
	local cash = leaderstats:WaitForChild("Cash")
	local function update()
		cashLabel.Text = "$" .. cash.Value
	end
	cash.Changed:Connect(update)
	update()
end
task.spawn(bindCash)

-- Nut mua x2 Cash (Game Pass)
local passButton = Instance.new("TextButton")
passButton.Name = "DoubleCashButton"
passButton.Size = UDim2.new(0, 200, 0, 40)
passButton.Position = UDim2.new(1, -216, 0, 16)
passButton.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
passButton.TextColor3 = Color3.fromRGB(255, 255, 255)
passButton.Font = Enum.Font.GothamBold
passButton.TextScaled = true
passButton.Text = "x2 Cash (VIP)"
passButton.Parent = gui
passButton.MouseButton1Click:Connect(function()
	if Config.DoubleCashGamePassId == 0 then
		showMessage("Game Pass x2 Cash chua duoc cau hinh (Config.lua)")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, Config.DoubleCashGamePassId)
end)

-- Nut mua Cash bang Robux (Developer Product dau tien trong Config)
local productButton = Instance.new("TextButton")
productButton.Name = "BuyCashButton"
productButton.Size = UDim2.new(0, 200, 0, 40)
productButton.Position = UDim2.new(1, -216, 0, 64)
productButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
productButton.TextColor3 = Color3.fromRGB(255, 255, 255)
productButton.Font = Enum.Font.GothamBold
productButton.TextScaled = true
productButton.Text = "Mua them Cash"
productButton.Parent = gui
productButton.MouseButton1Click:Connect(function()
	local productId = next(Config.CashProducts)
	if not productId then
		showMessage("Chua co Developer Product nao trong Config.lua")
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end)
