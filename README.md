![Screenshot](screenshot.png)

Static Spawnpoint [spawnpoint]
================================
* License: MIT (see LICENSE)
* [Download Latest Version](https://github.com/octacian/spawnpoint/archive/master.zip)
* ...or browse the code on [GitHub](https://github.com/octacian/spawnpoint)

This is a rather simple mod introducing two commands to set a static spawnpoint and to teleport to it. Yes, I know you can set this in `minetest.conf`, however, doing so causes the spawnpoint to be the same across all of your worlds (very inconvenient). Instead of using `minetest.conf`, this mod stores the spawnpoint as a string in a file called `spawnpoint.conf` in the world directory. This allows each and every world to have a different spawnpoint.

The most unique thing about this spawn mod, is that it includes a feature allowing you to set the time between executing the command until the player is actually teleported. By default, the teleportation will be interupted if the player moves within that time. The time can be configured in `minetest.conf` with `spawnpoint.time` (if `0`, players will be immediately teleported), and you can disable the feature requiring players to stand still by setting `spawnpoint.do_not_move` to `false` (default: `true`).

### Commands
- `/spawnpoint`: Display spawnpoint position if set
- `/spawn <player>`: Teleports you or the player specified to the spawnpoint (requires `spawn` privilege, and `bring` privilege to teleport another player)
- `/setspawn <position>`: Sets the spawn to the position specified (in format `x, y, z`) or to your current location (requires `server` privilege)

__Note:__ If no spawnpoint is specified, the player will be told "No spawnpoint set!"

Screenshot was taken at spawn on the awesome [HOMETOWN](https://forum.minetest.net/viewtopic.php?f=10&t=16699) server!
