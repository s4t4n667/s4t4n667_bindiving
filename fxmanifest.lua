fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'Asgaard Developments | s4t4n667'
description 'Bin diving'
version '3.0.0'

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
}

shared_script '@ox_lib/init.lua'

client_scripts {
    'resource/client.lua'
}

server_scripts {
    'resource/server.lua'
}

files {
    'config.lua',
    'locales/*.json',
}