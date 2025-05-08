if GetCurrentResourceName() ~= "tm-multiscript" then
    print("^3[tm-multiscript]^1 ERROR: Don't rename the resource!^7")
    return
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
    TriggerEvent('QBCore:Notify', 'You notice a grenade in their back pocket', 'error', 5000)
    if exports['qb-core'] then
        exports['qb-core']:Notify('You notice a grenade in their back pocket', 'error', 5000)
    end
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
local permClean = false
local permFix = false
RegisterCommand("permclean", function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        permClean = not permClean
        TriggerServerEvent("permvehicle:setCleanState", VehToNet(veh), permClean)
        TriggerEvent("permvehicle:notify", "Permanent clean " .. (permClean and "enabled." or "disabled."))
    else
        TriggerEvent("permvehicle:notify", "You are not in a vehicle.")
    end
end)
RegisterCommand("permfix", function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        permFix = not permFix
        TriggerServerEvent("permvehicle:setFixState", VehToNet(veh), permFix)
        TriggerEvent("permvehicle:notify", "Permanent fix " .. (permFix and "enabled." or "disabled."))
    else
        TriggerEvent("permvehicle:notify", "You are not in a vehicle.")
    end
end)
RegisterNetEvent("permvehicle:doFix")
AddEventHandler("permvehicle:doFix", function(netId)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        print("[permvehicle] Vehicle fixed (netId: " .. netId .. ")")
    end
end)
RegisterNetEvent("permvehicle:doClean")
AddEventHandler("permvehicle:doClean", function(netId)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        print("[permvehicle] Vehicle cleaned (netId: " .. netId .. ")")
    end
end)
RegisterNetEvent("permvehicle:notify")
AddEventHandler("permvehicle:notify", function(msg)
    print("[permvehicle] " .. msg)
    TriggerEvent("chat:addMessage", {
        args = { "[permvehicle]", msg }
    })
end)

-- =========================
-- npcgun/client.lua
-- =========================
local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('qb-aig:client:attack', function(targetServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    if targetServerId ~= myServerId then return end
    local targetPed = PlayerPedId()
    local tx, ty, tz = table.unpack(GetEntityCoords(targetPed))
    local closestPed, pedDist = nil, 100.0
    local handle, ped = FindFirstPed()
    local success
    repeat
        if ped ~= targetPed 
           and not IsPedAPlayer(ped) 
           and not IsPedInAnyVehicle(ped) 
           and not IsEntityDead(ped) then
            local dist = #(vector3(tx,ty,tz) - GetEntityCoords(ped))
            if dist < pedDist then
                closestPed, pedDist = ped, dist
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    if closestPed then
        GiveWeaponToPed(closestPed, GetHashKey('weapon_pistol'), 255, false, true)
        TaskCombatPed(closestPed, targetPed, 0, 16)
    end
    local closestVeh = GetClosestVehicle(tx, ty, tz, 100.0, 0, 70)
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
local QBCore = exports['qb-core']:GetCoreObject()
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
                TriggerServerEvent('QBCore:Notify', sourcePlayer, "Hijacker is trying to enter the vehicle... Attempt: " .. attempts, "info")
            end
        end
        if enteredVehicle then
            local driveAwayCoords = spawnCoords + vector3(100.0, 100.0, 0.0)
            TaskVehicleDriveToCoord(hijackerPed, vehicle, driveAwayCoords, 20.0, 1.0, GetEntityModel(vehicle), 786603, 1, true)
        else
            TriggerServerEvent('QBCore:Notify', sourcePlayer, "Hijacker failed to get in the vehicle.", "error")
        end
        SetModelAsNoLongerNeeded(hijackerModel)
    else
        TriggerServerEvent('QBCore:Notify', sourcePlayer, "The target player is not in a vehicle.", "error")
    end
end)

-- =========================
-- fuel/cl_fuel.lua
-- =========================
local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('custom-fuel:depleteFuel', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        if exports['LegacyFuel'] then
            exports['LegacyFuel']:SetFuel(vehicle, 0.0)
        else
            print("LegacyFuel export not found.")
            QBCore.Functions.Notify("Fuel system error", "error")
        end
    else
        QBCore.Functions.Notify("You are not in a vehicle", "error")
    end
end)

-- =========================
-- fatjack/client/client.lua
-- =========================
local QBCore = exports['qb-core']:GetCoreObject()
local function DebugNotify(message, type)
    if Config.Modules.fatjack and Config.Modules.fatjack.debug then
        QBCore.Functions.Notify(message, type)
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
local QBCore = exports['qb-core']:GetCoreObject()
RegisterCommand("dirty", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        SetVehicleDirtLevel(vehicle, 15.0)
        local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('syncVehicleDirt', vehicleNetId, 15.0)
        QBCore.Functions.Notify('Your vehicle is now dirty!', 'success', 5000)
    else
        QBCore.Functions.Notify('You are not in a vehicle!', 'error', 5000)
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
    TriggerClientEvent("chatMessage", -1, "", { 162, 214, 11 }, "* " .. Config.Modules.joinfak.fakeName .. " joined")
end, false)
RegisterCommand("fakeleave", function(source, args, rawCommand)
    TriggerClientEvent("chatMessage", -1, "", { 162, 214, 11 }, "* " .. Config.Modules.joinfak.fakeName .. " left (Exiting)")
end, false) 