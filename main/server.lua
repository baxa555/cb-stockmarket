ESX,QBCore = nil,nil
local FrameWork = GetResourceState('es_extended') ==  'started' and 'ESX' or GetResourceState('qb-core') ==  'started' and 'QBCORE'
local stocks = {}
local ownedStocks = {}

if FrameWork == "ESX" then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    if not ESX then
        ESX = exports['es_extended']:getSharedObject()
    end
elseif FrameWork == 'QBCORE' then
	QBCore = exports['qb-core']:GetCoreObject() 
else
    print("FrameWork Not Detected!")
end

print("Framework: ".. FrameWork)

local function getOwnerStock(stockname, owner)
    for index, entry in ipairs(ownedStocks) do
        if entry.stockname == stockname and entry.owner == owner then
            return index
        end
    end
    return nil
end

local function getTotalCountByOwner(stockname, owner)
    local total = 0
    for _, entry in ipairs(ownedStocks) do
        if entry.stockname == stockname and entry.owner == owner then
            total = total + entry.count
        end
    end
    return total
end

local function getStock(stockname)
    for index, entry in ipairs(stocks) do
        if entry.name == stockname then
            return index
        end
    end
    return nil
end

CreateThread(function()
    stocks = exports.oxmysql:executeSync('SELECT * FROM cb_stockmarket', {})
    ownedStocks = exports.oxmysql:executeSync('SELECT * FROM cb_stocks', {})
    while true do
        math.randomseed(os.time())

        for i=1,#stocks do
            if(stocks[i].worth == 0)then
                stocks[i].worth = math.ceil(stocks[i].baseWorth * (math.random(2, 20) / 10))
            else
                stocks[i].worth = math.ceil(stocks[i].worth * (math.random(2, 20) / 10))

                if(stocks[i].worth < ((stocks[i].baseWorth / 100) * Config.LowestBasePrice))then
                    stocks[i].worth = math.ceil((stocks[i].baseWorth / 100) * Config.LowestBasePrice)
                end

                if(stocks[i].worth > ((stocks[i].baseWorth / 100) * Config.HighestBasePrice))then
                    stocks[i].worth = math.ceil((stocks[i].baseWorth / 100) * Config.HighestBasePrice)
                end
            end
            Wait(100)
            exports.oxmysql:execute('UPDATE cb_stockmarket SET worth = @worth WHERE id = @id', {['@worth'] = stocks[i].worth, ['@id'] = stocks[i].id})
        end

        TriggerClientEvent("cb-stockmarket:client:updateStock", -1, stocks)
        Wait(Config.PricingInterval)
    end
end)

