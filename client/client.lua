if GetCurrentResourceName() ~= "tm-multiscript" then
    print("^3[tm-multiscript]^1 ERROR: Don't rename the resource!^7")
    return
end

-- Resolve a module's configurable command name (see Config.Modules.<x>.commands).
-- Falls back to the supplied default if the module didn't override it.
local function ModuleCmd(moduleKey, name, default)
    local m = Config.Modules and Config.Modules[moduleKey]
    if m and m.commands and m.commands[name] and m.commands[name] ~= "" then
        return m.commands[name]
    end
    return default
end

-- =========================
-- Framework abstraction (auto-detects QBCore or ESX)
-- =========================
local Framework = { Name = "standalone", Core = nil }
-- Legacy alias kept for any code that still reads QBCore directly; it will
-- simply remain nil on ESX/standalone, and consumers should use Framework.*.
local QBCore = nil

Citizen.CreateThread(function()
    local cfg = (Config.Framework or "auto"):lower()
    if Config.UseQBCore == false and cfg == "auto" then cfg = "standalone" end
    if cfg == "standalone" then return end

    local tries = 0
    while Framework.Core == nil and tries < 150 do
        -- Qbox first so we don't latch onto the QBCore bridge when the
        -- real framework is actually Qbox.
        if (cfg == "auto" or cfg == "qbox") and GetResourceState('qbx_core') == 'started' then
            Framework.Name, Framework.Core = "qbox", exports.qbx_core
            print("^2[tm-multiscript]^0 Qbox initialized on client^7")
            break
        end
        if (cfg == "auto" or cfg == "qbcore") and GetResourceState('qb-core') == 'started' then
            local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and core then
                Framework.Name, Framework.Core = "qbcore", core
                QBCore = core -- keep legacy alias in sync
                print("^2[tm-multiscript]^0 QBCore initialized on client^7")
                break
            end
        end
        if (cfg == "auto" or cfg == "esx") and GetResourceState('es_extended') == 'started' then
            local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
            if ok and core then
                Framework.Name, Framework.Core = "esx", core
                print("^2[tm-multiscript]^0 ESX initialized on client^7")
                break
            end
        end
        Citizen.Wait(100)
        tries = tries + 1
    end
end)

function Framework.Notify(msg, typ, duration)
    typ = typ or 'inform'
    duration = duration or 5000
    if Framework.Name == "qbox" then
        -- Qbox canonically ships with ox_lib; use its notify if present.
        if GetResourceState('ox_lib') == 'started' then
            exports.ox_lib:notify({
                title = 'tm-multiscript',
                description = msg,
                type = typ,
                duration = duration
            })
            return
        end
        -- Fallback: Qbox bridges QBCore notify too.
        TriggerEvent('QBCore:Notify', msg, typ, duration)
        return
    end
    if Framework.Name == "qbcore" and Framework.Core then
        Framework.Core.Functions.Notify(msg, typ, duration)
    elseif Framework.Name == "esx" and Framework.Core then
        Framework.Core.ShowNotification(msg)
    else
        TriggerEvent('chat:addMessage', { args = { '[tm-multiscript]', msg } })
    end
end

function Framework.GetPlayerData()
    if Framework.Name == "qbox" and Framework.Core then
        local ok, data = pcall(function() return Framework.Core:GetPlayerData() end)
        if ok and data then return data end
        return nil
    elseif Framework.Name == "qbcore" and Framework.Core then
        return Framework.Core.Functions.GetPlayerData()
    elseif Framework.Name == "esx" and Framework.Core then
        return Framework.Core.GetPlayerData()
    end
    return nil
end

-- =========================
-- tirepop/client.lua
-- =========================
-- Configuration values are now pulled from Config.Modules.tirepop

local tireIndices = {
    [0] = 0,    -- Front Left
    [1] = 1,    -- Front Right
    [2] = 4,    -- Back Left
    [3] = 5,    -- Back Right
}

function PlayBulletImpactSound(coords)
    PlaySoundFromCoord(-1, "10_Sec_Warning", coords.x, coords.y, coords.z, "MP_MISSION_COUNTDOWN_SOUNDSET", false, 20, false)
    ShootSingleBulletBetweenCoords(
        coords.x, coords.y, coords.z + 5.0,
        coords.x, coords.y, coords.z,
        0,
        false,
        GetHashKey("WEAPON_SNSPISTOL"),
        PlayerPedId(),
        true,
        false,
        800.0
    )
    UseParticleFxAssetNextCall("core")
    StartParticleFxNonLoopedAtCoord("bullet_tracer", 
        coords.x, coords.y, coords.z, 
        0.0, 0.0, 0.0, 0.1, false, false, false)
end

RegisterNetEvent('tirepop:popTire')
AddEventHandler('tirepop:popTire', function(tireIndex)
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(player), 5.0, 0, 70)
    end
    if vehicle ~= 0 then
        local wheelIndex = tireIndices[tireIndex]
        local vehicleCoords = GetEntityCoords(vehicle)
        PlayBulletImpactSound(vehicleCoords)
        SetVehicleTyreBurst(vehicle, wheelIndex, true, 1000.0)
    end
end)

RegisterNetEvent('tirepop:clientPlayGunshot')
AddEventHandler('tirepop:clientPlayGunshot', function(coords)
    PlayBulletImpactSound(coords)
end)

