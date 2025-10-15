Perfect! Here’s a **fully upgraded, GitHub-friendly README.md** for your `qbx_badger_bridge` resource. It includes **badges, a Table of Contents, and a quick usage example**.

````markdown
# QBX Badger Bridge (Discord Job Sync)

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Dependencies](https://img.shields.io/badge/dependencies-QBX--Core-orange)
![License](https://img.shields.io/badge/license-MIT-green)

**QBX Badger Bridge** automatically synchronizes a player's in-game jobs with their Discord roles. Designed for **multi-job-enabled QBX-Core**, this resource ensures that Discord is the single source of truth for job assignments and ranks.

It also provides a clean `ox_lib` interface for players to view and select their active job.

---

## Table of Contents

- [Features](#features)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Example](#quick-example)
- [How It Works](#how-it-works)
- [Staff Procedures](#staff-procedures)

---

## Features

- **Automatic Synchronization:** Assigns, updates, or removes jobs when a player loads their character based on Discord roles.
- **Multi-Job Support:** Works with multiple jobs per player, fully compatible with QBX-Core multi-job setups.
- **Rank Prioritization:** Ensures each player receives the highest eligible rank per job using a structured `RankedJobs` table.
- **Admin Control:** Admins can manually trigger synchronization via a configurable command (default: `/syncjobs`).
- **Player UI:** Players can view and select their active job using an `ox_lib` context menu (default command: `/jobs`).
- **Configurable:** Almost all settings—including commands, admin permissions, and notification systems—can be adjusted via `config/config.lua`.

---

## Dependencies

Ensure the following resources are installed:

- **[QBX-Core (Multi-Job Fork)](https://github.com/venado34/qbx_core)**
- **[Honeybadger Resource](https://gitlab.nerdyjohnny.com/fivem/resources/essentials/owenbadger-resource)**
- **[ox_lib](https://github.com/overextended/ox_lib)**
- **[crm-multicharacter](https://github.com/project-crm/crm-multicharacter)** (required for automatic sync on character load)

---

## Installation

1. **Install Dependencies:** Confirm all required resources are present and running.

2. **Modify Honeybadger Resource:**  
Add this export to `honeybadger-resource/server.lua` **at the end** of the file:

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
````

3. **Install QBX Badger Bridge:**

   * Place the `qbx_badger_bridge` folder in your `resources` directory.
   * Add the following line to `server.cfg` **after all dependencies**:

```cfg
ensure qbx_badger_bridge
```

---

## Configuration

All configurations are located in the `config/` folder.

### `config/config.lua`

* **`Config.Debug`** – Enables/disables console debug logs.
* **`Config.NotificationSystem`** – Options: `'crm-hud'`, `'ox_lib'`, `'none'`.
* **`Config.Commands`** – Customize `/jobs` and `/syncjobs` commands.
* **`Config.AdminPermissions`** – ACE permissions required to use admin commands.

### `config/jobs.lua`

Contains the `RankedJobs` table, mapping Discord roles to in-game jobs and grades.
**Important:** List higher ranks first for each job to ensure proper prioritization.

---

## Quick Example

Players can manage jobs with these commands:

```text
/jobs           - Opens the job selection menu (ox_lib UI)
/syncjobs [id]  - Admin-only: manually sync jobs with Discord roles
```

* Players see all assigned jobs and select their active one.
* Admins can trigger a manual sync at any time.

---

## How It Works

* **Automatic Sync:** Triggered whenever a player loads a character (via `crm-multicharacter`).
* **Manual Sync:** Admins can run `/syncjobs` to force synchronization for a player.

---

## Staff Procedures

* **Promotions / Job Assignment:** Assign the appropriate Discord role; the in-game job updates automatically.
* **Demotions / Job Removal:** Remove the Discord role; the in-game job is removed on next login.
* **In-Game Changes:** Any manual in-game `/setjob` changes will be overridden by Discord roles at next sync.

---

