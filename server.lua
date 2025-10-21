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
-- Core Job Synchronization (Final Version with Configurable Save Delay)
--------------------------------------------------------------------------------
function SyncPlayerJobs(playerSource, manual)
    local Player = GetPlayer(playerSource)
    if not Player then
        print(("^1[QBX Badger Bridge] Player not found for source %s^7"):format(playerSource))
        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Player not found. Cannot sync jobs.",
            "error")
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

    if manual then
        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Starting manual job synchronization...",
            "info")
    end

    --------------------------------------------------------------------------------
    -- Fetch Discord roles from Honeybadger
    --------------------------------------------------------------------------------
    exports['honeybadger-resource']:GetPlayerRoles(playerSource, function(roles)
        if not roles then
            print(("^1[QBX Badger Bridge] Could not fetch Discord roles for source %s^7"):format(playerSource))
            TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource,
                "Could not fetch your Discord roles. Please re-link your account.", "error")
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
        local discordJobs = {}

        --------------------------------------------------------------------------------
        -- Build list of jobs based on Discord roles
        --------------------------------------------------------------------------------
        for _, rankedJob in ipairs(RankedJobs) do
            local roleName, jobName, jobGrade = rankedJob.roleName, rankedJob.job, rankedJob.grade
            if tableContains(roles, roleName) then
                if not discordJobs[jobName] then
                    discordJobs[jobName] = jobGrade
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Add or update jobs
        --------------------------------------------------------------------------------
        for jobName, jobGrade in pairs(discordJobs) do
            local currentGrade = Player.PlayerData.jobs and Player.PlayerData.jobs[jobName]
            if not currentGrade or currentGrade ~= jobGrade then
                local success, err = exports['qbx_core']:AddPlayerToJob(Player.PlayerData.citizenid, jobName, jobGrade)
                if success then
                    changesMade = true
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource,
                        ('Added or updated job: %s (Grade %s)'):format(jobName, jobGrade), "success")
                    if Config.Debug then
                        print(('[%s][DEBUG] Added/Updated job %s to grade %s for %s'):format(
                            GetCurrentResourceName(), jobName, jobGrade, playerSource))
                    end
                else
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource,
                        ('Failed to assign job %s.'):format(jobName), "error")
                    if Config.Debug then
                        print(('[%s][ERROR] Failed to add job %s for %s: %s'):format(
                            GetCurrentResourceName(), jobName, playerSource, tostring(err)))
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Remove jobs not present in Discord roles
        --------------------------------------------------------------------------------
        local currentJobs = Player.PlayerData.jobs or {}
        for jobName, _ in pairs(currentJobs) do
            if not discordJobs[jobName] then
                local success, err = exports['qbx_core']:RemovePlayerFromJob(Player.PlayerData.citizenid, jobName)
                if success then
                    changesMade = true
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource,
                        ('Removed job: %s'):format(jobName), "info")
                    if Config.Debug then
                        print(('[%s][DEBUG] Removed job %s for %s'):format(GetCurrentResourceName(),
                            jobName, playerSource))
                    end
                else
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource,
                        ('Failed to remove job %s.'):format(jobName), "error")
                    if Config.Debug then
                        print(('[%s][ERROR] Failed to remove job %s for %s: %s'):format(
                            GetCurrentResourceName(), jobName, playerSource, tostring(err)))
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Save player data after configured delay (to avoid race conditions)
        --------------------------------------------------------------------------------
        if changesMade then
            local delay = Config.SaveDelay or 1000
            if Config.Debug then
                print(('[%s][DEBUG] Waiting %sms before saving player data...'):format(GetCurrentResourceName(), delay))
            end

            SetTimeout(delay, function()
                local ok, err = pcall(function()
                    Player.Functions.Save()
                end)
                if ok then
                    if Config.Debug then
                        print(('[%s][DEBUG] Player data saved for source %s.'):format(GetCurrentResourceName(),
                            playerSource))
                    end
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Job data saved successfully.",
                        "success")
                else
                    print(('[%s][ERROR] Failed to save player data for %s: %s'):format(GetCurrentResourceName(),
                        playerSource, tostring(err)))
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Failed to save job data.",
                        "error")
                end
            end)
        else
            if Config.Debug then
                print(('[%s][DEBUG] No changes detected for source %s, skipping save.'):format(GetCurrentResourceName(),
                    playerSource))
            end
        end

        if manual then
            TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Job synchronization complete.", "info")
        end
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
-- Player Command: Manual Job Sync (Debug Only)
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.syncJobs, function(source)
    if not Config.Debug then
        -- Prevent use if debug is disabled
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "This command is only available in debug mode.",
            "error")
        return
    end

    local Player = GetPlayer(source)
    if not Player then
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "Player data not found. Cannot sync jobs.", "error")
        return
    end

    TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "Starting manual job synchronization...", "info")

    SyncPlayerJobs(source, true)
end, false)

--------------------------------------------------------------------------------
-- Admin Command: Resync All Players (Configurable)
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.resyncAll, function(source, _)
    -- Only allow console or players with permission
    if source ~= 0 then
        local Player = GetPlayer(source)
        if not Player then
            print("^1[QBX Badger Bridge] Invalid player tried to run " .. Config.Commands.resyncAll .. "^7")
            TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You are not authorized to use this command.",
                "error")
            return
        end

        if not IsPlayerAceAllowed(source, "qbx_badger_bridge.admin") then
            TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You are not authorized to use this command.",
                "error")
            return
        end
    end

    print("^3[QBX Badger Bridge] Starting global job synchronization for all online players...^7")

    local players = GetPlayers()
    if #players == 0 then
        print("^3[QBX Badger Bridge] No players online to resync.^7")
        if source ~= 0 then
            TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "No players online to resync.", "info")
        end
        return
    end

    for _, playerId in ipairs(players) do
        local playerSource = tonumber(playerId)
        if Config.Debug then
            print(('[%s][DEBUG] Resyncing jobs for player %s'):format(GetCurrentResourceName(), playerSource))
        end
        SyncPlayerJobs(playerSource, true)
    end

    if source ~= 0 then
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source,
            ("Resync triggered for %s players."):format(#players), "success")
    end

    print(("^2[QBX Badger Bridge] Global job resync complete for %s players.^7"):format(#players))
end, false)

--------------------------------------------------------------------------------
-- ox_lib
--------------------------------------------------------------------------------
-- Event to send player's current jobs to the client menu
RegisterNetEvent('qbx_badger_bridge:server:getJobs', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end

    -- Player.PlayerData.jobs stores all jobs a player has
    TriggerClientEvent('qbx_badger_bridge:client:receiveJobs', src, Player.PlayerData.jobs)
end)

-- Event to set the player's active job from the menu
RegisterNetEvent('qbx_badger_bridge:server:setActiveJob', function(jobName)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end

    -- Get the player's current grade for this job
    local jobGrade = Player.PlayerData.jobs[jobName]

    -- Check if the player actually has this job
    if jobGrade then
        exports.qbx_core:SetJob(Player.PlayerData.citizenid, jobName, jobGrade)


        -- Send notification to the player
        TriggerClientEvent('qbx_badger_bridge:client:Notify', src, ("Your active job is now %s"):format(jobName), "success")
    else
        print(('[%s][ERROR] Player %s tried to set active job %s, but they do not have it.'):format(
            GetCurrentResourceName(), src, jobName))
        TriggerClientEvent('qbx_badger_bridge:client:Notify', src, "An error occurred while setting your job.", "error")
    end
end)
