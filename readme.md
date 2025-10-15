# QBX Badger Bridge (Discord Job Sync)

[![Version](https://img.shields.io/badge/version-2.0.0-blue)](https://github.com/yourusername/qbx_badger_bridge)
[![Dependencies](https://img.shields.io/badge/dependencies-QBX_Core%2C%20Honeybadger%2C%20ox_lib-lightgrey)](https://github.com/venado34/qbx_core)

QBX Badger Bridge automatically synchronizes a player's in-game jobs on a FiveM server with their **Discord roles**, supporting multi-job systems and a clean **ox_lib-based UI**.

---

## Table of Contents

- [Features](#features)  
- [Dependencies](#dependencies)  
- [Installation](#installation)  
- [Configuration](#configuration)  
- [Character System Support](#character-system-support)  
- [Commands & Usage](#commands--usage)  
- [Debugging](#debugging)  
- [How It Works](#how-it-works)  

---

## Features

- **Automatic Synchronization:** Updates in-game jobs based on Discord roles whenever a player loads their character.  
- **Multi-Job Support:** Assigns multiple jobs simultaneously with priority rankings.  
- **Configurable Character System:** Supports `crm-multicharacter`, `QBCore`, or any custom server event.  
- **Admin Controls:** `/syncjobs` command allows authorized staff to manually synchronize jobs.  
- **Player UI:** `/jobs` opens an **ox_lib context menu** to view and select active jobs.  
- **Detailed Debug Logs:** Fully configurable debug output to track job assignment and sync events.  

---

## Dependencies

This resource requires the following:

- **[QBX-Core (Multi-Job Fork)](https://github.com/venado34/qbx_core)** – supports multiple jobs per player.  
- **[Honeybadger Resource](https://gitlab.nerdyjohnny.com/fivem/resources/essentials/owenbadger/honeybadger-resource)** – fetches Discord roles.  
- **[ox_lib](https://github.com/overextended/ox_lib)** – for job menu UI and optional notifications.  
- **[crm-multicharacter](https://github.com/project-crm/crm-multicharacter)** – used for automatic job sync (configurable).  

---

## Installation

1. Ensure all dependencies are installed and working.  
2. **Modify Honeybadger** to add the export `GetPlayerRoles` (see [Installation Section](#installation) in previous docs).  
3. Place `qbx_badger_bridge` in your `resources` folder.  
4. Add to `server.cfg` **after dependencies**:  

```cfg
ensure qbx_core
ensure honeybadger-resource
ensure ox_lib
ensure qbx_badger_bridge
````

---

## Configuration

All configuration is in `config/config.lua`:

```lua
Config = {}

-- Debug
Config.Debug = true

-- Notification system: 'crm-hud', 'ox_lib', or 'none'
Config.NotificationSystem = 'ox_lib'

-- Commands
Config.Commands = {
    jobsMenu = "jobs",
    syncJobs = "syncjobs"
}

-- Admin ACE permissions
Config.AdminPermissions = {"admin", "mod"}

-- Server event fired when a player has loaded their character
Config.CharacterLoadedEvent = 'crm-multicharacter:server:playerLoaded'
```

### Jobs Table

`config/jobs.lua` contains `RankedJobs` mapping Discord roles to in-game jobs and grades.

* **Order matters:** Highest priority roles must be listed first for each job.
* Supports single-rank side jobs and multi-rank department jobs.

---

## Character System Support

This resource can automatically detect your character system via `Config.CharacterLoadedEvent`.

* Example:

```lua
RegisterNetEvent(Config.CharacterLoadedEvent, function()
    local src = source
    local Player = GetPlayer(src) -- QBX or QBCore
    if Player then
        -- Automatic job synchronization
        SyncPlayerJobs(src, false)
    else
        print("^1[QBX Badger Bridge] No compatible character system detected. Automatic sync disabled.^7")
    end
end)
```

Supported examples:

* `crm-multicharacter:server:playerLoaded`
* `QBCore:Server:OnPlayerLoaded`
* Custom events can be set in `Config.CharacterLoadedEvent`.

---

## Commands & Usage

| Command     | Description                                                             |
| ----------- | ----------------------------------------------------------------------- |
| `/jobs`     | Opens the **ox_lib job selection menu** for players.                    |
| `/syncjobs` | Admin-only command to manually sync a player's jobs with Discord roles. |

**Notes:**

* Active job is always the first in the list by default.
* Changing jobs via `/setjob` will be overwritten on next sync.

---

## Debugging

* Set `Config.Debug = true` to enable detailed console logs for both client and server.
* Check for ox_lib issues: `"No context menu of such id found"` or `"export not found"` usually means ox_lib is not loaded before QBX Badger Bridge.
* Use `Config.NotificationSystem = 'ox_lib'` to see in-game debug messages.

---

## How It Works

1. Player loads character.
2. Server fetches Discord roles via Honeybadger.
3. Jobs are compared against `RankedJobs`:

   * Assign new jobs
   * Update existing grades
   * Remove unmatched jobs
4. Player receives optional notifications.
5. Player can open `/jobs` menu to select an active job.

**Promotions & Demotions:**

* Manage all roles **via Discord**.
* In-game promotions or demotions are temporary; the next sync will align jobs to Discord roles.
