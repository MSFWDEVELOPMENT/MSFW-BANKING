local QBCore = exports['qb-core']:GetCoreObject()
local blips = {}

-- Functions

local function createBlips()
    for k, v in pairs(Config.BankLocations) do
        blips[k] = AddBlipForCoord(tonumber(v.x), tonumber(v.y), tonumber(v.z))
        SetBlipSprite(blips[k], Config.Blip.blipType)
        SetBlipDisplay(blips[k], 4)
        SetBlipScale  (blips[k], Config.Blip.blipScale)
        SetBlipColour (blips[k], Config.Blip.blipColor)
        SetBlipAsShortRange(blips[k], true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(tostring(Config.Blip.blipName))
        EndTextCommandSetBlipName(blips[k])
    end
end

local function removeBlips()
    for k, _ in pairs(Config.BankLocations) do
        RemoveBlip(blips[k])
    end
    blips = {}
end

local function openAccountScreen()
    QBCore.Functions.TriggerCallback('msfw-banking:getBankingInformation', function(banking)
        if banking ~= nil then
            SetNuiFocus(true, true)
            SendNUIMessage({
                status = "openbank",
                information = banking
            })
        end
    end)
end

-- Events

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    removeBlips()
end)

RegisterNetEvent('msfw-banking:transferError', function(msg)
    SendNUIMessage({
        status = "transferError",
        error = msg
    })
end)

RegisterNetEvent('msfw-banking:successAlert', function(msg)
    SendNUIMessage({
        status = "successMessage",
        message = msg
    })
end)

RegisterNetEvent('msfw-banking:openBankScreen', function()
    openAccountScreen()
end)

local BankControlPress = false
 local function BankControl()
    CreateThread(function()
        BankControlPress = true
        while BankControlPress do
            if IsControlPressed(0, 38) then
                exports['qb-core']:KeyPressed()
                TriggerEvent('msfw-banking:openBankScreen')
            end
            Wait(0)
        end
    end)
end

CreateThread(function()
    if Config.UseTarget then
        for k, v in pairs(Config.Zones) do
            exports["qb-targett"]:AddBoxZone("Bank_"..k, v.position, v.length, v.width, {
                name = "Bank_"..k,
                heading = v.heading,
                minZ = v.minZ,
                maxZ = v.maxZ
            }, {
                options = {
                    {
                        type = "client",
                        event = "msfw-banking:openBankScreen",
                        icon = "fas fa-university",
                        label = "Access Bank",
                    }
                },
                distance = 1.5
            })
        end
    else
        local bankPoly = {}
        for k, v in pairs(Config.BankLocations) do
            bankPoly[#bankPoly+1] = BoxZone:Create(vector3(v.x, v.y, v.z), 1.5, 1.5, {
                heading = -20,
                name="bank"..k,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            })
            local bankCombo = ComboZone:Create(bankPoly, {name = "bankPoly"})
            bankCombo:onPlayerInOut(function(isPointInside)
                if isPointInside then
                    exports['qb-core']:DrawText(Lang:t('info.access_bank_key'),'left')
                    BankControl()
                else
                    BankControlPress = false
                    exports['qb-core']:HideText()
                end
            end)
        end
    end
end)

-- NUI

RegisterNetEvent("hidemenu", function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        status = "closebank"
    })
end)

RegisterNetEvent('msfw-banking:client:newCardSuccess', function(cardno, ctype)
    SendNUIMessage({
        status = "updateCard",
        number = cardno,
        cardtype = ctype
    })
end)

-- NUI Callbacks

RegisterNUICallback("NUIFocusOff", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        status = "closebank"
    })
    cb("ok")
end)

RegisterNUICallback("createSavingsAccount", function(_, cb)
    TriggerServerEvent('msfw-banking:createSavingsAccount')
    cb("ok")
end)

RegisterNUICallback("doDeposit", function(data, cb)
    if tonumber(data.amount) ~= nil and tonumber(data.amount) > 0 then
        TriggerServerEvent('msfw-banking:doQuickDeposit', data.amount)
        openAccountScreen()
        cb("ok")
    end
    cb(nil)
end)

RegisterNUICallback("doWithdraw", function(data, cb)
    if tonumber(data.amount) ~= nil and tonumber(data.amount) > 0 then
        TriggerServerEvent('msfw-banking:doQuickWithdraw', data.amount, true)
        openAccountScreen()
        cb("ok")
    end
    cb(nil)
end)

RegisterNUICallback("doATMWithdraw", function(data, cb)
    if tonumber(data.amount) ~= nil and tonumber(data.amount) > 0 then
        TriggerServerEvent('msfw-banking:doQuickWithdraw', data.amount, false)
        openAccountScreen()
        cb("ok")
    end
    cb(nil)
end)

RegisterNUICallback("savingsDeposit", function(data, cb)
    if tonumber(data.amount) ~= nil and tonumber(data.amount) > 0 then
        TriggerServerEvent('msfw-banking:savingsDeposit', data.amount)
        openAccountScreen()
        cb("ok")
    end
    cb(nil)
end)

RegisterNUICallback("requestNewCard", function(_, cb)
    TriggerServerEvent('msfw-banking:createNewCard')
    cb("ok")
end)

RegisterNUICallback("savingsWithdraw", function(data, cb)
    if tonumber(data.amount) ~= nil and tonumber(data.amount) > 0 then
        TriggerServerEvent('msfw-banking:savingsWithdraw', data.amount)
        openAccountScreen()
        cb("ok")
    end
    cb(nil)
end)

RegisterNUICallback("doTransfer", function(data, cb)
    if data ~= nil then
        TriggerServerEvent('msfw-banking:initiateTransfer', data)
        cb("ok")
    end
    cb(nil)
end)

RegisterNUICallback("createDebitCard", function(data, cb)
    if data.pin ~= nil then
        TriggerServerEvent('msfw-banking:createBankCard', data.pin)
        cb("ok")
    end
    cb(nil)
end)

RegisterNUICallback("lockCard", function(_, cb)
    TriggerServerEvent('msfw-banking:toggleCard', true)
    cb("ok")
end)

RegisterNUICallback("unLockCard", function(_, cb)
    TriggerServerEvent('msfw-banking:toggleCard', false)
    cb("ok")
end)

RegisterNUICallback("updatePin", function(data, cb)
    if data.pin ~= nil then
        TriggerServerEvent('msfw-banking:updatePin', data.pin)
        cb("ok")
    end
    cb(nil)
end)
