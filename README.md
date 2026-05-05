# s4t4n667_bindiving
## Bin diving 🗑️♻️

Simple bin diving script with configurable loot, optional skillcheck and cooldown to prevent spam-searching. Has a built-in loot buyer, with optional blip.

## 🔐 Dependencies:
- any framework
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
   
## 📝 Loot Examples:
```lua
    binLoot = { -- set sell to 0 to hide in sellshop
        { item = 'burger', label = 'Burger', min = 1, max = 3, chance = 80, sell = 0 },
        { item = 'water', label = 'Water', min = 1, max = 3, chance = 80, sell = 0 },
        { item = 'steel', label = 'Steel',  min = 1, max = 2, chance = 50, sell = 10},        
        { item = 'glass', label = 'Glass',  min = 2, max = 5, chance = 50, sell = 10},
        { item = 'plastic', label = 'Plastic',  min = 1, max = 2, chance = 60, sell = 10},
    },
```

## 📌 Asgaard Developments
I’m a solo FiveM developer creating custom clothing, logos and graphics, liveries, MLO retextures and Discord servers. Lots of different packages available, along with plenty of free assets and scripts for the community to enjoy. 

Join the Discord: [here](https://discord.gg/eFsB5ZFxeq)
