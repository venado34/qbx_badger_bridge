fx_version 'cerulean'
game 'gta5'

author 'Venado'
description 'Assigns QBX jobs based on Discord roles with a UI menu.'
version '2.0.0'

shared_script 'config/config.lua'

server_scripts {
    'config/jobs.lua',
    'server.lua'
}

client_script 'client.lua'

dependencies {
    'qbx_core',
    'honeybadger-resource',
    'ox_lib'
}