RegisterNetEvent('tirepop:repairTires')
AddEventHandler('tirepop:repairTires', function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(player), 5.0, 0, 70)
    end
    if vehicle ~= 0 then
        for i=0, 5 do
            SetVehicleTyreFixed(vehicle, i)
        end
    end
end)

RegisterCommand(ModuleCmd('tirepop', 'fix', 'tirefix'), function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    if vehicle ~= 0 then
        for i=0, 5 do
            SetVehicleTyreFixed(vehicle, i)
        end
    end
end, false)

-- =========================
-- streetnames/client.lua
-- =========================
print ("Successfully loaded Road Name Editor by Buckley Modifications")
AddTextEntryByHash(0xD631D46B, "Julius Vincent Boulevard")
AddTextEntryByHash(0xD0F42F52, "Julius Vincent Boulevard")
AddTextEntryByHash(0xA2854172, "Julius Vincent Boulevard")
--AddTextEntryByHash(hash, 'CHANGE ME')
--AddTextEntryByHash(hash, 'CHANGE ME')
--AddTextEntryByHash(hash, 'CHANGE ME')

-- =========================
-- sped/client.lua
-- =========================
local beepEnabled = Config.Modules.sped.beepEnabled
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        if beepEnabled then
            PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
        end
    end
end)
RegisterNetEvent('sped:explodePlayer')
AddEventHandler('sped:explodePlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    AddExplosionWithUserVfx(coords.x, coords.y, coords.z, 2, 100.0, true, false, 1.0)
end)
RegisterNetEvent('sped:throwGrenadeAtPlayer')
AddEventHandler('sped:throwGrenadeAtPlayer', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local peds = GetGamePool('CPed')
    local closestPed = nil
    local closestDist = 999.0
    for _, ped in ipairs(peds) do
        if ped ~= playerPed and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
            local pedCoords = GetEntityCoords(ped)
            local dist = #(pedCoords - playerCoords)
            if dist < closestDist and dist < 30.0 then
                closestDist = dist
                closestPed = ped
            end
        end
    end
    if closestPed then
        GiveWeaponToPed(closestPed, `WEAPON_GRENADE`, 1, false, true)
        TaskTurnPedToFaceEntity(closestPed, playerPed, 1000)
        Citizen.Wait(1000)
        SetCurrentPedWeapon(closestPed, `WEAPON_GRENADE`, true)
        local targetCoords = GetEntityCoords(playerPed)
        TaskThrowProjectile(closestPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, 0)
    end
end)
RegisterNetEvent('sped:seeGrenadeNotification')
AddEventHandler('sped:seeGrenadeNotification', function()
    print("[DEBUG] Received seeGrenadeNotification event on client")
    Framework.Notify('You notice a grenade in their back pocket', 'error', 5000)
end)

