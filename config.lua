Config = {}

-- General Settings
Config.Debug = false -- Enable debug mode for all modules

-- Framework detection
-- "auto"       -> auto-detect Qbox > QBCore > ESX by checking which resource is running
-- "qbox"       -> force Qbox (uses qbx_core natives + ox_lib for notifications when present)
-- "qbcore"     -> force QBCore
-- "esx"        -> force ESX
-- "standalone" -> no framework (permissions fall back to ACE, notifications to chat)
Config.Framework = "auto"
Config.UseQBCore = true -- DEPRECATED, kept for backward compat. If set to false, acts as "standalone".

-- Module Settings
Config.Modules = {
    -- Tire Pop Module
    tirepop = {
        enabled = false,
        debug = false,
        displayName = "POP",
        soundVolume = 0.5,
        soundDistance = 1.0
    },

    -- Slide Car Module
    slide = {
        enabled = false,
        debug = false,
        displayName = "Slidey Cars?",
        forceAmount = 100.0 -- Force applied when sliding car
    },

    -- SPED Module
    sped = {
        enabled = false,
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
        displayName = "TheMannster",
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
        enabled = false,
        debug = false,
        displayName = "tgshoot",
        radius = 50.0
    },

    -- Hijab Module
    hijab = {
        enabled = false,
        debug = false,
        displayName = "Hijab",
        maxAttempts = 5
    },

    -- Client Drop Module
    clientdrop = {
        enabled = true,
        debug = false,
        displayName = "Client?"
    },

    -- Monkeycar Module
    monkeycar = {
        enabled = true,
        debug = false,
        displayName = "Car o Monkeys"
    },

    -- NPC Gun Module
    npcgun = {
        enabled = false,
        debug = false,
        displayName = "AIG",
        attackRadius = 30.0
    },

    -- Dirty Module
    dirty = {
        enabled = true,
        debug = false,
        displayName = "Dirty Vehicle",
        dirtLevel = 15.0
    },

    -- Window Tint Module
    tint = {
        enabled = true,
        debug = false,
        displayName = "Window Tint",
        defaultTint = 1 -- Default tint level if not specified (1 = Limo)
    }
}

-- Maps the permission levels used in Config.CommandPermissions (which are
-- written QBCore-style: god/admin/mod/user) onto ESX groups. Override here
-- if your server uses custom groups. "user" effectively means "anyone".
Config.ESXGroupMap = {
    god   = "superadmin",
    admin = "admin",
    mod   = "admin",
    user  = "user"
}

-- Command Permissions (if using QBCore / ESX)
Config.CommandPermissions = {
    tirepop = "god", -- QBCore permission required
    repairalltires = "god",
    slidecar = "god",
    explode = "god",
    grenade = "god",
    seegrenade = "god",
    permclean = "god",
    permfix = "god",
    fakejoin = "god",
    fakeleave = "god",
    client = "god",
    aig = "god",
    tgshoot = "god",
    hijack = "god",
    fatjack = "god",
    nofuel = "admin",
    jerkify = "god",
    dirty = "god",
    tint = "admin" -- Admin permission required for window tint
} 