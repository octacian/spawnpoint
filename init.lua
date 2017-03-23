-- spawnpoint/init.lua

spawnpoint = {}

spawnpoint.time        = tonumber(minetest.setting_get("spawnpoint.time")) or 3
spawnpoint.do_not_move = not not minetest.setting_get("spawnpoint.do_not_move") or true

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
  local res = io.open(path, "r")
  if res then
    res = res:read("*all")
    if res ~= "" then
      spawnpoint.pos = minetest.string_to_pos(res)
    end
  end
end

-- [function] Save
function spawnpoint.save()
  if spawnpoint.pos then
    io.open(path, "w"):write(minetest.pos_to_string(spawnpoint.pos))
  end
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

-- [function] Begin Countdown
function spawnpoint.begin(player, time)
  if not time then
    time = spawnpoint.time
  end

  if type(player) == string then
    player = minetest.get_player_by_name(player)
  end

  local name = player:get_player_name()

  if player and time and time ~= 0 then
    local move = "Do not move!"
    if spawnpoint.do_not_move ~= true then
      move = ""
    end

    local pos       = player:get_pos()
    local has_moved = false
    local seconds   = "s"

    if time < 2 then
      seconds = ""
    end

    -- Send to chat
    minetest.chat_send_player(name, "Teleportation will be complete in "..time..
      " second"..seconds..". "..move)

    -- Add initial HUD
    local hud = player:hud_add({
      hud_elem_type = "text",
      text = "Teleportation Progress: "..time.." seconds remaining!",
      position = {x = 0.5, y = 0.5},
      number = 0xFFFFFF,
    })

    -- Register update callbacks
    for i = 1, time do
      if i == time then
        minetest.after(i, function()
          if move ~= "" and has_moved ~= true and not vector.equals(pos, player:get_pos()) then
            player:hud_remove(hud)
            minetest.chat_send_player(name, "Teleportation interrupted! (Player moved)")
            has_moved = true
            return
          end

          player:hud_remove(hud)
          spawnpoint.bring(player)

          -- Send to chat
          minetest.chat_send_player(name, "Teleportation successful!")
        end)
      else
        minetest.after(i, function()
          if move ~= "" and has_moved ~= true and not vector.equals(pos, player:get_pos()) then
            player:hud_remove(hud)
            minetest.chat_send_player(name, "Teleportation interrupted! (Player moved)")
            has_moved = true
            spawnpoint.log(dump(pos)..", "..dump(player:getpos()))
            return
          end

          player:hud_change(hud, "text", "Teleportation Progress: "..time - i.." seconds remaining!")
        end)
      end
    end
  elseif player then
    minetest.chat_send_player(name, "Teleporting to spawn")
    spawnpoint.bring(player)
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
  description = "Set spawn",
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

    spawnpoint.begin(player)
  end,
})