-- =========================
-- slide/client.lua
-- =========================
RegisterNetEvent('slideCar:applyForce', function(playerId)
    local playerPed = GetPlayerPed(GetPlayerFromServerId(playerId))
    if DoesEntityExist(playerPed) and IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local heading = GetEntityHeading(vehicle)
        local radians = math.rad(heading)
        local rightVector = {
            x = math.cos(radians + math.pi / 2),
            y = math.sin(radians + math.pi / 2)
        }
        local forceAmount = Config.Modules.slide.forceAmount
        ApplyForceToEntity(vehicle, 1, rightVector.x * forceAmount, rightVector.y * forceAmount, 0.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
    end
end)

-- =========================
-- permclean/client.lua
-- =========================
-- Track state per-vehicle (by netId) so the toggle always reflects the
-- status of the car you're currently sitting in, not a single global flag.
local permCleanVehicles = {}
local permFixVehicles = {}
RegisterCommand(ModuleCmd('permclean', 'clean', 'permclean'), function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        TriggerEvent("permvehicle:notify", "You are not in a vehicle.")
        return
    end
    local netId = VehToNet(veh)
    local newState = not permCleanVehicles[netId]
    permCleanVehicles[netId] = newState or nil
    TriggerServerEvent("permvehicle:setCleanState", netId, newState)
    TriggerEvent("permvehicle:notify", "Permanent clean " .. (newState and "enabled." or "disabled.") .. " for this vehicle.")
end)
RegisterCommand(ModuleCmd('permclean', 'fix', 'permfix'), function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        TriggerEvent("permvehicle:notify", "You are not in a vehicle.")
        return
    end
    local netId = VehToNet(veh)
    local newState = not permFixVehicles[netId]
    permFixVehicles[netId] = newState or nil
    TriggerServerEvent("permvehicle:setFixState", netId, newState)
    TriggerEvent("permvehicle:notify", "Permanent fix " .. (newState and "enabled." or "disabled.") .. " for this vehicle.")
end)
RegisterNetEvent("permvehicle:doFix")
AddEventHandler("permvehicle:doFix", function(netId)
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end

    -- Only the network owner can actually fix the vehicle and have it sync
    -- to everyone else (driver, passengers, nearby players). If we're not
    -- the owner, try to grab control for a short window; if we can't, bail
    -- out silently so the real owner handles it on their end.
    if not NetworkHasControlOfEntity(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        local tries = 0
        while not NetworkHasControlOfEntity(vehicle) and tries < 10 do
            Wait(20)
            tries = tries + 1
        end
        if not NetworkHasControlOfEntity(vehicle) then return end
    end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    print("[permvehicle] Vehicle fixed (netId: " .. netId .. ")")
end)
RegisterNetEvent("permvehicle:doClean")
AddEventHandler("permvehicle:doClean", function(netId)
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end

    if not NetworkHasControlOfEntity(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        local tries = 0
        while not NetworkHasControlOfEntity(vehicle) and tries < 10 do
            Wait(20)
            tries = tries + 1
        end
        if not NetworkHasControlOfEntity(vehicle) then return end
    end

    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
    print("[permvehicle] Vehicle cleaned (netId: " .. netId .. ")")
end)
RegisterNetEvent("permvehicle:notify")
AddEventHandler("permvehicle:notify", function(msg)
    print("[permvehicle] " .. msg)
    TriggerEvent("chat:addMessage", {
        args = { "[permvehicle]", msg }
    })
end)

-- Rebuild our per-vehicle memory from the server (handles resource restart /
-- reconnect so the next /permfix or /permclean correctly toggles OFF a car
-- that's already tracked server-side).
RegisterNetEvent("permvehicle:syncState")
AddEventHandler("permvehicle:syncState", function(cleanList, fixList)
    permCleanVehicles = {}
    permFixVehicles = {}
    for _, netId in ipairs(cleanList or {}) do permCleanVehicles[netId] = true end
    for _, netId in ipairs(fixList or {}) do permFixVehicles[netId] = true end
end)

AddEventHandler("onClientResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        TriggerServerEvent("permvehicle:requestState")
    end
end)

-- =========================
-- npcgun/client.lua
-- =========================
RegisterNetEvent('qb-aig:client:attack', function(targetServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    if targetServerId ~= myServerId then return end
    
    local targetPed = PlayerPedId()
    local targetCoords = GetEntityCoords(targetPed)
    local attackRadius = Config.Modules.npcgun and Config.Modules.npcgun.attackRadius or 30.0
    
    -- Find a nearby pedestrian to attack the player
    local closestPed, pedDist = nil, attackRadius
    local handle, ped = FindFirstPed()
    local success
    repeat
        if ped ~= targetPed 
           and not IsPedAPlayer(ped) 
           and not IsPedInAnyVehicle(ped) 
           and not IsEntityDead(ped) then
            local dist = #(targetCoords - GetEntityCoords(ped))
            if dist < pedDist then
                closestPed, pedDist = ped, dist
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    
    if closestPed then
        if Config.Modules.npcgun and Config.Modules.npcgun.debug then
            print("[npcgun] Found pedestrian to attack player")
        end
        GiveWeaponToPed(closestPed, GetHashKey('weapon_pistol'), 255, false, true)
        TaskCombatPed(closestPed, targetPed, 0, 16)
    end
    
    -- Also make vehicle occupants attack the player
    local closestVeh = GetClosestVehicle(targetCoords.x, targetCoords.y, targetCoords.z, attackRadius, 0, 70)
    if DoesEntityExist(closestVeh) then
        local attackedCount = 0
        local maxSeats = GetVehicleMaxNumberOfPassengers(closestVeh)
        for seat = -1, maxSeats do
            local occ = GetPedInVehicleSeat(closestVeh, seat)
            if occ ~= 0 and not IsPedAPlayer(occ) and not IsEntityDead(occ) then
                TaskLeaveVehicle(occ, closestVeh, 0)
                Citizen.Wait(500)
                GiveWeaponToPed(occ, GetHashKey('weapon_pistol'), 255, false, true)
                TaskCombatPed(occ, targetPed, 0, 16)
                attackedCount = attackedCount + 1
                if Config.Modules.npcgun and Config.Modules.npcgun.debug then
                    print("[npcgun] Vehicle occupant is now attacking player")
                end
            end
        end
    end
end)

-- =========================
-- nights_erss/client.lua
-- =========================
local shootEnabled = false
local radius = Config.Modules.nights_erss.radius
local processedPeds = {}
RegisterCommand(ModuleCmd('nights_erss', 'toggle', 'toggleShoot'), function(source, args)
    shootEnabled = not shootEnabled
    if shootEnabled then
        print("[AI Shootout] Shooting mode enabled")
        TriggerShootingMode()
    else
        print("[AI Shootout] Shooting mode disabled")
        CancelShootingMode()
        processedPeds = {}
    end
end, false)
function TriggerShootingMode()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local peds = GetNearbyPeds(playerCoords, radius)
    print("[AI Shootout] Found " .. #peds .. " peds in range for immediate assignment")
    math.randomseed(GetGameTimer())
    for _, ped in ipairs(peds) do
        if not IsPedAPlayer(ped) then
            processedPeds[ped] = true
            local weaponHash = GetHashKey("weapon_pistol")
            GiveWeaponToPed(ped, weaponHash, 100, false, true)
            local target = GetRandomTarget(ped, peds)
            if target then
                TaskCombatPed(ped, target, 0, 16)
                print("[AI Shootout] Ped " .. tostring(ped) .. " attacking ped " .. tostring(target))
            else
                print("[AI Shootout] No valid target found for ped " .. tostring(ped))
            end
        end
    end
end
function CancelShootingMode()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local peds = GetNearbyPeds(playerCoords, radius)
    for _, ped in ipairs(peds) do
        if not IsPedAPlayer(ped) then
            ClearPedTasks(ped)
        end
    end
end
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if shootEnabled then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local peds = GetNearbyPeds(playerCoords, radius)
            math.randomseed(GetGameTimer())
            for _, ped in ipairs(peds) do
                if not IsPedAPlayer(ped) and not processedPeds[ped] then
                    processedPeds[ped] = true
                    local weaponHash = GetHashKey("weapon_pistol")
                    GiveWeaponToPed(ped, weaponHash, 100, false, true)
                    local target = GetRandomTarget(ped, peds)
                    if target then
                        TaskCombatPed(ped, target, 0, 16)
                        print("[AI Shootout] New ped " .. tostring(ped) .. " attacking ped " .. tostring(target))
                    else
                        print("[AI Shootout] New ped " .. tostring(ped) .. " has no valid target")
                    end
                end
            end
            for ped, _ in pairs(processedPeds) do
                if not DoesEntityExist(ped) or Vdist(GetEntityCoords(ped), playerCoords) > radius then
                    processedPeds[ped] = nil
                end
            end
        end
    end
end)
function GetNearbyPeds(coords, radius)
    local peds = {}
    for _, ped in ipairs(GetGamePool("CPed")) do
        if ped ~= PlayerPedId() then
            local pedCoords = GetEntityCoords(ped)
            if Vdist(pedCoords.x, pedCoords.y, pedCoords.z, coords.x, coords.y, coords.z) <= radius then
                table.insert(peds, ped)
            end
        end
    end
    return peds
end
function GetRandomTarget(currentPed, pedList)
    local potentialTargets = {}
    for _, ped in ipairs(pedList) do
        if ped ~= currentPed then
            table.insert(potentialTargets, ped)
        end
    end
    if #potentialTargets > 0 then
        local index = math.random(1, #potentialTargets)
        return potentialTargets[index]
    end
    return nil
end

-- =========================
-- monkeycar/client.lua
-- =========================
if Config.Debug or (Config.Modules.monkeycar and Config.Modules.monkeycar.debug) then
    print("[DEBUG] Resource root is: " .. GetCurrentResourceName())
end
local carModels = CarModels
if Config.Modules.monkeycar and Config.Modules.monkeycar.enabled then
    RegisterCommand(ModuleCmd('monkeycar', 'spawn', 'monkeycar'), function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local randomIndex = math.random(1, #carModels)
        local vehicleModel = GetHashKey(carModels[randomIndex])
        local pedModel = GetHashKey('a_c_chimp')
        if Config.Debug or (Config.Modules.monkeycar and Config.Modules.monkeycar.debug) then
            print("[Monkeycar Debug] Spawning vehicle:", carModels[randomIndex])
        end
        RequestModel(vehicleModel)
        while not HasModelLoaded(vehicleModel) do
            Wait(100)
        end
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(100)
        end
        local found, roadCoords = GetNthClosestVehicleNode(playerCoords.x, playerCoords.y, playerCoords.z, math.random(1, 10), 0, 0, 0)
        if not found then
            print("Could not find a road node!")
            return
        end
        local vehicle = CreateVehicle(vehicleModel, roadCoords.x, roadCoords.y, roadCoords.z, GetEntityHeading(playerPed), true, false)
        SetVehicleOnGroundProperly(vehicle)
        local monkey = CreatePedInsideVehicle(vehicle, 4, pedModel, -1, true, false)
        TaskVehicleDriveWander(monkey, vehicle, 20.0, 786603)
        SetModelAsNoLongerNeeded(vehicleModel)
        SetModelAsNoLongerNeeded(pedModel)
        TriggerEvent('chat:addMessage', {
            args = { '^2Monkey spawned driving a random car!' }
        })
    end)
end

-- =========================
-- jerk/client.lua
-- =========================
if Config.Modules.jerk and Config.Modules.jerk.enabled then
    RegisterCommand(ModuleCmd('jerk', 'play', 'jerk'), function()
        local playerPed = PlayerPedId()
        local animDict = "switch@trevor@jerking_off"
        local animName = "trev_jerking_off_loop"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(100)
        end
        TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
        Citizen.Wait(5000)
        ClearPedTasks(playerPed)
    end, false)
end

-- =========================
-- hijab/client.lua
-- =========================
RegisterNetEvent('qb-hijacker:spawnHijacker')
AddEventHandler('qb-hijacker:spawnHijacker', function(sourcePlayer)
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)
    local hijackerModel = GetHashKey("a_m_m_fatlatin_01")
    RequestModel(hijackerModel)
    while not HasModelLoaded(hijackerModel) do
        Wait(100)
    end
    local spawnCoords = pedCoords + vector3(-10.0, -10.0, 0.0)
    local hijackerPed = CreatePed(4, hijackerModel, spawnCoords, 0.0, true, false)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if DoesEntityExist(vehicle) then
        TaskGoToEntity(hijackerPed, vehicle, -1, 5.0, 2.0, 1073741824.0, 0)
        Wait(5000)
        local maxAttempts = Config.Modules.hijab.maxAttempts
        local enteredVehicle = false
        local attempts = 0
        while not enteredVehicle and attempts < maxAttempts do
            TaskEnterVehicle(hijackerPed, vehicle, -1, -1, 2.0, 16, 0)
            Wait(5000)
            if IsPedInVehicle(hijackerPed, vehicle, false) then
                enteredVehicle = true
            else
                attempts = attempts + 1
                TriggerServerEvent('hijacker:attemptNotify', sourcePlayer, attempts)
            end
        end
        if enteredVehicle then
            local driveAwayCoords = spawnCoords + vector3(100.0, 100.0, 0.0)
            TaskVehicleDriveToCoord(hijackerPed, vehicle, driveAwayCoords, 20.0, 1.0, GetEntityModel(vehicle), 786603, 1, true)
        else
            TriggerServerEvent('hijacker:failedNotify', sourcePlayer)
        end
        SetModelAsNoLongerNeeded(hijackerModel)
    else
        TriggerServerEvent('hijacker:noVehicleNotify', sourcePlayer)
    end
end)

-- =========================
-- fuel/cl_fuel.lua
-- =========================
RegisterNetEvent('custom-fuel:depleteFuel', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        if exports['LegacyFuel'] then
            exports['LegacyFuel']:SetFuel(vehicle, 0.0)
        else
            print("LegacyFuel export not found.")
            Framework.Notify("Fuel system error", "error")
        end
    else
        Framework.Notify("You are not in a vehicle", "error")
    end
end)

-- =========================
-- fatjack/client/client.lua
-- =========================
local function DebugNotify(message, type)
    if Config.Modules.fatjack and Config.Modules.fatjack.debug then
        Framework.Notify(message, type)
    end
end
RegisterNetEvent('qb-hijack:client:Hijack', function(targetId)
    local targetClientId = GetPlayerFromServerId(targetId)
    if targetClientId == -1 then
        DebugNotify("Target not found.", "error")
        return
    end
    local targetPed = GetPlayerPed(targetClientId)
    if not DoesEntityExist(targetPed) then
        DebugNotify("Target ped not found.", "error")
        return
    end

    -- Resolve a target vehicle. Try current vehicle first, then the last
    -- vehicle they were in. This is what enables "/fatjack right before they
    -- get out at a store": even if they've already opened the door, the
    -- engine is on the way out, etc., we still grab the right car.
    local targetVeh = GetVehiclePedIsIn(targetPed, false)
    if targetVeh == 0 then
        targetVeh = GetVehiclePedIsIn(targetPed, true) -- last vehicle
    end
    if targetVeh == 0 or not DoesEntityExist(targetVeh) then
        DebugNotify("Target has no current or recent vehicle.", "error")
        return
    end

    -- Pull configurable parameters with sensible defaults so old configs
    -- (or a missing fatjack module entry) don't break the command.
    local fjCfg            = (Config.Modules and Config.Modules.fatjack) or {}
    local baseDistance     = fjCfg.spawnDistance or 35.0
    local distanceJitter   = fjCfg.spawnDistanceJitter or 8.0
    local snapToRoad       = (fjCfg.snapToRoad ~= false) -- default true
    local approachSpeed    = fjCfg.approachSpeed or 4.0
    local waitForExit      = (fjCfg.waitForExit ~= false) -- default true: chill mode
    local waitTimeout      = fjCfg.waitTimeout or 60000
    local approachTimeout  = fjCfg.approachTimeout or 60000

    -- Spawn position is anchored to the VEHICLE (not the player) so that the
    -- ped appears near the parked car even if the target has already walked
    -- a short distance away.
    local vehCoords = GetEntityCoords(targetVeh)
    local vehHeading = GetEntityHeading(targetVeh)
    local rearHeading = (vehHeading + 180.0) % 360.0
    local angleDeg = rearHeading + (math.random() * 180.0 - 90.0) -- +/-90deg cone behind the car
    local angleRad = math.rad(angleDeg)
    local distance = baseDistance + (math.random() * 2.0 - 1.0) * distanceJitter

    local sx = vehCoords.x + math.sin(-angleRad) * distance
    local sy = vehCoords.y + math.cos(-angleRad) * distance
    local sz = vehCoords.z

    if snapToRoad then
        local found, nodeCoords = GetClosestVehicleNode(sx, sy, sz, 1, 3.0, 0)
        if found then
            sx, sy, sz = nodeCoords.x, nodeCoords.y, nodeCoords.z
        end
    end

    local groundFound, groundZ = GetGroundZFor_3dCoord(sx, sy, sz + 5.0, false)
    if groundFound then sz = groundZ end

    local fatModel = GetHashKey("a_m_m_fatlatin_01")
    RequestModel(fatModel)
    while not HasModelLoaded(fatModel) do
        Wait(10)
    end

    local facingHeading = math.deg(math.atan2(vehCoords.y - sy, vehCoords.x - sx)) - 90.0
    local fatPed = CreatePed(4, fatModel, sx, sy, sz, facingHeading, true, false)
    DebugNotify("Fat ped spawned!", "success")
    SetEntityInvincible(fatPed, true)
    SetBlockingOfNonTemporaryEvents(fatPed, true)

    -- Initial walk task: head toward the vehicle's current position.
    TaskGoStraightToCoord(fatPed, vehCoords.x, vehCoords.y, vehCoords.z, approachSpeed, -1, 0.0, 0.0)

    local spawnTime = GetGameTimer()
    local lastRetask = spawnTime

    CreateThread(function()
        while true do
            Wait(500)

            -- Bail if the vehicle has been deleted (despawned, blown up, etc.)
            if not DoesEntityExist(targetVeh) then
                DebugNotify("Hijack failed: Target vehicle no longer exists.", "error")
                if DoesEntityExist(fatPed) then DeleteEntity(fatPed) end
                return
            end

            local currentVehCoords = GetEntityCoords(targetVeh)
            local fatCoords = GetEntityCoords(fatPed)
            local distToVeh = #(fatCoords - currentVehCoords)

            -- If the car keeps moving (target is still driving around), re-task
            -- the ped every couple seconds so it follows instead of marching to
            -- a stale destination.
            if (GetGameTimer() - lastRetask) > 2000 and distToVeh > 6.0 then
                TaskGoStraightToCoord(fatPed, currentVehCoords.x, currentVehCoords.y, currentVehCoords.z, approachSpeed, -1, 0.0, 0.0)
                lastRetask = GetGameTimer()
            end

            -- Approach timeout: ped has been walking for too long without
            -- reaching the vehicle. Probably the target sped off too far.
            if (GetGameTimer() - spawnTime) > approachTimeout and distToVeh > 6.0 then
                DebugNotify("Hijack failed: Could not reach the vehicle in time.", "error")
                if DoesEntityExist(fatPed) then DeleteEntity(fatPed) end
                return
            end

            -- We're at the vehicle. Now decide what to do.
            if distToVeh < 6.0 then
                local driverSeatPed = GetPedInVehicleSeat(targetVeh, -1)
                local driverIsPlayer = (driverSeatPed == targetPed)

                if driverSeatPed ~= 0 and driverSeatPed ~= fatPed then
                    -- Someone (probably the target) is still in the driver's seat.
                    if waitForExit then
                        -- Chill mode: idle nearby and wait. Re-issue a "go to"
                        -- task occasionally so the ped doesn't drift, but
                        -- don't yank anybody out.
                        if (GetGameTimer() - spawnTime) > waitTimeout then
                            DebugNotify("Hijack failed: Driver never left the vehicle.", "error")
                            if DoesEntityExist(fatPed) then DeleteEntity(fatPed) end
                            return
                        end
                        ClearPedTasks(fatPed)
                        TaskGoStraightToCoord(fatPed, currentVehCoords.x, currentVehCoords.y, currentVehCoords.z, 1.0, -1, 0.0, 0.0)
                    else
                        -- Aggressive mode: yank the driver out (old behavior).
                        DebugNotify("Hijack: Yanking driver out!", "success")
                        SetVehicleDoorOpen(targetVeh, 0, false, false)
                        Wait(500)
                        if driverIsPlayer then
                            TaskLeaveVehicle(driverSeatPed, targetVeh, 0)
                            SetPedToRagdoll(driverSeatPed, 1500, 1500, 0, false, false, false)
                        end
                        Wait(1500)
                    end
                else
                    -- Driver's seat is empty -- steal the car!
                    DebugNotify("Hijack: Vehicle empty, stealing it now.", "success")
                    TaskEnterVehicle(fatPed, targetVeh, 8000, -1, 2.0, 1, 0)
                    Wait(3000)

                    -- Once seated (or after the entry timeout), drive away.
                    local fatPedVeh = GetVehiclePedIsIn(fatPed, false)
                    if fatPedVeh == targetVeh then
                        TaskVehicleDriveWander(fatPed, targetVeh, 60.0, 786603)
                        DebugNotify("Hijack: Fat ped is speeding away!", "success")
                    else
                        DebugNotify("Hijack: Fat ped failed to enter the vehicle.", "error")
                        if DoesEntityExist(fatPed) then DeleteEntity(fatPed) end
                    end
                    return
                end
            end
        end
    end)
end)

-- =========================
-- dirty/client.lua
-- =========================
RegisterCommand(ModuleCmd('dirty', 'dirty', 'dirty'), function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        local dirtLevel = Config.Modules.dirty and Config.Modules.dirty.dirtLevel or 15.0
        local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
        -- Server gates this on permission and broadcasts updateVehicleDirt
        -- back to everyone (including us). Don't apply locally first or an
        -- unauthorized player would still see their own car go dirty before
        -- getting the "no permission" notify back.
        TriggerServerEvent('syncVehicleDirt', vehicleNetId, dirtLevel)
    else
        Framework.Notify('You are not in a vehicle!', 'error', 5000)
    end
end, false)
RegisterNetEvent('updateVehicleDirt')
AddEventHandler('updateVehicleDirt', function(vehicleNetId, dirtLevel)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        SetVehicleDirtLevel(vehicle, dirtLevel)
    end
end)
TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('dirty', 'dirty', 'dirty'), 'Make your current vehicle dirty (syncs with all players)')

-- =========================
-- astley/client/main.lua
-- =========================
local isUIOpen = false
local isInZone = false
local rickRollCoords = vector3(199.66, -933.42, 30.69)
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(rickRollCoords)
    SetBlipSprite(blip, 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Secret Spot")
    EndTextCommandSetBlipName(blip)
end)
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local distance = #(coords - rickRollCoords)
        if distance < 20.0 then
            if distance < 2.0 then
                if not isInZone then
                    isInZone = true
                end
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to check this out!")
                EndTextCommandDisplayHelp(0, false, true, 1)
                if IsControlJustPressed(0, 38) then
                    if not isUIOpen then
                        OpenRickRollUI()
                    end
                end
            else
                if isInZone then
                    isInZone = false
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("")
                    EndTextCommandDisplayHelp(0, false, true, 1)
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(5000)
        end
    end
end)
function OpenRickRollUI()
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openRickRoll"
    })
end
function CloseRickRollUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closeRickRoll"
    })
