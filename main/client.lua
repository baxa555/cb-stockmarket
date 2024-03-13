ESX,QBCore = nil,nil
local FrameWork = GetResourceState('es_extended') ==  'started' and 'ESX' or GetResourceState('qb-core') ==  'started' and 'QBCORE'

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

RegisterNetEvent("cb-stockmarket:client:updateStock", function(data)
    SendNUIMessage({ nui = "update", stock = data })
end)

RegisterNuiCallback("exit", function()
    ClearPedTasks(PlayerPedId())
    TriggerScreenblurFadeOut(1)
    SetNuiFocus(false, false)
end)

RegisterNuiCallback("buy", function(data, cb)
    if QBCore then
        QBCore.Functions.TriggerCallback("cb-stockmarket:server:buyStock", function(result)
            cb(result)
        end, data)
    else
        ESX.TriggerServerCallback("cb-stockmarket:server:buyStock", function(result)
            cb(result)
        end, data)
    end
end)

RegisterNuiCallback("sell", function(data, cb)
    if QBCore then
        QBCore.Functions.TriggerCallback("cb-stockmarket:server:sellStock", function(result)
            cb(result)
        end, data)
    else
        ESX.TriggerServerCallback("cb-stockmarket:server:sellStock", function(result)
            cb(result)
        end, data)
    end
end)

RegisterNetEvent("cb-stockmarket:client:openStockMarket", function()
    SetPedCanPlayAmbientAnims(PlayerPedId(), true)
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_STAND_MOBILE", 0, true)
    TriggerScreenblurFadeIn(1)
    if QBCore then
        QBCore.Functions.TriggerCallback("cb-stockmarket:server:getDatas", function(data, stock)
            SendNUIMessage({ nui = "open", myDatas = data, stock = stock, buyDays = Config.BuyDays, sellDays = Config.SellDays })
            SetNuiFocus(true, true)
        end)
    else
        ESX.TriggerServerCallback("cb-stockmarket:server:getDatas", function(data, stock)
            SendNUIMessage({ nui = "open", myDatas = data, stock = stock, buyDays = Config.BuyDays, sellDays = Config.SellDays })
            SetNuiFocus(true, true)
        end)
    end
end)