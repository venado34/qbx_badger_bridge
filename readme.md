\<tool\_code\>
print(file\_writer.create\_file(filename='README.md', content='''\# QBX Discord Job Sync

This script automatically synchronizes a player's in-game jobs and ranks on a QBX-Core server with their roles on a Discord server. It is designed for servers running a **multi-job enabled version of QBX-Core** and uses the Honeybadger API to fetch Discord roles.

The script establishes Discord as the single "source of truth" for all player jobs and ranks, ensuring that a player's in-game status always reflects their official roles.

## Features

  * **Automatic Job Assignment:** Assigns jobs to players when they log in based on their Discord roles.
  * **Multi-Job Support:** Natively supports assigning multiple jobs simultaneously to a single player, provided your QBX-Core framework is modified to allow it.
  * **Prioritized Ranks:** Uses a prioritized configuration to ensure players are always assigned the single highest rank they are eligible for within each job category.
  * **Source of Truth:** Simplifies staff procedures by making Discord the definitive source for promotions, demotions, and job assignments.

-----

## Dependencies

  * **[QBX-Core (Multi-Job Fork)](https://gitlab.nerdyjohnny.com/fivem/resources/development/nextgen/qbx/qbx_core):** This script is built for a specific version of QBX-Core that supports multiple jobs.
  * **[Honeybadger Resource](https://gitlab.nerdyjohnny.com/fivem/resources/essentials/owenbadger/honeybadger-resource):** A specific Discord API bridge that fetches and provides player role information. This script will not work without it.

-----

## Installation

1.  **Prerequisites:** Ensure `qbx_core` and your `honeybadger-resource` are installed, configured, and working correctly on your server.

2.  **Modify Honeybadger (CRITICAL STEP):** This script requires a custom function to be added to `honeybadger-resource`. Open `honeybadger-resource/server.lua` and **add the following code to the very end of the file**:

    ```lua
    exports(\'GetPlayerRoles\', function(playerId, callback)
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

      * Create a new folder named `qbx_discord_jobs` in your `resources` directory.
      * Inside this new folder, create the three files below inside this folder: `fxmanifest.lua`, `config.lua`, and `server.lua`.
      * Add `ensure qbx_badger_bridge` to your `server.cfg`, making sure it starts *after* its dependencies.

-----

## Configuration

All job configuration is done in `config.lua`. This file contains one main table, `RankedJobs`.

### The `RankedJobs` Table

This table is a list where you map Discord Role Names to in-game jobs and ranks.

**Structure:**

```lua
{ roleName = "Discord Role Name", job = "qbx_job_name", grade = 0 },
```

  * `roleName`: The **exact, case-sensitive name** of the role in your Discord server.
  * `job`: The job ID from your `qbx-core/shared/jobs.lua` file.
  * `grade`: The grade number for that rank, also from `jobs.lua`.

### **Priority System (IMPORTANT)**

The order of the `RankedJobs` table is critical. The script reads the list from **top to bottom**. For each unique job (e.g., `police`, `dps`), the script will assign the rank associated with the **first matching role it finds**. Therefore, you must list ranks from **highest to lowest** within each job block.

**Example:**

```lua
RankedJobs = {
    -- K9 Unit (Highest rank is at the top)
    { roleName = "K9 Coordinator", job = "k9", grade = 10 },
    { roleName = "K9 Supervisor",  job = "k9", grade = 5 },
    { roleName = "K9 Certified",   job = "k9", grade = 2 },
    { roleName = "K9 Trainee",     job = "k9", grade = 0 },
}
```

-----

## How It Works & Staff Procedures

This script runs every time a player loads into the server. It fetches their current Discord roles and updates their in-game jobs accordingly.

### **Promotions and Demotions**

Because Discord is the "source of truth," all staff management must be done through Discord roles.

  * **To promote or assign a job:** Give the user the appropriate role in Discord. Their in-game job will be updated the next time they log in.
  * **To demote or remove a job:** Remove the role from the user in Discord. Their in-game job will be removed/demoted the next time they log in.

If a player is promoted in-game via a command (e.g., `/setjob`), their rank will be **overwritten and reverted** to match their Discord roles the next time they connect to the server.
'''))
\</tool\_code\>