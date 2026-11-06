lib.locale()
local config = require('config')

local searchCooldown = config.setup.cooldowns.search * 1000
local binCooldown = config.setup.cooldowns.sameBin * 1000
local searchDuration = config.setup.search.duration * 1000

local lastSearch = 0
local binCooldowns = {}

local function getBinKey(coords)
    return ('%0.2f_%0.2f_%0.2f'):format(coords.x, coords.y, coords.z)
end

local function isPlayerFacingEntity(ped, entity, threshold)
    local pCoords = GetEntityCoords(ped)
    local eCoords = GetEntityCoords(entity)

    local dx = eCoords.x - pCoords.x
    local dy = eCoords.y - pCoords.y

    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return false end

    dx, dy = dx / dist, dy / dist

    local forward = GetEntityForwardVector(ped)

    return (forward.x * dx + forward.y * dy) > (threshold or 0.65)
end

local function notify(id, titleKey, descriptionKey, icon, iconColor)
    lib.notify({
        id = id,
        title = locale(titleKey),
        description = locale(descriptionKey),
        position = config.notifications.position,
        icon = icon,
        iconColor = iconColor
    })
end

local function isOnGlobalCooldown(currentTime)
    if currentTime - lastSearch < searchCooldown then
        notify('binCooldown', 'cooldown.title', 'cooldown.description', 'fa-solid fa-hourglass-half', config.notifications.cooldownColor)
        return true
    end
    return false
end

local function isBinOnCooldown(binKey, currentTime)
    local lastBinSearch = binCooldowns[binKey]
    if lastBinSearch and (currentTime - lastBinSearch) < binCooldown then
        notify('binCooldown', 'cooldown.titleBin', 'cooldown.descriptionBin', 'fa-solid fa-trash', config.notifications.failColor)
        return true
    end
    return false
end

local function performSkillCheck()
    local skillCheck = config.setup.skillCheck
    if not skillCheck.enabled then return true end

    if not lib.skillCheck(skillCheck.difficulty, skillCheck.keys) then
        ClearPedTasks(cache.ped)
        notify('binFail', 'notifySkillCheck.title', 'notifySkillCheck.description', 'times-circle', config.notifications.failColor)
        return false
    end
    return true
end

RegisterNetEvent('s4t4n667_bindiving:injure', function(damage)
    if GetInvokingResource() then return end

    ApplyDamageToPed(cache.ped, damage, false)
    notify('binHurt', 'injury.title', 'injury.description', 'fa-solid fa-droplet', config.notifications.failColor)

    local cameraShake = config.setup.injury.cameraShake
    if cameraShake and cameraShake.enabled then
        ShakeGameplayCam(cameraShake.name, cameraShake.intensity)
    end

    local screenEffect = config.setup.injury.screenEffect
    if screenEffect and screenEffect.enabled then
        AnimpostfxPlay(screenEffect.name, 0, true)
        Wait(screenEffect.duration * 1000)
        AnimpostfxStop(screenEffect.name)
    end
end)

local function notifyBinEmptied()
    notify('binCooldown', 'cooldown.titleEmptied', 'cooldown.descriptionEmptied', 'fa-solid fa-trash', config.notifications.failColor)
end

local function binDive(bin)
    if cache.vehicle or not DoesEntityExist(bin) then return false end

    local currentTime = GetGameTimer()
    if isOnGlobalCooldown(currentTime) then return false end

    local binCoords = GetEntityCoords(bin)
    local binKey = getBinKey(binCoords)
    if isBinOnCooldown(binKey, currentTime) then return false end

    if lib.callback.await('s4t4n667_bindiving:isBinEmptied', false, binCoords) then
        notifyBinEmptied()
        return false
    end

    if not performSkillCheck() then return false end

    if not lib.progressBar({
        duration = searchDuration,
        label = locale('progressBar'),
        canCancel = config.setup.search.canCancel,
        position = 'bottom',
        anim = config.setup.search.anim,
        disable = {
            car = true,
            move = true
        },
    }) then return false end

    lastSearch = GetGameTimer()
    binCooldowns[binKey] = lastSearch

    local success, reason = lib.callback.await('s4t4n667_bindiving:binSearch', false, binCoords)

    if reason == 'emptied' then
        notifyBinEmptied()
    end

    return success or false
end

local function getItemLabel(loot)
    if loot.label then return loot.label end

    local item = exports.ox_inventory:Items(loot.item)
    return item and item.label or loot.item
end

local defaultImagePath = 'nui://ox_inventory/web/images'
local itemImages = {}

