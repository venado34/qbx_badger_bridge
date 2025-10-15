# QBX Badger Bridge

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue)]()

QBX Badger Bridge synchronizes Discord roles with QBX jobs in GTA V roleplay servers. It supports multiple character systems and modular notifications.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Commands](#commands)
- [Notifications](#notifications)
- [Debugging](#debugging)
- [Contributing](#contributing)

---

## Features

- Automatic job synchronization based on Discord roles.
- Supports multiple character systems:
  - `qbx_core` – QBX-Core native character system.
  - `crm-multicharacter` – CRM-Multicharacter system.
  - `custom` – Custom character system with a manual server event.
  - `none` – Disable automatic sync.
- Modular client-side notifications:
  - `none`
  - `crm-hud`
  - `ox_lib`
- Configurable commands for job menu and manual sync.
- Detailed debug logs for troubleshooting.

---

## Requirements

- [QBX-Core](https://github.com/Qbox-project/qbx_core)
- [Honeybadger](https://github.com/Qbox-project/honeybadger-resource)
- [ox_lib](https://github.com/overextended/ox_lib)

---

## Installation

1. Place the resource in your server:  

```

resources/[qbx]/[jobs]/qbx_badger_bridge

````

2. Add the resource to your `server.cfg`:

```cfg
ensure qbx_badger_bridge
````

3. Configure your Discord roles, commands, and notifications in `config.lua`.

---

## Configuration

All settings are in `config.lua`.

```lua
Config.Debug = true                       -- Toggle debug prints
Config.Multicharacter = 'crm-multicharacter' -- Character system to use
Config.Notifications = 'ox_lib'           -- Client-side notification system
Config.AdminPermissions = {               -- ACE permissions for admin commands
    "group.admin",
    "group.superadmin"
}
Config.Commands = {
    jobs = 'jobs',         -- Opens the job selection menu
    syncJobs = 'syncjobs', -- Manually sync player jobs
}
```

---

## Commands

Commands are fully configurable in `config.lua`.

| Command     | Description                                        |
| ----------- | -------------------------------------------------- |
| `/jobs`     | Opens the job selection menu (client-side)         |
| `/syncjobs` | Manually triggers job synchronization (admin only) |

---

## Notifications

Notifications are handled client-side and can be configured in `Config.Notifications`:

* `none` – No notifications.
* `crm-hud` – Uses the CRM HUD notification system.
* `ox_lib` – Uses `ox_lib` notifications:

```lua
lib.notify({
    title = 'Job Sync',
    description = message,
    type = type -- 'success', 'error', 'info', etc.
})
```

---

## Debugging

Enable `Config.Debug = true` for detailed logs in the server and client consoles. Logs include:

* Player Discord roles.
* Job assignments and updates.
* Any errors when saving or assigning jobs.

---

## Contributing

Feel free to submit issues, PRs, or improvements. Please maintain the code style, comments, and modular structure.

---

## License

This project is licensed under MIT.
