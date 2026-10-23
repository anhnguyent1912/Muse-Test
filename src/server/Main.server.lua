-- Main.server.lua - Diem khoi chay cua server.
-- Noi cac he thong lai: tai du lieu -> nhan tycoon -> choi -> luu du lieu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("Server")
local DataManager = require(serverFolder:WaitForChild("DataManager"))
local TycoonManager = require(serverFolder:WaitForChild("TycoonManager"))
local Monetization = require(serverFolder:WaitForChild("Monetization"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

TycoonManager.Init()
Monetization.Init(TycoonManager)

local sessions = {} -- [UserId] = true khi da tai xong

local function onPlayerAdded(player)
	local data = DataManager.Load(player)
	TycoonManager.RegisterPlayer(player, data)
	sessions[player.UserId] = true

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		TycoonManager.TeleportToPlot(player)
	end)
	if player.Character then
		TycoonManager.TeleportToPlot(player)
	end
end

local function savePlayer(player)
	if not sessions[player.UserId] then
		return
	end
	local data = TycoonManager.GetSessionData(player)
	DataManager.Save(player, data)
end

local function onPlayerRemoving(player)
	if not sessions[player.UserId] then
		return
	end
	sessions[player.UserId] = nil
	local data = TycoonManager.UnregisterPlayer(player)
	DataManager.Save(player, data)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Tu dong luu dinh ky (chi chup du lieu, khong thay doi tycoon dang choi)
task.spawn(function()
	while true do
		task.wait(Config.AutosaveSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayer(player)
		end
	end
end)

-- Luu tat ca khi server tat (Studio: bam Stop)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end)
