-- server.lua
-- QBX Badger Bridge (Discord Job Sync)
-- Automatically and manually syncs roles, and supports a UI for job selection.

-- NOTE: This script now uses the settings defined in config/config.lua

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------
local function GetPlayer(source)
    return exports['qbx_core']:GetPlayer(source)
end

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
local function SyncPlayerJobs(playerSource, isManual)
    local Player = GetPlayer(playerSource)
    if not Player then return end

    if isManual and Config.Debug then 
        print(('[%s][DEBUG] Manual sync started for source: %s.'):format(GetCurrentResourceName(), playerSource))
        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Starting manual synchronization...", "primary")
    end

    exports['honeybadger-resource']:GetPlayerRoles(playerSource, function(roleList)
        local discordRoles = ConvertRolesToLookupTable(roleList)
        
        if Config.Debug then print(('[%s][DEBUG] Received roles for source %s: %s'):format(GetCurrentResourceName(), playerSource, json.encode(discordRoles))) end

        local shouldHaveJobs = {}
        for _, jobData in ipairs(RankedJobs) do
            if discordRoles[jobData.roleName] then
                if not shouldHaveJobs[jobData.job] then
                    shouldHaveJobs[jobData.job] = jobData.grade
                end
            end
        end

        local currentlyHasJobs = {}
        if Player.PlayerData.jobs and type(Player.PlayerData.jobs) == "table" then
            for _, jobData in ipairs(Player.PlayerData.jobs) do
                currentlyHasJobs[jobData.name] = jobData.grade
            end
        end

        local changesMade = false
        for jobName, jobGrade in pairs(shouldHaveJobs) do
            if currentlyHasJobs[jobName] ~= jobGrade then
                Player.Functions.SetJob(jobName, jobGrade)
                if isManual then TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, ('Assigned/Updated job: %s'):format(jobName), "success") end
                changesMade = true
            end
        end

        for jobName, _ in pairs(currentlyHasJobs) do
            if not shouldHaveJobs[jobName] then
                Player.Functions.RemoveJob(jobName)
                if isManual then TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, ('Removed job: %s'):format(jobName), "error") end
                changesMade = true
            end
        end

        if changesMade then
            Player.Functions.Save()
            if Config.Debug then print(('[%s][DEBUG] Player data saved for source %s.'):format(GetCurrentResourceName(), playerSource)) end
        end
        
        if isManual then
            if Config.Debug then print(('[%s][DEBUG] Job sync complete for source %s.'):format(GetCurrentResourceName(), playerSource)) end
            TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Synchronization complete!", "success")
        end
    end)
end

--------------------------------------------------------------------------------
-- Triggers for Synchronization
--------------------------------------------------------------------------------
-- AUTOMATIC: Triggered when a player loads their character.
RegisterNetEvent('crm-multicharacter:server:playerLoaded', function()
    local source = source
    if Config.Debug then print(('[%s][DEBUG] Automatic sync triggered for source: %s.'):format(GetCurrentResourceName(), source)) end
    SyncPlayerJobs(source, false) -- isManual is false
end)

-- MANUAL: Command to trigger the job sync for admins.
-- The command name is now controlled by Config.Commands.syncJobs
RegisterCommand(Config.Commands.syncJobs, function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You are not authorized to use this command.", "error")
        return
    end
    SyncPlayerJobs(source, true) -- isManual is true
end, true) -- Set restricted to true

--------------------------------------------------------------------------------
-- Server Events for Client UI
--------------------------------------------------------------------------------
-- Event for the client to request the player's job list.
RegisterNetEvent('qbx_badger_bridge:server:getJobs', function()
    local source = source
    local Player = GetPlayer(source)
    if not Player then return end
    TriggerClientEvent('qbx_badger_bridge:client:receiveJobs', source, Player.PlayerData.jobs)
end)

-- Event for the client to set a new active job.
RegisterNetEvent('qbx_badger_bridge:server:setActiveJob', function(jobName)
    local source = source
    local Player = GetPlayer(source)
    if not Player then return end

    if not jobName then
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "Invalid job name specified.", "error")
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
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You do not have that job.", "error")
    end
end)