if QBCore then
    QBCore.Functions.CreateUseableItem(Config.Item, function(source)
        TriggerClientEvent('cb-stockmarket:client:openStockMarket', source)
    end)

    RegisterCommand("addstock", function (source, args)
        for _, value in pairs(Config.StaffGroups) do
            if QBCore.Functions.HasPermission(source, value) then
                if args[1] then
                    if args[2] then
                        if tonumber(args[2]) >= Config.LowestBasePrice and Config.HighestBasePrice >= tonumber(args[2]) then
                            if args[3] then
                                exports.oxmysql:execute('INSERT INTO cb_stockmarket (name, baseWorth, amount) VALUES (@name, @baseWorth, @amount)', {
                                    ['@name'] = args[1],
                                    ['@baseWorth'] = args[2],
                                    ['@amount'] = args[3],
                                }, function (id)
                                    table.insert(stocks, {id = id.insertId, name = args[1], baseWorth = args[2], amount = args[3], worth = 0})
                                    TriggerClientEvent('QBCore:Notify', source, "Succesfully added", "success")
                                    TriggerClientEvent("cb-stockmarket:client:updateStock", -1, stocks)
                                end)
                            else
                                TriggerClientEvent('QBCore:Notify', source, "You need enter amount", "error")
                            end
                        else
                            TriggerClientEvent('QBCore:Notify', source, "You need enter Min: "..Config.LowestBasePrice.." Max: "..Config.HighestBasePrice, "error")
                        end
                    else
                        TriggerClientEvent('QBCore:Notify', source, "You need enter base price", "error")
                    end
                else
                    TriggerClientEvent('QBCore:Notify', source, "You need enter Stock Name", "error")
                end
                break
            end
        end
    end, false)

    QBCore.Functions.CreateCallback("cb-stockmarket:server:getDatas", function(source, cb)
        local Player = QBCore.Functions.GetPlayer(source)
        local ownedStocksData = {}
        for _, value in pairs(stocks) do
            ownedStocksData[value.name] = getTotalCountByOwner(value.name, Player.PlayerData.citizenid)
        end
        cb(ownedStocksData, stocks)
    end)

    QBCore.Functions.CreateCallback("cb-stockmarket:server:buyStock", function(source, cb, data)
        local Player = QBCore.Functions.GetPlayer(source)
        local toIndex = getOwnerStock(data.stock, Player.PlayerData.citizenid)
        local index = getStock(data.stock)
        if index then
            if stocks[index].amount >= data.count then
                if Player.Functions.RemoveMoney("bank", stocks[index].worth * data.count, "StockMarket_Buy") then
                    stocks[index].amount = stocks[index].amount - data.count
                    if ownedStocks[toIndex] then
                        ownedStocks[toIndex].count = ownedStocks[toIndex].count + data.count
                    else
                        table.insert(ownedStocks, { owner = Player.PlayerData.citizenid, stockname = data.stock, count = data.count})
                    end
                    exports.oxmysql:execute('INSERT INTO cb_stocks (owner, stockname, count) VALUES (@owner, @stockname, @count) ON DUPLICATE KEY UPDATE count = count + '..data.count, {
                        ['@owner'] = Player.PlayerData.citizenid,
                        ['@stockname'] = stocks[index].name,
                        ['@count'] = data.count,
                    })
                    exports.oxmysql:execute('UPDATE cb_stockmarket SET amount = @count WHERE name = @name', {['@count'] = stocks[index].amount, ['@name'] = stocks[index].name })
                    TriggerClientEvent("cb-stockmarket:client:updateStock", -1, stocks)
                    cb(true)
                else
                    cb(false)
                end
            else
                cb(false)
            end
        end
    end)

    QBCore.Functions.CreateCallback("cb-stockmarket:server:sellStock", function(source, cb, data)
        local Player = QBCore.Functions.GetPlayer(source)
        local index = getOwnerStock(data.stock, Player.PlayerData.citizenid)
        local toIndex = getStock(data.stock)
        if index then
            if ownedStocks[index].count >= data.count then
                ownedStocks[index].count = ownedStocks[index].count - data.count
                stocks[toIndex].amount = stocks[toIndex].amount + data.count
                Player.Functions.AddMoney("bank", stocks[toIndex].worth * data.count, "StockMarket_Sell")
                exports.oxmysql:execute('UPDATE cb_stocks SET count = @count WHERE stockname = @name AND owner = @owner', {['@count'] = ownedStocks[index].count, ['@name'] = ownedStocks[index].stockname, ['@owner'] = Player.PlayerData.citizenid })
                exports.oxmysql:execute('UPDATE cb_stockmarket SET amount = @count WHERE name = @name', {['@count'] = stocks[toIndex].amount, ['@name'] = stocks[toIndex].name })
                cb(true)
            else
                cb(false)
            end
        end
    end)
