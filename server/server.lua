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

-- =========================
-- Framework abstraction (auto-detects QBCore or ESX)
-- =========================
local Framework = { Name = "standalone", Core = nil }

local function detectFramework()
    local cfg = (Config.Framework or "auto"):lower()
    -- Backward compat: Config.UseQBCore=false forces standalone when auto.
    if Config.UseQBCore == false and cfg == "auto" then cfg = "standalone" end
    if cfg == "standalone" then return end

    -- Prefer Qbox first: it ships a qb-core compatibility bridge, so if we
    -- didn't check Qbox explicitly we'd misidentify a Qbox server as QBCore
    -- and miss out on the native exports.
    if (cfg == "auto" or cfg == "qbox") and GetResourceState('qbx_core') == 'started' then
        Framework.Name = "qbox"
        Framework.Core = exports.qbx_core -- Qbox uses exported methods directly
        return
    end

    if (cfg == "auto" or cfg == "qbcore") and GetResourceState('qb-core') == 'started' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core then
            Framework.Name, Framework.Core = "qbcore", core
            return
        end
    end

    if (cfg == "auto" or cfg == "esx") and GetResourceState('es_extended') == 'started' then
        local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and core then
            Framework.Name, Framework.Core = "esx", core
            return
        end
        -- Fallback for older ESX versions
        TriggerEvent('esx:getSharedObject', function(obj) Framework.Core = obj end)
        if Framework.Core then Framework.Name = "esx" end
    end
end

detectFramework()

if Framework.Name == "qbox" then
    print('^2[tm-multiscript] Qbox detected and initialized^7')
elseif Framework.Name == "qbcore" then
    print('^2[tm-multiscript] QBCore detected and initialized^7')
elseif Framework.Name == "esx" then
    print('^2[tm-multiscript] ESX detected and initialized^7')
else
    print('^3[tm-multiscript] No supported framework detected, running in standalone mode^7')
end

-- Legacy alias so any older references to QBCore still resolve when QBCore is active.
local QBCore = (Framework.Name == "qbcore") and Framework.Core or nil

-- Print loaded modules
Citizen.CreateThread(function()
    local loadedModules = {}
    for moduleName, module in pairs(Config.Modules) do
        if module.enabled then
            local displayName = module.displayName or moduleName:gsub("^%l", string.upper):gsub("_", " ")
            table.insert(loadedModules, displayName)
        end
    end

    local fwLabel
    if Framework.Name == "qbox" then
        fwLabel = 'Qbox (native)'
    elseif Framework.Name == "qbcore" then
        fwLabel = 'QBCore'
    elseif Framework.Name == "esx" then
        fwLabel = 'ESX'
    else
        fwLabel = 'Standalone (no framework detected)'
    end
    print('^2[tm-multiscript] Framework: ' .. fwLabel .. '^7')

    print('^2[tm-multiscript] Modules Loaded:^7')
    for _, name in ipairs(loadedModules) do
        print('^2[tm-multiscript]   - ' .. name .. '^7')
    end
end)

-- Helper function for notifications (framework-aware)
local function Notify(source, message, type)
    if source == 0 then
        print('^2SYSTEM: ' .. message .. '^7')
        return
    end
    if Framework.Name == "qbox" then
        -- Prefer ox_lib (Qbox's native notify stack). Fall back to the
        -- QBCore bridge event (also works on Qbox) if ox_lib isn't loaded.
        if GetResourceState('ox_lib') == 'started' then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'tm-multiscript',
                description = message,
                type = type or 'inform'
            })
        else
            TriggerClientEvent('QBCore:Notify', source, message, type)
        end
    elseif Framework.Name == "qbcore" then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    elseif Framework.Name == "esx" then
        TriggerClientEvent('esx:showNotification', source, message)
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

