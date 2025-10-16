-- server.lua
-- QBX Badger Bridge (Discord Job Sync)

--------------------------------------------------------------------------------
-- Wait for Config and RankedJobs to load
--------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while Config == nil or RankedJobs == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then
        print(('^2[%s] Config and jobs loaded. Initializing server script.^7'):format(GetCurrentResourceName()))
    end
end)

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------
local function GetPlayer(source)
    return exports['qbx_core']:GetPlayer(source)
end

local function HasAdminPermission(source)
    for _, permission in ipairs(Config.AdminPermissions) do
        if IsPlayerAceAllowed(source, permission) then
            return true
        end
    end
    return false
end

local function tableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Core Job Synchronization
--------------------------------------------------------------------------------
function SyncPlayerJobs(playerSource, manual)
    local Player = GetPlayer(playerSource)
    if not Player then
        print("^1[QBX Badger Bridge] Player not found for source " .. playerSource .. "^7")
        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Player not found. Cannot sync jobs.", "error")
        return
    end

    if Config.Debug then
        print(('[%s][DEBUG] Starting job sync for %s (%s). Manual trigger: %s'):format(
            GetCurrentResourceName(),
            Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            playerSource,
            tostring(manual)
        ))
    end
    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Starting job synchronization...", "info")

    --------------------------------------------------------------------------------
    -- Fetch Discord roles from Honeybadger
    --------------------------------------------------------------------------------
    exports['honeybadger-resource']:GetPlayerRoles(playerSource, function(roles)
        if not roles then
            print("^1[QBX Badger Bridge] Could not fetch Discord roles for source " .. playerSource .. "^7")
            TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Could not fetch your Discord roles. Please re-link your account.", "error")
            return
        end

        if Config.Debug then
            print(('[%s][DEBUG] Discord roles for source %s: %s'):format(
                GetCurrentResourceName(),
                playerSource,
                table.concat(roles, ", ")
            ))
        end

        local changesMade = false

        --------------------------------------------------------------------------------
        -- Determine which jobs the player should have
        --------------------------------------------------------------------------------
        for _, rankedJob in ipairs(RankedJobs) do
            local roleName, jobName, jobGrade = rankedJob.roleName, rankedJob.job, rankedJob.grade

            if tableContains(roles, roleName) then
                local currentJob = Player.PlayerData.jobs[jobName] or -1
                if currentJob ~= jobGrade then
                    local success = Player.Functions.SetJob(jobName, jobGrade)
                    if success then
                        changesMade = true
                        if Config.Debug then
                            print(('[%s][DEBUG] Assigned/Updated job %s to grade %s for source %s'):format(
                                GetCurrentResourceName(), jobName, jobGrade, playerSource
                            ))
                        end
                        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, ('Assigned job %s (Grade %s)'):format(jobName, jobGrade), "success")
                    else
                        print(('[%s][ERROR] Failed to assign job %s grade %s for source %s. Check if the job exists in QBX-Core.'):format(
                            GetCurrentResourceName(), jobName, jobGrade, playerSource
                        ))
                        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, ('Failed to assign job %s (grade %s). Job not found.'):format(jobName, jobGrade), "error")
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Save player data if changes made
        --------------------------------------------------------------------------------
        if changesMade then
            local saveSuccess, saveError = pcall(function()
                Player.Functions.Save()
            end)
            if saveSuccess then
                if Config.Debug then
                    print(('[%s][DEBUG] Player data saved for source %s.'):format(GetCurrentResourceName(), playerSource))
                end
                TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Player data saved successfully.", "success")
            else
                print(('[%s][ERROR] Failed to save player data for source %s: %s'):format(GetCurrentResourceName(), playerSource, tostring(saveError)))
                TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Error saving player data. Check console for details.", "error")
            end
        else
            if Config.Debug then
                print(('[%s][DEBUG] No job changes detected for source %s. Skipping save.'):format(GetCurrentResourceName(), playerSource))
            end
            TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "No job changes detected. Skipping save.", "info")
        end

        if Config.Debug then
            print(('[%s][DEBUG] Job sync complete for source %s.'):format(GetCurrentResourceName(), playerSource))
        end
        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Job synchronization complete.", "info")
    end)
end

--------------------------------------------------------------------------------
-- Character Loaded Event (Modular)
--------------------------------------------------------------------------------
if Config.Multicharacter == 'qbx_core' then
    AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
        local src = source
        local Player = GetPlayer(src)
        if not Player then return end

        if Config.Debug then
            print(('[%s][DEBUG] QBX-Core player %s (%s) loaded. Triggering job sync.'):format(
                GetCurrentResourceName(),
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                src
            ))
        end
        SyncPlayerJobs(src, false)
    end)

elseif Config.Multicharacter == 'crm-multicharacter' then
    RegisterNetEvent('crm-multicharacter:server:playerLoaded', function()
        local src = source
        local Player = GetPlayer(src)
        if not Player then
            print("^1[QBX Badger Bridge] No compatible character system detected. Automatic sync disabled.^7")
            return
        end

        if Config.Debug then
            print(('[%s][DEBUG] CRM-Multicharacter player %s (%s) loaded. Triggering job sync.'):format(
                GetCurrentResourceName(),
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                src
            ))
        end
        SyncPlayerJobs(src, false)
    end)
else
    print("^1[QBX Badger Bridge] No compatible character system detected. Automatic sync disabled.^7")
end

--------------------------------------------------------------------------------
-- Admin Commands (Modular)
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.syncJobs, function(source)
    if not HasAdminPermission(source) then
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You are not authorized to use this command.", "error")
        return
    end
    SyncPlayerJobs(source, true)
end, true)
