lib.locale()
local config = require('config')
lib.versionCheck('s4t4n667/s4t4n667_bindiving')


local function reward(source)
    if not source or source == 0 then return end

    local xPlayer = nil

    if config.useQBCore == true then 
        QBCore = exports["qb-core"]:GetCoreObject()
        xPlayer = QBCore.Functions.GetPlayer(source)
    else 
        ESX = exports['es_extended']:getSharedObject()
        xPlayer = ESX.GetPlayerFromId(source)
    end

    if not xPlayer then return end

    if math.random(100) <= config.noLoot then
        return nil
    end

    for _, loot in ipairs(config.binLoot) do
        if math.random(100) <= loot.chance then
            return {
                item = loot.item,
                amount = math.random(loot.min, loot.max)
            }
        end
    end
    return nil
end


lib.callback.register("s4t4n667_bindiving:binSearch", function(source, playerCoords)
    local ped = GetPlayerPed(source)
    local serverPlayerCoords = GetEntityCoords(ped)

    local adjustedMaxDistance = config.maximumDistance

    if #(serverPlayerCoords - playerCoords) > adjustedMaxDistance then
        print(("[EXPLOIT] Player %s attempted to execute reward function remotely!"):format(GetPlayerName(source)))
        return false
    end

    local rewardItem = reward(source)

    if rewardItem then
        if exports.ox_inventory:CanCarryItem(source, rewardItem.item, rewardItem.amount) then
            exports.ox_inventory:AddItem(source, rewardItem.item, rewardItem.amount)
            return true
        else
            lib.notify(source,{
                title = locale('notifyFullInventory.title'),
                description = locale('notifyFullInventory.description'),
                duration = 3000,
                icon = 'times-circle',
                iconColor = '#8C2425',
            })
            return false
        end
    end

    return false
end)