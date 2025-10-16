-- client.lua
-- QBX Badger Bridge Client

local PlayerJobs = {}

--------------------------------------------------------------------------------
-- Intermittent debug helper
--------------------------------------------------------------------------------
local function debug(msg)
    if Config.Debug then
        print(('[%s][DEBUG] %s'):format(GetCurrentResourceName(), msg))
    end
end

--------------------------------------------------------------------------------
-- Notifications (Modular)
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:Notify', function(message, type)
    if Config.Notifications == 'none' then
        return

    elseif Config.Notifications == 'crm-hud' then
        if exports['crm-hud'] and exports['crm-hud'].crm_notify then
            exports['crm-hud']:crm_notify(message, 5000, 'crm-primary', 'fa-solid fa-circle-info')
        else
            print('^1[QBX Badger Bridge] crm-hud notify not found.^7')
        end

    elseif Config.Notifications == 'ox_lib' then
        if lib and lib.notify then
            lib.notify({
                title = 'Job Sync',
                description = message,
                type = type or 'inform'
            })
        else
            print('^1[QBX Badger Bridge] ox_lib notify not found.^7')
        end

    elseif Config.Debug then
        print(('[DEBUG][Notification] %s (%s)'):format(message, type or 'info'))
    end
end)------------------------------------------------------------------------------
-- Context Menu for Jobs (ox_lib)
--------------------------------------------------------------------------------
local function OpenJobMenu()
    local menuItems = {}
    for jobName, grade in pairs(PlayerJobs) do
        table.insert(menuItems, {
            title = jobName,
            description = "Grade: " .. tostring(grade),
            event = 'qbx_badger_bridge:client:setActiveJob',
            args = { jobName = jobName }
        })
    end

    if #menuItems == 0 then
        debug("No jobs available to display in menu")
        return
    end

    exports.ox_lib:showContext('qbx_jobs_menu', menuItems)
end

--------------------------------------------------------------------------------
-- Receive Jobs from Server
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:receiveJobs', function(jobs)
    PlayerJobs = jobs
    debug("Received jobs from server")
end)

--------------------------------------------------------------------------------
-- Open Job Menu Command
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.jobs, function()
    TriggerServerEvent('qbx_badger_bridge:server:getJobs')
    Citizen.Wait(100)
    OpenJobMenu()
end, false)

--------------------------------------------------------------------------------
-- Set Active Job
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:setActiveJob', function(data)
    TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', data.jobName)
end)
