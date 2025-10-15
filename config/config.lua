-- config/config.lua
-- Configuration for QBX Badger Bridge (Discord Job Sync)

Config = {}

--------------------------------------------------------------------------------
-- Debugging
--------------------------------------------------------------------------------
Config.Debug = true -- Enable detailed console logs

--------------------------------------------------------------------------------
-- Notification system
--------------------------------------------------------------------------------
-- Options: 'crm-hud', 'ox_lib', 'none'
Config.NotificationSystem = 'crm-hud'

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------
Config.Commands = {
    jobsMenu = "jobs",       -- Command to open job selection menu
    syncJobs = "syncjobs",   -- Admin command to manually sync jobs
}

--------------------------------------------------------------------------------
-- Admin Permissions
--------------------------------------------------------------------------------
Config.AdminPermissions = {
    "admin",
    "mod",
}

--------------------------------------------------------------------------------
-- Character System Integration
--------------------------------------------------------------------------------
-- Set the type of character system your server uses
-- Options: 'crm-multicharacter', 'qbx', etc.
Config.CharacterSystem = 'qbx'
