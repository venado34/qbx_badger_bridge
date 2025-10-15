-- client.lua
-- QBX Badger Bridge: Client-side script for job selection and notifications

--------------------------------------------------------------------------------
-- Wait for Config to Load
--------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while Config == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then
        print(('^2[%s] Config loaded. Initializing client script.^7'):format(GetCurrentResourceName()))
    end
end)

--------------------------------------------------------------------------------
-- Safe ShowContext Function
--------------------------------------------------------------------------------
local function SafeShowContext(data)
    Citizen.CreateThread(function()
        while not exports.ox_lib or not exports.ox_lib.showContext do
            Citizen.Wait(100)
        end
        exports.ox_lib:showContext(data)
    end)
end

--------------------------------------------------------------------------------
-- Command: Open Job Menu
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.jobsMenu, function()
    TriggerServerEvent('qbx_badger_bridge:server:getJobs')
end, false)

--------------------------------------------------------------------------------
-- Event: Receive Jobs from Server and Build Menu
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:receiveJobs', function(jobs)
    local options = {}

    if not jobs or #jobs == 0 then
        table.insert(options, {
            title = "No Jobs",
            description = "You have no jobs assigned.",
            icon = "fa-solid fa-circle-xmark"
        })
    else
        for i, jobData in ipairs(jobs) do
            local is_active = (i == 1) -- First job is active

            table.insert(options, {
                title = jobData.label or jobData.name or "Unknown Job",
                description = "Grade: " .. (jobData.grade.name or tostring(jobData.grade)),
                icon = is_active and "fa-solid fa-check" or "fa-solid fa-briefcase",
                onSelect = function()
                    if not is_active then
                        TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', jobData.name)
                    end
                end
            })
        end
    end

    if #options > 0 then
        SafeShowContext({
            title = "Select Active Job",
            options = options
        })
    else
        if Config.Debug then
            print("^1[QBX Badger Bridge] No jobs available to show.^7")
        end
    end
end)

--------------------------------------------------------------------------------
-- Event: Notifications
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:Notify', function(message, type)
    if Config.NotificationSystem == 'none' then return end

    if Config.NotificationSystem == 'crm-hud' then
        if exports['crm-hud'] and exports['crm-hud'].crm_notify then
            exports['crm-hud']:crm_notify(message, 5000, 'crm-primary', 'fa-solid fa-circle-info')
        end

    elseif Config.NotificationSystem == 'ox_lib' then
        if exports.ox_lib and exports.ox_lib.notify then
            exports.ox_lib.notify({
                title = "Job Sync",
                description = message,
                type = type
            })
        end
    end
end)
