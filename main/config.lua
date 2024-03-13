Config = {}

Config.PricingInterval = 1000 -- 30000
Config.LowestBasePrice = 70
Config.HighestBasePrice = 200

Config.Item = "cryptophone"

-- for admins /addstock stockname baseprice quantity

Config.StaffGroups = { 'god', 'admin', 'mod' } -- FOR ESX { 'superadmin', 'admin', 'mod' }


Config.BuyDays = {
	["Monday"] = true,
	["Tuesday"] = true,
	["Thursday"] = true,
	["Friday"] = true,
	["Wednesday"] = true,
}

Config.SellDays = {
	["Saturday"] = true,
	["Sunday"] = true,
}