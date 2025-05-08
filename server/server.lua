if GetCurrentResourceName() ~= "tm-multiscript" then
    print("^3[tm-multiscript]^1 ERROR: Don't rename the resource!^7")
    StopResource(GetCurrentResourceName())
    return
end

-- Main server file for tm-multiscript
print("^3 _______ __  __ ")
print("^3|__   __|  \\/  |")
print("^3   | |  | \\  / |")
print("^3   | |  | |\\/| |")
print("^3   | |  | |  | |")
print("^3   |_|  |_|  |_|")
print('^2[tm-multiscript] Server script started^7')

-- QBCore initialization
local QBCore = nil
if Config.UseQBCore and GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
    print('^2[tm-multiscript] QBCore detected and initialized^7')
else
    print('^3[tm-multiscript] QBCore not detected or disabled, running in standalone mode^7')
end

-- Print loaded modules
Citizen.CreateThread(function()
    local loadedModules = {}
    for moduleName, module in pairs(Config.Modules) do
        if module.enabled then
            local displayName = module.displayName or moduleName:gsub("^%l", string.upper):gsub("_", " ")
            table.insert(loadedModules, displayName)
        end
    end
    print('^2[tm-multiscript] Modules Loaded:^7')
    for _, name in ipairs(loadedModules) do
        print('^2[tm-multiscript]   - ' .. name .. '^7')
    end
end)

-- Helper function for notifications
local function Notify(source, message, type)
    if source == 0 then
        print('^2SYSTEM: ' .. message .. '^7')
    elseif QBCore then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    else
        TriggerClientEvent('chatMessage', source, '^2SYSTEM', {0, 255, 0}, message)
    end
end

-- Helper function to validate player ID
local function ValidatePlayerId(source, targetId)
    if not targetId then
        if source == 0 then
            print('^1ERROR: You must specify a player ID when using this command from console^7')
        else
            Notify(source, 'You must specify a player ID', 'error')
        end
        return false
    end
    
    if not GetPlayerName(targetId) then
        if source == 0 then
            print('^1ERROR: Invalid player ID: ' .. targetId .. '^7')
        else
            Notify(source, 'Invalid player ID', 'error')
        end
        return false
    end
    
    return true
end

-- Helper function to check command permissions using QBCore's HasPermission
local function HasPermission(source, command)
    if not Config.UseQBCore or source == 0 then return true end
    if not Config.CommandPermissions[command] then return true end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        if Config.Debug then print('^1[DEBUG] Player not found for source: ' .. source .. '^7') end
        return false
    end

    local requiredPerm = Config.CommandPermissions[command]
    -- Hierarchy: god > admin > mod > user
    local hierarchy = {"god", "admin", "mod", "user"}
    local requiredIndex = nil

    for i, perm in ipairs(hierarchy) do
        if perm == requiredPerm then
            requiredIndex = i
            break
        end
    end

    if not requiredIndex then
        if Config.Debug then print('^1[DEBUG] Required permission not found in hierarchy: ' .. tostring(requiredPerm) .. '^7') end
        return false
    end

    -- Check if player has any permission at or above the required level
    for i = 1, requiredIndex do
        if QBCore.Functions.HasPermission(Player.PlayerData.source, hierarchy[i]) then
            return true
        end
    end

    if Config.Debug then print('^1[DEBUG] Player does not have required permission: ' .. requiredPerm .. '^7') end
    return false
end

-- Helper function to check if a player is whitelisted for permclean
local function IsPermcleanWhitelisted(source)
    if source == 0 then return false end
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local identifier = GetPlayerIdentifier(source, i)
        if Config.Modules.permclean.whitelist[identifier] then
            return true
        end
    end
    return false
end

