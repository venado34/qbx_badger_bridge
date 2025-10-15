-- server.lua
-- QBX Badger Bridge (Discord Job Sync)
-- Automatically synchronizes in-game jobs with Discord roles

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while Config == nil or RankedJobs == nil do
        Citizen.Wait(100)
    end

    if Config.Debug then
        print(('^2[qbx_badger_bridge] Config and jobs loaded. Initializing server script.^7'))
    end
end)

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------
local function GetPlayer(source)
    -- Get the player object from QBX-Core
    return exports['qbx_core']:GetPlayer(source)
end

local function ConvertRolesToLookupTable(roleList)
    -- Convert Discord role list to a lookup table for easier checking
    local lookup = {}
    if type(roleList) ~= "table" then return lookup end
    for _, roleName in ipairs(roleList) do
        lookup[roleName] = true
    end
    return lookup
end

local function HasAdminPermission(source)
    -- Check if the player has at least one of the configured admin permissions
    for _, permission in ipairs(Config.AdminPermissions) do
        if IsPlayerAceAllowed(source, permission) then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- Core Synchronization Logic
--------------------------------------------------------------------------------
local function SyncPlayerJobs(playerSource, isManual)
    local Player = GetPlayer(playerSource)
    if not Player then return end

    if isManual and Config.Debug then 
        print(('[qbx_badger_bridge][DEBUG] Manual sync started for source: %s.'):format(playerSource))
        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Starting manual synchronization...", "primary")
    end

    -- Fetch Discord roles for the player
    exports['honeybadger-resource']:GetPlayerRoles(playerSource, function(roleList)
        local discordRoles = ConvertRolesToLookupTable(roleList)

        if Config.Debug then
            print(('[qbx_badger_bridge][DEBUG] Received roles for source %s: %s'):format(playerSource, json.encode(discordRoles)))
        end

        --------------------------------------------------------------------------------
        -- Determine which jobs the player should have
        --------------------------------------------------------------------------------
        local shouldHaveJobs = {}
        for _, jobData in ipairs(RankedJobs) do
            if discordRoles[jobData.roleName] and not shouldHaveJobs[jobData.job] then
                shouldHaveJobs[jobData.job] = jobData.grade
            end
        end

        --------------------------------------------------------------------------------
        -- Get current jobs the player already has
        --------------------------------------------------------------------------------
        local currentlyHasJobs = {}
        if Player.PlayerData.jobs and type(Player.PlayerData.jobs) == "table" then
            for _, jobData in ipairs(Player.PlayerData.jobs) do
                currentlyHasJobs[jobData.name] = jobData.grade
            end
        end

        --------------------------------------------------------------------------------
        -- Compare and update jobs
        --------------------------------------------------------------------------------
        local changesMade = false

        -- Assign or update jobs
        for jobName, jobGrade in pairs(shouldHaveJobs) do
            if currentlyHasJobs[jobName] ~= jobGrade then
                Player.Functions.SetJob(jobName, jobGrade)
                if isManual then
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, ('Assigned/Updated job: %s'):format(jobName), "success")
                end
                changesMade = true
            end
        end

        -- Remove jobs no longer matched
        for jobName, _ in pairs(currentlyHasJobs) do
            if not shouldHaveJobs[jobName] then
                Player.Functions.RemoveJob(jobName)
                if isManual then
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, ('Removed job: %s'):format(jobName), "error")
                end
                changesMade = true
            end
        end

        --------------------------------------------------------------------------------
        -- Save player data if changes occurred
        --------------------------------------------------------------------------------
        if changesMade then
            Player.Functions.Save()
            if Config.Debug then
                print(('[qbx_badger_bridge][DEBUG] Player data saved for source %s.'):format(playerSource))
            end
        end

        -- Notify manual sync complete
        if isManual then
            if Config.Debug then
                print(('[qbx_badger_bridge][DEBUG] Job sync complete for source %s.'):format(playerSource))
            end
            TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Synchronization complete!", "success")
        end
    end)
end

--------------------------------------------------------------------------------
-- Automatic Job Sync on Player Loaded
--------------------------------------------------------------------------------
if Config.CharacterSystem == 'crm-multicharacter' then
    RegisterNetEvent('crm-multicharacter:server:playerLoaded', function()
        local source = source
        if Config.Debug then
            print(('[qbx_badger_bridge][DEBUG] Automatic sync triggered for source: %s.'):format(source))
        end
        SyncPlayerJobs(source, false)
    end)
elseif Config.CharacterSystem == 'qbx' then
    AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
        local src = source
        -- Trigger automatic job sync
        SyncPlayerJobs(src, false)
    end)
else
    print("^1[QBX Badger Bridge] No compatible character system detected. Automatic sync disabled.^7")
end

--------------------------------------------------------------------------------
-- Admin Command: Manual Job Sync
--------------------------------------------------------------------------------
RegisterCommand(Config.Commands.syncJobs, function(source)
    if not HasAdminPermission(source) then
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You are not authorized to use this command.", "error")
        return
    end
    SyncPlayerJobs(source, true)
end, true)

--------------------------------------------------------------------------------
-- Server Events for Client UI
--------------------------------------------------------------------------------
RegisterNetEvent('qbx_badger_bridge:server:getJobs', function()
    local source = source
    local Player = GetPlayer(source)
    if not Player then return end

    -- Send player's jobs to client for menu
    TriggerClientEvent('qbx_badger_bridge:client:receiveJobs', source, Player.PlayerData.jobs)
end)

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
        -- Set the selected job as active
        Player.Functions.SetActiveJob(jobName)
    else
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You do not have that job.", "error")
    end
end)
