local minetest,math,vector,os = minetest,math,vector,os
local mod_storage = minetest.get_mod_storage()
local pool = {}
local experience_bar_max = 36

-- loads data from mod storage
local name
local temp_pool
local load_data = function(player)
	name = player:get_player_name()
	pool[name] = {}
	temp_pool = pool[name]
	if mod_storage:get_int(name.."xp_save") > 0 then
		temp_pool.xp_level = mod_storage:get_int(name.."xp_level")
		temp_pool.xp_bar   = mod_storage:get_int(name.."xp_bar"  )
		temp_pool.buffer   = 0
		temp_pool.last_time= os.clock()
	else
		temp_pool.xp_level = 0
		temp_pool.xp_bar   = 0
		temp_pool.buffer   = 0
		temp_pool.last_time= os.clock()
	end
end

-- saves data to be utilized on next login
local name
local temp_pool
local save_data = function(name)
	if type(name) ~= "string" and name:is_player() then
		name = name:get_player_name()
	end
	temp_pool = pool[name]
	
	mod_storage:set_int(name.."xp_level",temp_pool.xp_level)
	mod_storage:set_int(name.."xp_bar",  temp_pool.xp_bar  )

	mod_storage:set_int(name.."xp_save",1)

	pool[name] = nil
end

-- saves specific users data for when they relog
minetest.register_on_leaveplayer(function(player)
	save_data(player)
end)

-- is used for shutdowns to save all data
local save_all = function()
	for name,_ in pairs(pool) do
		save_data(name)
	end
end

-- save all data to mod storage on shutdown
minetest.register_on_shutdown(function()
	save_all()
end)


minetest.hud_replace_builtin("health",{
    hud_elem_type = "statbar",
    position = {x = 0.5, y = 1},
    text = "heart.png",
    number = core.PLAYER_MAX_HP_DEFAULT,
    direction = 0,
    size = {x = 24, y = 24},
    offset = {x = (-10 * 24) - 25, y = -(48 + 24 + 38)},
})

local name
local temp_pool
minetest.register_on_joinplayer(function(player)

	load_data(player)

	name = player:get_player_name()
	temp_pool = pool[name]
		
    hud_manager.add_hud(player,"heart_bar_bg",{
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "heart_bg.png",
        number = core.PLAYER_MAX_HP_DEFAULT,
        direction = 0,
        size = {x = 24, y = 24},
        offset = {x = (-10 * 24) - 25, y = -(48 + 24 + 38)},
	})
	

    hud_manager.add_hud(player,"experience_bar_background",{
        hud_elem_type = "statbar",
        position = {x=0.5, y=1},
        name = "experience bar background",
        text = "experience_bar_background.png",
        number = 36,
        direction = 0,
        offset = {x = (-8 * 28) - 29, y = -(48 + 24 + 16)},
        size = { x=28, y=28 },
        z_index = 0,
	})
	
    hud_manager.add_hud(player,"experience_bar",{
        hud_elem_type = "statbar",
        position = {x=0.5, y=1},
        name = "experience bar",
        text = "experience_bar.png",
        number = temp_pool.xp_bar,
        direction = 0,
        offset = {x = (-8 * 28) - 29, y = -(48 + 24 + 16)},
        size = { x=28, y=28 },
        z_index = 0,
    })
	
    hud_manager.add_hud(player,"xp_level_bg",{
        hud_elem_type = "text",
        position = {x=0.5, y=1},
        name = "xp_level_bg",
        text = tostring(temp_pool.xp_level),
        number = 0x000000,
        offset = {x = 0, y = -(48 + 24 + 24)},
        z_index = 0,
    })                            
    hud_manager.add_hud(player,"xp_level_fg",{
        hud_elem_type = "text",
        position = {x=0.5, y=1},
        name = "xp_level_fg",
        text = tostring(temp_pool.xp_level),
        number = 0xFFFFFF,
        offset = {x = -1, y = -(48 + 24 + 25)},
        z_index = 0,
	})                                                           
end)


