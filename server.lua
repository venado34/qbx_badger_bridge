-- QBX Badger Bridge (Discord Job Sync)
-- Server-side script

--------------------------------------------------------------------------------
-- Wait for Config and RankedJobs to be loaded
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

local function ConvertRolesToLookupTable(roleList)
    local lookup = {}
    if type(roleList) ~= "table" then return lookup end
    for _, roleName in ipairs(roleList) do
        lookup[roleName] = true
    end
    return lookup
end

local function HasAdminPermission(source)
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
        print(('[%s][DEBUG] Manual sync started for source: %s.'):format(GetCurrentResourceName(), playerSource))
        TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Starting manual synchronization...", "primary")
    end

    -- Get Discord roles via Honeybadger
    exports['honeybadger-resource']:GetPlayerRoles(playerSource, function(roleList)
        local discordRoles = ConvertRolesToLookupTable(roleList)

        if Config.Debug then
            print(('[%s][DEBUG] Received roles for source %s: %s'):format(GetCurrentResourceName(), playerSource, json.encode(discordRoles)))
        end

        -- Determine which jobs the player should have
        local shouldHaveJobs = {}
        for _, jobData in ipairs(RankedJobs) do
            if discordRoles[jobData.roleName] then
                if not shouldHaveJobs[jobData.job] then
                    shouldHaveJobs[jobData.job] = jobData.grade
                end
            end
        end

        -- Get current jobs
        local currentlyHasJobs = {}
        if Player.PlayerData.jobs and type(Player.PlayerData.jobs) == "table" then
            for _, jobData in ipairs(Player.PlayerData.jobs) do
                currentlyHasJobs[jobData.name] = jobData.grade
            end
        end

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

        -- Remove jobs no longer in Discord roles
        for jobName, _ in pairs(currentlyHasJobs) do
            if not shouldHaveJobs[jobName] then
                Player.Functions.RemoveJob(jobName)
                if isManual then
                    TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, ('Removed job: %s'):format(jobName), "error")
                end
                changesMade = true
            end
        end

        -- Save changes if any
        if changesMade then
            Player.Functions.Save()
            if Config.Debug then
                print(('[%s][DEBUG] Player data saved for source %s.'):format(GetCurrentResourceName(), playerSource))
            end
        end

        -- Notify manual sync complete
        if isManual then
            if Config.Debug then
                print(('[%s][DEBUG] Job sync complete for source %s.'):format(GetCurrentResourceName(), playerSource))
            end
            TriggerClientEvent('qbx_badger_bridge:client:Notify', playerSource, "Synchronization complete!", "success")
        end
    end)
end

--------------------------------------------------------------------------------
-- Commands
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
        Player.Functions.SetActiveJob(jobName)
    else
        TriggerClientEvent('qbx_badger_bridge:client:Notify', source, "You do not have that job.", "error")
    end
end)

--------------------------------------------------------------------------------
-- Character Loaded Event (Modular)
--------------------------------------------------------------------------------
if Config.Multicharacter == 'qbx_core' then

    -- QBX-Core OnPlayerLoaded
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

elseif Config.Multicharacter == 'crm_multicharacter' then

    -- CRM-Multicharacter event
    local CharacterLoadedEvent = 'crm-multicharacter:server:playerLoaded'
    RegisterNetEvent(CharacterLoadedEvent, function()
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

    -- Fallback if no character system is configured
    print("^1[QBX Badger Bridge] No compatible character system detected. Automatic sync disabled.^7")

end
