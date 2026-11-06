lib.locale()
lib.versionCheck('s4t4n667/s4t4n667_bindiving')
local config = require('config')

local shopRange = config.shop.sellRange or 5.0
local shopCoords = config.shop.ped.coords.xyz
local cooldownGrace = 500
local searchCooldown = config.setup.cooldowns.search * 1000
local binCooldown = config.setup.cooldowns.sameBin * 1000
local emptiedBinCooldown = (config.setup.cooldowns.emptiedBin or 0) * 1000
local lastSearch = {}
local binCooldowns = {}
local emptiedBins = {}
local injuryCheckDelay = 1500
local rollPrecision = 1000000

local function randomFraction()
    return (math.random(1, rollPrecision) - 1) / rollPrecision
end

local function rollPercent(chance)
    return randomFraction() * 100 < (tonumber(chance) or 0)
end

local function itemWeight(loot)
    return tonumber(loot.chance) or 0
end

local function rarityOf(loot)
    return loot.rarity or 'common'
end

for _, loot in ipairs(config.setup.loot.items) do
    if not config.setup.loot.rarities[rarityOf(loot)] then
        lib.print.warn(("%s has unknown rarity '%s' and will never drop"):format(loot.item, rarityOf(loot)))
    end
end

local function weightedPick(list, getWeight)
    local totalWeight = 0

    for _, entry in ipairs(list) do
        totalWeight = totalWeight + getWeight(entry)
    end

    if totalWeight <= 0 then return nil end

    local roll = randomFraction() * totalWeight
    local current = 0

    for i, entry in ipairs(list) do
        current = current + getWeight(entry)
        if roll < current then return i end
    end

    return nil
end

