local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

if minetest.settings:get_bool("enable_premium_features") == nil then
	minetest.settings:set_bool("enable_premium_features", true) -- Enable premium features by default if no value initialized
elseif minetest.settings:get_bool("enable_premium_features") == false then
	minetest.log("action", "[RACING GAME] Premium features are disabled. Not initializing.")
	return
end

local house_location = { x = -89.6, y = 71.5, z = 187.2 }

------------------
-- Privileges --
------------------
minetest.register_privilege("has_premium", {
    description = S("The user has premium features. See /donate for more information."),
    give_to_singleplayer = false,
    give_to_admin = false,
})

----------------
-- Commands --
----------------

minetest.register_chatcommand("premium_house", {
	params = "<player>",
	description = S("Teleport (the given player) to the premium/VIP house."),
    privs = {
        shout = true,
    },
    func = function(name, param)
		if param == "" then
			if not minetest.check_player_privs(minetest.get_player_by_name(name), { has_premium = true }) then
				return false, S("You don't have sufficient permissions to run this command. Missing privileges: has_premium")
			else
				minetest.get_player_by_name(name):set_pos(house_location)
				return true, S("Successfully teleported to the premium/VIP house.")
			end
		end

		if param ~= "" and
				minetest.check_player_privs(name, { core_admin = true }) or param == name then
			name = param
		else
			return false, S("You don't have sufficient permissions to run this command. Missing privileges: core_admin")
		end

		local player = minetest.get_player_by_name(name)
		if player then
			player:set_pos(house_location)
			return true, S("Successfully teleported @1 to the premium/VIP house.", param)
		else
			return false, S("Player @1 does not exist or is not online.", name)
		end
	end,
})

minetest.register_chatcommand("vip_nametag", {
	params = "<player>",
	description = S("Give VIP nametag to the given player."),
    privs = {
        core_admin = true,
    },
    func = function(name, param)
		if param == "" then
			return false, S("Invalid player name. See /help vip_nametag")
		end

		if param ~= "" and
				minetest.check_player_privs(name, { core_admin = true }) or param == name then
			name = param
		else
			return false, S("You don't have sufficient permissions to run this command. Missing privileges: core_admin")
		end

		local player = minetest.get_player_by_name(name)
		if player then
			player:set_nametag_attributes({
				text = "[VIP] " .. param,
				color = {r = 255, g = 255, b = 0},
				bgcolor = false
			})

			return true, S("Successfully set VIP nametag for player @1.", param)
		else
			return false, S("Player @1 does not exist or is not online.", name)
		end
	end,
})
