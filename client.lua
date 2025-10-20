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
    debug(("Notification triggered: %s (%s)"):format(message, type or 'info'))

    if Config.Notifications == 'none' then return end

    if Config.Notifications == 'crm-hud' then
        if exports['crm-hud'] and exports['crm-hud'].crm_notify then
            exports['crm-hud']:crm_notify(message, 10000, 'crm-primary', 'fa-solid fa-circle-info')
        else
            debug("crm-hud notify not found")
        end
    elseif Config.Notifications == 'ox_lib' then
        if lib and lib.notify then
            lib.notify({
                title = 'Job Sync',
                description = message,
                type = type or 'inform'
            })
        else
            debug("ox_lib notify not found")
        end
    elseif Config.Debug then
        print(('[DEBUG][Notification] %s (%s)'):format(message, type or 'info'))
    end
end)

--------------------------------------------------------------------------------
-- Context Menu for Jobs (ox_lib)
--------------------------------------------------------------------------------
local function OpenJobMenu()
    if not exports.ox_lib or not exports.ox_lib.showContext then
        print("^1[QBX Badger Bridge] ox_lib showContext export not found.^7")
        return
    end

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
        print("^3[QBX Badger Bridge] No jobs available to display in menu.^7")
        return
    end

    exports.ox_lib:showContext({
        title = "Select Active Job",
        options = menuItems
    })
end

--------------------------------------------------------------------------------
-- Receive Jobs from Server
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:receiveJobs', function(jobs)
    PlayerJobs = jobs
    debug("Received jobs from server: " ..
    table.concat((function()
        local t = {}
        for k, _ in pairs(jobs) do table.insert(t, k) end
        return t
    end)(), ", "))
end)

--------------------------------------------------------------------------------
-- Open Job Menu Command
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.jobs, function()
    debug("Jobs command triggered")
    TriggerServerEvent('qbx_badger_bridge:server:getJobs')
    Citizen.Wait(200) -- slight delay to ensure jobs are received
    OpenJobMenu()
end, false)

--------------------------------------------------------------------------------
-- Set Active Job
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:setActiveJob', function(data)
    debug(("Setting active job: %s"):format(data.jobName))
    TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', data.jobName)
end)
