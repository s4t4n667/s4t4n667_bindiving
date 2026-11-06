## Bin diving 🗑️♻️

Bin diving script with configurable loot, optional skillcheck and cooldown to prevent spam-searching. Has a built-in loot buyer, with optional blip.

## ✨ Features
- Search any bin or dumpster model you list in the config
- Loot rarities (common, uncommon, rare, legendary) with a notification for rare finds
- Configurable loot table: amounts, chances and sell prices per item
- Cooldowns between searches and per bin
- Optional ox_lib skill check before searching
- Chance to cut yourself on broken glass and lose health, with a screen effect and camera shake
- Loot buyer ped with an optional map blip
- Shop ped only spawns when a player is nearby
- Locales: English, German, French and Turkish

## 🔐 Dependencies:
- [ESX](https://github.com/esx-framework/esx_core), [QBCore](https://github.com/qbcore-framework) or [Qbox](https://github.com/Qbox-project/)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)

## 🔗 Useful links:
- [Preview video](https://youtu.be/g4nuGCuWKe0)
- [Documentation](https://s4t4n667.gitbook.io/asgaard-developments/free-scripts/s4t4n667_bindiving)

## ⚙️ How to install:
1) Download the latest release
2) Add `s4t4n667_bindiving` to your server's `resource` folder
3) Adjust the `config.lua` to your liking
4) Restart your server

## 💎 Rarities
Each loot slot first rolls a rarity, then picks an item of that rarity. Change weight to make that whole tier more or less common. Change an item’s chance to favour it over the other items of the same rarity. `notify = true` shows the player a "Rare find!" notification
```lua
rarities = {
    common = { weight = 70, label = 'Common' },
    uncommon = { weight = 22, label = 'Uncommon' },
    rare = { weight = 7, label = 'Rare', notify = true },
    legendary = { weight = 1, label = 'Legendary', notify = true },
},
```

## 📝 Loot
- `rarity` defaults to `'common'` if left out
- `chance` is a weight against other items **of the same rarity**
- `min` / `max` is how many of that item are given
- `sell` is the price per item at the loot buyer (`0` hides it from the shop)
- Labels and images come from ox_inventory (add `label = '...'` to override)
```lua
items = {
    { item = 'burger', rarity = 'common', min = 1, max = 3, chance = 80, sell = 0 },
    { item = 'plastic', rarity = 'common', min = 1, max = 2, chance = 60, sell = 10 },
    { item = 'glass', rarity = 'uncommon', min = 2, max = 5, chance = 50, sell = 10 },
    { item = 'lockpick', rarity = 'rare', min = 1, max = 1, chance = 1, sell = 0 },
},
```

## 🩸 Injuries
Each search has a chance of the player cutting themselves on broken glass and losing health.
- `chance` is the % chance of getting hurt on each search (decimals like `2.5` work)
- `damage` is how much health is lost (players have 200 health and go down at 100)
- `keepLoot` decides whether players still get their items when they get hurt
- `screenEffect` and `cameraShake` can each be turned off, or swapped for any GTA screen effect or camera shake
```lua
injury = {
    enabled = true,
    chance = 10,
    damage = 10,
    keepLoot = false,
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
```

## 📌 Asgaard Developments
I’m a solo FiveM developer creating scripts, custom clothing, logos and graphics, liveries, MLO retextures and Discord servers. Lots of different packages available, along with plenty of free assets and scripts for the community to enjoy. 

Join the Discord: [here](https://discord.gg/eFsB5ZFxeq)

