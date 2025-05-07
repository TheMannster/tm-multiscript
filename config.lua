Config = {}

-- General Settings
Config.Debug = false -- Enable debug mode for all modules
Config.UseQBCore = true -- Set to false if not using QBCore

-- Module Settings
Config.Modules = {
    -- Tire Pop Module
    tirepop = {
        enabled = true,
        debug = false,
        displayName = "POP",
        soundVolume = 0.5,
        soundDistance = 1.0
    },

    -- Slide Car Module
    slide = {
        enabled = true,
        debug = false,
        displayName = "Slidey Cars?",
        forceAmount = 100.0 -- Force applied when sliding car
    },

    -- SPED Module
    sped = {
        enabled = true,
        debug = false,
        displayName = "SPED",
        explosionRadius = 100.0,
        grenadeThrowDistance = 30.0,
        beepEnabled = false
    },

    -- Permanent Clean/Fix Module
    permclean = {
        enabled = true,
        debug = false,
        displayName = "Permanent Clean/Fix",
        fixInterval = 30000, -- How often to fix vehicles (ms)
        cleanInterval = 15000, -- How often to clean vehicles (ms)
        whitelist = {
            -- Add identifiers here, e.g. ["steam:11000010abcdefg"] = true
            ["license:ec708d5c72fc8633c3712148d25d15477b0861f8"] = true, -- TheVannster
        }
    },

    -- Fake Join/Leave Module
    joinfak = {
        enabled = true,
        debug = false,
        displayName = "Jerry2348",
        fakeName = "Mannfreddi" -- Name to use for fake join/leave messages
    },

    -- Astley Module
    astley = {
        enabled = true,
        debug = false,
        displayName = "RickAstley"
    },

    -- Night's ERSS Module
    nights_erss = {
        enabled = true,
        debug = false,
        displayName = "tgshoot",
        radius = 50.0
    },

    -- Hijab Module
    hijab = {
        enabled = true,
        debug = false,
        displayName = "Hijab",
        maxAttempts = 5
    }
}

-- Command Permissions (if using QBCore)
Config.CommandPermissions = {
    tirepop = "admin", -- QBCore permission required
    repairalltires = "admin",
    slidecar = "admin",
    explode = "admin",
    grenade = "admin",
    seegrenade = "admin",
    permclean = "admin",
    permfix = "admin",
    fakejoin = "admin",
    fakeleave = "admin"
} 