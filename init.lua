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
----- GLOBALSTEP -----
----------------------

local moved = {}
local huds  = {}
local pos   = {}

minetest.register_globalstep(function(dtime)
  for _, player in pairs(minetest.get_connected_players()) do
    local name = player:get_player_name()

    if pos[name] and spawnpoint.do_not_move then
      if not moved[name] and not vector.equals(pos[name], player:getpos()) then
        moved[name] = true

        player:hud_remove(huds[name])
        minetest.chat_send_player(name, "Teleportation interrupted! (Player moved)")
      end
    end
  end
end)

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
    res = res:read("*all"):split("\n", true)

    spawnpoint.time        = tonumber(res[1]) or 3
    spawnpoint.do_not_move = not not res[2] or true

    if res[3] then
      spawnpoint.pos = minetest.string_to_pos(res[3])
    end
  else
    spawnpoint.time        = 3
    spawnpoint.do_not_move = true
  end
end

-- [function] Save
function spawnpoint.save()
  local str = tostring(spawnpoint.time)..
    "\n"..tostring(spawnpoint.do_not_move) or ""

  if spawnpoint.pos then
    str = str.."\n"..minetest.pos_to_string(spawnpoint.pos)
  end

  io.open(path, "w"):write(str)
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

    local seconds = "s"
    if time < 2 then
      seconds = ""
    end

    -- Send to chat
    minetest.chat_send_player(name, "Teleportation will be complete in "..time..
      " second"..seconds..". "..move)

    -- Add initial HUD
    huds[name] = player:hud_add({
      hud_elem_type = "text",
      text = "Teleportation Progress: "..time.." seconds remaining!",
      position = {x = 0.5, y = 0.5},
      number = 0xFFFFFF,
    })

    local hud   = huds[name]
    pos[name]   = player:getpos()
    moved[name] = false

    -- Register update callbacks
    for i = 1, time do
      if i == time then
        minetest.after(i, function()
          if not moved[name] then
            player:hud_remove(hud)
            spawnpoint.bring(player)

            -- Send to chat
            minetest.chat_send_player(name, "Teleportation successful!")

            -- Prevent further callbacks from globalstep
            moved[name] = true
          end
        end)
      else
        minetest.after(i, function()
          if not moved[name] then
            player:hud_change(hud, "text", "Teleportation Progress: "..time - i.." seconds remaining!")
          end
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

    if not spawnpoint.pos then
      return false, "No spawnpoint set!"
    end

    spawnpoint.begin(player)
  end,
})

-- [register cmd] Manage spawnpoint
minetest.register_chatcommand("spawnpoint", {
  description = "Get/Set SpawnPoint information",
  func = function(name, param)
    if not param or param == "" then
      local pos = "Not set!"
      if spawnpoint.pos then
        pos = minetest.pos_to_string(spawnpoint.pos)
      end

      return true, "SpawnPoint Position: "..pos
    elseif minetest.check_player_privs(minetest.get_player_by_name(name), {server=true}) then
      local p = param:split(" ")

      if p[1] == "time" then
        local num = tonumber(p[2])

        if not num then
          return true, "SpawnPoint->time: "..spawnpoint.time
        elseif num == spawnpoint.time then
          return false, "Time already set to "..p[2].."!"
        else
          spawnpoint.time = num
          return true, "Set time to "..tostring(num)
        end
      elseif p[1] == "do_not_move" then
        local move = minetest.is_yes(p[2])
        minetest.log("action", dump(p[2])..", "..dump(move))
        if move == nil then
          return true, "SpawnPoint->do_not_move: "..tostring(spawnpoint.do_not_move)
        else
          spawnpoint.do_not_move = move
          return true, "Set do_not_move to "..tostring(move)
        end
      end
    end
  end,
})
