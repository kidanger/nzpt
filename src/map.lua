local drystal = require 'drystal'
local physic = require 'physic'

local Hero = require 'src/hero'

local Map = {
	hero=nil,
	walls={},
	lights={},
	ghosts={},
	doors={},
	stairs_up=nil, -- TODO
	stairs_down=nil, -- TODO
}
Map.__index = Map

function Map.new()
	local map = setmetatable({}, Map)
	return map
end

function Map.load_from_file(filename)
	filename = 'maps/' .. filename
	if not drystal.file_exists(filename .. '.lua') then
		print(filename .. '.lua doesn\'t exists')
		return nil
	end
	local mapdata = require(filename)
	local map = Map.new()
	mapdata.load_into(map)
	return map
end

function Map:unload()
	local function destroy_all(table)
		for _, e in ipairs(table) do e:destroy() end
	end
	destroy_all(self.walls)
	destroy_all(self.lights)
	destroy_all(self.ghosts)
	destroy_all(self.doors)
	self.hero:destroy()
end

function Map:new_hero()
	self.hero = Hero.new()
	self.hero.map = self
	return self.hero
end

function Map:add_wall(wall)
	table.insert(self.walls, wall)
end

function Map:add_light(light)
	table.insert(self.lights, light)
end

function Map:add_ghost(ghost)
	ghost.map = self
	table.insert(self.ghosts, ghost)
end

function Map:add_door(door)
	door.map = self
	table.insert(self.doors, door)
end

function Map:remove_at(x, y)
	local objects = physic.query(x-0.1, y-0.1, x+0.1, y+0.1)
	for _, o in ipairs(objects) do
		if o.parent.is_wall then
			for i, w in ipairs(self.walls) do
				if w == o.parent then
					w:destroy()
					table.remove(self.walls, i)
					break
				end
			end
		end
	end
end

return Map

