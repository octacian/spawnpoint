![Screenshot](screenshot.png)

Static Spawnpoint [spawnpoint]
================================
* License: MIT (see LICENSE)
* [Download Latest Version](https://github.com/octacian/spawnpoint/archive/master.zip)
* ...or browse the code on [GitHub](https://github.com/octacian/spawnpoint)

This is a rather simple mod introducing two commands to set a static spawnpoint and to teleport to it. Yes, I know you can set this in `minetest.conf`, however, doing so causes the spawnpoint to be the same across all of your worlds (very inconvenient). Instead of using `minetest.conf`, this mod stores the spawnpoint (and other settings) as a multi-line string within a file called `spawnpoint.conf` in the world directory. This allows each and every world to have a different spawnpoint.

The most unique thing about this spawn mod is that it includes a feature allowing you to set the time between executing the command until the player is actually teleported. By default, the teleportation will be interrupted if the player moves within that time. The time and the feature requiring players to stand still can be configured as documented below in the configuration section.

### Commands
- `/spawnpoint`: Display spawnpoint position if set (also see configuration section)
- `/spawn <player>`: Teleports you or the player specified to the spawnpoint (requires `spawn` privilege, and `bring` privilege to teleport another player)
- `/setspawn <position>`: Sets the spawn to the position specified (in format `x, y, z`) or to your current location (requires `server` privilege)

__Note:__ If no spawnpoint is specified and a player attempts to execute `/spawn`, he/she will be told "No spawnpoint set!"

### Configuration
The different "variables" of SpawnPoint can be configured per-world using the `/spawnpoint` command (requires server privilege). By default this command displays the spawnpoint, but when providing a setting name as well, the value of the setting is returned (assuming such a setting exists). If a setting name and value is provided, the setting is changed. Valid setting names are listed below.

* `time`: Time before teleportation is completed (if `0` teleportation is immediate)
* `do_not_move`: Whether a player should be required to not move to allow teleportation to be successful

Screenshot was taken at spawn on the awesome [HOMETOWN](https://forum.minetest.net/viewtopic.php?f=10&t=16699) server!