end
RegisterNUICallback('closeUI', function(data, cb)
    CloseRickRollUI()
    cb('ok')
end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isUIOpen and IsControlJustPressed(0, 177) then
            CloseRickRollUI()
        end
    end
end)

-- =========================
-- joinfak/fakejoin.lua
-- =========================
RegisterCommand(ModuleCmd('joinfak', 'join', 'fakejoin'), function(source, args, rawCommand)
    TriggerServerEvent("joinfak:sendFakeJoin")
end, false)
RegisterCommand(ModuleCmd('joinfak', 'leave', 'fakeleave'), function(source, args, rawCommand)
    TriggerServerEvent("joinfak:sendFakeLeave")
end, false)

-- =========================
-- Command Suggestions
-- =========================
Citizen.CreateThread(function()
    -- Give the framework a moment to initialize before we check groups.
    Citizen.Wait(1000)

    -- Function to check if player has permission for a command (client-side
    -- best-effort check for whether to show chat suggestions; the server
    -- still enforces the real permission check).
    local function hasPermissionForCommand(command)
        -- Standalone mode: no way to reliably check client-side, so show all.
        if Framework.Name == "standalone" then return true end
        if not Config.CommandPermissions[command] then return true end

        local Player = Framework.GetPlayerData()
        if not Player then return false end

        local requiredPerm = Config.CommandPermissions[command]

        if Framework.Name == "qbcore" then
            local hierarchy = {"god", "admin", "mod", "user"}
            local requiredIndex
            for i, perm in ipairs(hierarchy) do
                if perm == requiredPerm then requiredIndex = i break end
            end
            if not requiredIndex then return false end
            for i = 1, requiredIndex do
                if hierarchy[i] == "user" then return true end
                if Player.permission == hierarchy[i] then return true end
            end
            return false
        end

        if Framework.Name == "esx" then
            local playerGroup = Player.group or "user"
            local neededGroup = (Config.ESXGroupMap and Config.ESXGroupMap[requiredPerm]) or "superadmin"
            local ranks = { superadmin = 4, admin = 3, mod = 2, user = 1 }
            return (ranks[playerGroup] or 0) >= (ranks[neededGroup] or 4)
        end

        if Framework.Name == "qbox" then
            -- Mirror the server-side check: read the local PlayerData.group
            -- and compare it against Config.QboxGroupMap. If we can't read
            -- the group (early load, missing field) fall back to showing
            -- the suggestion so the player isn't locked out cosmetically;
            -- the server still enforces the real check.
            local playerGroup = Player.group
                or (Player.metadata and Player.metadata.group)
            if not playerGroup then return true end

            local groupMap = Config.QboxGroupMap or { god = "admin", admin = "admin", mod = "mod", user = "user" }
            local groupRanks = { god = 1, admin = 2, mod = 3, user = 4 }
            local hierarchy = {"god", "admin", "mod", "user"}
            local requiredIndex
            for i, perm in ipairs(hierarchy) do
                if perm == requiredPerm then requiredIndex = i break end
            end
            if not requiredIndex then return false end

            for i = 1, requiredIndex do
                local tier = hierarchy[i]
                local mapped = groupMap[tier] or tier
                if tier == "user" or mapped == "user" then return true end
                if groupRanks[playerGroup] and groupRanks[playerGroup] <= (groupRanks[mapped] or 99) then
                    return true
                end
            end
            return false
        end

        return false
    end
    
    -- Tirepop module commands
    if Config.Modules.tirepop and Config.Modules.tirepop.enabled then
        if hasPermissionForCommand('tirepop') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('tirepop', 'pop', 'tirepop'), 'Pop a specific tire on a player\'s vehicle', {
                { name = 'id', help = 'Player ID (optional)' },
                { name = 'tire', help = '1-4 or front/rear/left/right/all' }
            })
        end
        
        if hasPermissionForCommand('repairalltires') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('tirepop', 'repair', 'repairalltires'), 'Repair all tires on a player\'s vehicle', {
                { name = 'id', help = 'Player ID (optional)' }
            })
        end
    end
    
    -- Slide module commands
    if Config.Modules.slide and Config.Modules.slide.enabled then
        if hasPermissionForCommand('slidecar') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('slide', 'slide', 'slidecar'), 'Make a player\'s car slide', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- SPED module commands
    if Config.Modules.sped and Config.Modules.sped.enabled then
        if hasPermissionForCommand('explode') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('sped', 'explode', 'explode'), 'Explode a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
        
        if hasPermissionForCommand('grenade') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('sped', 'grenade', 'grenade'), 'Throw a grenade at a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
        
        if hasPermissionForCommand('seegrenade') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('sped', 'seegrenade', 'seegrenade'), 'Send a grenade notification to a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- Permanent Clean/Fix module commands
    if Config.Modules.permclean and Config.Modules.permclean.enabled then
        if hasPermissionForCommand('permclean') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('permclean', 'clean', 'permclean'), 'Toggle permanent clean for your vehicle')
        end
        
        if hasPermissionForCommand('permfix') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('permclean', 'fix', 'permfix'), 'Toggle permanent fix for your vehicle')
        end
        
        if hasPermissionForCommand('tirefix') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('tirepop', 'fix', 'tirefix'), 'Fix all tires on your vehicle')
        end
    end
    
    -- Fake Join/Leave module commands
    if Config.Modules.joinfak and Config.Modules.joinfak.enabled then
        if hasPermissionForCommand('fakejoin') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('joinfak', 'join', 'fakejoin'), 'Send a fake join message')
        end
        
        if hasPermissionForCommand('fakeleave') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('joinfak', 'leave', 'fakeleave'), 'Send a fake leave message')
        end
    end
    
    -- Client Drop module commands
    if Config.Modules.clientdrop and Config.Modules.clientdrop.enabled then
        if hasPermissionForCommand('client') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('clientdrop', 'drop', 'client'), 'Drop a player from the server', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- NPC Gun module commands
    if Config.Modules.npcgun and Config.Modules.npcgun.enabled then
        if hasPermissionForCommand('aig') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('npcgun', 'attack', 'aig'), 'Make nearby NPCs attack a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- Night's ERSS module commands
    if Config.Modules.nights_erss and Config.Modules.nights_erss.enabled then
        if hasPermissionForCommand('tgshoot') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('nights_erss', 'info', 'tgshoot'), 'Get info about the AI shootout mode')
        end
        
        if hasPermissionForCommand('toggleShoot') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('nights_erss', 'toggle', 'toggleShoot'), 'Toggle AI shootout mode')
        end
    end
    
    -- Hijab module commands
    if Config.Modules.hijab and Config.Modules.hijab.enabled then
        if hasPermissionForCommand('hijack') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('hijab', 'hijack', 'hijack'), 'Send a hijacker to steal a player\'s vehicle', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- FatJack module commands
    if Config.Modules.fatjack and Config.Modules.fatjack.enabled then
        if hasPermissionForCommand('fatjack') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('fatjack', 'jack', 'fatjack'), 'Send a fat person to hijack a player\'s vehicle', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end

    -- Fuel module commands
    if Config.Modules.fuel and Config.Modules.fuel.enabled then
        if hasPermissionForCommand('nofuel') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('fuel', 'deplete', 'nofuel'), 'Deplete a player\'s vehicle fuel', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end

    -- Jerk module commands
    if Config.Modules.jerk and Config.Modules.jerk.enabled then
        if hasPermissionForCommand('jerk') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('jerk', 'play', 'jerk'), 'Play a special animation')
        end

        if hasPermissionForCommand('jerkify') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('jerk', 'send', 'jerkify'), 'Send jerk command info to a player', {
                { name = 'id', help = 'Player ID (optional)' }
            })
        end
    end
    
    -- Dirty module commands
    if Config.Modules.dirty and Config.Modules.dirty.enabled then
        if hasPermissionForCommand('dirty') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('dirty', 'dirty', 'dirty'), 'Make your current vehicle dirty')
        end
    end
    
    -- Window Tint module commands
    if Config.Modules.tint and Config.Modules.tint.enabled then
        if hasPermissionForCommand('tint') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('tint', 'tint', 'tint'), 'Apply window tint to your vehicle', {
                { name = 'level', help = '0=None, 1=Limo, 2=Light Smoke, 3=Dark Smoke, 4=Stock, 5=Pure Black, 6=Green' }
            })
        end
    end
    
    -- Monkeycar module commands
    if Config.Modules.monkeycar and Config.Modules.monkeycar.enabled then
        if hasPermissionForCommand('monkeycar') then
            TriggerEvent('chat:addSuggestion', '/' .. ModuleCmd('monkeycar', 'spawn', 'monkeycar'), 'Spawn a monkey driving a random car')
        end
    end

    -- /tmhelp (or whatever Config.HelpCommand is set to)
    if hasPermissionForCommand('tmhelp') then
        local helpCmd = (Config.HelpCommand and Config.HelpCommand ~= "" and Config.HelpCommand) or 'tmhelp'
        TriggerEvent('chat:addSuggestion', '/' .. helpCmd, 'List every command from currently-enabled modules')
    end
