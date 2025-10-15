-- client.lua
-- Handles the ox_lib menu for job selection and dynamic notifications.

Citizen.CreateThread(function()
    -- Wait until the Config table is ready
    while Config == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then
        print(('^2[%s] Config loaded. Initializing client script.^7'):format(GetCurrentResourceName()))
    end

    --------------------------------------------------------------------------------
    -- Commands
    --------------------------------------------------------------------------------
    -- Open the job selection menu
    RegisterCommand(Config.Commands.jobsMenu, function()
        TriggerServerEvent('qbx_badger_bridge:server:getJobs')
    end, false)

    --------------------------------------------------------------------------------
    -- Event Handlers
    --------------------------------------------------------------------------------
    -- Receive job list from server and build context menu
    RegisterNetEvent('qbx_badger_bridge:client:receiveJobs', function(jobs)
        local options = {}

        -- No jobs fallback
        if not jobs or #jobs == 0 then
            table.insert(options, {
                title = "No Jobs",
                description = "You have no jobs assigned.",
                icon = "fa-solid fa-circle-xmark"
            })
        else
            -- Build options from jobs
            for i, jobData in ipairs(jobs) do
                local is_active = (i == 1) -- First job is active

                table.insert(options, {
                    title = jobData.label,
                    description = "Grade: " .. jobData.grade.name,
                    icon = is_active and "fa-solid fa-check" or "fa-solid fa-briefcase",
                    onSelect = function()
                        -- Change active job if not already active
                        if not is_active then
                            TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', jobData.name)
                        end
                    end
                })
            end
        end

        -- Show context menu
        if lib and lib.showContext then
            lib.showContext({
                title = 'Select Active Job',
                options = options
            })
        else
            if Config.Debug then
                print("^1[QBX Badger Bridge] ox_lib not loaded or showContext export missing.^7")
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Notification wrapper
    --------------------------------------------------------------------------------
    RegisterNetEvent('qbx_badger_bridge:client:Notify', function(message, type)
        if Config.NotificationSystem == 'ox_lib' and lib and lib.notify then
            lib.notify({
                title = '',
                description = message,
                type = type or "inform"
            })
        elseif Config.NotificationSystem == 'crm-hud' then
            TriggerEvent('crm-hud:sendNotification', {text = message, type = type or "info"})
        else
            print(('[QBX Badger Bridge] %s'):format(message))
        end
    end)
end)
