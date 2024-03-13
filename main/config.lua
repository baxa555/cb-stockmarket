Config = {}

Config.PricingInterval = 5000 -- It indicates how many seconds it will decrease and increase. (1000 = 1second)
Config.LowestBasePrice = 70 -- Minimum price of the coin you added (It is not recommended to replace it!)
Config.HighestBasePrice = 200 -- Maximum price of the coin you added (It is not recommended to replace it!)

Config.Item = "cryptophone"

-- for admins /addstock stockname baseprice quantity

Config.StaffGroups = { 'god', 'admin', 'mod' } -- FOR ESX { 'superadmin', 'admin', 'mod' }


Config.BuyDays = {
	["Monday"] = true,  -- or false
	["Tuesday"] = true,
	["Thursday"] = true,
	["Friday"] = true,
	["Wednesday"] = true,
}

Config.SellDays = {
	["Saturday"] = true,
	["Sunday"] = true,
}
