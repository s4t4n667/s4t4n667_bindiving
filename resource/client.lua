lib.locale()
local config = require('config')

local lastSearch = 0
local closestBin, binPos
local binID = 0
local binCooldowns = {}

CreateThread(function()
    if config.shop.blip then
        local shopBlip = AddBlipForCoord(config.shop.coords.x, config.shop.coords.y, config.shop.coords.z)
        SetBlipSprite(shopBlip, config.shop.blipSprite)
        SetBlipColour(shopBlip, config.shop.blipColor)
        SetBlipScale(shopBlip, config.shop.blipScale)
        SetBlipAsShortRange(shopBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(config.shop.blipLabel)
        EndTextCommandSetBlipName(shopBlip)
    end 
end)

local function getBinKey(coords)
    return ("%0.2f_%0.2f_%0.2f"):format(coords.x, coords.y, coords.z)
end

local function IsPlayerFacingEntity(ped, entity, threshold)
    local pCoords = GetEntityCoords(ped)
    local eCoords = GetEntityCoords(entity)

    local dx = eCoords.x - pCoords.x
    local dy = eCoords.y - pCoords.y

    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return false end

    local invDist = 1 / dist
    dx, dy = dx * invDist, dy * invDist

    local forward = GetEntityForwardVector(ped)
    threshold = threshold or 0.65

    return (forward.x * dx + forward.y * dy) > threshold
end

local function getClosestBin(pCoords)
    for _, model in ipairs(config.binModels) do
        local bin = GetClosestObjectOfType(
            pCoords.x, pCoords.y, pCoords.z,
            config.setup.maxDistance,
            model,
            false, false, false
        )

        if DoesEntityExist(bin) then
            return bin
        end
    end

    return nil
end

local function isOnGlobalCooldown(currentTime)
    if currentTime - lastSearch < config.setup.cooldown then
        lib.notify({
            id = 'binCooldown',
            title = locale('cooldown.title'),
            description = locale('cooldown.description'),
            position = config.notifications.position,
            icon = 'fa-solid fa-hourglass-half',
            iconColor = config.notifications.cooldownColor
        })
        return true
    end
    return false
end

local function isBinOnCooldown(binKey, currentTime)
    if binCooldowns[binKey] and (currentTime - binCooldowns[binKey]) < config.setup.binCooldown then
        lib.notify({
            id = 'binCooldown',
            title = locale('cooldown.titleBin'),
            description = locale('cooldown.descriptionBin'),
            position = config.notifications.position,
            icon = 'fa-solid fa-trash',
            iconColor = config.notifications.failColor
        })
        return true
    end
    return false
end

local function performSkillCheck()
    if config.setup.useSkillCheck then
        if not lib.skillCheck(config.setup.difficulty, config.setup.keys) then
            ClearPedTasks(ped)
            lib.notify({
                id = 'binFail',
                title = locale('notifySkillCheck.title'),
                description = locale('notifySkillCheck.description'),
                position = 'top-right',
                icon = 'times-circle',
                iconColor = config.notifications.failColor
            })
            return false
        end
    end
    return true
end

function binDive()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, true) then return false end

    local currentTime = GetGameTimer()

    if isOnGlobalCooldown(currentTime) then return false end

    local pCoords = GetEntityCoords(ped)
    local closestBin = getClosestBin(pCoords)
    if not closestBin then return false end

    local binCoords = GetEntityCoords(closestBin)
    local binKey = getBinKey(binCoords)

    if isBinOnCooldown(binKey, currentTime) then return false end

    if not performSkillCheck() then return false end

    lastSearch = currentTime
    binCooldowns[binKey] = currentTime

    if not lib.progressBar({
        duration = config.setup.searchTime,
        label = locale('progressBar'),
        canCancel = config.setup.searchCancel,
        position = 'bottom',
        anim = {
            dict = 'amb@prop_human_bum_bin@base',
            clip = 'base'
        },
        disable = {
            car = true,
            move = true
        },
    }) then return false end

    local success = lib.callback.await('s4t4n667_bindiving:binSearch', false, binCoords)

    return success or false
end

CreateThread(function()
    local pedModel = config.shop.ped
    local coords = config.shop.coords

    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(0) end

    local ped = CreatePed(4, pedModel, coords.x, coords.y, coords.z -1, coords.w, false, true)

    if not DoesEntityExist(ped) then
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'bindiving-shop',
            icon = 'fa-solid fa-basket-shopping',
            label = locale('shop.target'),
            onSelect = function()
                OpenSellMenu()
            end
        }
    })
end)

function OpenSellMenu()
    local options = {}

    for _, v in pairs(config.binLoot) do
        if v.sell and v.sell > 0 then
            options[#options + 1] = {
                title = (v.label or v.item) .. " - $" .. v.sell,
                icon = v.icon or "fa-solid fa-dollar-sign",
                iconColor = v.iconColor,
                onSelect = function()
                    TriggerServerEvent("s4t4n667_bindiving:sellItem", v.item, 1)
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

local function addTarget()
    binID = binID + 1

    for _, model in ipairs(config.binModels) do
        local options = {
            {
                name = ('fibrePicking_%d'):format(binID),
                label = config.target.label,
                icon = config.target.icon,
                iconColor = config.target.iconColor,
                distance = config.target.distance,
                canInteract = function(entity, distance)
                    if distance > config.target.distance then
                        return false
                    end
                    return IsPlayerFacingEntity(PlayerPedId(), entity, 0.65)
                end,
                onSelect = function()
                    binDive()
                end,
            },
        }
        exports.ox_target:addModel(model, options)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    addTarget()
end)

RegisterNetEvent('esx:playerLoaded', function()
    addTarget()
end)

AddEventHandler('onResourceStart', function(resource)
    addTarget()
end)