if Config.ServerType == "QB" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.ServerType == "ESX" then
    ESX = exports['es_extended']:getSharedObject()
end


if Config.OpenSettings.command.enabled then
    lib.addCommand(Config.OpenSettings.command.name, {
        help = "Open Fingerprint Scanner",
        restricted = false
    }, function(source, args)
        TriggerClientEvent('cs:fscanner:openUI', source)
    end)
end

if Config.OpenSettings.item.enabled then
    if Config.ServerType == 'QB' then
        QBCore.Functions.CreateUseableItem(Config.OpenSettings.item.name, function(source)
            TriggerClientEvent('cs:fscanner:openUI', source)
        end)
    elseif Config.ServerType == 'ESX' then
        ESX.RegisterUsableItem(Config.OpenSettings.item.name, function(source)
            TriggerClientEvent('cs:fscanner:openUI', source)
        end)
    else
        --YOU CAN ADD YOUR CUSTOM EVENTS HERE
    end
end

local function GetPlayerJob(source)
    if Config.ServerType == 'QB' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.PlayerData.job.name
    elseif Config.ServerType == 'ESX' then
        local Player = ESX.GetPlayerFromId(source)
        return Player.job.name
    end
end

local function tableContains(table, element)
    if not element or #element == 0 then
        return false
    end
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function isPlayerAllowed(source, check)
    local pJob = GetPlayerJob(source)
    local playerIdentifiers = GetPlayerIdentifiers(source)

    if tableContains(check, pJob) then
        return true
    end

    for _, acePerm in ipairs(check) do
        if IsPlayerAceAllowed(source, acePerm) then
            return true
        end
    end

    for _, identifier in ipairs(playerIdentifiers) do
        if tableContains(check, identifier) then
            return true
        end
    end

    return false
end

lib.callback.register('cs:fscanner:isAllowed', function(source)
    if not Config.Restriction.Enable then
        return true
    end
    return isPlayerAllowed(source, Config.Restriction.Restrict)
end)

RegisterNetEvent('cs:fscanner:server:promptTarget', function(targetSrc)
    TriggerClientEvent('cs:fscanner:client:openTargetUI', targetSrc, source)
end)

local function GetPlayerDetail(pID)
    local pData = nil

    if Config.ServerType == "ESX" then 
        local Player = ESX.GetPlayerFromId(pID)
        if not Player then return nil end

        local firstName = Player.get and Player.get('firstName') or nil
        local lastName = Player.get and Player.get('lastName') or nil
        local fullName = (firstName and lastName) and (firstName .. " " .. lastName) or (Player.getName and Player.getName()) or "Unknown"
        local dob = Player.dateofbirth or (Player.get and Player.get('dateofbirth')) or "UNKNOWN"
        local ssn = (Player.getSSN and Player.getSSN()) or (Player.get and Player.get('ssn')) or CreateRandomFingerId()
        local rawGender = Player.sex or (Player.get and Player.get('sex')) or 'm'
        local formattedGender = (rawGender == 'm' or rawGender == 'M' or rawGender == 0 or rawGender == '0') and 'Male' or 'Female'

        pData = {
            name = fullName,
            dob = dob,
            cid = ssn,
            gender = formattedGender,
            identifier = Player.identifier,
        }

    elseif Config.ServerType == "QB" then
        local Player = QBCore.Functions.GetPlayer(pID)
        if not Player then return nil end

        local charInfo = Player.PlayerData.charinfo or {}
        local isMale = (charInfo.gender == 0 or charInfo.gender == "0" or charInfo.gender == "m")

        pData = {
            name = string.format("%s %s", charInfo.firstname or "Unknown", charInfo.lastname or ""),
            dob = charInfo.birthdate or "UNKNOWN",
            cid = Player.PlayerData.metadata["fingerprint"] or Player.PlayerData.citizenid,
            gender = isMale and 'Male' or 'Female',
            identifier = Player.PlayerData.citizenid,
        }

    else
        -- Standalone Mode
        local playerName = GetPlayerName(pID) or "Unknown"
        pData = {
            name = playerName,
            dob = string.format("%02d/%02d/19%02d", math.random(1, 12), math.random(1, 28), math.random(60, 99)),
            cid = CreateRandomFingerId(),
            gender = 'Human',
            identifier = tostring(pID),
        }
    end

    return pData
end

function CreateRandomFingerId()
    return string.format("%s-%s-%s-%s", RandomStr(2), RandomInt(3), RandomStr(3), RandomInt(2))
end

RegisterNetEvent('cs:fscanner:server:completeScan', function(officerSrc, scannedPlayerSrc)
    local targetSrc = scannedPlayerSrc or source
    local TargetPlayer = GetPlayerDetail(targetSrc)
    if not TargetPlayer then return end

    TriggerClientEvent('cs:fscanner:client:startScanEffect', officerSrc)

    local mugshotUrl = nil
    if Config.UsingLicenseCreator and TargetPlayer.identifier then
        local success, pfp = pcall(function()
            return exports['cs_license']:fetchPic(TargetPlayer.identifier)
        end)
        if success and pfp then
            mugshotUrl = pfp
        end
    end

    local encodedName = TargetPlayer.name:gsub(" ", "+")
    local defaultAvatar = string.format("https://ui-avatars.com/api/?name=%s&background=0f172a&color=0ea5e9&size=150", encodedName)

    local profile = {
        id = TargetPlayer.cid,
        name = TargetPlayer.name,
        dob = TargetPlayer.dob,
        gender = TargetPlayer.gender,
        image = mugshotUrl or defaultAvatar
    }

    SetTimeout(2500, function()
        TriggerClientEvent('cs:fscanner:client:receiveResult', officerSrc, profile)
    end)
end)