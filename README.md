Static Spawnpoint [spawnpoint]
==============================
* License: MIT (see LICENSE)
* [Download Latest Version](https://github.com/octacian/spawnpoint/archive/master.zip)
* ...or browse the code on [GitHub](https://github.com/octacian/spawnpoint)

This is a rather simple mod introducing two commands to set a static spawnpoint and to teleport to it. Yes, I know you can set this in `minetest.conf`, however, doing so causes the spawnpoint to be the same across all of your worlds (very inconvenient). Instead of using `minetest.conf`, this mod stores the spawnpoint as a string in a file called `spawnpoint.conf` in the world directory. This allows each and every world to have a different spawnpoint.

### Commands
- `/spawn <player>`: Teleports you or the player specified to the spawnpoint (requires `spawn` privilege, and `bring` privilege to teleport another player)
- `/setspawn <position>`: Sets the spawn to the position specified (in format `x, y, z`) or to your current location (requires `server` privilege)

__Note:__ If no spawnpoint is specified, nothing will happen when a player executes `/spawn`.
