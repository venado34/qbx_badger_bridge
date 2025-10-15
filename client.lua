-- client.lua
-- Handles the ox_lib menu for job selection and dynamic notifications

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
Citizen.CreateThread(function()
    -- Wait until the Config table is ready
    while Config == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then
        print(('^2[qbx_badger_bridge] Config loaded. Initializing client script.^7'))
    end
end)

--------------------------------------------------------------------------------
-- Register Commands
--------------------------------------------------------------------------------
-- Command to open the job selection menu
RegisterCommand(Config.Commands.jobsMenu, function()
    -- Request the player's current list of jobs from the server
    TriggerServerEvent('qbx_badger_bridge:server:getJobs')
end, false)

--------------------------------------------------------------------------------
-- Event: Receive Jobs from Server
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:receiveJobs', function(jobs)
    local options = {}

    -- Check if the player has any jobs
    if not jobs or #jobs == 0 then
        table.insert(options, {
            title = "No Jobs",
            description = "You have no jobs assigned.",
            icon = "fa-solid fa-circle-xmark"
        })
    else
        -- Build options for each job
        for i, jobData in ipairs(jobs) do
            -- The first job in the list is always the active one
            local is_active = (i == 1)

            table.insert(options, {
                title = jobData.label,
                description = "Grade: " .. jobData.grade.name,
                icon = is_active and "fa-solid fa-check" or "fa-solid fa-briefcase",
                onSelect = function()
                    -- If the job is not already active, set it
                    if not is_active then
                        TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', jobData.name)
                    end
                end
            })
        end
    end

    -- Display the menu using ox_lib
    if exports.ox_lib and exports.ox_lib.showContext then
        exports.ox_lib:showContext({
            title = 'Select Active Job',
            options = options
        })
    else
        print("^1[qbx_badger_bridge] ox_lib showContext export not found.^7")
    end
end)

--------------------------------------------------------------------------------
-- Event: Notifications
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:client:Notify', function(message, type)
    if Config.NotificationSystem == 'none' then
        return
    elseif Config.NotificationSystem == 'crm-hud' then
        exports['crm-hud']:crm_notify(message, 5000, 'crm-primary', 'fa-solid fa-circle-info')
    elseif Config.NotificationSystem == 'ox_lib' then
        if exports.ox_lib and exports.ox_lib.notify then
            exports.ox_lib.notify({
                title = 'Job Sync',
                description = message,
                type = type
            })
        else
            print("^1[qbx_badger_bridge] ox_lib notify export not found.^7")
        end
    end
end)
