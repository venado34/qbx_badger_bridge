Config = {}

--------------------------------------------------------------------------------
-- Debugging
--------------------------------------------------------------------------------
-- Enable or disable detailed debug logs in the server/client console
Config.Debug = true

--------------------------------------------------------------------------------
-- Notification System
--------------------------------------------------------------------------------
-- Options:
-- 'crm-hud' -> Uses CRM-HUD notifications
-- 'ox_lib'  -> Uses ox_lib notify system
-- 'none'    -> Disables notifications entirely
Config.NotificationSystem = 'ox_lib'

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------
Config.Commands = {
    -- Command players use to open the job selection menu
    jobsMenu = "jobs",
    -- Command for admins to manually synchronize jobs with Discord roles
    syncJobs = "syncjobs"
}

--------------------------------------------------------------------------------
-- Admin Permissions
--------------------------------------------------------------------------------
-- ACE permissions required to use administrative commands like /syncjobs
-- Any player with at least ONE of these permissions will have access
Config.AdminPermissions = {
    "admin",
    "mod",
}

--------------------------------------------------------------------------------
-- Character Loaded Event
--------------------------------------------------------------------------------
-- Server event fired when a player has loaded their character
-- Used to trigger the automatic job sync
-- Examples: 'crm-multicharacter:server:playerLoaded', 'QBCore:Server:OnPlayerLoaded'
Config.CharacterLoadedEvent = 'crm-multicharacter:server:playerLoaded'
