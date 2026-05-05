return {
    
    setup = {
        cooldown = 10000, -- cooldown between searching (10 seconds default)
        binCooldown = 30000, -- cooldown between searching the same bin (30 seconds default)
        noLoot = 10, -- % chance of finding nothing
        lootRange = {1, 3}, -- number of different items as a reward
        
        searchTime = 2000, -- time to search bin (2 seconds)
        searchCancel = false, -- can cancel search progressbar?
        maxDistance = 2.0, -- how far away people can be from the bins when trying to search

        useSkillCheck = false,
        difficulty = {'easy', 'easy', 'easy'},
        keys = { 'e', 'e', 'e' },
    },

    shop = {
        ped = 'mp_m_waremech_01',
        coords = vec4(753.5070, -1399.9722, 26.5619, 183.4185),
        blip = true,
        blipLabel = 'Loot Buyer',
        blipSprite = 59,
        blipColor = 11,
        blipScale = 0.7,
    },

    binLoot = { -- set sell to 0 to hide in sellshop
        { item = 'burger', label = 'Burger', min = 1, max = 3, chance = 80, sell = 0 },
        { item = 'water', label = 'Water', min = 1, max = 3, chance = 80, sell = 0 },
        { item = 'steel', label = 'Steel',  min = 1, max = 2, chance = 50, sell = 10},        
        { item = 'glass', label = 'Glass',  min = 2, max = 5, chance = 50, sell = 10},
        { item = 'plastic', label = 'Plastic',  min = 1, max = 2, chance = 60, sell = 10},
    },

    target = {
        label = 'Rummage through bin',
        icon = 'fa-solid fa-magnifying-glass',
        iconColor = '',
        distance = 2.0,
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
