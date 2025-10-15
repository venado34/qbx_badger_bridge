-- server.lua
-- QBX Badger Bridge (Discord Job Sync)
-- Manually syncs Discord roles to in-game jobs for a multi-job enabled QBX-Core server.

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
Config = {}
Config.Debug = true -- Set to true to enable detailed console logs.
Config.SyncPermission = "admin" -- The ACE permission required to use the /syncjobs command.

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------
-- Gets the Player object from QBX-Core.
local function GetPlayer(source)
    return exports['qbx_core']:GetPlayer(source)
end

-- Converts a list of roles into a lookup table.
local function ConvertRolesToLookupTable(roleList)
    local lookup = {}
    if type(roleList) ~= "table" then return lookup end
    for _, roleName in ipairs(roleList) do
        lookup[roleName] = true
    end
    return lookup
end

--------------------------------------------------------------------------------
-- Core Synchronization Logic 
--------------------------------------------------------------------------------
local function SyncPlayerJobs(playerSource)
    local Player = GetPlayer(playerSource)
    if not Player then return end

    if Config.Debug then print(('[%s][DEBUG] Manual sync started for source: %s. Fetching roles.'):format(GetCurrentResourceName(), playerSource)) end
    TriggerClientEvent('ox_lib:notify', playerSource, { title = "Job Sync", description = "Starting synchronization with Discord...", type = "inform" })

    -- Fetch Discord roles from Honeybadger resource.
    exports['honeybadger-resource']:GetPlayerRoles(playerSource, function(roleList)
        local discordRoles = ConvertRolesToLookupTable(roleList)
        
        if Config.Debug then print(('[%s][DEBUG] Received and processed roles for source %s: %s'):format(GetCurrentResourceName(), playerSource, json.encode(discordRoles))) end

        -- Part 1: Determine all jobs the player SHOULD have.
        local shouldHaveJobs = {}
        for _, jobData in ipairs(RankedJobs) do
            if discordRoles[jobData.roleName] then
                if not shouldHaveJobs[jobData.job] then
                    shouldHaveJobs[jobData.job] = jobData.grade
                end
            end
        end

        -- Part 2: Get a list of jobs the player CURRENTLY has.
        local currentlyHasJobs = {}
        if Player.PlayerData.jobs and type(Player.PlayerData.jobs) == "table" then
            for _, jobData in ipairs(Player.PlayerData.jobs) do
                currentlyHasJobs[jobData.name] = jobData.grade
            end
        end

        -- Part 3: Add or Update jobs.
        for jobName, jobGrade in pairs(shouldHaveJobs) do
            if currentlyHasJobs[jobName] ~= jobGrade then
                Player.Functions.SetJob(jobName, jobGrade)
                TriggerClientEvent('ox_lib:notify', playerSource, { title = "Job Sync", description = ('Assigned/Updated job: %s'):format(jobName), type = "success" })
            end
        end

        -- Part 4: Remove jobs the player no longer has roles for.
        for jobName, _ in pairs(currentlyHasJobs) do
            if not shouldHaveJobs[jobName] then
                Player.Functions.RemoveJob(jobName)
                TriggerClientEvent('ox_lib:notify', playerSource, { title = "Job Sync", description = ('Removed job: %s'):format(jobName), type = "error" })
            end
        end

        -- NEW: Save the player's data to the database.
        Player.Functions.Save()
        if Config.Debug then print(('[%s][DEBUG] Player data saved for source %s.'):format(GetCurrentResourceName(), playerSource)) end
        
        if Config.Debug then print(('[%s][DEBUG] Job sync complete for source %s.'):format(GetCurrentResourceName(), playerSource)) end
        TriggerClientEvent('ox_lib:notify', playerSource, { title = "Job Sync", description = "Synchronization with Discord is complete and saved!", type = "success" })
    end)
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------
RegisterCommand("syncjobs", function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.SyncPermission) then
        TriggerClientEvent('ox_lib:notify', source, { title = "Permission Denied", description = "You are not authorized to use this command.", type = "error" })
        return
    end
    SyncPlayerJobs(source)
end, false)

RegisterCommand("myjobs", function(source, args, rawCommand)
    local Player = GetPlayer(source)
    if not Player then return end

    if not Player.PlayerData.jobs or #Player.PlayerData.jobs == 0 then
        TriggerClientEvent('ox_lib:notify', source, { title = "Your Jobs", description = "You have no jobs assigned.", type = "inform" })
        return
    end

    local jobList = {}
    for _, jobData in ipairs(Player.PlayerData.jobs) do
        table.insert(jobList, string.format("%s (%s)", jobData.label, jobData.grade.name))
    end

    TriggerClientEvent('ox_lib:notify', source, { title = "Your Jobs", description = table.concat(jobList, "<br>"), type = "inform" })
end, false)

RegisterCommand("setactivejob", function(source, args, rawCommand)
    local Player = GetPlayer(source)
    if not Player then return end

    local jobName = args[1]
    if not jobName then
        TriggerClientEvent('ox_lib:notify', source, { title = "Invalid Usage", description = "Please specify a job name. Usage: /setactivejob [job_name]", type = "error" })
        return
    end

    local hasJob = false
    for _, jobData in ipairs(Player.PlayerData.jobs) do
        if jobData.name == jobName then
            hasJob = true
            break
        end
    end

    if hasJob then
        Player.Functions.SetActiveJob(jobName)
    else
        TriggerClientEvent('ox_lib:notify', source, { title = "Job Not Found", description = "You do not have that job.", type = "error" })
    end
end, false)