-- =========================
-- Module: Tire Pop
-- =========================
if Config.Modules.tirepop.enabled then
    local function HandleTirePop(source, targetId, tireInput)
        if not ValidatePlayerId(source, targetId) then return end
        
        local tiresToPop = {}
        
        if tireInput then
            local keyword = string.lower(tireInput)
            
            if keyword == "rear" or keyword == "back" then
                table.insert(tiresToPop, 2)
                table.insert(tiresToPop, 3)
            elseif keyword == "front" then
                table.insert(tiresToPop, 0)
                table.insert(tiresToPop, 1)
            elseif keyword == "left" then
                table.insert(tiresToPop, 0)
                table.insert(tiresToPop, 2)
            elseif keyword == "right" then
                table.insert(tiresToPop, 1)
                table.insert(tiresToPop, 3)
            elseif keyword == "all" then
                table.insert(tiresToPop, 0)
                table.insert(tiresToPop, 1)
                table.insert(tiresToPop, 2)
                table.insert(tiresToPop, 3)
            else
                local tireIndex = tonumber(tireInput)
                
                if not tireIndex or tireIndex < 1 or tireIndex > 4 then
                    Notify(source, 'Invalid tire index. Use 1-4 or keywords: front, rear, left, right, all', 'error')
                    return
                end
                
                table.insert(tiresToPop, tireIndex - 1)
            end
        else
            Notify(source, 'Missing arguments. Usage: tirepop [player_id] [tire_index or keyword]', 'error')
            return
        end
        
        local tireNames = {"Front Left", "Front Right", "Back Left", "Back Right"}
        local tireList = ""
        
        for i, tireIndex in ipairs(tiresToPop) do
            local tireName = tireNames[tireIndex + 1] or "Unknown"
            if i > 1 then
                tireList = tireList .. ", "
            end
            tireList = tireList .. tireName
        end
        
        Notify(source, 'Popped ' .. tireList .. ' tire(s) on player ' .. targetId, 'success')
        
        for _, tireIndex in ipairs(tiresToPop) do
            TriggerClientEvent('tirepop:popTire', targetId, tireIndex)
        end
    end

    RegisterCommand('tirepop', function(source, args, rawCommand)
        if not HasPermission(source, 'tirepop') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        local tireInput = args[2]
        
        if not tireInput then
            tireInput = args[1]
            targetId = source
        end
        
        HandleTirePop(source, targetId, tireInput)
    end, false)

    RegisterCommand('repairalltires', function(source, args, rawCommand)
        if not HasPermission(source, 'repairalltires') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        
        if not targetId then
            if source == 0 then
                print('^1ERROR: You must specify a player ID when using this command from console^7')
                return
            end
            targetId = source
        end
        
        if not ValidatePlayerId(source, targetId) then return end
        
        TriggerClientEvent('tirepop:repairTires', targetId)
        Notify(source, 'Repaired all tires on player ' .. targetId .. "'s vehicle", 'success')
    end, false)

    RegisterServerEvent('tirepop:playGunshot')
    AddEventHandler('tirepop:playGunshot', function(coords)
        local source = source
        
        if source and coords then
            TriggerClientEvent('tirepop:clientPlayGunshot', source, coords)
            if Config.Modules.tirepop.debug then
                print("[tirepop] Playing gunshot sound for player " .. source)
            end
        end
    end)
end

-- =========================
-- Module: Slide Car
-- =========================
if Config.Modules.slide.enabled then
    RegisterCommand('slidecar', function(source, args, rawCommand)
        if not HasPermission(source, 'slidecar') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        if #args < 1 then
            Notify(source, 'You must specify a player ID', 'error')
            return
        end

        local targetId = tonumber(args[1])
        if not ValidatePlayerId(source, targetId) then return end

        TriggerClientEvent('slideCar:applyForce', targetId, targetId)
        Notify(source, 'Slid car for player ' .. targetId, 'success')
    end, false)
end

-- =========================
-- Module: SPED
-- =========================
if Config.Modules.sped.enabled then
    RegisterCommand('explode', function(source, args)
        if not HasPermission(source, 'explode') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        if not ValidatePlayerId(source, targetId) then return end
        
        TriggerClientEvent('sped:explodePlayer', targetId)
        Notify(source, 'Exploded player ' .. targetId, 'success')
    end, false)

    RegisterCommand('grenade', function(source, args)
        if not HasPermission(source, 'grenade') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        if not ValidatePlayerId(source, targetId) then return end
        
        TriggerClientEvent('sped:throwGrenadeAtPlayer', targetId)
        Notify(source, 'Threw grenade at player ' .. targetId, 'success')
    end, false)

    RegisterCommand('seegrenade', function(source, args)
        if not HasPermission(source, 'seegrenade') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        if not ValidatePlayerId(source, targetId) then return end
        
        TriggerClientEvent('sped:seeGrenadeNotification', targetId)
        Notify(source, 'Sent grenade notification to player ' .. targetId, 'success')
    end, false)
end

