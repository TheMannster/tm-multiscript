 _______ __  __ 
|__   __|  \/  |
   | |  | \  / |
   | |  | |\/| |
   | |  | |  | |
   |_|  |_|  |_|

# tm-multiscript

**Version:** 0.7.15  
**Author:** TheMannster

## Description

`tm-multiscript` is a modular, all-in-one FiveM resource that combines several popular scripts into a single, easy-to-manage package. It features a robust configuration system, QBCore support, and fine-grained permission controls, including per-module whitelisting.

## Features

- **Modular Design:** Enable or disable each script/module via the config.
- **QBCore Support:** Automatically detects and integrates with QBCore if available.
- **Centralized Configuration:** All tunable values and permissions are managed in `config.lua`.
- **Per-Module Whitelisting:** Allow specific users access to commands, even if they are not admins.
- **Resource Name Protection:** The script will not run if renamed from `tm-multiscript`.
- **Console and In-Game Command Support:** All commands can be run from both the server console and in-game (with proper permissions).
- **Combined Functionality:** Includes tire pop, slide car, SPED, permanent clean/fix, fake join/leave, and more.

## Installation

1. **Extract the resource** to your server's `resources` directory as `tm-multiscript`.
2. **Ensure the resource** in your `server.cfg`:
   ```
   ensure tm-multiscript
   ```
3. **Do not rename the resource.** The script will not run if the folder name is changed.

## Configuration

All settings are managed in `config.lua`.  
Key sections include:

- **General Settings:**  
  Enable debug mode, toggle QBCore support, etc.

- **Modules:**  
  Enable/disable each module, set display names, and adjust module-specific settings.

- **Command Permissions:**  
  Set required QBCore permissions for each command.

- **Whitelists:**  
  For example, to allow specific users access to `permclean` commands:
  ```lua
  permclean = {
      ...
      whitelist = {
          ["license:ec708d5c72fc8633c3712148d25d15477b0861f8"] = true, -- TheVannster
      }
  }
  ```

## Supported Modules

- **Tire Pop:** Pop or repair vehicle tires via command.
- **Slide Car:** Slide vehicles sideways for fun or admin purposes.
- **SPED:** Explode or throw grenades at players.
- **Permanent Clean/Fix:** Keep vehicles clean and fixed automatically.
- **Fake Join/Leave:** Send fake join/leave messages to chat.
- **Astley, Night's ERSS, and more:** Additional fun/admin scripts.

## Adding/Removing Modules

- To **disable** a module, set its `enabled` property to `false` in the config.
- To **add users** to a module's whitelist, add their Steam hex or FiveM license ID to the module's `whitelist` table.

## Updating

To update `tm-multiscript` to a new version:

1. **Backup your current config.lua** if you have custom settings or whitelists.
2. **Replace all files** in the `tm-multiscript` folder with the new version, except your `config.lua` (unless the update specifically requires changes to the config).
3. **Review the changelog or update notes** (if provided) for any new config options or breaking changes.
4. **Merge any new config options** from the updated `config.lua` into your existing config if needed.
5. **Restart your server** or use `refresh` and `ensure tm-multiscript` in your server console.

## Contribution

- Pull requests and suggestions are welcome!
- Please follow the existing code style and update the README and config documentation as needed.

## Credits

- Combined and maintained by TheMannster
- Includes code and ideas from various open-source FiveM scripts (see individual module comments for attribution)

## Changelog

### v0.7.14
- Added /client [id] command to drop a specified player with a custom message, usable from both server console and in-game (with permissions)
- Added clientdrop module configuration and permissions to config.lua
- Updated permission system to use QBCore.Functions.HasPermission with proper hierarchy (god > admin > mod > user)
- Debug prints for permission checks are now controlled by the global Config.Debug flag
- Improved debug output for permission checks
- General code cleanup and improved permission handling

### v0.7.15
- Added car_list.lua with a comprehensive list of vanilla GTA V traffic vehicles for use with commands like monkeycar
- Fixed errors related to missing or empty car_list.lua

---

**Enjoy your all-in-one FiveM admin and fun script!** 