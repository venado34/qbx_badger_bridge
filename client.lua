-- client.lua
-- QBX Badger Bridge Client (Sorted Job Menu)

local PlayerJobs = {}

--------------------------------------------------------------------------------
-- Debug helper
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
    if Config.Notifications == 'none' then return end

    if Config.Notifications == 'crm-hud' then
        if exports['crm-hud'] and exports['crm-hud'].crm_notify then
            exports['crm-hud']:crm_notify(message, 10000, 'crm-primary', 'fa-solid fa-circle-info')
        else
            debug("crm-hud notify not found")
        end

    elseif exports.ox_lib and exports.ox_lib.notify then
        exports.ox_lib:notify({
            title = 'Job Sync',
            description = message,
            type = type or 'inform'
        })
    elseif Config.Debug then
        print(('[DEBUG][Notification] %s (%s)'):format(message, type or 'info'))
    end
end)

--------------------------------------------------------------------------------
-- Open Job Menu (Sorted by Grade)
--------------------------------------------------------------------------------
local function OpenJobMenu()
    if not PlayerJobs or next(PlayerJobs) == nil then
        debug("No jobs available to display in menu")
        TriggerEvent('qbx_badger_bridge:client:Notify', "No jobs available", "info")
        return
    end

    -- Convert table to array for sorting
    local sortedJobs = {}
    for jobName, grade in pairs(PlayerJobs) do
        table.insert(sortedJobs, { name = jobName, grade = grade })
    end

    table.sort(sortedJobs, function(a, b)
        return a.grade > b.grade
    end)

    local options = {}
    for _, job in ipairs(sortedJobs) do
        table.insert(options, {
            title = job.name,
            description = "Grade: " .. tostring(job.grade),
            icon = 'briefcase',
            onSelect = function()
                TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', job.name)
            end
        })
    end

    -- Register the context menu
    exports.ox_lib:registerContext({
        id = 'qbx_jobs_menu',
        title = 'My Jobs',
        options = options
    })

    -- Show the menu
    exports.ox_lib:showContext('qbx_jobs_menu')
end

--------------------------------------------------------------------------------
-- Command: Open Job Menu
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.jobs, function()
    debug("Jobs command triggered")
    -- Request jobs from the server; menu will open when jobs are received
    TriggerServerEvent('qbx_badger_bridge:server:getJobs')
end, false)

--------------------------------------------------------------------------------
-- Receive Jobs from Server and Open Menu
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:receiveJobs', function(jobs)
    PlayerJobs = jobs or {}
    local jobList = next(PlayerJobs) and table.concat(PlayerJobs, ", ") or "(none)"
    debug("Received jobs from server: " .. jobList)

    -- Open the menu after jobs are received
    OpenJobMenu()
end)

--------------------------------------------------------------------------------
-- Set Active Job
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:setActiveJob', function(data)
    if data and data.jobName then
        TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', data.jobName)
    else
        debug("Invalid job data received for setActiveJob")
    end
end)