-- =========================
-- Module: Permanent Clean/Fix
-- =========================
if Config.Modules.permclean.enabled then
    local cleanVehicles = {}
    local fixVehicles = {}

    RegisterNetEvent("permvehicle:setCleanState")
    AddEventHandler("permvehicle:setCleanState", function(netId, state)
        if state then
            cleanVehicles[netId] = source
            if Config.Modules.permclean.debug then
                print("[permvehicle] CLEAN enabled for netId:", netId)
            end
        else
            cleanVehicles[netId] = nil
            if Config.Modules.permclean.debug then
                print("[permvehicle] CLEAN disabled for netId:", netId)
            end
        end
    end)

    RegisterNetEvent("permvehicle:setFixState")
    AddEventHandler("permvehicle:setFixState", function(netId, state)
        if state then
            fixVehicles[netId] = source
            if Config.Modules.permclean.debug then
                print("[permvehicle] FIX enabled for netId:", netId)
            end
        else
            fixVehicles[netId] = nil
            if Config.Modules.permclean.debug then
                print("[permvehicle] FIX disabled for netId:", netId)
            end
        end
    end)

    CreateThread(function()
        while true do
            Wait(Config.Modules.permclean.fixInterval)
            for netId, playerSrc in pairs(fixVehicles) do
                TriggerClientEvent("permvehicle:doFix", playerSrc, netId)
            end
        end
    end)

    CreateThread(function()
        while true do
            Wait(Config.Modules.permclean.cleanInterval)
            for netId, playerSrc in pairs(cleanVehicles) do
                TriggerClientEvent("permvehicle:doClean", playerSrc, netId)
            end
        end
    end)

    RegisterCommand("permclean", function(source, args, rawCommand)
        if not HasPermission(source, 'permclean') and not IsPermcleanWhitelisted(source) then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end
        -- ... existing code ...
    end, false)

    RegisterCommand("permfix", function(source, args, rawCommand)
        if not HasPermission(source, 'permfix') and not IsPermcleanWhitelisted(source) then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        TriggerClientEvent("chatMessage", -1, "", { 162, 214, 11 }, "* " .. Config.Modules.joinfak.fakeName .. " left (Exiting)")
        if source == 0 then
            print('^2SYSTEM: Sent fake leave message^7')
        end
    end, false)
end

-- =========================
-- Module: Client Drop
-- =========================
if Config.Modules.clientdrop.enabled then
    RegisterCommand('client', function(source, args, rawCommand)
        if not HasPermission(source, 'client') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        if not ValidatePlayerId(source, targetId) then return end

        DropPlayer(targetId, "500 OOPS: child died\nConnection closed by remote host.")
        Notify(source, 'Dropped player ' .. targetId .. ' from the server', 'success')
    end, false)
end

-- Update check (GitHub)
local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)
local versionURL = "https://raw.githubusercontent.com/TheMannster/tm-multiscript/main/fxmanifest.lua"

PerformHttpRequest(versionURL, function(statusCode, response, headers)
    if statusCode == 200 and response then
        local latestVersion = response:match("version%s+'([%d%.]+)'")
        local function versionToTable(v)
            local t = {}
            for num in v:gmatch("%d+") do t[#t+1] = tonumber(num) end
            return t
        end
        local function compareVersions(v1, v2)
            local t1, t2 = versionToTable(v1), versionToTable(v2)
            for i = 1, math.max(#t1, #t2) do
                local n1, n2 = t1[i] or 0, t2[i] or 0
                if n1 > n2 then return 1 end
                if n1 < n2 then return -1 end
            end
            return 0
        end
        if latestVersion then
            local cmp = compareVersions(currentVersion, latestVersion)
            if cmp < 0 then
                print("^3["..resourceName.."]^1 You are running an outdated version! ("..currentVersion.." → "..latestVersion..")^7")
                print("^3["..resourceName.."]^0 Update at: https://github.com/TheMannster/tm-multiscript/releases^7")
            elseif cmp > 0 then
                print("^3["..resourceName.."]^6 You are running a development version! (local: "..currentVersion..", github: "..latestVersion..")^7")
            else
                print("^2["..resourceName.."] You are running the latest version. ("..currentVersion..")^7")
            end
        else
            print("^1["..resourceName.."] Could not parse latest version from GitHub.^7")
        end
    else
        print("^1["..resourceName.."] Could not check for updates (HTTP "..tostring(statusCode)..")^7")
    end
end, "GET") 
