-- TycoonManager.lua - Tao va van hanh cac khu tycoon.
-- Toan bo map duoc dung bang code khi server chay: Anh chi can 1 place
-- Baseplate trong, sync Rojo roi bam Play la co game.
--
-- Co che kinh dien cua the loai Tycoon:
--   Dropper tha vat pham -> bang chuyen dua toi may thu -> nhan Cash
--   Dung Cash mua nut tiep theo -> mo Dropper manh hon / vat pham moi

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local TycoonManager = {}

-- Main/Monetization co the ghi de ham nay (tra ve 2 neu co Game Pass x2 Cash)
TycoonManager.CashMultiplierFn = function(_player)
	return 1
end

local PLOT_SIZE = 56
local PLOT_GAP = 90
local DROPPER_Z = { -20, -14, -8, -2, 4 }
local DROPPER_COLORS = {
	Color3.fromRGB(96, 165, 250),
	Color3.fromRGB(74, 222, 128),
	Color3.fromRGB(250, 204, 21),
	Color3.fromRGB(251, 146, 60),
	Color3.fromRGB(255, 215, 0),
}

local plots = {} -- danh sach plotState
local plotByPlayer = {} -- [UserId] = plotState
local messageRemote = nil

local function makePart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function sendMessage(player, text)
	if messageRemote and player then
		messageRemote:FireClient(player, text)
	end
end

local function plotOrigin(index)
	return Vector3.new((index - 1) * PLOT_GAP, 0, 0)
end

-- ---------------------------------------------------------------- Sinh map
local function buildPlotShell(index)
	local origin = plotOrigin(index)
	local model = Instance.new("Model")
	model.Name = "Tycoon" .. index

	local floor = makePart(model, "Floor", Vector3.new(PLOT_SIZE, 1, PLOT_SIZE),
		origin + Vector3.new(0, 0, 0), Color3.fromRGB(100, 116, 139), Enum.Material.Concrete)

	-- Bang chuyen: vat ly day vat pham ve phia may thu (+Z)
	local conveyor = makePart(model, "Conveyor", Vector3.new(10, 1, 40),
		origin + Vector3.new(0, 1, -1), Color3.fromRGB(31, 41, 55), Enum.Material.Metal)
	conveyor.AssemblyLinearVelocity = Vector3.new(0, 0, 14)

	-- May thu (collector)
	local collector = makePart(model, "Collector", Vector3.new(12, 7, 3),
		origin + Vector3.new(0, 4.5, 21), Color3.fromRGB(34, 197, 94), Enum.Material.Neon)
	collector.Transparency = 0.35
	collector.CanCollide = false

	-- Cong nang cap (upgrader) - chi kich hoat khi da mua vat pham Upgrader
	local gate = makePart(model, "UpgraderGate", Vector3.new(10, 6, 1),
		origin + Vector3.new(0, 4, 10), Color3.fromRGB(168, 85, 247), Enum.Material.Neon)
	gate.Transparency = 1
	gate.CanCollide = false
	gate:SetAttribute("Enabled", false)

	-- Diem hoi sinh cua chu tycoon
	local spawnPad = makePart(model, "SpawnPad", Vector3.new(8, 1, 8),
		origin + Vector3.new(18, 1, 20), Color3.fromRGB(59, 130, 246), Enum.Material.Neon)

	-- Bang ten
	local sign = makePart(model, "Sign", Vector3.new(20, 6, 1),
		origin + Vector3.new(0, 11, 27), Color3.fromRGB(17, 24, 39), Enum.Material.SmoothPlastic)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SignGui"
	gui.Size = UDim2.new(0, 300, 0, 80)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "Tycoon trong"
	label.Parent = gui

	local itemsFolder = Instance.new("Folder")
	itemsFolder.Name = "Items"
	itemsFolder.Parent = model
	local partsFolder = Instance.new("Folder")
	partsFolder.Name = "Parts"
	partsFolder.Parent = model

	model.Parent = workspace:WaitForChild("Tycoons")

	local state = {
		Index = index,
		Origin = origin,
		Model = model,
		Owner = nil,
		Purchased = {},
		Generation = 0,
		Button = nil,
		ButtonBusy = false,
	}
	plots[index] = state

	collector.Touched:Connect(function(hit)
		TycoonManager.OnCollectorTouched(state, hit)
	end)
	gate.Touched:Connect(function(hit)
		if gate:GetAttribute("Enabled") and hit.Name == "TycoonPart" then
			if not hit:GetAttribute("Upgraded") then
				hit:SetAttribute("Upgraded", true)
				local value = hit:GetAttribute("CashValue") or 0
				hit:SetAttribute("CashValue", value * 2)
				hit.Color = Color3.fromRGB(216, 180, 254)
			end
		end
	end)

	return state
end