-- Helper function to check command permissions (framework-aware)
local function HasPermission(source, command)
    if source == 0 then return true end
    local requiredPerm = Config.CommandPermissions[command]
    if not requiredPerm then return true end

    -- Qbox: prefer the native HasGroup export, fall back to ACE perms.
    if Framework.Name == "qbox" then
        local hierarchy = {"god", "admin", "mod", "user"}
        local requiredIndex
        for i, perm in ipairs(hierarchy) do
            if perm == requiredPerm then requiredIndex = i break end
        end
        if not requiredIndex then return false end
        for i = 1, requiredIndex do
            local group = hierarchy[i]
            if group == "user" then return true end
            local okHG, has = pcall(function() return Framework.Core:HasGroup(source, group) end)
            if okHG and has then return true end
            if IsPlayerAceAllowed(source, 'group.' .. group) or
               IsPlayerAceAllowed(source, 'qbx.' .. group) then
                return true
            end
        end
        if Config.Debug then print('^1[DEBUG] Qbox player missing permission: ' .. requiredPerm .. '^7') end
        return false
    end

    -- QBCore: use HasPermission with a god > admin > mod > user hierarchy.
    if Framework.Name == "qbcore" then
        local Player = Framework.Core.Functions.GetPlayer(source)
        if not Player then
            if Config.Debug then print('^1[DEBUG] Player not found for source: ' .. source .. '^7') end
            return false
        end
        local hierarchy = {"god", "admin", "mod", "user"}
        local requiredIndex
        for i, perm in ipairs(hierarchy) do
            if perm == requiredPerm then requiredIndex = i break end
        end
        if not requiredIndex then return false end
        for i = 1, requiredIndex do
            if Framework.Core.Functions.HasPermission(Player.PlayerData.source, hierarchy[i]) then
                return true
            end
        end
        if Config.Debug then print('^1[DEBUG] Player does not have required permission: ' .. requiredPerm .. '^7') end
        return false
    end

    -- ESX: map QBCore-style perms onto ESX groups and compare by rank.
    if Framework.Name == "esx" then
        local xPlayer = Framework.Core.GetPlayerFromId(source)
        if not xPlayer then return false end
        local playerGroup = (xPlayer.getGroup and xPlayer.getGroup()) or "user"
        local neededGroup = (Config.ESXGroupMap and Config.ESXGroupMap[requiredPerm]) or "superadmin"
        local ranks = { superadmin = 4, admin = 3, mod = 2, user = 1 }
        local playerRank = ranks[playerGroup] or 0
        local neededRank = ranks[neededGroup] or 4
        if playerRank >= neededRank then return true end
        if Config.Debug then
            print('^1[DEBUG] ESX player group ' .. tostring(playerGroup) .. ' < required ' .. tostring(neededGroup) .. '^7')
        end
        return false
    end

    -- Standalone: fall back to ACE permissions, keyed as tm-multiscript.<command>.
    if IsPlayerAceAllowed(source, 'tm-multiscript.' .. tostring(command)) then
        return true
    end
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

    -- When a client asks for its current list (e.g. on resource start /
    -- reconnect), send back every netId it has toggled on so its per-vehicle
    -- memory can be rebuilt.
    RegisterNetEvent("permvehicle:requestState")
    AddEventHandler("permvehicle:requestState", function()
        local src = source
        local cleanList, fixList = {}, {}
        for netId, owner in pairs(cleanVehicles) do
            if owner == src then cleanList[#cleanList + 1] = netId end
        end
        for netId, owner in pairs(fixVehicles) do
            if owner == src then fixList[#fixList + 1] = netId end
        end
        TriggerClientEvent("permvehicle:syncState", src, cleanList, fixList)
    end)

    -- Clean up a player's tracked vehicles when they disconnect so the
    -- tables don't leak stale netIds over long sessions.
    AddEventHandler("playerDropped", function()
        local src = source
        for netId, owner in pairs(cleanVehicles) do
            if owner == src then cleanVehicles[netId] = nil end
        end
        for netId, owner in pairs(fixVehicles) do
            if owner == src then fixVehicles[netId] = nil end
        end
    end)

    CreateThread(function()
        while true do
            Wait(Config.Modules.permclean.fixInterval)
            for netId, _ in pairs(fixVehicles) do
                -- Broadcast to everyone. Only the current network owner of
                -- the vehicle will actually apply the fix, so it syncs
                -- properly whether the toggler is the driver or just a
                -- passenger.
                TriggerClientEvent("permvehicle:doFix", -1, netId)
            end
        end
    end)

    CreateThread(function()
        while true do
            Wait(Config.Modules.permclean.cleanInterval)
            for netId, _ in pairs(cleanVehicles) do
                TriggerClientEvent("permvehicle:doClean", -1, netId)
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

-- =========================
-- Module: NPC Gun (AIG)
-- =========================
if Config.Modules.npcgun and Config.Modules.npcgun.enabled then
    RegisterCommand('aig', function(source, args, rawCommand)
        if not HasPermission(source, 'aig') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        if not ValidatePlayerId(source, targetId) then return end
        
        TriggerClientEvent('qb-aig:client:attack', targetId)
        Notify(source, 'Initiated NPC attack on player ' .. targetId, 'success')
    end, false)
end

-- =========================
-- Module: Night's ERSS
-- =========================
if Config.Modules.nights_erss and Config.Modules.nights_erss.enabled then
    RegisterCommand('tgshoot', function(source, args, rawCommand)
        if not HasPermission(source, 'tgshoot') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        TriggerClientEvent('chat:addMessage', source, {
            args = { '[AI Shootout]', 'Use /toggleShoot to toggle the AI shootout mode.' }
        })
    end, false)
end

-- =========================
-- Module: Hijab
-- =========================
if Config.Modules.hijab and Config.Modules.hijab.enabled then
    RegisterCommand('hijack', function(source, args, rawCommand)
        if not HasPermission(source, 'hijack') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end

        local targetId = tonumber(args[1])
        if not ValidatePlayerId(source, targetId) then return end
        
        TriggerClientEvent('qb-hijacker:spawnHijacker', targetId, source)
        Notify(source, 'Sent hijacker to player ' .. targetId, 'success')
    end, false)
    
    -- Hijacker notification events
    RegisterServerEvent('hijacker:attemptNotify')
    AddEventHandler('hijacker:attemptNotify', function(sourcePlayer, attempts)
        Notify(sourcePlayer, "Hijacker is trying to enter the vehicle... Attempt: " .. attempts, "info")
    end)
    
    RegisterServerEvent('hijacker:failedNotify')
    AddEventHandler('hijacker:failedNotify', function(sourcePlayer)
        Notify(sourcePlayer, "Hijacker failed to get in the vehicle.", "error")
    end)
    
    RegisterServerEvent('hijacker:noVehicleNotify')
    AddEventHandler('hijacker:noVehicleNotify', function(sourcePlayer)
        Notify(sourcePlayer, "The target player is not in a vehicle.", "error")
    end)
end

-- =========================
-- Module: FatJack
-- =========================
RegisterCommand('fatjack', function(source, args, rawCommand)
    if not HasPermission(source, 'fatjack') then
        Notify(source, 'You do not have permission to use this command', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not ValidatePlayerId(source, targetId) then return end
    
    TriggerClientEvent('qb-hijack:client:Hijack', targetId, targetId)
    Notify(source, 'Sent fat person to hijack player ' .. targetId, 'success')
end, false)

-- =========================
-- Module: Fuel
-- =========================
RegisterCommand('nofuel', function(source, args, rawCommand)
    if not HasPermission(source, 'nofuel') then
        Notify(source, 'You do not have permission to use this command', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not ValidatePlayerId(source, targetId) then return end
    
    TriggerClientEvent('custom-fuel:depleteFuel', targetId)
    Notify(source, 'Depleted fuel for player ' .. targetId, 'success')
end, false)

-- =========================
-- Module: Jerk
-- =========================
RegisterCommand('jerkify', function(source, args, rawCommand)
    if not HasPermission(source, 'jerkify') then
        Notify(source, 'You do not have permission to use this command', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        targetId = source
    end
    
    if not ValidatePlayerId(source, targetId) then return end
    
    TriggerClientEvent('chat:addMessage', targetId, {
        args = { '[Animation]', 'Use /jerk to play a special animation.' }
    })
    Notify(source, 'Sent jerk command info to player ' .. targetId, 'success')
end, false)

-- =========================
-- Module: Fake Join/Leave
-- =========================
if Config.Modules.joinfak and Config.Modules.joinfak.enabled then
    RegisterServerEvent("joinfak:sendFakeJoin")
    AddEventHandler("joinfak:sendFakeJoin", function()
        local source = source
        if not HasPermission(source, 'fakejoin') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end
        
        TriggerClientEvent("chatMessage", -1, "", { 162, 214, 11 }, "* " .. Config.Modules.joinfak.fakeName .. " joined")
        Notify(source, 'Sent fake join message', 'success')
    end)
    
    RegisterServerEvent("joinfak:sendFakeLeave")
    AddEventHandler("joinfak:sendFakeLeave", function()
        local source = source
        if not HasPermission(source, 'fakeleave') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end
        
        TriggerClientEvent("chatMessage", -1, "", { 162, 214, 11 }, "* " .. Config.Modules.joinfak.fakeName .. " left (Exiting)")
        Notify(source, 'Sent fake leave message', 'success')
    end)
    
    -- Also add direct commands for console use
    RegisterCommand('fakejoin', function(source, args, rawCommand)
        if not HasPermission(source, 'fakejoin') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end
        
        TriggerClientEvent("chatMessage", -1, "", { 162, 214, 11 }, "* " .. Config.Modules.joinfak.fakeName .. " joined")
        if source == 0 then
            print('^2SYSTEM: Sent fake join message^7')
        else
            Notify(source, 'Sent fake join message', 'success')
        end
    end, false)
    
    RegisterCommand('fakeleave', function(source, args, rawCommand)
        if not HasPermission(source, 'fakeleave') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end
        
        TriggerClientEvent("chatMessage", -1, "", { 162, 214, 11 }, "* " .. Config.Modules.joinfak.fakeName .. " left (Exiting)")
        if source == 0 then
            print('^2SYSTEM: Sent fake leave message^7')
        else
            Notify(source, 'Sent fake leave message', 'success')
        end
    end, false)
end

-- =========================
-- Module: Dirty
-- =========================
if Config.Modules.dirty and Config.Modules.dirty.enabled then
    RegisterServerEvent('syncVehicleDirt')
    AddEventHandler('syncVehicleDirt', function(vehicleNetId, dirtLevel)
        local source = source
        if not HasPermission(source, 'dirty') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end
        
        TriggerClientEvent('updateVehicleDirt', -1, vehicleNetId, dirtLevel)
        if Config.Debug or (Config.Modules.dirty and Config.Modules.dirty.debug) then
            print("[dirty] Syncing dirt level " .. dirtLevel .. " for vehicle netId: " .. vehicleNetId)
        end
    end)
end

-- =========================
-- Module: Window Tint
-- =========================
if Config.Modules.tint and Config.Modules.tint.enabled then
    RegisterServerEvent('syncVehicleTint')
    AddEventHandler('syncVehicleTint', function(vehicleNetId, tintLevel)
        local source = source
        if not HasPermission(source, 'tint') then
            Notify(source, 'You do not have permission to use this command', 'error')
            return
        end
        
        print("[DEBUG] Server received tint sync request: Vehicle " .. vehicleNetId .. ", Tint Level " .. tintLevel)
        TriggerClientEvent('updateVehicleTint', -1, vehicleNetId, tintLevel)
        if Config.Debug or (Config.Modules.tint and Config.Modules.tint.debug) then
            print("[tint] Player " .. source .. " set tint level " .. tintLevel .. " for vehicle " .. vehicleNetId)
        end
    end)
end

-- Update check (GitHub)
local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)
local versionURL = "https://raw.githubusercontent.com/TheMannster/tm-multiscript/main/fxmanifest.lua"
local changelogURL = "https://raw.githubusercontent.com/TheMannster/tm-multiscript/refs/heads/main/changelog.json"

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
                -- Fetch and print latest changelog
                PerformHttpRequest(changelogURL, function(clStatus, clResponse, clHeaders)
                    if clStatus == 200 and clResponse then
                        local ok, changelogData = pcall(function() return json.decode(clResponse) end)
                        if ok and changelogData and changelogData.changelogs and changelogData.changelogs[latestVersion] then
                            print("^3["..resourceName.."]^2 Latest update: " .. changelogData.changelogs[latestVersion] .. "^7")
                        else
                            print("^1["..resourceName.."] Could not parse changelog for version "..tostring(latestVersion)..".^7")
                        end
                    else
                        print("^1["..resourceName.."] Could not fetch changelog information (HTTP "..tostring(clStatus)..")^7")
                    end
                end, "GET")
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