local function getRandomLoot(pool)
    local available, seen = {}, {}

    for _, loot in ipairs(pool) do
        local rarity = rarityOf(loot)
        if not seen[rarity] and config.setup.loot.rarities[rarity] and itemWeight(loot) > 0 then
            seen[rarity] = true
            available[#available + 1] = rarity
        end
    end

    local rarityIndex = weightedPick(available, function(name)
        return tonumber(config.setup.loot.rarities[name].weight) or 0
    end)
    if not rarityIndex then return nil end

    local rarity = available[rarityIndex]
    local candidates = {}

    for i, loot in ipairs(pool) do
        if rarityOf(loot) == rarity then
            candidates[#candidates + 1] = i
        end
    end

    local index = candidates[weightedPick(candidates, function(i) return itemWeight(pool[i]) end)]
    local loot = pool[index]

    return index, {
        item = loot.item,
        amount = math.random(loot.min or 1, loot.max or 1),
        rarity = rarity
    }
end

local function reward(source, injured)
    if not source or source == 0 then return end

    if rollPercent(config.setup.loot.emptyChance) then
        if not injured then
            TriggerClientEvent('ox_lib:notify', source, {
                title = locale('notifyNoLoot.title'),
                description = locale('notifyNoLoot.description'),
                icon = 'trash',
                iconColor = config.notifications.failColor,
                position = config.notifications.position
            })
        end
        return {}
    end

    if not config.setup.loot.items or #config.setup.loot.items == 0 then
        lib.print.error('setup.loot.items is empty')
        return {}
    end

    local pool = {}
    for i = 1, #config.setup.loot.items do
        pool[i] = config.setup.loot.items[i]
    end

    local lootAmount = config.setup.loot.amount or { 1, 1 }
    local minItems = lootAmount[1] or 1
    local itemCount = math.random(minItems, math.max(minItems, lootAmount[2] or minItems))

    local rewards = {}

    for _ = 1, itemCount do
        local index, loot = getRandomLoot(pool)
        if not loot then break end

        rewards[#rewards + 1] = loot
        table.remove(pool, index)
    end

    return rewards
end

local function notifyFullInventory(source)
    TriggerClientEvent('ox_lib:notify', source, {
        title = locale('notifyFullInventory.title'),
        description = locale('notifyFullInventory.description'),
        icon = 'times-circle',
        iconColor = config.notifications.failColor,
        position = config.notifications.position
    })
end

local function giveRewards(source, rewards)
    for _, item in ipairs(rewards) do
        if not exports.ox_inventory:CanCarryItem(source, item.item, item.amount) then
            notifyFullInventory(source)
            return false
        end
    end

    for _, item in ipairs(rewards) do
        exports.ox_inventory:AddItem(source, item.item, item.amount)

        local rarity = config.setup.loot.rarities[item.rarity]
        if rarity.notify then
            local itemData = exports.ox_inventory:Items(item.item)

            TriggerClientEvent('ox_lib:notify', source, {
                title = locale('rareFind.title', rarity.label),
                description = locale('rareFind.description', itemData and itemData.label or item.item),
                icon = 'fa-solid fa-gem',
                position = config.notifications.position,
                duration = 6000
            })
        end
    end

    return true
end

local function getBinKey(coords)
    return ('%0.2f_%0.2f_%0.2f'):format(coords.x, coords.y, coords.z)
end

local function isBinEmptied(binKey, currentTime)
    local emptiedAt = emptiedBins[binKey]
    return emptiedAt ~= nil and (currentTime - emptiedAt) < emptiedBinCooldown
end

local function markBinEmptied(binKey, currentTime)
    if emptiedBinCooldown <= 0 then return end

    for key, emptiedAt in pairs(emptiedBins) do
        if currentTime - emptiedAt >= emptiedBinCooldown then
            emptiedBins[key] = nil
        end
    end

    emptiedBins[binKey] = currentTime
end

lib.callback.register('s4t4n667_bindiving:isBinEmptied', function(_, binCoords)
    if type(binCoords) ~= 'vector3' then return false end
    return isBinEmptied(getBinKey(binCoords), GetGameTimer())
end)

local function injurePlayer(source, ped)
    local injury = config.setup.injury
    if not injury or not injury.enabled then return true, false end
    if not rollPercent(injury.chance) then return true, false end

    local healthBefore = GetEntityHealth(ped)
    TriggerClientEvent('s4t4n667_bindiving:injure', source, injury.damage)

    if not injury.keepLoot then return false, true end

    Wait(injuryCheckDelay)

    if healthBefore - GetEntityHealth(ped) < injury.damage / 2 then
        lib.print.warn(('%s did not take glass injury damage, loot withheld'):format(source))
        return false, true
    end

    return true, true
end

lib.callback.register('s4t4n667_bindiving:binSearch', function(source, binCoords)
    if type(binCoords) ~= 'vector3' then return false end

    local currentTime = GetGameTimer()

    if lastSearch[source] and (currentTime - lastSearch[source]) < (searchCooldown - cooldownGrace) then
        return false
    end

    local binKey = getBinKey(binCoords)
    local playerBins = binCooldowns[source]

    if playerBins and playerBins[binKey] and (currentTime - playerBins[binKey]) < (binCooldown - cooldownGrace) then
        return false
    end

    if isBinEmptied(binKey, currentTime) then
        return false, 'emptied'
    end

    local ped = GetPlayerPed(source)
    local serverPlayerCoords = GetEntityCoords(ped)
    local maxDist = config.setup.search.maxDistance

    if #(serverPlayerCoords - binCoords) > maxDist then
        return false
    end

    if playerBins then
        for key, searchedAt in pairs(playerBins) do
            if currentTime - searchedAt >= binCooldown then
                playerBins[key] = nil
            end
        end
    else
        playerBins = {}
        binCooldowns[source] = playerBins
    end

    lastSearch[source] = currentTime
    playerBins[binKey] = currentTime
    markBinEmptied(binKey, currentTime)

    local canLoot, injured = injurePlayer(source, ped)
    if not canLoot then return false end

    local rewards = reward(source, injured)
    if not rewards or #rewards == 0 then return false end

    return giveRewards(source, rewards)
end)

AddEventHandler('playerDropped', function()
    lastSearch[source] = nil
    binCooldowns[source] = nil
end)

local sellPrices = {}
for _, loot in ipairs(config.setup.loot.items) do
    if loot.sell and loot.sell > 0 then
        sellPrices[loot.item] = loot.sell
    end
end

local function notifyShop(source, descriptionKey, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = locale('shop.notify_title'),
        description = locale(descriptionKey),
        type = notifyType,
        position = config.notifications.position
    })
end

RegisterNetEvent('s4t4n667_bindiving:sellItem', function(item, amount)
    local src = source

    if #(GetEntityCoords(GetPlayerPed(src)) - shopCoords) > shopRange then
        lib.print.warn(('%s tried to sell %s away from the shop'):format(src, tostring(item)))
        return
    end

    local price = type(item) == 'string' and sellPrices[item]
    if not price then
        lib.print.warn(('%s tried to sell invalid item: %s'):format(src, tostring(item)))
        return
    end

    amount = math.tointeger(tonumber(amount))
    if not amount or amount < 1 then return end

    local count = exports.ox_inventory:Search(src, 'count', item)
    if not count or count < amount then
        return notifyShop(src, 'shop.notify_no_item', 'error')
    end

    if not exports.ox_inventory:RemoveItem(src, item, amount) then return end

    exports.ox_inventory:AddItem(src, config.shop.payoutItem or 'money', price * amount)
    notifyShop(src, 'shop.notify_sell_success', 'success')
end)
