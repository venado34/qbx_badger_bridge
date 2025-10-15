fx_version 'cerulean'
game 'gta5'

author 'Venado'
description 'Assigns QBX jobs based on Discord roles with a UI menu.'
version '2.0.0'


files {
    'lib/LemonUI.FiveM.dll'
}

server_scripts {
    'config.lua',
    'server.lua'
}

client_scripts {
    '@qbx_badger_bridge/lib/LemonUI.FiveM.dll',
    'client.lua'
}

dependencies {
    'qbx_core',
    'honeybadger-resource'
}