-- spawnpoint/init.lua

spawnpoint = {}

local storage
local path = minetest.get_worldpath().."/spawnpoint.conf"
local data = Settings(path)

if minetest.get_mod_storage then
	storage = minetest.get_mod_storage()
end

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

-- [local function] Count table contents
local function count(t)
	local count = 0
	for _, i in pairs(t) do
		count = count + 1
	end
	return count
end

-- [local function] Check if table is empty
local function is_empty(t)
	if t.fields then
		return count(t.fields) == 0
	else
		return count(t) == 0
	end
end

-- [function] Load
function spawnpoint.load()
	if data and not is_empty(data:to_table()) then
		spawnpoint.time = tonumber(data:get("time"))
		spawnpoint.do_not_move = data:get_bool("do_not_move")

		local pos = data:get("pos")
		if pos then
			spawnpoint.pos = minetest.string_to_pos(pos)
		end

		if storage then
			os.remove(path)
		end
	elseif storage and not is_empty(storage:to_table()) then
		local pos = storage:get_string("pos")
		if pos then
			spawnpoint.pos = minetest.string_to_pos(pos)
		end

		local do_not_move = storage:get_string("do_not_move")
		if do_not_move == "true" or do_not_move == true then
			spawnpoint.do_not_move = true
		else
			spawnpoint.do_not_move = false
		end

		spawnpoint.time = storage:get_float("time")
	else
		local f = io.open(path, "r")
		if f then
			local res = f:read("*all"):split("\n", true)

			spawnpoint.time = tonumber(res[1])

			if res[2] == "true" or res[2] == true then
				spawnpoint.do_not_move = true
			else
				spawnpoint.do_not_move = false
			end

			if res[3] then
				spawnpoint.pos = minetest.string_to_pos(res[3])
			end

			f:close()
			-- Clear file
			os.remove(path)
		end
	end
end

-- [function] Save
function spawnpoint.save()
	if storage then
		storage:set_float("time", spawnpoint.time)
		storage:set_string("do_not_move", tostring(spawnpoint.do_not_move))

		if spawnpoint.pos then
			storage:set_string("pos", minetest.pos_to_string(spawnpoint.pos))
		end

		return true
	elseif data then
		data:set("time", tostring(spawnpoint.time))
		data:set_bool("do_not_move", spawnpoint.do_not_move)

		if spawnpoint.pos then
			data:set("pos", minetest.pos_to_string(spawnpoint.pos))
		end

		data:write()
		return true
	end
end

-- [function] Set
function spawnpoint.set(pos)
	if type(pos) == "string" then
		pos = minetest.string_to_pos(pos)
	end

	if type(pos) == "table" then
		spawnpoint.pos = pos
		spawnpoint.save()
		spawnpoint.log("Set spawnpoint to "..minetest.pos_to_string(pos))
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
		pos = vector.round(pos)

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
					return true, "SpawnPoint->time: "..dump(spawnpoint.time)
				elseif num == spawnpoint.time then
					return false, "Time already set to "..p[2].."!"
				else
					spawnpoint.time = num
					spawnpoint.save()
					spawnpoint.log("Set time to "..dump(num))
					return true, "Set time to "..dump(num)
				end
			elseif p[1] == "do_not_move" then
				local move = minetest.is_yes(p[2])
				if move == nil or not p[2] then
					return true, "SpawnPoint->do_not_move: "..dump(spawnpoint.do_not_move)
				else
					spawnpoint.do_not_move = move
					spawnpoint.save()
					spawnpoint.log("Set do_not_move to "..dump(move))
					return true, "Set do_not_move to "..dump(move)
				end
			end
		end
	end,
})
