if GetCurrentResourceName() ~= "tm-multiscript" then
    print("^3[tm-multiscript]^1 ERROR: Don't rename the resource!^7")
    return
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

RegisterCommand('tirefix', function()
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
RegisterCommand("permclean", function()
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
RegisterCommand("permfix", function()
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
RegisterCommand("toggleShoot", function(source, args)
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
    RegisterCommand('monkeycar', function()
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
RegisterCommand("jerk", function()
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
    local targetVeh = GetVehiclePedIsIn(targetPed, false)
    if targetVeh == 0 then
        DebugNotify("Target is not in a vehicle.", "error")
        return
    end
    local targetCoords = GetEntityCoords(targetPed)
    local spawnCoords = vector3(targetCoords.x + 10.0, targetCoords.y + 10.0, targetCoords.z)
    local fatModel = GetHashKey("a_m_m_fatlatin_01")
    RequestModel(fatModel)
    while not HasModelLoaded(fatModel) do
        Wait(10)
    end
    local fatPed = CreatePed(4, fatModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    DebugNotify("Fat ped spawned!", "success")
    SetEntityInvincible(fatPed, true)
    SetBlockingOfNonTemporaryEvents(fatPed, true)
    TaskGoStraightToCoord(fatPed, targetCoords.x, targetCoords.y, targetCoords.z, 10.0, -1, 0.0, 0.0)
    local spawnTime = GetGameTimer()
    local attemptedHijack = false
    CreateThread(function()
        while true do
            Wait(500)
            local fatCoords = GetEntityCoords(fatPed)
            local dist = #(fatCoords - targetCoords)
            if dist < 5.0 and not attemptedHijack then
                attemptedHijack = true
                DebugNotify("Hijack: Initiating carjack sequence", "success")
                SetVehicleDoorOpen(targetVeh, 0, false, false)
                Wait(500)
                local animDict = "veh@break_in@0h@p_m_one@"
                local animName = "break_in_enter"
                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do
                    Wait(10)
                end
                TaskPlayAnim(fatPed, animDict, animName, 8.0, -8.0, 2500, 0, 0, false, false, false)
                Wait(2500)
                if GetVehiclePedIsIn(targetPed, false) ~= 0 then
                    TaskLeaveVehicle(targetPed, targetVeh, 0)
                    SetPedToRagdoll(targetPed, 1500, 1500, 0, false, false, false)
                end
                Wait(500)
                SetVehicleDoorShut(targetVeh, 0, false)
                Wait(500)
                TaskEnterVehicle(fatPed, targetVeh, 5000, -1, 2.0, 1, 0)
                DebugNotify("Hijack: Fat ped now entering driver's seat", "success")
                Wait(2000)
                TaskVehicleDriveWander(fatPed, targetVeh, 60.0, 786603)
                DebugNotify("Hijack: Fat ped is speeding away!", "success")
                break
            end
            if (GetGameTimer() - spawnTime) > 20000 and not IsPedInAnyVehicle(fatPed, false) then
                DebugNotify("Hijack failed: Fat ped despawned.", "error")
                DeleteEntity(fatPed)
                break
            end
        end
    end)
end)

-- =========================
-- dirty/client.lua
-- =========================
RegisterCommand("dirty", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        local dirtLevel = Config.Modules.dirty and Config.Modules.dirty.dirtLevel or 15.0
        SetVehicleDirtLevel(vehicle, dirtLevel)
        local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('syncVehicleDirt', vehicleNetId, dirtLevel)
        Framework.Notify('Your vehicle is now dirty!', 'success', 5000)
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
TriggerEvent('chat:addSuggestion', '/dirty', 'Make your current vehicle dirty (syncs with all players)')

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
RegisterCommand("fakejoin", function(source, args, rawCommand)
    TriggerServerEvent("joinfak:sendFakeJoin")
end, false)
RegisterCommand("fakeleave", function(source, args, rawCommand)
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
            -- Client-side group info isn't reliably exposed on Qbox; the
            -- server is the source of truth. Show suggestions to everyone
            -- here and let the server's HasPermission reject unauthorized
            -- use. (Players just won't be able to actually run it.)
            return true
        end

        return false
    end
    
    -- Tirepop module commands
    if Config.Modules.tirepop and Config.Modules.tirepop.enabled then
        if hasPermissionForCommand('tirepop') then
            TriggerEvent('chat:addSuggestion', '/tirepop', 'Pop a specific tire on a player\'s vehicle', {
                { name = 'id', help = 'Player ID (optional)' },
                { name = 'tire', help = '1-4 or front/rear/left/right/all' }
            })
        end
        
        if hasPermissionForCommand('repairalltires') then
            TriggerEvent('chat:addSuggestion', '/repairalltires', 'Repair all tires on a player\'s vehicle', {
                { name = 'id', help = 'Player ID (optional)' }
            })
        end
    end
    
    -- Slide module commands
    if Config.Modules.slide and Config.Modules.slide.enabled then
        if hasPermissionForCommand('slidecar') then
            TriggerEvent('chat:addSuggestion', '/slidecar', 'Make a player\'s car slide', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- SPED module commands
    if Config.Modules.sped and Config.Modules.sped.enabled then
        if hasPermissionForCommand('explode') then
            TriggerEvent('chat:addSuggestion', '/explode', 'Explode a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
        
        if hasPermissionForCommand('grenade') then
            TriggerEvent('chat:addSuggestion', '/grenade', 'Throw a grenade at a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
        
        if hasPermissionForCommand('seegrenade') then
            TriggerEvent('chat:addSuggestion', '/seegrenade', 'Send a grenade notification to a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- Permanent Clean/Fix module commands
    if Config.Modules.permclean and Config.Modules.permclean.enabled then
        if hasPermissionForCommand('permclean') then
            TriggerEvent('chat:addSuggestion', '/permclean', 'Toggle permanent clean for your vehicle')
        end
        
        if hasPermissionForCommand('permfix') then
            TriggerEvent('chat:addSuggestion', '/permfix', 'Toggle permanent fix for your vehicle')
        end
        
        TriggerEvent('chat:addSuggestion', '/tirefix', 'Fix all tires on your vehicle')
    end
    
    -- Fake Join/Leave module commands
    if Config.Modules.joinfak and Config.Modules.joinfak.enabled then
        if hasPermissionForCommand('fakejoin') then
            TriggerEvent('chat:addSuggestion', '/fakejoin', 'Send a fake join message')
        end
        
        if hasPermissionForCommand('fakeleave') then
            TriggerEvent('chat:addSuggestion', '/fakeleave', 'Send a fake leave message')
        end
    end
    
    -- Client Drop module commands
    if Config.Modules.clientdrop and Config.Modules.clientdrop.enabled then
        if hasPermissionForCommand('client') then
            TriggerEvent('chat:addSuggestion', '/client', 'Drop a player from the server', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- NPC Gun module commands
    if Config.Modules.npcgun and Config.Modules.npcgun.enabled then
        if hasPermissionForCommand('aig') then
            TriggerEvent('chat:addSuggestion', '/aig', 'Make nearby NPCs attack a player', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- Night's ERSS module commands
    if Config.Modules.nights_erss and Config.Modules.nights_erss.enabled then
        if hasPermissionForCommand('tgshoot') then
            TriggerEvent('chat:addSuggestion', '/tgshoot', 'Get info about the AI shootout mode')
        end
        
        TriggerEvent('chat:addSuggestion', '/toggleShoot', 'Toggle AI shootout mode')
    end
    
    -- Hijab module commands
    if Config.Modules.hijab and Config.Modules.hijab.enabled then
        if hasPermissionForCommand('hijack') then
            TriggerEvent('chat:addSuggestion', '/hijack', 'Send a hijacker to steal a player\'s vehicle', {
                { name = 'id', help = 'Player ID' }
            })
        end
    end
    
    -- FatJack module commands
    if hasPermissionForCommand('fatjack') then
        TriggerEvent('chat:addSuggestion', '/fatjack', 'Send a fat person to hijack a player\'s vehicle', {
            { name = 'id', help = 'Player ID' }
        })
    end
    
    -- Fuel module commands
    if hasPermissionForCommand('nofuel') then
        TriggerEvent('chat:addSuggestion', '/nofuel', 'Deplete a player\'s vehicle fuel', {
            { name = 'id', help = 'Player ID' }
        })
    end
    
    -- Jerk module commands
    TriggerEvent('chat:addSuggestion', '/jerk', 'Play a special animation')
    
    if hasPermissionForCommand('jerkify') then
        TriggerEvent('chat:addSuggestion', '/jerkify', 'Send jerk command info to a player', {
            { name = 'id', help = 'Player ID (optional)' }
        })
    end
    
    -- Dirty module commands
    if Config.Modules.dirty and Config.Modules.dirty.enabled then
        if hasPermissionForCommand('dirty') then
            TriggerEvent('chat:addSuggestion', '/dirty', 'Make your current vehicle dirty')
        end
    end
    
    -- Window Tint module commands
    if Config.Modules.tint and Config.Modules.tint.enabled then
        if hasPermissionForCommand('tint') then
            TriggerEvent('chat:addSuggestion', '/tint', 'Apply window tint to your vehicle', {
                { name = 'level', help = '0=None, 1=Limo, 2=Light Smoke, 3=Dark Smoke, 4=Stock, 5=Pure Black, 6=Green' }
            })
        end
    end
    
    -- Monkeycar module commands
    if Config.Modules.monkeycar and Config.Modules.monkeycar.enabled then
        TriggerEvent('chat:addSuggestion', '/monkeycar', 'Spawn a monkey driving a random car')
    end
end)

-- =========================
-- tint/client.lua
-- =========================
RegisterCommand("tint", function(source, args, rawCommand)
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