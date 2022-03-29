core_game = { }
core_game.position = { x = -95.6, y = 3.5, z = 198.5 } -- Default lobby position

minetest.register_privilege("core_admin", {
    description = "Can manage the lobby position and core game configurations.",
    give_to_singleplayer = true,
	give_to_admin = true,
})

core_game.game_started = false
core_game.is_end = {}
core_game.count = {}

core_game.is_waiting_end = {}
core_game.is_waiting = {}
core_game.player_count = 0

if tonumber(minetest.settings:get("minimum_required_players")) == nil then
	minetest.settings:set("minimum_required_players", 4) -- SET MINIMUM REQUIRED PLAYERS FOR A RACE
end

function core_game.get_formspec(name)
    local text = "Which car/vehicle do you want to use?"

    local formspec = {
        "formspec_version[4]",
        "size[7,3.75]",
        "label[0.5,0.5;", minetest.formspec_escape(text), "]",
        "button_exit[0.3,2.3;3,0.8;use_hovercraft;Hovercraft]",
		"button_exit[3.8,2.3;3,0.8;use_car;Car01]"
    }

    -- table.concat is faster than string concatenation - `..`
    return table.concat(formspec, "")
end

minetest.register_chatcommand("change_position", {
	params = "<x y z>",
	description = "Change lobby's position",
    privs = {
        core_admin = true,
    },
    func = function(name, param)
		-- Start: code taken from Minetest builtin teleport command
		local p = {}
		p.x, p.y, p.z = param:match("^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		p = vector.apply(p, tonumber)
		if not p.x and not p.y and not p.z then
			return false, "Wrong usage of command. Use <x y z>"
		end
		-- End: code taken from Minetest builtin teleport command
		core_game.position = {x = p.x, y = p.y, z = p.z}
		return true, "Changed lobby's position to: <" .. param .. ">"
    end,
})

minetest.register_on_joinplayer(function(player)
	player:set_pos(core_game.position)
	minetest.log("action", "[RACING GAME] Player " .. player:get_player_name() .. " joined and was teleported to the lobby successfully.")
	if core_game.player_count > 3 then
		core_game.waiting_to_end(player)
		return
	end
	core_game.start_game(player)
end)

minetest.register_on_dieplayer(function(player)
	player:set_pos(core_game.position)
	minetest.log("action", "[RACING GAME] Player " .. player:get_player_name() .. " died. Teleported to the lobby successfully.")
end)

minetest.register_on_newplayer(function(player)
	minetest.chat_send_all(player:get_player_name() .. " just joined! Welcome to the Racing Game!")
end)

minetest.register_on_leaveplayer(function(player)
	if core_game.game_started == true then
		core_game.player_count = core_game.player_count - 1
	end
end)

function core_game.waiting_to_end(player)
	hud_fs.show_hud(player, "core_game:pending_race", {
		{type = "size", w = 40, h = 0.5},
		{type = "position", x = 0.9, y = 0.9},
		{
			type = "label", x = 0, y = 0,
			label = "Waiting for the current race to finish..."
		}
	})
	core_game.is_waiting_end[player] = true
end

function core_game.player_lost(player)
	local attached_to = player:get_attach()
	if attached_to then
		local entity = attached_to:get_luaentity()

		lib_mount.detach(player, {x=0, y=0, z=0})
		entity.object:remove()
	end
	minetest.after(3.5, function()
		player:set_pos(core_game.position)
		hud_fs.close_hud(player, "core_game:race_count")
	end)
	core_game.is_end[player] = true
	core_game.game_started = false
end

local function count(player)
	for i = 1,50, 1
	do
		minetest.after(i, function()
			if core_game.is_end[player] == true then
				hud_fs.show_hud(player, "core_game:race_count", {
					{type = "size", w = 40, h = 0.5},
					{type = "position", x = 0.9, y = 0.9},
					{
						type = "label", x = 0, y = 0,
						label = "You finished at: " .. core_game.count[player] .. " seconds!"
					}
				})
				if core_game.game_started == false then
					hud_fs.close_hud(player, "core_game:race_count")
				end
				return
			end
			core_game.count[player] = i
			hud_fs.show_hud(player, "core_game:race_count", {
				{type = "size", w = 40, h = 0.5},
				{type = "position", x = 0.9, y = 0.9},
				{
					type = "label", x = 0, y = 0,
					label = "Race count: " .. core_game.count[player]
				}
			})
			if core_game.count[player] == 50 then
				minetest.chat_send_player(player:get_player_name(), "You lost the race for ending out of time.")
				core_game.player_lost(player)
				return
			end
		end)
	end
end

local function hud_321(player)
	local hud = player:hud_add({
		hud_elem_type = "image",
		position      = {x = 0.5, y = 0.5},
		offset        = {x = 0,   y = 0},
		text          = "core_game_3.png",
		alignment     = {x = 0, y = 0},
		scale         = {x = 1, y = 1},
   })
   minetest.after(3, function() player:hud_change(hud, "text", "core_game_2.png")
	   minetest.after(1, function() player:hud_change(hud, "text", "core_game_1.png") end) -- Change text to `1` AFTER the text is `2`
   end)
   minetest.after(5, function() player:hud_change(hud, "text", "core_game_go.png") count(player) core_game.game_started = true end)
   minetest.after(7, function() player:hud_remove(hud) end)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "core_game:choose_car" then
        return
    end

    if fields.use_hovercraft then
        local pname = player:get_player_name()
        minetest.chat_send_player(pname, "You will use Hovercraft in the next race.")

		local obj = minetest.add_entity(player:get_pos(), "vehicle_mash:hover_blue", nil)
		lib_mount.attach(obj:get_luaentity(), player, false, 0)
	elseif fields.use_car then
		local pname = player:get_player_name()
        minetest.chat_send_player(pname, "You will use CAR01 in the next race.")

		local obj = minetest.add_entity(player:get_pos(), "vehicle_mash:car_dark_grey", nil)
		lib_mount.attach(obj:get_luaentity(), player, false, 0)
    end
end)

