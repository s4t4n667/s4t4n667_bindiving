return {
    
    useQBCore = true,

    cooldown = 10000, -- cooldown between searching (10 seconds)
    noLoot = 10, -- % chance of finding nothing
    searchTime = 2000, -- time to search bin (2 seconds)
    maximumDistance = 2.0, -- how far away people can be from the bins when trying to search
    
    useSkillCheck = true, 
    skillCheck = {'medium', 'medium', 'medium'},
    skillCheckKeys = { 'e', 'e', 'e' },

    binLoot = {
        { item = 'burger', min = 1, max = 1, chance = 50 },
        { item = 'water', min = 1, max = 3, chance = 80 },
    },

    target = {
        label = 'Rummage through bin',
        icon = 'fa-solid fa-magnifying-glass',
        iconColor = '',
        distance = 2.0,
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
