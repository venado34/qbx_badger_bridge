Config = {}

Config.Debug = true

--------------------------------------------------------------------------------
-- Character System
-- Options:
-- 'qbx_core'           => QBX-Core native character system
-- 'crm-multicharacter' => CRM-Multicharacter system
-- 'none'               => No automatic job sync
--------------------------------------------------------------------------------
Config.Multicharacter = 'qbx_core'

--------------------------------------------------------------------------------
-- Notifications System
-- 'none'      => No notifications
-- 'crm-hud'   => CRM HUD notification
-- 'ox_lib'    => ox_lib notification
--------------------------------------------------------------------------------
Config.Notifications = 'crm-hud'

--------------------------------------------------------------------------------
-- Admin Permissions
-- List of ACE permissions required to use admin commands
--------------------------------------------------------------------------------
Config.AdminPermissions = {
    "admin",
    "superadmin"
}

--------------------------------------------------------------------------------
-- Commands
-- All commands are configurable here
--------------------------------------------------------------------------------
Config.Commands = {
    jobs = 'jobs',                  -- Opens the job selection menu
    syncJobs = 'syncjobs',          -- Manually syncs player jobs
    resyncAll = 'syncjobsall',      -- admin: sync all online players
}

--------------------------------------------------------------------------------
-- Save delay (milliseconds)
-- Controls how long the script waits before saving player data after assigning/removing jobs.
--------------------------------------------------------------------------------
Config.SaveDelay = 1000 -- Default: 1000 ms (1 second).

--------------------------------------------------------------------------------
-- Ignored Jobs
-- A list of jobs that the bridge will NEVER remove from a player,
-- even if they don't have the Discord role for it.
-- This MUST include 'unemployed'.
--------------------------------------------------------------------------------
Config.IgnoredJobs = {
    ['unemployed'] = true,
}