local function start(player)
	if core_game.game_started == true then
		minetest.chat_send_player(player:get_player_name(), "There's a current race running. Please wait until it finishes.")
		core_game.waiting_to_end(player)
		return
	end
	-- Start: car selection formspec
	-- Ask the player which car they want to use
	local meta = player:get_meta()
	local data = minetest.deserialize(meta:get_string("hovercraft_bought"))

	if data and data.bought_already == true then
		minetest.show_formspec(player:get_player_name(), "core_game:choose_car", core_game.get_formspec(player))
	end
	-- End: car selection formspec

	-- Start: cleanup race count and ending booleans
	core_game.is_end = {}
	core_game.count = {}
	core_game.is_waiting = {}
	lib_mount.win_count = 1
	-- End: cleanup race count and ending booleans

	-- Start: HUD/count stuff
	hud_321(player)
	-- End: HUD/count stuff
end

function core_game.start_game(player)
	-- Start: player count checks
	if not core_game.game_started == true then
		core_game.player_count = core_game.player_count + 1
	end

	if core_game.player_count < tonumber(minetest.settings:get("minimum_required_players")) then
		hud_fs.show_hud(player, "core_game:waiting_for_players", {
			{type = "size", w = 40, h = 0.5},
			{type = "position", x = 0.9, y = 0.9},
			{
				type = "label", x = 0, y = 0,
				label = "Waiting for players (" .. tonumber(minetest.settings:get("minimum_required_players")) .. " required)..."
			}
		})
		core_game.is_waiting[player] = player
		return
	elseif core_game.player_count >= tonumber(minetest.settings:get("minimum_required_players")) then
		for _,name in pairs(core_game.is_waiting) do
			start(name)
			hud_fs.close_hud(name:get_player_name(), "core_game:waiting_for_players")
		end
	end
	-- End: player count checks

	-- Start: start race for non-waiting players, or recently joined ones
	start(player)
	-- End: start race for non-waiting players, or recently joined ones
end
