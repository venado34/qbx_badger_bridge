-- client.lua
-- Handles the ox_lib menu for job selection and notifications.

Citizen.CreateThread(function()
    -- Wait until the Config table is loaded
    while Config == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then
        print(('^2[%s] Config loaded. Initializing client script.^7'):format(GetCurrentResourceName()))
    end

    --------------------------------------------------------------------------------
    -- Commands
    --------------------------------------------------------------------------------

    -- Open job selection menu
    RegisterCommand(Config.Commands.jobsMenu, function()
        if Config.Debug then print('[DEBUG] Player requested job menu.') end
        TriggerServerEvent('qbx_badger_bridge:server:getJobs')
    end, false)

    --------------------------------------------------------------------------------
    -- Receive jobs from server and build ox_lib context menu
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
                -- Determine which job is currently active
                local is_active = (i == 1) 

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

        -- Show ox_lib context menu
        if exports.ox_lib and exports.ox_lib.showContext then
            exports.ox_lib:showContext({
                title = 'Select Active Job',
                options = options
            })
        elseif Config.Debug then
            print("^1[QBX Badger Bridge] ox_lib not available or showContext export missing.^7")
        end
    end)

    --------------------------------------------------------------------------------
    -- Notifications
    --------------------------------------------------------------------------------

    RegisterNetEvent('qbx_badger_bridge:client:Notify', function(message, type)
        if Config.NotificationSystem == 'none' then
            return
        elseif Config.NotificationSystem == 'crm-hud' then
            if exports['crm-hud'] and exports['crm-hud'].crm_notify then
                exports['crm-hud']:crm_notify(message, 5000, 'crm-primary', 'fa-solid fa-circle-info')
            elseif Config.Debug then
                print("^1[QBX Badger Bridge] crm-hud not found or crm_notify missing.^7")
            end
        elseif Config.NotificationSystem == 'ox_lib' then
            if exports.ox_lib and exports.ox_lib.notify then
                exports.ox_lib.notify({
                    title = 'Job Sync',
                    description = message,
                    type = type
                })
            elseif Config.Debug then
                print("^1[QBX Badger Bridge] ox_lib notify not found.^7")
            end
        end
    end)
end)
