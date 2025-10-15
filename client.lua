-- client.lua
-- Handles the ox_lib menu for job selection and dynamic notifications.

Citizen.CreateThread(function()
    -- Wait until the Config table is ready.
    while Config == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then print(('^2[%s] Config is ready. Initializing client script.^7'):format(GetCurrentResourceName())) end

    -- Register the command to open the job selection menu.
    RegisterCommand(Config.Commands.jobsMenu, function()
        -- Ask the server for the player's current list of jobs.
        TriggerServerEvent('qbx_badger_bridge:server:getJobs')
    end, false)

    -- Event handler to receive the job list from the server and build the ox_lib menu.
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
                local is_active = (i == 1) -- The first job in the list is always the active one.

                table.insert(options, {
                    title = jobData.label,
                    description = "Grade: " .. jobData.grade.name,
                    icon = is_active and "fa-solid fa-check" or "fa-solid fa-briefcase",
                    onSelect = function()
                        -- If the job is not already active, send the event to the server to change it.
                        if not is_active then
                            TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', jobData.name)
                        end
                    end
                })
            end
        end

        -- Show the context menu to the player.
        exports.ox_lib:showContext('job_selector_menu', {
            title = 'Select Active Job',
            options = options
        })
    end)

    -- Dynamic notification event handler (unchanged).
    RegisterNetEvent('qbx_badger_bridge:client:Notify', function(message, type)
        if Config.NotificationSystem == 'none' then
            return
            
        elseif Config.NotificationSystem == 'crm-hud' then
            exports['crm-hud']:crm_notify(text, 5000, 'crm-primary', 'fa-solid fa-circle-info')
                
        elseif Config.NotificationSystem == 'ox_lib' then
            if exports.ox_lib and exports.ox_lib.notify then
                exports.ox_lib.notify({
                    title = 'Job Sync',
                    description = message,
                    type = type
                })
            end
        end
    end)
end)