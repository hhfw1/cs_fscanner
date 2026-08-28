Config = {}

-- 'QB' = For QBCore or QBOX Framework
-- 'ESX' = For ESX Framework
-- false = For Standalone Mode

Config.ServerType = 'QB'    --QB|ESX|false

Config.OpenSettings = {
    command = {
        enabled = true,
        name = 'fscan' -- Command
    },
    keybind = {
        enabled = true,
        name = 'H', -- Default key
    },
    item = {
        enabled = false,
        name = 'finger_scanner' -- Item name in your inventory
    }
}

-- If you are using CodeStudio License Creator, set this to true to get the real image. If not, set it to false to use the default avatar
-- https://youtu.be/jBi7CESHrqk

Config.UsingLicenseCreator = true 

Config.Restriction = { -- Restriction for using the scanner
    Enable = false,  -- Enable/Disable Restriction
    Restrict = {    --Restrict Jobs | Ace Perms | Identifers(Discord/Steam/Fivem)
        'police',
    }
}