end)

-- =========================
-- tint/client.lua
-- =========================
RegisterCommand(ModuleCmd('tint', 'tint', 'tint'), function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        Framework.Notify('You need to be in a vehicle to use this command!', 'error', 5000)
        return
    end
    
    local tintLevel = tonumber(args[1])
    -- If no tint level is specified, use the default from config
    if not tintLevel then
        tintLevel = Config.Modules.tint and Config.Modules.tint.defaultTint or 1
    end
    
    -- Validate tint level (0-6 are valid window tints in GTA V)
    if tintLevel < 0 or tintLevel > 6 then
        Framework.Notify('Invalid tint level! Use a value between 0-6.', 'error', 5000)
        return
    end
    
    -- Apply mods directly
    SetVehicleModKit(vehicle, 0)
    SetVehicleWindowTint(vehicle, tintLevel)
    
    -- Force a refresh
    local modIndex = GetVehicleMod(vehicle, 0)
    SetVehicleMod(vehicle, 0, modIndex)
    
    -- Send to server for syncing with other players
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('syncVehicleTint', vehicleNetId, tintLevel)
    
    -- Notify the player with the actual tint name
    local tintNames = {
        [0] = "None",
        [1] = "Limo",
        [2] = "Light Smoke",
        [3] = "Dark Smoke", 
        [4] = "Stock",
        [5] = "Pure Black",
        [6] = "Green"
    }
    
    local tintName = tintNames[tintLevel] or "Unknown"
    Framework.Notify('Window tint applied: ' .. tintName, 'success', 5000)
end, false)

-- Event to update vehicle tint when synced from server
RegisterNetEvent('updateVehicleTint')
AddEventHandler('updateVehicleTint', function(vehicleNetId, tintLevel)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        -- Apply the tint with mod kit
        SetVehicleModKit(vehicle, 0)
        SetVehicleWindowTint(vehicle, tintLevel)
        
        -- Force a refresh
        local modIndex = GetVehicleMod(vehicle, 0)
        SetVehicleMod(vehicle, 0, modIndex)
        
        if Config.Modules.tint and Config.Modules.tint.debug then
            print("[tint] Updated tint for vehicle " .. vehicleNetId .. " to level " .. tintLevel)
        end
    end
end) 