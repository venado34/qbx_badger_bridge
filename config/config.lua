Config = {}

-- Enable or disable detailed debug logs in the server console.
Config.Debug = true

-- Configure the notification system to use.
-- Options: 'crm-hud', 'ox_lib', 'none'
Config.NotificationSystem = 'crm-hud'

-- Configure the commands used by this script.
Config.Commands = {
    -- The command players will use to open the job selection menu.
    jobsMenu = "jobs",
    -- The command for admins to manually synchronize jobs with Discord roles.
    syncJobs = "syncjobs"
}

-- The ACE permissions required to use administrative commands like /syncjobs.
-- You can add multiple permissions here. Anyone with at least ONE of these will have access.
Config.AdminPermissions = {
    "admin",
    "mod",
}
