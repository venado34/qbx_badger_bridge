-- client.lua
-- Handles the LemonUI menu for job selection and dynamic notifications.

-- Wait a moment for all resources to be fully loaded and exports to be ready.
Citizen.CreateThread(function()
    Citizen.Wait(1000)

    -- Check if the LemonUI export is available from the loaded DLL.
    if not exports.LemonUI then
        print(('^1[%s] LemonUI export was not found! The job menu will not work. Ensure LemonUI.FiveM.dll is in the lib folder and loaded in the manifest.^7'):format(GetCurrentResourceName()))
        return
    end
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

    -- Notification event handler.
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
            else
                print(('^1[%s] crm-hud is not available! Please check your configuration.^7'):format(GetCurrentResourceName()))
            end
        elseif Config.NotificationSystem == 'ox_lib' then
            if exports.ox_lib and exports.ox_lib.notify then
                exports.ox_lib.notify({
                    title = 'Job Sync',
                    description = message,
                    type = type -- 'success', 'error', 'inform'
                })
            else
                print(('^1[%s] ox_lib is not available! Please check your configuration.^7'):format(GetCurrentResourceName()))
            end
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

