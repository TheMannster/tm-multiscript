Config = {}

-- General Settings
Config.Debug = false -- Enable debug mode for all modules

-- Help command: lists every command from currently-enabled modules in chat.
-- Defaults to god-only so it doubles as a quick admin overview.
Config.HelpCommand = "tmhelp"

-- Chat autocomplete suggestions ('/' menu in the chatbox). Set to false to
-- hide ALL of this resource's commands from the chat suggestions list.
-- Commands themselves still work, they just won't autocomplete.
Config.ChatSuggestions = false

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
        soundDistance = 1.0,
        commands = {
            pop    = "tirepop",        -- /tirepop [id] [tire|keyword]
            repair = "repairalltires", -- /repairalltires [id]
            fix    = "tirefix"         -- /tirefix (self, client-side)
        }
    },

    -- Slide Car Module
    slide = {
        enabled = true,
        debug = false,
        displayName = "Slidey Cars?",
        forceAmount = 100.0, -- Force applied when sliding car
        commands = {
            slide = "slidecar" -- /slidecar [id]
        }
    },

    -- SPED Module
    sped = {
        enabled = true,
        debug = false,
        displayName = "SPED",
        explosionRadius = 100.0,
        grenadeThrowDistance = 30.0,
        beepEnabled = false,
        commands = {
            explode    = "explode",    -- /explode [id]
            grenade    = "grenade",    -- /grenade [id]
            seegrenade = "seegrenade"  -- /seegrenade [id]
        }
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
            -- ["license:yourlicensehexhere"] = true, -- YourName
        },
        commands = {
            clean = "permclean", -- /permclean
            fix   = "permfix"    -- /permfix
        }
    },

    -- Fake Join/Leave Module
    joinfak = {
        enabled = true,
        debug = false,
        displayName = "TheMannster",
        fakeName = "Hero982", -- Name to use for fake join/leave messages
        commands = {
            join  = "fakejoin",  -- /fakejoin
            leave = "fakeleave"  -- /fakeleave
        }
    },

    -- Astley Module
    astley = {
        enabled = true,
        debug = false,
        displayName = "RickAstley"
        -- (no commands; this is a location-based easter egg)
    },

    -- Night's ERSS Module
    nights_erss = {
        enabled = false,
        debug = false,
        displayName = "tgshoot",
        radius = 50.0,
        commands = {
            info   = "tgshoot",     -- /tgshoot (info chat message)
            toggle = "toggleShoot"  -- /toggleShoot (client toggle)
        }
    },

    -- Hijab Module
    hijab = {
        enabled = true,
        debug = false,
        displayName = "Hijab",
        maxAttempts = 5,
        commands = {
            hijack = "hijack" -- /hijack [id]
        }
    },

    -- FatJack Module (sends a fat NPC to carjack a player)
    fatjack = {
        enabled = true,
        debug = false,
        displayName = "FatJack",
        spawnDistance = 35.0,    -- How far from the target the fat ped spawns (units)
        spawnDistanceJitter = 8.0, -- +/- random variation on spawnDistance
        snapToRoad = true,       -- Try to spawn on the nearest road node (more realistic)
        approachSpeed = 4.0,     -- How fast the fat ped walks/jogs to the target (1.0 walk, 2.0 run, 4.0+ sprint)

        -- Behavior:
        -- waitForExit = true  -> chill: ped waits until the driver's seat is empty
        --                       (use this to send /fatjack right before someone
        --                        gets out at a store; the fat guy will calmly
        --                        walk up and steal the parked car).
        -- waitForExit = false -> aggressive: ped yanks the driver out and steals
        --                       the car immediately on arrival.
        waitForExit = true,
        waitTimeout = 60000,      -- ms to wait for the target to leave their vehicle (only used when waitForExit = true)
        approachTimeout = 60000,  -- ms the ped will keep walking toward the vehicle before giving up

        commands = {
            jack = "fatjack" -- /fatjack [id]
        }
    },

    -- Fuel Module (drains a player's fuel)
    fuel = {
        enabled = true,
        debug = false,
        displayName = "No Fuel",
        commands = {
            deplete = "nofuel" -- /nofuel [id]
        }
    },

    -- Jerk Module (silly animation for self + a "send hint" command)
    jerk = {
        enabled = true,
        debug = false,
        displayName = "Jerk Animation",
        commands = {
            play = "jerk",    -- /jerk        (self-only animation, visible to all)
            send = "jerkify"  -- /jerkify [id] (admin: tells a player about /jerk)
        }
    },

    -- Client Drop Module
    clientdrop = {
        enabled = true,
        debug = false,
        displayName = "Client?",
        commands = {
            drop = "client" -- /client [id]
        }
    },

    -- Monkeycar Module
    monkeycar = {
        enabled = true,
        debug = false,
        displayName = "Car o Monkeys",
        commands = {
            spawn = "monkeycar" -- /monkeycar
        }
    },

    -- NPC Gun Module
    npcgun = {
        enabled = false,
        debug = false,
        displayName = "AIG",
        attackRadius = 30.0,
        commands = {
            attack = "aig" -- /aig [id]
        }
    },

    -- Dirty Module
    dirty = {
        enabled = true,
        debug = false,
        displayName = "Dirty Vehicle",
        dirtLevel = 15.0,
        commands = {
            dirty = "dirty" -- /dirty
        }
    },

    -- Window Tint Module
    tint = {
        enabled = true,
        debug = false,
        displayName = "Window Tint",
        defaultTint = 1, -- Default tint level if not specified (1 = Limo)
        commands = {
            tint = "tint" -- /tint [0-6]
        }
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

-- Same idea for Qbox. Qbox supports both a "god" group AND ACE perms --
-- ACE is the preferred approach on Qbox, but group-based checks still work.
-- This resource accepts whichever your server is configured for:
--   * ACE `command.allow` (server owners usually have this)
--   * ACE entries like `group.god` / `group.admin` / `qbx.god` / `qbx.admin`
--   * PlayerData.group matching the tier name
-- Override the values below if your server uses custom group names.
Config.QboxGroupMap = {
    god   = "god",
    admin = "admin",
    mod   = "mod",
    user  = "user"
}

-- Command Permissions (if using QBCore / ESX / Qbox)
-- These keys are the *internal* permission identifiers, NOT the actual
-- command names. Renaming a command in Config.Modules.<x>.commands does
-- NOT require changing anything here.
--
-- Tiers: god > admin > mod > user. Set to "user" (or omit entirely) to
-- let everyone see/use the command. Self-only fun commands default to
-- "user" so they show up for everyone -- override to lock them down.
Config.CommandPermissions = {
    tirepop = "god",
    repairalltires = "god",
    tirefix = "admin",      -- self-only: fix your own tires (visible to all)
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
    toggleShoot = "god",  -- self-only: toggle your AI shootout mode (visible to all)
    hijack = "god",
    fatjack = "god",
    nofuel = "admin",
    jerkify = "god",
    jerk = "user",         -- self-only: play jerk animation (visible to all)
    dirty = "god",
    tint = "admin",        -- self-only: tint your own vehicle
    monkeycar = "admin",    -- self-only: spawn a monkey driving a car (visible to all)
    tmhelp = "god"          -- /tmhelp: list every command from enabled modules
} 