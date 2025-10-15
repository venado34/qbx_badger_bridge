-- client.lua
-- Handles the LemonUI menu for job selection and dynamic notifications.

Citizen.CreateThread(function()
    -- Wait until both the Config table and LemonUI are ready.
    while Config == nil or exports.LemonUI == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then print(('^2[%s] Config and LemonUI are ready. Initializing client script.^7'):format(GetCurrentResourceName())) end
    local LemonUI = exports.LemonUI

    -- Create the LemonUI menu and object pool.
    local pool = LemonUI:NewPool()
    local menu = LemonUI:NewMenu("Job Selector", "Select your active job")
    pool:Add(menu)

    -- Main function to open the job selection menu.
    local function openJobsMenu()
        menu:Clear()
        TriggerServerEvent('qbx_badger_bridge:server:getJobs')
        menu:Visible(true)
    end
    RegisterCommand(Config.Commands.jobsMenu, openJobsMenu, false)

    -- Event handler to receive the job list from the server and build the menu.
    RegisterNetEvent('qbx_badger_bridge:client:receiveJobs', function(jobs)
        if not jobs or #jobs == 0 then
            menu:AddItem(LemonUI:NewItem("No Jobs", "You have no jobs assigned."))
            return
        end

        for i, jobData in ipairs(jobs) do
            local item = LemonUI:NewItem(jobData.label, "Grade: " .. jobData.grade.name)

            if i == 1 then
                item:RightBadge(LemonUI.BadgeStyle.Tick)
            end

            menu:AddItem(item)

            item.Activated = function()
                TriggerServerEvent('qbx_badger_bridge:server:setActiveJob', jobData.name)
                menu:Visible(false)
            end
        end
    end)

    -- Dynamic notification event handler.
    RegisterNetEvent('qbx_badger_bridge:client:Notify', function(message, type)
        if Config.NotificationSystem == 'crm-hud' then
            if exports['crm-hud'] and exports['crm-hud'].crm_notify then
                local time = 5000 
                local icon = 'fa-solid fa-circle-info'
                local color = 'crm-primary'

                if type == 'success' then
                    icon = 'fa-solid fa-check-double'
                    color = 'crm-success'
                elseif type == 'error' then
                    icon = 'fa-solid fa-circle-xmark'
                    color = 'crm-danger'
                elseif type == 'warning' then
                    icon = 'fa-solid fa-triangle-exclamation'
                    color = 'crm-warning'
                end
                exports['crm-hud']:crm_notify(message, time, color, icon)
            end
        elseif Config.NotificationSystem == 'ox_lib' then
            if exports.ox_lib and exports.ox_lib.notify then
                exports.ox_lib.notify({
                    title = 'Job Sync',
                    description = message,
                    type = type
                })
            end
        elseif config.NotificationSystem == 'none' then
            showBaseNotification(text)
        end
    end)

    -- Create a thread to process the LemonUI pool every frame.
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            pool:ProcessMenus()
        end
    end)
end)

