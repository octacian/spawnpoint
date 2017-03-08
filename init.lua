-- spawnpoint/init.lua

spawnpoint = {}

local path = minetest.get_worldpath().."/spawnpoint.conf"

-- [function] Log
function spawnpoint.log(content, log_type)
  if not content then return false end
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[HUD Plus] "..content)
end

----------------------
-- HELPER FUNCTIONS --
----------------------

-- [function] Load
function spawnpoint.load()
  local res = io.open(path, "r")
  if res then
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
    spawnpoint.pos = pos
  end
end

-- [function] Bring
function spawnpoint.bring(player)
  if type(player) == "string" then
    player = minetest.get_player_by_name(player)
  end

  if player then
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
