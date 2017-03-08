-- spawnpoint/init.lua

spawnpoint = {}

local path = minetest.get_worldpath().."/spawnpoint.conf"

-- [function] Log
function spawnpoint.log(content, log_type)
  if not content then return false end
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[HUD Plus] "..content)
end
