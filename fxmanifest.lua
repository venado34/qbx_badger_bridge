fx_version 'cerulean'
game 'gta5'

author 'Venado'
description 'Synchronizes QBX jobs with Discord roles and provides a UI menu.'
version '2.0.0'

shared_script 'config/config.lua'

server_scripts {
    'config/jobs.lua',  -- RankedJobs table
    'server.lua',       -- Server-side logic
}

client_script 'client.lua'

dependencies {
    'qbx_core',             -- Multi-job enabled QBX-Core
    'honeybadger-resource', -- Discord API integration
    'ox_lib',               -- UI and optional notifications
}