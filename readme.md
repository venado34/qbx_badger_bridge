# QBX Badger Bridge (Discord Job Sync)

This script automatically synchronizes a player's in-game jobs on a FiveM server with their roles on a Discord server. It is specifically designed to work with a **multi-job enabled version of QBX-Core** and uses the Honeybadger resource to fetch Discord roles.

The script establishes Discord as the single "source of truth" for all player jobs and ranks. It handles adding, updating, and removing jobs automatically, both when a player logs in and through a manual admin command. It also provides a clean user interface powered by `ox_lib` for players to manage their active job.

## Features

- **Full Synchronization:** Automatically assigns, updates, and removes in-game jobs based on a player's Discord roles every time they load their character.
- **Multi-Job Support:** Natively supports assigning multiple jobs simultaneously, compatible with modified QBX-Core frameworks.
- **Prioritized Ranks:** Uses a carefully ordered `jobs.lua` file to ensure players are always assigned the single highest rank they are eligible for within each unique job category.
- **Admin Control:** Includes a configurable admin-only command (`/syncjobs` by default) to manually trigger the synchronization process for a player.
- **Player UI:** Provides a clean `ox_lib` context menu (`/jobsmenu` by default) for players to view all of their jobs and select which one is active.
- **Configurable:** Almost all features, including command names, admin permissions, and notification systems, can be easily changed in `config/config.lua`.

---
## Dependencies

This script will not function without the following resources installed and configured correctly.

- **[QBX-Core (Multi-Job Fork)](https://github.com/venado34/qbx_core):** This script is built for a specific version of QBX-Core that supports multiple jobs.
- **[Honeybadger Resource](https://gitlab.nerdyjohnny.com/fivem/resources/essentials/owenbadger/honeybadger-resource):** The Discord API bridge used to fetch player role information.
- **[ox_lib](https://github.com/overextended/ox_lib):** Required for the job selection UI and optionally for notifications.
- **[crm-multicharacter](https://github.com/project-crm/crm-multicharacter):** Required for the automatic job sync when a player loads their character.

---
## Installation

1.  **Prerequisites:** Ensure all dependencies listed above are installed and working on your server.

2.  **Modify Honeybadger (CRITICAL STEP):** This script requires a custom export to be added to `honeybadger-resource`. Open `honeybadger-resource/server.lua` and **add the following code to the very end of the file**:
    ```lua
    exports('GetPlayerRoles', function(playerId, callback)
        local discord_id = nil
        for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
            if string.match(id, "^discord:") then
                discord_id = string.gsub(id, "discord:", "")
                break
            end
        end

        if not discord_id then
            if callback then callback(nil) end
            return
        end

        PerformHttpRequest(("%s/user/%s.json"):format(honeybadger_url, discord_id), function(code, response)
            if code ~= 200 or not response or response == "" then
                if callback then callback(nil) end
                return
            end

            local ok, decoded = pcall(json.decode, response)
            if not ok or type(decoded) ~= "table" then
                if callback then callback(nil) end
                return
            end
            
            if callback then callback(decoded) end
        end)
    end)
    ```

3.  **Install the Script:**
    - Place the `qbx_badger_bridge` folder into your `resources` directory.
    - Add `ensure qbx_badger_bridge` to your `server.cfg`. This line must come *after* all of the script's dependencies.

---
## Configuration

All configuration is handled in the `config/` subfolder.

### `config/config.lua`
This file controls the script's settings.
- `Config.Debug`: Enable or disable detailed console logs.
- `Config.NotificationSystem`: Choose the notification system to use. Options are `'crm-hud'`, `'ox_lib'`, or `'none'`.
- `Config.Commands`: Change the names of the `/jobsmenu` and `/syncjobs` commands.
- `Config.AdminPermissions`: A list of ACE permissions that are allowed to use the `/syncjobs` command.

### `config/jobs.lua`
This file contains the `RankedJobs` table, where you map Discord Role Names to in-game jobs and grades.

**Priority System (IMPORTANT)**
The order of the `RankedJobs` table is critical. For each unique job (e.g., `police`, `dps`), the script will assign the rank associated with the **first matching role it finds**. Therefore, you must list ranks from **highest to lowest** within each job block.

---
## How It Works & Staff Procedures

The script runs automatically every time a player loads their character via `crm-multicharacter`.

### **Promotions and Demotions**
Because Discord is the "source of truth," all staff management **must** be done by changing roles in Discord.

- **To promote or assign a job:** Give the user the appropriate role in Discord. Their job will be updated the next time they log in.
- **To demote or remove a job:** Remove the role from the user in Discord. Their job will be removed the next time they log in.

If a player is promoted in-game via a command (`/setjob`), their rank will be **overwritten and reverted** to match their Discord roles the next time they connect.