local name
local temp_pool
local function level_up_experience(player)
	name = player:get_player_name()
	temp_pool = pool[name]
	
    temp_pool.xp_level = temp_pool.xp_level + 1
	
	hud_manager.change_hud({
		player   = player,
		hud_name = "xp_level_fg",
		element  = "text",
		data     = tostring(temp_pool.xp_level)
	})
	hud_manager.change_hud({
		player   = player,
		hud_name = "xp_level_bg",
		element  = "text",
		data     = tostring(temp_pool.xp_level)
	})
end


local name
local temp_pool
local function add_experience(player,experience)
	name = player:get_player_name()
	temp_pool = pool[name]
	
	temp_pool.xp_bar = temp_pool.xp_bar + experience
	
	if temp_pool.xp_bar > 36 then
		if os.clock() - temp_pool.last_time > 0.04 then
			minetest.sound_play("level_up",{gain=0.2,to_player = name})
			temp_pool.last_time = os.clock()
		end
        temp_pool.xp_bar = temp_pool.xp_bar - 36
		level_up_experience(player)
	else
		if os.clock() - temp_pool.last_time > 0.01 then
			temp_pool.last_time = os.clock()
			minetest.sound_play("experience",{gain=0.1,to_player = name,pitch=math.random(75,99)/100})
		end
	end
	hud_manager.change_hud({
		player   = player,
		hud_name = "experience_bar",
		element  = "number",
		data     = temp_pool.xp_bar
	})
end

--reset player level
local name
local temp_pool
local xp_amount
minetest.register_on_dieplayer(function(player)
	name = player:get_player_name()
	temp_pool = pool[name]
	xp_amount = temp_pool.xp_level
	
	temp_pool.xp_bar   = 0
	temp_pool.xp_level = 0


	hud_manager.change_hud({
		player   = player,
		hud_name = "xp_level_fg",
		element  = "text",
		data     = tostring(temp_pool.xp_level)
	})
	hud_manager.change_hud({
		player   = player,
		hud_name = "xp_level_bg",
		element  = "text",
		data     = tostring(temp_pool.xp_level)
	})

	hud_manager.change_hud({
		player   = player,
		hud_name = "experience_bar",
		element  = "number",
		data     = temp_pool.xp_bar
	})

    minetest.throw_experience(player:get_pos(), xp_amount)                       
end)


