-- DataManager.lua - Luu / tai du lieu nguoi choi bang DataStore.
-- Luu: Cash + danh sach Id vat pham da mua trong tycoon.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local DataManager = {}

local store = nil
local function getStore()
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	end
	return store
end

function DataManager.Load(player)
	local fallback = { Cash = Config.StartingCash, Items = {} }
	local ds = getStore()
	if not ds then
		return fallback
	end
	local ok, data = pcall(function()
		return ds:GetAsync("Player_" .. player.UserId)
	end)
	if ok and type(data) == "table" then
		if type(data.Cash) ~= "number" then
			data.Cash = Config.StartingCash
		end
		if type(data.Items) ~= "table" then
			data.Items = {}
		end
		return data
	end
	return fallback
end

function DataManager.Save(player, data)
	local ds = getStore()
	if not ds then
		return false
	end
	local ok = pcall(function()
		ds:SetAsync("Player_" .. player.UserId, data)
	end)
	return ok
end

return DataManager
