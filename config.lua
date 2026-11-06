return {

    setup = {
        loot = {
            emptyChance = 10,       -- % chance the bin has nothing in it
            amount = { 1, 3 },      -- how many different items a search gives (min, max)
            rarities = { -- change weight to make that whole tier more or less common
                common = { weight = 70, label = 'Common' },
                uncommon = { weight = 22, label = 'Uncommon' },
                rare = { weight = 7, label = 'Rare', notify = true },
                legendary = { weight = 1, label = 'Legendary', notify = true },
            },
            items = { -- change chance to favour it over the other items of the same rarity
                { item = 'burger', rarity = 'common', min = 1, max = 3, chance = 80, sell = 0 },
                { item = 'water', rarity = 'common', min = 1, max = 3, chance = 80, sell = 0 },
                { item = 'plastic', rarity = 'common', min = 1, max = 2, chance = 60, sell = 10 },
                { item = 'glass', rarity = 'uncommon', min = 2, max = 5, chance = 50, sell = 10 },
                { item = 'steel', rarity = 'rare', min = 1, max = 2, chance = 50, sell = 10 },
            },
        },
        cooldowns = {
            search = 10,            -- seconds between any two searches
            sameBin = 10,           -- seconds before the same bin can be searched again
            emptiedBin = 60,        -- seconds before a bin that was emptied can be searched again
        },
        search = {
            duration = 2,           -- seconds the progress bar takes
            canCancel = false,      -- can players cancel the search?
            maxDistance = 2.0,      -- metres a player can be from the bin
            anim = {
                dict = 'amb@prop_human_bum_bin@base',
                clip = 'base',
            },
        },
        skillCheck = {
            enabled = false,
            difficulty = { 'easy', 'easy', 'easy' },
            keys = { 'e', 'e', 'e' },
        },
        injury = {
            enabled = true,
            chance = 10,            -- % chance of injury when searching a bin
            damage = 10,
            keepLoot = false,       -- should players still get items if they get hurt?
            screenEffect = {
                enabled = true,
                name = 'Dont_tazeme_bro',
                duration = 0.8,
            },
            cameraShake = {
                enabled = true,
                name = 'SMALL_EXPLOSION_SHAKE',
                intensity = 0.15,
            },
        },
    },

    shop = {
        payoutItem = 'money',           -- item given when selling (e.g. 'black_money' for dirty cash)
        sellRange = 5.0,
        ped = {
            model = 'mp_m_waremech_01',
            coords = vec4(753.5070, -1399.9722, 26.5619, 183.4185),
            spawnDistance = 100.0,      -- ped only exists while a player is within this many metres
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        target = {
            icon = 'fa-solid fa-basket-shopping',
            iconColor = '',
            distance = 2.0,
        },
        blip = {
            enabled = true,
            label = 'Loot Buyer',
            sprite = 59,
            color = 11,
            scale = 0.7,
        },
    },

    target = {
        label = 'Rummage through bin',
        icon = 'fa-solid fa-magnifying-glass',
        iconColor = '',
        distance = 2.0,
        facingThreshold = 0.65,
    },

    notifications = {
        position = 'top-right',
        failColor = '#D20103',
        cooldownColor = '#FE9900',
    },

    binModels = { -- https://forge.plebmasters.de/objects
        `prop_dumpster_01a`,
        `prop_dumpster_02a`,
        `prop_dumpster_02b`,
        `prop_dumpster_3a`,
        `prop_dumpster_4a`,
        `prop_dumpster_4b`,
        `prop_cs_bin_02`,
        `prop_bin_01a`,
        `prop_bin_07a`,
        `prop_bin_07b`,
        `prop_bin_07c`,
        `prop_bin_07d`,
        `prop_bin_08a`,
    },

}
