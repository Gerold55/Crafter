--[[
--map
running - set fov set_fov(fov, is_multiplier) set_breath(value)
sneaking --set eye offset

]]--
minetest.register_on_joinplayer(function(player)
	--add in info
	player:hud_set_flags({minimap=true})
	player:hud_add({
		hud_elem_type = "text",
		position = {x=0,y=0},
		text = "Crafter Alpha 0.1",
		number = 000000,
		alignment = {x=1,y=1},
		offset = {x=2, y=2},
	})
	player:hud_add({
		hud_elem_type = "text",
		position = {x=0,y=0},
		text = "Crafter Alpha 0.1",
		number = 0xffffff,
		alignment = {x=1,y=1},
		offset = {x=0, y=0},
	})
end)

--hurt sound
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if hp_change < 0 then
		minetest.sound_play("hurt", {object=player, gain = 1.0, max_hear_distance = 60,pitch = math.random(80,100)/100})
	end
end)


minetest.register_globalstep(function(dtime)
	--collection
	for _,player in ipairs(minetest.get_connected_players()) do
		local run = player:get_player_control().aux1
		local sneak = player:get_player_control().sneak
		
		if run then
			--[[ I'll impliment this in later
			local meta = player:get_meta()
			
			local run_time = meta:get_float("running_timer")
			
			if not run_time then
				run_time = 0
			end
			
			if run_time >= 0.1 then
				--take breath away
				local breath = player:get_breath()
				breath = breath - 1
				player:set_breath(breath)
				run_time = 0
				print(breath)
			end
			
			meta:set_float("running_timer", run_time + dtime)
			
			]]--
			
			local fov = player:get_fov()
			if fov == 0 then
				fov = 1
			end
			
			if fov < 1.2 then
				player:set_fov(fov + 0.05, true)
			end
			
			player:set_physics_override({speed=1.5})
		else
			local meta = player:get_meta()
			local fov = player:get_fov()
			if fov > 1 then
				player:set_fov(fov - 0.05, true)
			end
			
			player:set_physics_override({speed=1})
			--meta:set_float("running_timer", 0)
		end
		
		if sneak then
			player:set_eye_offset({x=0,y=-1,z=0},{x=0,y=-1,z=0})
		else
			player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
		end
	end
end)