lib.locale()
local config = require('config')

local lastsearch = 0
local closestBin, binPos


local function binDive()
    if IsPedInAnyVehicle(PlayerPedId(), true) then return end
    if NetworkIsInSpectatorMode() then return end
    if not IsPlayerPlaying(PlayerId()) then return end
    
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local currentTime = GetGameTimer()
    
    if currentTime - lastsearch < config.cooldown then
        lib.notify({
            id = 'binCooldown',
            title = locale('cooldown.title'),
            description = locale('cooldown.description'),
            showDuration = true,
            position = 'top-right',
            icon = 'fa-solid fa-hourglass-half',
            iconColor = '#FE9900'
        })
        return false
    end

    for _, model in ipairs(config.binModels) do
        local bin = GetClosestObjectOfType(playerPos.x, playerPos.y, playerPos.z, config.maximumDistance, model, false, false, false)

        if DoesEntityExist(bin) then
            closestBin, binPos = bin, GetEntityCoords(bin)
            break
        end
    end

    if not closestBin then return false end

    local distance = #(playerPos - binPos)

    if distance > config.maximumDistance then
        lib.notify({
            id = 'binFail',
            title = locale('distance.title'),
            description = locale('distance.description'),
            showDuration = true,
            duration = 3000,
            position = 'top-right',
            icon = 'ban',
            iconColor = '#D20103'
        })
        return false
    end

    local searchAnim = {dict = 'amb@prop_human_bum_bin@base', clip = 'base'}

    if config.useSkillCheck then
        local skillSuccess = lib.skillCheck(config.skillCheck, config.skillCheckKeys)

        if not skillSuccess then
            ClearPedTasks(ped)
            lib.notify({
                id = 'binFail',
                title = locale('notifySkillCheck.title'),
                description = locale('notifySkillCheck.description'),
                showDuration = true,
                duration = 3000,
                position = 'top-right',
                icon = 'times-circle',
                iconColor = '#D20103'
            })
            return false
        end
    end

    lastsearch = currentTime

    local progSuccess = lib.progressCircle({
        duration = config.searchTime,
        label = locale('progressBar'),
        canCancel = true,
        position = 'bottom',
        anim = searchAnim,
        disable = {
            car = true,
            move = true
        },
    })

    if not progSuccess then return false end

    local success = lib.callback.await('s4t4n667_bindiving:binSearch', false, GetEntityCoords(PlayerPedId()))

    if not success then return false end

    return true
end


local function addTarget()
    for _, model in ipairs(config.binModels) do
        local options = {
            {
                name = 'binTarget',
                label = config.target.label,
                icon = config.target.icon,
                iconColor = config.target.iconColor,
                distance = config.target.distance,
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