-- ---------------------------------------------------------------- Vat pham
local function buildDropper(state, item)
	local index = item.DropperIndex or 1
	local z = DROPPER_Z[index] or -20
	local color = DROPPER_COLORS[index] or Color3.fromRGB(255, 255, 255)
	local origin = state.Origin
	local folder = state.Model:WaitForChild("Items")

	local model = Instance.new("Model")
	model.Name = item.Id
	-- Hai cot + thanh ngang o tren bang chuyen
	makePart(model, "PostL", Vector3.new(1, 8, 1), origin + Vector3.new(-6, 4, z), color, Enum.Material.Metal)
	makePart(model, "PostR", Vector3.new(1, 8, 1), origin + Vector3.new(6, 4, z), color, Enum.Material.Metal)
	local head = makePart(model, "Head", Vector3.new(6, 3, 5), origin + Vector3.new(0, 8.5, z), color, Enum.Material.Metal)
	model.Parent = folder

	-- Vong lap tha vat pham
	local generation = state.Generation
	task.spawn(function()
		while state.Owner and state.Generation == generation and head.Parent do
			local partsFolder = state.Model:FindFirstChild("Parts")
			if partsFolder and #partsFolder:GetChildren() < Config.MaxPartsPerTycoon then
				local box = Instance.new("Part")
				box.Name = "TycoonPart"
				box.Size = Vector3.new(2, 2, 2)
				box.Position = origin + Vector3.new(0, 6, z)
				box.Color = color
				box.Material = Enum.Material.SmoothPlastic
				box:SetAttribute("CashValue", item.DropValue)
				box:SetAttribute("PlotIndex", state.Index)
				box.Parent = partsFolder
				game:GetService("Debris"):AddItem(box, 30)
			end
			task.wait(item.DropInterval or 2)
		end
	end)
	return model
end

local function buildWalls(state)
	local origin = state.Origin
	local folder = state.Model:WaitForChild("Items")
	local model = Instance.new("Model")
	model.Name = "Walls"
	local color = Color3.fromRGB(148, 163, 184)
	local half = PLOT_SIZE / 2
	makePart(model, "WallBack", Vector3.new(PLOT_SIZE, 8, 1), origin + Vector3.new(0, 4, -half), color, Enum.Material.Brick)
	makePart(model, "WallLeft", Vector3.new(1, 8, PLOT_SIZE), origin + Vector3.new(-half, 4, 0), color, Enum.Material.Brick)
	makePart(model, "WallRight", Vector3.new(1, 8, PLOT_SIZE), origin + Vector3.new(half, 4, 0), color, Enum.Material.Brick)
	model.Parent = folder
	return model
end

local function buildDecor(state)
	local origin = state.Origin
	local folder = state.Model:WaitForChild("Items")
	local model = Instance.new("Model")
	model.Name = "Decor"
	for _, offset in ipairs({ Vector3.new(-22, 0, -22), Vector3.new(22, 0, -22), Vector3.new(-22, 0, 22), Vector3.new(22, 0, 22) }) do
		local trunk = makePart(model, "Trunk", Vector3.new(1.5, 5, 1.5), origin + offset + Vector3.new(0, 2.5, 0), Color3.fromRGB(120, 72, 20), Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		local leaves = makePart(model, "Leaves", Vector3.new(6, 6, 6), origin + offset + Vector3.new(0, 8, 0), Color3.fromRGB(34, 139, 34), Enum.Material.Grass)
		leaves.Shape = Enum.PartType.Ball
	end
	model.Parent = folder
	return model
end

function TycoonManager.BuildItem(state, item)
	if item.DropValue and item.DropValue > 0 then
		return buildDropper(state, item)
	elseif item.Id == "Walls" then
		return buildWalls(state)
	elseif item.Id == "Decor" then
		return buildDecor(state)
	elseif item.Id == "Upgrader" then
		local gate = state.Model:FindFirstChild("UpgraderGate")
		if gate then
			gate:SetAttribute("Enabled", true)
			gate.Transparency = 0.6
		end
		return nil
	end
	return nil
end

-- ---------------------------------------------------------------- Nut mua
local function nextItem(state)
	for _, item in ipairs(Config.Items) do
		if not state.Purchased[item.Id] then
			return item
		end
	end
	return nil
end

function TycoonManager.RefreshButton(state)
	if state.Button then
		state.Button:Destroy()
		state.Button = nil
	end
	if not state.Owner then
		return
	end
	local item = nextItem(state)
	if not item then
		sendMessage(state.Owner, "Ban da mua het vat pham cua tycoon nay!")
		return
	end
	local origin = state.Origin
	local button = makePart(state.Model, "BuyButton", Vector3.new(5, 1, 5),
		origin + Vector3.new(-18, 1, 14), Color3.fromRGB(34, 197, 94), Enum.Material.Neon)
	button.Shape = Enum.PartType.Cylinder

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 220, 0, 60)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = button
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = item.Name .. " - $" .. item.Price
	label.Parent = gui

	state.Button = button
	button.Touched:Connect(function(hit)
		TycoonManager.OnButtonTouched(state, hit)
	end)
end