else
    ESX.RegisterUsableItem(Config.Item, function(source)
        TriggerClientEvent('cb-stockmarket:client:openStockMarket', source)
    end)

    RegisterCommand("addstock", function (source, args)
        local xPlayer = ESX.GetPlayerFromId(source)
        local playerGroup = xPlayer.getGroup()
        for _, value in pairs(Config.StaffGroups) do
            if playerGroup == value then
                if args[1] then
                    if args[2] then
                        if tonumber(args[2]) >= Config.LowestBasePrice and Config.HighestBasePrice >= tonumber(args[2]) then
                            if args[3] then
                                exports.oxmysql:execute('INSERT INTO cb_stockmarket (name, baseWorth, amount) VALUES (@name, @baseWorth, @amount)', {
                                    ['@name'] = args[1],
                                    ['@baseWorth'] = args[2],
                                    ['@amount'] = args[3],
                                }, function (id)
                                    table.insert(stocks, {id = id.insertId, name = args[1], baseWorth = args[2], amount = args[3], worth = 0})
                                    xPlayer.showNotification("Succesfully added")
                                    TriggerClientEvent("cb-stockmarket:client:updateStock", -1, stocks)
                                end)
                            else
                                xPlayer.showNotification("You need enter Min: "..Config.LowestBasePrice.." Max: "..Config.HighestBasePrice)
                            end
                        else
                            xPlayer.showNotification("You need enter amount")
                        end
                    else
                        xPlayer.showNotification("You need enter base price")
                    end
                else
                    xPlayer.showNotification("You need enter Stock Name")
                end
                break
            end
        end
    end, false)

    ESX.RegisterServerCallback("cb-stockmarket:server:getDatas", function(source, cb)
        local Player = ESX.GetPlayerFromId(source)
        local ownedStocksData = {}
        for _, value in pairs(stocks) do
            ownedStocksData[value.name] = getTotalCountByOwner(value.name, Player.identifier)
        end
        cb(ownedStocksData, stocks)
    end)

    ESX.RegisterServerCallback("cb-stockmarket:server:buyStock", function(source, cb, data)
        local Player = ESX.GetPlayerFromId(source)
        local toIndex = getOwnerStock(data.stock, Player.identifier)
        local index = getStock(data.stock)
        if index then
            if stocks[index].amount >= data.count then
                if Player.getAccount('bank').money >= (stocks[index].worth * data.count) then
                    Player.removeAccountMoney('bank', stocks[index].worth * data.count)
                    stocks[index].amount = stocks[index].amount - data.count
                    if ownedStocks[toIndex] then
                        ownedStocks[toIndex].count = ownedStocks[toIndex].count + data.count
                    else
                        table.insert(ownedStocks, { owner = Player.identifier, stockname = data.stock, count = data.count})
                    end
                    exports.oxmysql:execute('INSERT INTO cb_stocks (owner, stockname, count) VALUES (@owner, @stockname, @count) ON DUPLICATE KEY UPDATE count = count + '..data.count, {
                        ['@owner'] = Player.identifier,
                        ['@stockname'] = stocks[index].name,
                        ['@count'] = data.count,
                    })
                    exports.oxmysql:execute('UPDATE cb_stockmarket SET amount = @count WHERE name = @name', {['@count'] = stocks[index].amount, ['@name'] = stocks[index].name })
                    TriggerClientEvent("cb-stockmarket:client:updateStock", -1, stocks)
                    cb(true)
                else
                    cb(false)
                end
            else
                cb(false)
            end
        end
    end)

    ESX.RegisterServerCallback("cb-stockmarket:server:sellStock", function(source, cb, data)
        local Player = ESX.GetPlayerFromId(source)
        local index = getOwnerStock(data.stock, Player.identifier)
        local toIndex = getStock(data.stock)
        if index then
            if ownedStocks[index].count >= data.count then
                ownedStocks[index].count = ownedStocks[index].count - data.count
                stocks[toIndex].amount = stocks[toIndex].amount + data.count
                Player.addAccountMoney('bank', stocks[toIndex].worth * data.count)
                exports.oxmysql:execute('UPDATE cb_stocks SET count = @count WHERE stockname = @name AND owner = @owner', {['@count'] = ownedStocks[index].count, ['@name'] = ownedStocks[index].stockname, ['@owner'] = Player.identifier })
                exports.oxmysql:execute('UPDATE cb_stockmarket SET amount = @count WHERE name = @name', {['@count'] = stocks[toIndex].amount, ['@name'] = stocks[toIndex].name })
                cb(true)
            else
                cb(false)
            end
        end
    end)
end