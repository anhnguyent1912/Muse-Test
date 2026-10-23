-- Config.lua - Tat ca so lieu cua game nam o day, sua file nay la chinh game.
-- Dat o ReplicatedStorage/Shared (ca server va client deu doc duoc).

local Config = {}

Config.GameName = "Dream Tycoon"
Config.DataStoreName = "DreamTycoon_v1"
Config.StartingCash = 0
Config.PlotCount = 4
Config.MaxPartsPerTycoon = 45
Config.AutosaveSeconds = 120

-- Monetization: tao Game Pass / Developer Product trong Creator Hub roi
-- dien ID vao day (de 0 = chua bat tinh nang do).
Config.DoubleCashGamePassId = 0 -- Game Pass "x2 Cash" (mua 1 lan)
Config.CashProducts = {
	-- [ProductId] = so Cash nhan duoc moi lan mua (mua lap lai duoc)
	-- Vi du: [123456789] = 1000,
}

-- Chuoi vat pham cua 1 tycoon: mua theo thu tu, nut mua sau chi hien
-- khi da mua nut truoc. Dropper nao co DropValue > 0 se tu tha vat pham.
Config.Items = {
	{ Id = "Dropper1", Name = "Dropper 1", Price = 0, DropValue = 5, DropInterval = 2.0, DropperIndex = 1 },
	{ Id = "Dropper2", Name = "Dropper 2", Price = 100, DropValue = 10, DropInterval = 2.0, DropperIndex = 2 },
	{ Id = "Walls", Name = "Tuong bao", Price = 250 },
	{ Id = "Dropper3", Name = "Dropper 3", Price = 600, DropValue = 25, DropInterval = 1.8, DropperIndex = 3 },
	{ Id = "Upgrader", Name = "May nang cap x2", Price = 1200 },
	{ Id = "Dropper4", Name = "Dropper 4", Price = 3000, DropValue = 60, DropInterval = 1.6, DropperIndex = 4 },
	{ Id = "Decor", Name = "Trang tri", Price = 7500 },
	{ Id = "GoldenDropper", Name = "Dropper Vang", Price = 15000, DropValue = 150, DropInterval = 1.5, DropperIndex = 5 },
}

return Config