local function getItemImage(itemName)
    if itemImages[itemName] ~= nil then return itemImages[itemName] end

    local item = exports.ox_inventory:Items(itemName)
    local image = item and item.client and item.client.image

    if not image then
        local imagePath = GetConvar('inventory:imagepath', defaultImagePath)

        if imagePath ~= defaultImagePath then
            image = ('%s/%s.png'):format(imagePath, itemName)
        elseif LoadResourceFile('ox_inventory', ('web/images/%s.png'):format(itemName)) then
            image = ('%s/%s.png'):format(imagePath, itemName)
        end
    end

    itemImages[itemName] = image or false
    return itemImages[itemName]
end

local function sellItem(loot)
    local count = exports.ox_inventory:Search('count', loot.item) or 0

    if count < 1 then
        notify('bindivingShop', 'shop.notify_title', 'shop.notify_no_item', 'times-circle', config.notifications.failColor)
        return
    end

    if count == 1 then
        TriggerServerEvent('s4t4n667_bindiving:sellItem', loot.item, 1)
        return
    end

    local input = lib.inputDialog(getItemLabel(loot), {
        {
            type = 'slider',
            label = locale('shop.amount'),
            min = 1,
            max = count,
            default = count,
            step = 1,
        },
    })

    local amount = input and tonumber(input[1])
    if not amount then return end

    TriggerServerEvent('s4t4n667_bindiving:sellItem', loot.item, amount)
end

local function formatPrice(price)
    local payoutItem = config.shop.payoutItem or 'money'
    if payoutItem == 'money' then
        return locale('shop.money', price)
    end

    return ('%s %s'):format(price, getItemLabel({ item = payoutItem }))
end

local function openSellMenu()
    local options = {}

    for _, loot in ipairs(config.setup.loot.items) do
        if loot.sell and loot.sell > 0 then
            local rarityName = loot.rarity or 'common'
            local rarity = config.setup.loot.rarities[rarityName] or {}
            local count = exports.ox_inventory:Search('count', loot.item) or 0

            options[#options + 1] = {
                title = ('%s - %s'):format(getItemLabel(loot), formatPrice(loot.sell)),
                description = locale('shop.rarity', rarity.label or rarityName),
                icon = loot.icon or getItemImage(loot.item) or 'fa-solid fa-dollar-sign',
                iconColor = loot.iconColor,
                disabled = count < 1,
                onSelect = function()
                    sellItem(loot)
                end
            }
        end
    end

    lib.registerContext({
        id = 'bindiving_shop_sell',
        title = locale('shop.title'),
        options = options
    })

    lib.showContext('bindiving_shop_sell')
end

local function createShopBlip()
    local settings = config.shop.blip
    local coords = config.shop.ped.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, settings.sprite)
    SetBlipColour(blip, settings.color)
    SetBlipScale(blip, settings.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(settings.label)
    EndTextCommandSetBlipName(blip)
end

local shopPed
local shopNearby = false

local function deleteShopPed()
    if shopPed and DoesEntityExist(shopPed) then
        exports.ox_target:removeLocalEntity(shopPed, 'bindiving-shop')
        DeleteEntity(shopPed)
    end
    shopPed = nil
end

local function createShopPed()
    if shopPed then return end

    local coords = config.shop.ped.coords
    local model = lib.requestModel(config.shop.ped.model)
    if not model then return end

    if not shopNearby then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1, coords.w, false, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(ped) then return end

    SetEntityAsMissionEntity(ped, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if config.shop.ped.scenario then
        TaskStartScenarioInPlace(ped, config.shop.ped.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'bindiving-shop',
            icon = config.shop.target.icon,
            iconColor = config.shop.target.iconColor,
            distance = config.shop.target.distance,
            label = locale('shop.target'),
            onSelect = openSellMenu
        }
    })

    shopPed = ped
end

local function setupShopPoint()
    lib.points.new({
        coords = config.shop.ped.coords.xyz,
        distance = config.shop.ped.spawnDistance or 50.0,
        onEnter = function()
            shopNearby = true
            createShopPed()
        end,
        onExit = function()
            shopNearby = false
            deleteShopPed()
        end,
    })
end

local function addBinTargets()
    exports.ox_target:addModel(config.binModels, {
        {
            name = 'bindiving-search',
            label = config.target.label,
            icon = config.target.icon,
            iconColor = config.target.iconColor,
            distance = config.target.distance,
            canInteract = function(entity)
                return isPlayerFacingEntity(cache.ped, entity, config.target.facingThreshold)
            end,
            onSelect = function(data)
                binDive(data.entity)
            end,
        },
    })
end

if config.shop.blip and config.shop.blip.enabled then
    createShopBlip()
end

AddEventHandler('onResourceStart', function(resource)
    if resource == cache.resource then
        setupShopPoint()
        addBinTargets()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        deleteShopPed()
    end
end)