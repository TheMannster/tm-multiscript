```
_______ __  __ 
|__   __|  \/  |
   | |  | \  / |
   | |  | |\/| |
   | |  | |  | |
   |_|  |_|  |_|
```

# tm-multiscript

**Version:** 0.10.0  
**Author:** TheMannster

## What is this?

Honestly? It's a pile of troll/meme FiveM scripts I wrote over time to mess with players on my server, all duct-taped together into one resource so I don't have to manage 15 folders.

If you came here looking for a clean, professional admin framework you're in the wrong place. This is closer to a prank toolkit with a config file.

Everything is modular — enable only the bits you want, leave the rest off. Works on Qbox, QBCore, ESX, or standalone (auto-detected). Permissions are gated per-command so your regular players can't nuke each other.

## The scripts

| Command | What it does |
|---|---|
| `/explode [id]` | Detonates a grenade on a player. Classic. |
| `/grenade [id]` | Makes a nearby NPC chuck a grenade at them. Plausible deniability. |
| `/seegrenade [id]` | Sends a fake "you see a grenade in their pocket" notification. Paranoia fuel. |
| `/slidecar [id]` | Slides their car sideways for no reason. |
| `/tirepop [id] [tire]` | Pops their tires. |
| `/repairalltires [id]` | Un-pops their tires (mercy button). |
| `/tirefix` | Fix your own tires (self). |
| `/hijack [id]` | Sends waves of hijacker NPCs after a player. |
| `/fatjack [id]` | Spawns a single fat guy who calmly jogs up from a street away and steals the target's car. Far funnier than it has any right to be. |
| `/client [id]` | "Drops" a player with a fake Client disconnect message. |
| `/nofuel [id]` | Drains their gas tank. |
| `/dirty` | Makes your own car look like it rolled through a swamp. |
| `/permclean` / `/permfix` | Keep your own car permanently clean and fixed. Whitelist-gated. |
| `/tint [0-6]` | Sets window tint on your current vehicle, synced to everyone. |
| `/monkeycar` | Spawns a random vehicle with a monkey driving it. |
| `/aig [id]` | Summons NPCs to shoot at a player. |
| `/fakejoin` / `/fakeleave` | Spams a fake join/leave message in chat. Great for causing confusion. |
| `/jerk` | Plays a dumb animation on yourself. |
| `/jerkify [id]` | DMs a player telling them about `/jerk`. Get them to incriminate themselves. |
| `/toggleShoot` | Toggle AI shoot-at-you mode for yourself. |
| `/tgshoot` | Info message for the above. |
| Astley | Location-based Rick Astley easter egg. No command — just exists. |
| `/tmhelp` | Lists every enabled command in chat. God-only. |

All command names above are **defaults** — every single one can be renamed in `config.lua` under `Config.Modules.<module>.commands`.

## Install

1. Drop the folder into `resources/` as `tm-multiscript`. Don't rename it — the resource checks its own name and refuses to run if it's been changed.
2. Add to `server.cfg`:
   ```
   ensure tm-multiscript
   ```
3. Open `config.lua` and turn on/off whatever modules you want.

## Config highlights

- `Config.Framework` — `"auto"` works for most people. Force `"qbox"`, `"qbcore"`, `"esx"`, or `"standalone"` if you want.
- `Config.ChatSuggestions` — set to **`true`** to register chat `/` autocomplete for this resource’s commands; omit, `false`, or `nil` hides them all. Commands still work when hidden.
- `Config.HelpCommand` — rename `/tmhelp` to whatever you want.
- `Config.CommandPermissions` — tiers are `god > admin > mod > user`. Set something to `"user"` (or omit it) to let everyone use it. Keys in this table are the *internal* identifiers, not the renamed command names, so changing command names doesn't break permissions.
- `Config.QboxGroupMap` / `Config.ESXGroupMap` — map the tier names onto whatever your framework actually uses.

### Per-module whitelisting

Some modules (like `permclean`) take a whitelist so non-admins you trust can still use them:

```lua
permclean = {
    ...
    whitelist = {
        ["license:yourlicensehexhere"] = true, -- YourName
    }
}
```

## Permissions (Qbox note)

Qbox has a `god` group, but the preferred approach on Qbox is **ACE perms**. This resource accepts both — whichever your server is set up for:

- ACE `command.allow` (server owners usually have this)
- `group.<tier>` and `qbx.<tier>` ACE entries
- `PlayerData.group` matching the tier name (`god`, `admin`, `mod`, `user`)

If your server uses different group names than the defaults, remap them in `Config.QboxGroupMap`. If you have god perm on a Qbox server and something still won't let you run it, set `Config.Debug = true` and the server console will tell you why.

## Credits

Everything written / stitched together by **TheMannster**. Individual modules borrow ideas from various open-source FiveM scripts — attribution is in the module comments where it applies.

## Changelog

### v0.10.0
- **NPC gun (AIG / `/aig`)** — Fixed server `TriggerClientEvent` so the victim’s client actually runs the attack logic. Replaced `FindFirstPed` iteration with `GetGamePool('CPed')` for reliable nearby NPCs; drivers and passengers in range can be pulled from vehicles to attack; default `attackRadius` increased (see `config.lua`). Optional `npcgun.debug` prints when no NPC is in range.
- **Chat suggestions** — Suggestions register only when `Config.ChatSuggestions == true`. `false` / omitted / `nil` all hide this resource’s commands (fixes the old bug where a missing key still showed every suggestion due to Lua `nil == false`).

### v0.9.0
- Added `/tmhelp` — lists every command from currently-enabled modules in chat (god-only by default, rename via `Config.HelpCommand`).
- Added **FatJack** module (`/fatjack [id]`) — spawns a fat NPC a street away who jogs over, waits for the target to exit their car (configurable), then steals it. Tracks the vehicle if it moves. Road-snaps the spawn point for realism.
- Added **Fuel** module (`/nofuel [id]`).
- Added **Jerk** module (`/jerk` self animation, `/jerkify [id]` DM trap for admins).
- **Every command in every module is now renamable** via `Config.Modules.<module>.commands`. Permission keys stay stable so renaming doesn't break perms.
- Added `Config.ChatSuggestions` — global toggle to hide this resource's commands from the chat `/` autocomplete. Also clears ghost suggestions cached by the FiveM chat resource on resource start/stop.
- Added Qbox support with full framework detection (`qbox > qbcore > esx > standalone`) and a proper `Config.QboxGroupMap` — fixes god/admin holders being denied commands on Qbox servers.
- Fixed `/explode` being silently invisible and inaudible on modern FiveM artifacts (wrong native + arg-count mismatch).
- Revamped console output colors (less green, more varied).

### v0.8.2
- Added Window Tint module (`/tint [0-6]`), synced to all players.

### v0.8.1
- Chat suggestions are now permission-filtered (only show commands the player can actually use).
- Suggestions for disabled modules are hidden.

### v0.8.0
- Split AIG into its own module (`npcgun`).
- Added `/dirty`.
- Reworked permission checks, notifications, and QBCore init.

### v0.7.15
- Added `car_list.lua` of vanilla GTA V traffic vehicles for `/monkeycar`.

### v0.7.14
- Added `/client [id]`.
- Permission hierarchy reworked (`god > admin > mod > user`).
- Debug prints now gated behind `Config.Debug`.

---

Enjoy ruining someone's day.