local name
local temp_pool
local collector
minetest.register_entity("experience:orb", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
		visual = "sprite",
		visual_size = {x = 0.4, y = 0.4},
		textures = {name="experience_orb.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}},
		spritediv = {x = 1, y = 14},
		initial_sprite_basepos = {x = 0, y = 0},
		is_visible = true,
		pointable = false,
	},
	moving_state = true,
	slippery_state = false,
	physical_state = true,
	-- Item expiry
	age = 0,
	-- Pushing item out of solid nodes
	force_out = nil,
	force_out_start = nil,
	--Collection Variables
	collection_timer = 2,
	collection_timer_goal = collection.collection_time,
	collection_height = 0.8,
	collectable = false,
	try_timer = 0,
	collected = false,
	delete_timer = 0,
	radius = 4,

	get_staticdata = function(self)
		return minetest.serialize({
			age = self.age,
			collection_timer = self.collection_timer,
			collectable = self.collectable,
			try_timer = self.try_timer,
			collected = self.collected,
			delete_timer = self.delete_timer,
			collector = self.collector,
		})
	end,

	on_activate = function(self, staticdata, dtime_s)
		if string.sub(staticdata, 1, string.len("return")) == "return" then
			local data = minetest.deserialize(staticdata)
			if data and type(data) == "table" then
				self.age = (data.age or 0) + dtime_s
				self.collection_timer = data.collection_timer
				self.collectable = data.collectable
				self.try_timer = data.try_timer
				self.collected = data.collected
				self.delete_timer = data.delete_timer
				self.collector = data.collector
				--print("restored timer: "..self.collection_timer)
			end
		else

			local x=math.random(-2,2)*math.random()
			local y=math.random(2,5)
			local z=math.random(-2,2)*math.random()
			self.object:set_velocity(vector.new(x,y,z))
		     -- print(self.collection_timer)
		end
		self.object:set_armor_groups({immortal = 1})
		self.object:set_velocity({x = 0, y = 2, z = 0})
		self.object:set_acceleration({x = 0, y = -9.81, z = 0})
        local size = math.random(20,36)/100
        self.object:set_properties({
			visual_size = {x = size, y = size},
			glow = 14,
		})
		self.object:set_sprite({x=1,y=math.random(1,14)}, 14, 0.05, false)
	end,

	enable_physics = function(self)
		if not self.physical_state then
			self.physical_state = true
			self.object:set_properties({physical = true})
			self.object:set_velocity({x=0, y=0, z=0})
			self.object:set_acceleration({x=0, y=-9.81, z=0})
		end
	end,

	disable_physics = function(self)
		if self.physical_state then
			self.physical_state = false
			self.object:set_properties({physical = false})
			self.object:set_velocity({x=0, y=0, z=0})
			self.object:set_acceleration({x=0, y=0, z=0})
		end
	end,
	on_step = function(self, dtime)
		--if item set to be collected then only execute go to player
		if self.collected == true then
			if not self.collector then
				self.collected = false
				return
			end
			collector = minetest.get_player_by_name(self.collector)
			if collector and collector:get_hp() > 0 and vector.distance(self.object:get_pos(),collector:get_pos()) < 5 then
				temp_pool = pool[self.collector]

				self.object:set_acceleration(vector.new(0,0,0))
				self.disable_physics(self)
				--get the variables
				local pos = self.object:get_pos()
				local pos2 = collector:get_pos()
				
                local player_velocity = collector:get_player_velocity()
                                            
				pos2.y = pos2.y + self.collection_height
								
				local direction = vector.direction(pos,pos2)
				local distance = vector.distance(pos2,pos)
                local multiplier = distance
                if multiplier < 1 then
                    multiplier = 1
                end
				local goal = vector.multiply(direction,multiplier)
                local currentvel = self.object:get_velocity()
				local acceleration

				if distance > 1 then
                    local multiplier = 20 - distance
                    local velocity = vector.multiply(direction,multiplier)
                    local goal = velocity--vector.add(player_velocity,velocity)
					acceleration = vector.new(goal.x-currentvel.x,goal.y-currentvel.y,goal.z-currentvel.z)
					self.object:add_velocity(vector.add(acceleration,player_velocity))
				elseif distance > 0.9 and temp_pool.buffer > 0 then
					temp_pool.buffer = temp_pool.buffer - dtime
					local multiplier = 20 - distance
					local velocity = vector.multiply(direction,multiplier)
					local goal = vector.multiply(minetest.yaw_to_dir(minetest.dir_to_yaw(vector.direction(vector.new(pos.x,0,pos.z),vector.new(pos2.x,0,pos2.z)))+math.pi/2),10)
					goal = vector.add(player_velocity,goal)
					acceleration = vector.new(goal.x-currentvel.x,goal.y-currentvel.y,goal.z-currentvel.z)
					self.object:add_velocity(acceleration)
                end
				if distance < 0.4 and temp_pool.buffer <= 0 then
					temp_pool.buffer = 0.04
                    add_experience(collector,2)
					self.object:remove()
				end
				return
			else
				self.collector = nil
				self.enable_physics(self)
			end
		end
		
		--allow entity to be collected after timer
		if self.collectable == false and self.collection_timer >= self.collection_timer_goal then
			self.collectable = true
		elseif self.collectable == false then
			self.collection_timer = self.collection_timer + dtime
		end
				
		self.age = self.age + dtime
		if self.age > 300 then
			self.object:remove()
			return
		end

		local pos = self.object:get_pos()
		local node
		if pos then
			node = minetest.get_node_or_nil({
				x = pos.x,
				y = pos.y + self.object:get_properties().collisionbox[2] - 0.05,
				z = pos.z
			})
		else
			return
		end

		-- Remove nodes in 'ignore'
		if node and node.name == "ignore" then
			self.object:remove()
			return
		end

		local is_stuck = false
		local snode = minetest.get_node_or_nil(pos)
		if snode then
			local sdef = minetest.registered_nodes[snode.name] or {}
			is_stuck = (sdef.walkable == nil or sdef.walkable == true)
				and (sdef.collision_box == nil or sdef.collision_box.type == "regular")
				and (sdef.node_box == nil or sdef.node_box.type == "regular")
		end

		-- Push item out when stuck inside solid node
		if is_stuck then
			local shootdir
			local order = {
				{x=1, y=0, z=0}, {x=-1, y=0, z= 0},
				{x=0, y=0, z=1}, {x= 0, y=0, z=-1},
			}

			-- Check which one of the 4 sides is free
			for o = 1, #order do
				local cnode = minetest.get_node(vector.add(pos, order[o])).name
				local cdef = minetest.registered_nodes[cnode] or {}
				if cnode ~= "ignore" and cdef.walkable == false then
					shootdir = order[o]
					break
				end
			end
			-- If none of the 4 sides is free, check upwards
			if not shootdir then
				shootdir = {x=0, y=1, z=0}
				local cnode = minetest.get_node(vector.add(pos, shootdir)).name
				if cnode == "ignore" then
					shootdir = nil -- Do not push into ignore
				end
			end

			if shootdir then
				-- Set new item moving speed accordingly
				local newv = vector.multiply(shootdir, 3)
				self:disable_physics()
				self.object:set_velocity(newv)

				self.force_out = newv
				self.force_out_start = vector.round(pos)
				return
			end
		elseif self.force_out then
			-- This code runs after the entity got a push from the above code.
			-- It makes sure the entity is entirely outside the solid node
			local c = self.object:get_properties().collisionbox
			local s = self.force_out_start
			local f = self.force_out
			local ok = (f.x > 0 and pos.x + c[1] > s.x + 0.5) or
				(f.y > 0 and pos.y + c[2] > s.y + 0.5) or
				(f.z > 0 and pos.z + c[3] > s.z + 0.5) or
				(f.x < 0 and pos.x + c[4] < s.x - 0.5) or
				(f.z < 0 and pos.z + c[6] < s.z - 0.5)
			if ok then
				-- Item was successfully forced out
				self.force_out = nil
				self:enable_physics()
			end
		end

		if not self.physical_state then
			return -- Don't do anything
		end

		-- Slide on slippery nodes
		local vel = self.object:get_velocity()
		local def = node and minetest.registered_nodes[node.name]
		local is_moving = (def and not def.walkable) or
			vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0
		local is_slippery = false

		if def and def.walkable then
			local slippery = minetest.get_item_group(node.name, "slippery")
			is_slippery = slippery ~= 0
			if is_slippery and (math.abs(vel.x) > 0.2 or math.abs(vel.z) > 0.2) then
				-- Horizontal deceleration
				local slip_factor = 4.0 / (slippery + 4)
				self.object:set_acceleration({
					x = -vel.x * slip_factor,
					y = 0,
					z = -vel.z * slip_factor
				})
			elseif vel.y == 0 then
				is_moving = false
			end
		end

		if self.moving_state == is_moving and self.slippery_state == is_slippery then
			-- Do not update anything until the moving state changes
			return
		end

		self.moving_state = is_moving
		self.slippery_state = is_slippery
		
		if is_moving then
			self.object:set_acceleration({x = 0, y = -9.81, z = 0})
		else
			self.object:set_acceleration({x = 0, y = 0, z = 0})
			self.object:set_velocity({x = 0, y = 0, z = 0})
		end
	end,
})


minetest.register_chatcommand("xp", {
	params = "nil",
	description = "Spawn x amount of a mob, used as /spawn 'mob' 10 or /spawn 'mob' for one",
	privs = {server=true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		pos.y = pos.y + 1.2
		minetest.throw_experience(pos, 1000)
	end,
})
