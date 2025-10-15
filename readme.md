# QBX Badger Bridge ⚡
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-brightgreen)](https://fivem.net/)
[![Lua](https://img.shields.io/badge/Lua-5.4-blue)](https://www.lua.org/)

Automatically synchronizes a player's in-game QBX jobs with their Discord roles, featuring **multi-job support** and a clean **ox_lib UI** for selecting active jobs.

---

## Table of Contents
- [Features](#features)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Configuration](#configuration)
- [RankedJobs Priority](#rankedjobs-priority)
- [Usage](#usage)
- [Staff Procedures](#staff-procedures)

---

## Features
- **Automatic Job Sync:** Updates jobs when players load their character.  
- **Manual Sync Command:** Admin-only `/syncjobs` command to force update.  
- **Multi-Job Support:** Players can hold multiple jobs at once.  
- **Active Job Selection UI:** Uses `ox_lib` context menu to choose your active job.  
- **Configurable Notifications:** Supports `crm-hud`, `ox_lib`, or no notifications.  
- **Priority-Based Roles:** Highest-priority Discord roles determine job grade.

---

## Dependencies
This resource requires the following to function:

- [QBX-Core (Multi-Job Fork)](https://github.com/venado34/qbx_core) – Core framework supporting multiple jobs.  
- [Honeybadger Resource](https://gitlab.nerdyjohnny.com/fivem/resources/essentials/owenbadger/honeybadger-resource) – Fetches Discord roles.  
- [ox_lib](https://github.com/overextended/ox_lib) – Handles context menu and optional notifications.  
- [crm-multicharacter](https://github.com/project-crm/crm-multicharacter) – Triggers automatic job sync on character load.

---

## Installation

1. **Ensure Dependencies:** Confirm all required resources are installed.  
2. **Modify Honeybadger Resource (Required):**  
   Add this export at the end of `honeybadger-resource/server.lua`:
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

3. **Install Resource:**

   * Place `qbx_badger_bridge` folder into your `resources` directory.
   * Add `ensure qbx_badger_bridge` to your `server.cfg`, **after dependencies**.

---

## Configuration

### `config/config.lua`

```lua
Config.Debug = true -- Toggle detailed server logs
Config.NotificationSystem = 'crm-hud' -- Options: 'crm-hud', 'ox_lib', 'none'

Config.Commands = {
    jobsMenu = "jobs",    -- Player command to open job menu
    syncJobs = "syncjobs" -- Admin command for manual sync
}

Config.AdminPermissions = {
    "admin",
    "mod"
}
```

### `config/jobs.lua`

* Contains the `RankedJobs` table mapping **Discord roles → QBX jobs & grades**.
* **Order matters**: highest-priority roles must appear first per job.

---

## RankedJobs Priority

* For each unique job (e.g., `police`, `dps`), the first matching Discord role determines the assigned grade.
* Multi-job support allows secondary jobs with single-rank positions.
* Example:

```lua
RankedJobs = {
    { roleName = "LSPD Chief", job = "police", grade = 11 },
    { roleName = "LSPD Officer", job = "police", grade = 2 },
    { roleName = "LSPD MCIU", job = "lspd_mciu", grade = 0 },
}
```

---

## Usage

* **Player Job Menu:** `/jobs` → Opens ox_lib menu to select active job.
* **Admin Manual Sync:** `/syncjobs [playerID]` → Forces Discord role synchronization.
* **Notifications:** Configurable via `Config.NotificationSystem`.

---

## Staff Procedures

### Promotions / Demotions

* Discord is the **single source of truth**.
* **To assign or promote a player:** Give them the corresponding Discord role.
* **To remove or demote:** Remove the role in Discord.
* Changes are applied automatically on next login or via `/syncjobs`.

### Active Job Changes

* Players can choose their active job via the ox_lib menu (`/jobs`).
* Multi-job players can switch active jobs without affecting stored grades.

---

## License

MIT © Venado

```

