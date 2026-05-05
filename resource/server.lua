lib.locale()
local config = require('config')
lib.versionCheck('s4t4n667/s4t4n667_bindiving')

local function getRandomLoot(pool)
    local totalWeight = 0

    for _, loot in ipairs(pool) do
        totalWeight = totalWeight + (tonumber(loot.chance) or 0)
    end

    if totalWeight <= 0 then return nil end

    local roll = math.random(1, totalWeight)
    local current = 0

    for i, loot in ipairs(pool) do
        current = current + (tonumber(loot.chance) or 0)

        if roll <= current then
            return i, {
                item = loot.item,
                amount = math.random(loot.min or 1, loot.max or 1)
            }
        end
    end

    return nil
end

local function reward(source)
    if not source or source == 0 then return end

    if math.random(100) <= (config.setup.noLoot or 0) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale('notifyNoLoot.title'),
            description = locale('notifyNoLoot.description'),
            icon = 'trash',
            iconColor = config.notifications.failColor,
            position = config.notifications.position
        })
        return {}
    end

    if not config.binLoot or #config.binLoot == 0 then
        print("^1[LOOT ERROR]^0 binLoot is empty")
        return {}
    end

    local pool = {}
    for i = 1, #config.binLoot do
        pool[i] = config.binLoot[i]
    end

    local lootRange = config.setup.lootRange or {1, 1}
    local itemCount = math.random(lootRange[1] or 1, lootRange[2] or 1)

    local rewards = {}

    for i = 1, itemCount do
        if #pool == 0 then break end

        local index, loot = getRandomLoot(pool)

        if loot then
            table.insert(rewards, loot)
            table.remove(pool, index)
        end
    end

    if #rewards == 0 then
        local fallback = config.binLoot[math.random(1, #config.binLoot)]
        rewards = {{
            item = fallback.item,
            amount = math.random(fallback.min or 1, fallback.max or 1)
        }}
    end

    return rewards
end

lib.callback.register("s4t4n667_bindiving:binSearch", function(source, playerCoords)
    local ped = GetPlayerPed(source)
    local serverPlayerCoords = GetEntityCoords(ped)
    local maxDist = config.setup.maxDistance

    if #(serverPlayerCoords - playerCoords) > maxDist then
        return false
    end

    local rewards = reward(source)

    if rewards and #rewards > 0 then
        for _, item in ipairs(rewards) do
            local canCarry = exports.ox_inventory:CanCarryItem(source, item.item, item.amount)

            if canCarry then
                exports.ox_inventory:AddItem(source, item.item, item.amount)
            else
                TriggerClientEvent('ox_lib:notify', source, {title = locale('notifyFullInventory.title'), description = locale('notifyFullInventory.description'), icon = 'times-circle', iconColor = config.notifications.failColor, })
                return false
            end
        end
        return true
    end
    return false
end)

local function GetShopItem(itemName)
    for _, item in pairs(config.binLoot) do
        if item.item == itemName then
            return item
        end
    end
    return nil
end

RegisterNetEvent("s4t4n667_bindiving:sellItem", function(item)
    local src = source

    local data = GetShopItem(item)
    if not data then
        print(("[s4t4n667_bindiving] %s invalid item: %s"):format(src, item))
        return
    end

    local count = exports.ox_inventory:Search(src, 'count', item)

    if count and count >= 1 then
        local amount = (data.sell or 0) * count

        if amount <= 0 then
            return
        end

        exports.ox_inventory:RemoveItem(src, item, count)
        exports.ox_inventory:AddItem(src, 'money', amount)

        TriggerClientEvent('ox_lib:notify', src, {title = locale('shop.notify_title'), description = locale('shop.notify_sell_success'), type = "success", position = config.notifications.position})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('shop.notify_title'), description = locale('shop.notify_no_item'),  type = "error", position = config.notifications.position})
    end
end)