function TycoonManager.OnButtonTouched(state, hit)
	if state.ButtonBusy or not state.Owner then
		return
	end
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or player ~= state.Owner then
		return
	end
	local item = nextItem(state)
	if not item then
		return
	end
	state.ButtonBusy = true
	task.delay(0.8, function()
		state.ButtonBusy = false
	end)

	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
	if not cashValue then
		return
	end
	if cashValue.Value < item.Price then
		sendMessage(player, "Chua du tien! " .. item.Name .. " can $" .. item.Price)
		return
	end
	cashValue.Value = cashValue.Value - item.Price
	state.Purchased[item.Id] = true
	TycoonManager.BuildItem(state, item)
	sendMessage(player, "Da mua " .. item.Name .. "!")
	TycoonManager.RefreshButton(state)
end

-- ---------------------------------------------------------------- Thu tien
function TycoonManager.OnCollectorTouched(state, hit)
	if hit.Name ~= "TycoonPart" then
		return
	end
	if hit:GetAttribute("PlotIndex") ~= state.Index then
		return
	end
	local owner = state.Owner
	local value = hit:GetAttribute("CashValue") or 0
	hit:Destroy()
	if not owner then
		return
	end
	local leaderstats = owner:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
	if cashValue then
		local multiplier = TycoonManager.CashMultiplierFn(owner)
		cashValue.Value = cashValue.Value + value * multiplier
	end
end

-- ---------------------------------------------------------------- Nguoi choi
function TycoonManager.RegisterPlayer(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.Cash or Config.StartingCash
	cash.Parent = leaderstats
	leaderstats.Parent = player

	-- Tu dong nhan 1 khu dat trong
	for _, state in ipairs(plots) do
		if not state.Owner then
			state.Owner = player
			state.Generation = state.Generation + 1
			state.Purchased = {}
			plotByPlayer[player.UserId] = state

			local owned = {}
			for _, id in ipairs(data.Items or {}) do
				owned[id] = true
			end
			for _, item in ipairs(Config.Items) do
				if owned[item.Id] then
					state.Purchased[item.Id] = true
					TycoonManager.BuildItem(state, item)
				end
			end

			local sign = state.Model:FindFirstChild("Sign")
			local gui = sign and sign:FindFirstChild("SignGui")
			local label = gui and gui:FindFirstChild("SignText")
			if label then
				label.Text = "Tycoon cua " .. player.DisplayName
			end
			TycoonManager.RefreshButton(state)
			sendMessage(player, "Chao mung den voi " .. Config.GameName .. "! Dam len nut xanh de mua vat pham.")
			return state
		end
	end
	sendMessage(player, "Server da het khu dat trong, cho nguoi khac thoat ra nhe.")
	return nil
end

function TycoonManager.TeleportToPlot(player)
	local state = plotByPlayer[player.UserId]
	if not state then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(state.Origin + Vector3.new(18, 5, 20))
	end
end

-- Chup lai du lieu hien tai cua nguoi choi (khong thay doi gi ca)
function TycoonManager.GetSessionData(player)
	local state = plotByPlayer[player.UserId]
	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
	local items = {}
	if state then
		for id, ownedFlag in pairs(state.Purchased) do
			if ownedFlag then
				table.insert(items, id)
			end
		end
	end
	return {
		Cash = cashValue and cashValue.Value or Config.StartingCash,
		Items = items,
	}
end

function TycoonManager.UnregisterPlayer(player)
	local snapshot = TycoonManager.GetSessionData(player)
	local state = plotByPlayer[player.UserId]
	if state then
		-- Don sach khu dat cho nguoi choi tiep theo
		state.Generation = state.Generation + 1
		state.Owner = nil
		state.Purchased = {}
		plotByPlayer[player.UserId] = nil
		local itemsFolder = state.Model:FindFirstChild("Items")
		if itemsFolder then
			itemsFolder:ClearAllChildren()
		end
		local partsFolder = state.Model:FindFirstChild("Parts")
		if partsFolder then
			partsFolder:ClearAllChildren()
		end
		local gate = state.Model:FindFirstChild("UpgraderGate")
		if gate then
			gate:SetAttribute("Enabled", false)
			gate.Transparency = 1
		end
		if state.Button then
			state.Button:Destroy()
			state.Button = nil
		end
		local sign = state.Model:FindFirstChild("Sign")
		local gui = sign and sign:FindFirstChild("SignGui")
		local label = gui and gui:FindFirstChild("SignText")
		if label then
			label.Text = "Tycoon trong"
		end
	end
	return snapshot
end

-- ---------------------------------------------------------------- Khoi tao
function TycoonManager.Init()
	local folder = workspace:FindFirstChild("Tycoons")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Tycoons"
		folder.Parent = workspace
	end
	messageRemote = Instance.new("RemoteEvent")
	messageRemote.Name = "TycoonMessage"
	messageRemote.Parent = ReplicatedStorage

	for index = 1, Config.PlotCount do
		buildPlotShell(index)
	end
end

return TycoonManager
