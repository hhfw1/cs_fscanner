local currentTargetServerId = nil
local scannerProp = nil

local function GetClosestPlayer()
    local playerPed = cache.ped
    local coords = GetEntityCoords(playerPed)
    local closestPlayer = lib.getClosestPlayer(coords, 2.5)
    if closestPlayer then
        return GetPlayerServerId(closestPlayer)
    end
    return false
end

local function ScannerAnimation(start)
    local ped = cache.ped
    local propModel = `prop_police_phone`
    local boneIndex = GetPedBoneIndex(ped, 28422)

    if start then
        lib.requestAnimDict("amb@world_human_stand_mobile@male@text@base")
        lib.requestModel(propModel)
        TaskPlayAnim(ped, "amb@world_human_stand_mobile@male@text@base", "base", 3.0, -3.0, -1, 49, 0, false, false, false)
        if scannerProp and DoesEntityExist(scannerProp) then
            DeleteObject(scannerProp)
            scannerProp = nil
        end
        local coords = GetEntityCoords(ped)
        scannerProp = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, false)
        AttachEntityToEntity(
            scannerProp,
            ped,
            boneIndex,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            true, true, false, true, 1, true
        )
        SetModelAsNoLongerNeeded(propModel)
    else
        ClearPedTasks(ped)
        if scannerProp and DoesEntityExist(scannerProp) then
            DeleteObject(scannerProp)
            scannerProp = nil
        end
    end
end

local function OpenScanner(isTarget)
    ScannerAnimation(true)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openScanner',
        isTarget = isTarget or false
    })
end

RegisterNetEvent('cs:fscanner:openUI', function()
    local isAllowed = lib.callback.await('cs:fscanner:isAllowed', false)
    if not isAllowed then 
        lib.notify({title = 'Fingerprint', description = 'Not allowed to use the fingerprint scanner'})
        return 
    end
    local targetServerId = GetClosestPlayer()
    currentTargetServerId = targetServerId
    if targetServerId then
        TriggerServerEvent('cs:fscanner:server:promptTarget', targetServerId)
    end
    OpenScanner(false)
end)

RegisterNetEvent('cs:fscanner:client:openTargetUI', function(officerSrc)
    currentTargetServerId = officerSrc
    OpenScanner(true)
end)

RegisterNUICallback('targetConfirmScan', function()
    if currentTargetServerId then
        TriggerServerEvent('cs:fscanner:server:completeScan', currentTargetServerId, GetPlayerServerId(PlayerId()))
    end
    SetNuiFocus(false, false)
    ScannerAnimation(false)
    SendNUIMessage({ action = 'close' })
end)

RegisterNUICallback('startScan', function()
    local targetServerId = GetClosestPlayer()
    if targetServerId then
        TriggerServerEvent('cs:fscanner:server:promptTarget', targetServerId)
        lib.notify({title = 'Fingerprint', description = 'Awaiting target fingerprint press...'})
    else
        lib.notify({title = 'Fingerprint', description = 'No target nearby. Running self-test scan...'})
        local myServerId = GetPlayerServerId(PlayerId())
        TriggerServerEvent('cs:fscanner:server:completeScan', myServerId, myServerId)
    end
end)

RegisterNetEvent('cs:fscanner:client:startScanEffect', function()
    SendNUIMessage({ action = 'setScanningAnimation' })
end)

RegisterNetEvent('cs:fscanner:client:receiveResult', function(profileData)
    SendNUIMessage({
        action = 'showResult',
        profile = profileData
    })
end)

RegisterNUICallback('closeUI', function()
    SetNuiFocus(false, false)
    ScannerAnimation(false)
    ClearPedTasks(PlayerPedId())
end)

if Config.OpenSettings.keybind.enabled then
    local keybind = lib.addKeybind({
        name = 'fpscan_keybind',
        description = 'press '..Config.OpenSettings.keybind.name..' to open fingerprint scanner',
        defaultKey = Config.OpenSettings.keybind.name,
        onPressed = function()
            TriggerClientEvent('cs:fscanner:openUI', source)
        end,
    })
end