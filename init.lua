-- spawnpoint/init.lua

spawnpoint = {}

local path = minetest.get_worldpath().."/spawnpoint.conf"

-- [function] Log
function spawnpoint.log(content, log_type)
  if not content then return false end
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[SpawnPoint] "..content)
end

----------------------
-- HELPER FUNCTIONS --
----------------------

-- [function] Clean Position
function spawnpoint.pos_clean(pos)
  pos.x = math.floor(pos.x)
  pos.y = math.floor(pos.y)
  pos.z = math.floor(pos.z)

  return pos
end

-- [function] Load
function spawnpoint.load()
  local res = io.open(path, "r"):read("*all")
  if res ~= "" then
    spawnpoint.pos = minetest.string_to_pos(res)
  end
end

-- [function] Save
function spawnpoint.save()
  io.open(path, "w"):write(minetest.pos_to_string(spawnpoint.pos))
end

-- [function] Set
function spawnpoint.set(pos)
  if type(pos) == "string" then
    pos = minetest.string_to_pos(pos)
  end

  if type(pos) == "table" then
    spawnpoint.pos = spawnpoint.pos_clean(pos)
  end
end

-- [function] Bring
function spawnpoint.bring(player)
  if type(player) == "string" then
    player = minetest.get_player_by_name(player)
  end

  if player and spawnpoint.pos then
    local pos = spawnpoint.pos
    player:setpos({x=pos.x, y=pos.y+0.5, z=pos.z})
  end
end

-------------------
---- CALLBACKS ----
-------------------

spawnpoint.load()

-- [register] On Shutdown
minetest.register_on_shutdown(spawnpoint.save)

-- [register] On Respawn Player
minetest.register_on_respawnplayer(function(player)
  spawnpoint.bring(player)
end)

-- [register] On New Player
minetest.register_on_newplayer(function(player)
  spawnpoint.bring(player)
end)

-- [register priv] Spawn
minetest.register_privilege("spawn", "Ability to teleport to spawn at will with /spawn")

-- [register cmd] Set spawn
minetest.register_chatcommand("setspawn", {
  description = "Teleport to spawn",
  privs = {server=true},
  func = function(name, param)
    local pos = minetest.get_player_by_name(name):getpos()
    if param then
      local ppos = minetest.string_to_pos(param)
      if type(ppos) == "table" then
        pos = ppos
      end
    end

    spawnpoint.set(pos)

    return true, "Set spawnpoint to "..minetest.pos_to_string(pos)
  end,
})

-- [register cmd] Teleport to spawn
minetest.register_chatcommand("spawn", {
  description = "Teleport to spawn",
  privs = {spawn=true},
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    if param ~= "" then
      local pplayer = minetest.get_player_by_name(param)
      if pplayer and minetest.check_player_privs(pplayer, {bring=true}) then
        player = pplayer
      else
        return false, "Cannot teleport another player to spawn without bring privilege"
      end
    end

    spawnpoint.bring(player)

    return true, "Teleporting to spawn"
  end,
})
