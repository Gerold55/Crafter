--here is where tnt is defined

local function tnt(pos,range)
	local pos = vector.floor(vector.add(pos,0.5))

	local min = vector.add(pos,range)
	local max = vector.subtract(pos,range)
	local vm = minetest.get_voxel_manip()	
	local emin, emax = vm:read_from_map(min,max)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local air = minetest.get_content_id("air")
	local content_id = minetest.get_name_from_content_id
	
	local pos2 = vector.new(0,0,0)
	
	for x=-range, range do
	for y=-range, range do
	for z=-range, range do
		if vector.distance(pos2, vector.new(x,y,z)) <= range then
			local p_pos = area:index(pos.x+x,pos.y+y,pos.z+z)							
			local n = content_id(data[p_pos])
			if n == "tnt:tnt" then
				--print("adding tnt")
				local obj = minetest.add_entity(vector.new(pos.x+x,pos.y+y,pos.z+z),"tnt:tnt")
				obj:get_luaentity().range = 5
				obj:get_luaentity().timer = math.random(1,10)*math.random()
				minetest.sound_play("tnt_ignite", {object=obj, gain = 1.0, max_hear_distance = range*range*range})
			elseif n ~= "air" and n ~= "ignore" then
				if math.random()>0.99 then
					local item = minetest.get_node_drops(n, "main:diamondpick")[1]
					minetest.add_item(vector.new(pos.x+x,pos.y+y,pos.z+z), item)
				end
			end
			
			data[p_pos] = air
		end
	end
	end
	end
	
	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
	
	minetest.sound_play("tnt_explode", {pos = pos, gain = 1.0, max_hear_distance = range*range*range})
	
	--stop client from lagging
	local particle = range
	if particle > 15 then
		particle = 15
	end
	
	minetest.add_particlespawner({
			amount = particle*particle*particle,
			time = 0.001,
			minpos = pos,
			maxpos = pos,
			minvel = vector.new(-range,-range,-range),
			maxvel = vector.new(range,range,range),
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 1.1,
			maxexptime = 1.5,
			minsize = 1,
			maxsize = 2,
			collisiondetection = false,
			vertical = false,
			texture = "smoke.png",
		})
end


minetest.register_entity("tnt:tnt", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "cube",
		visual_size = {x = 1, y = 1},
		textures = {"tnt_top.png", "tnt_bottom.png",
			"tnt_side.png", "tnt_side.png",
			"tnt_side.png", "tnt_side.png"},
		is_visible = true,
		pointable = true,
	},

	timer = 5,
	
	get_staticdata = function(self)
		return minetest.serialize({
			range = self.range,
			timer = self.timer,			
		})
	end,
	
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
		self.object:set_velocity({x = math.random(-5,5), y = 5, z = math.random(-5,5)})
		self.object:set_acceleration({x = 0, y = -9.81, z = 0})
		if string.sub(staticdata, 1, string.len("return")) == "return" then
			local data = minetest.deserialize(staticdata)
			if data and type(data) == "table" then
				self.range = data.range
				self.timer = data.timer
			end
		end
		
		minetest.add_particlespawner({
			amount = 50,
			time = 0,
			minpos = pos,
			maxpos = pos,
			minvel = vector.new(-0.5,1,-0.5),
			maxvel = vector.new(0.5,5,0.5),
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 1.1,
			maxexptime = 1.5,
			minsize = 1,
			maxsize = 2,
			collisiondetection = false,
			vertical = false,
			texture = "smoke.png",
			attached = self.object,
		})
	end,
		
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		local obj = minetest.add_item(self.object:getpos(), "tnt:tnt")
		obj:get_luaentity().collection_timer = 2
		self.object:remove()
	end,

	sound_played = false,
	on_step = function(self, dtime)
		self.timer = self.timer - dtime
		local vel = self.object:getvelocity()
		vel = vector.multiply(vel,-0.05)
		self.object:add_velocity(vector.new(vel.x,0,vel.z))
		
		if self.timer <= 0 then
			local pos = self.object:getpos()
			if not self.range then
				self.range = 7
			end
			tnt(pos,self.range)
			self.object:remove()
		end
	end,
})


minetest.register_node("tnt:tnt", {
    description = "Cobblestone",
    tiles = {"tnt_top.png", "tnt_bottom.png",
			"tnt_side.png", "tnt_side.png",
			"tnt_side.png", "tnt_side.png"},
    groups = {stone = 2, hard = 1, pickaxe = 2, hand = 4},
    sounds = main.stoneSound(),
    on_punch = function(pos, node, puncher, pointed_thing)
		local obj = minetest.add_entity(pos,"tnt:tnt")
		local range = 7
		obj:get_luaentity().range = range
		minetest.sound_play("tnt_ignite", {object = obj, gain = 1.0, max_hear_distance = range*range*range})
		minetest.remove_node(pos)
    end,
})

minetest.register_node("tnt:uh_oh", {
    description = "Cobblestone",
    tiles = {"tnt_top.png", "tnt_bottom.png",
			"tnt_side.png", "tnt_side.png",
			"tnt_side.png", "tnt_side.png"},
    groups = {stone = 2, hard = 1, pickaxe = 2, hand = 4},
    sounds = main.stoneSound(),
    on_punch = function(pos, node, puncher, pointed_thing)
		local range = 10
		for x=-range, range do
		for y=-range, range do
		for z=-range, range do 
			minetest.add_node(vector.new(pos.x+x,pos.y+y,pos.z+z),{name="tnt:tnt"})
		end
		end
		end
    end,
})



minetest.register_craft({
	output = "tnt:tnt",
	recipe = {
		{"main:wood", "main:wood", "main:wood"},
		{"main:wood", "main:coal", "main:wood"},
		{"main:wood", "main:wood", "main:wood"},
	},
})