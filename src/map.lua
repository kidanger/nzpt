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

function Map:remove(object)
	local function remove_from(_table)
		for i, e in ipairs(_table) do
			if e == object then
				e:destroy()
				table.remove(_table, i)
				break
			end
		end
	end
	remove_from(self.walls)
	remove_from(self.lights)
	remove_from(self.ghosts)
	remove_from(self.doors)
end
local function distance(x, y, x2, y2)
	return math.sqrt((x2-x)^2 + (y2-y)^2)
end
function Map:remove_at(x, y, filter)
	local objects = physic.query(x-0.1, y-0.1, x+0.1, y+0.1)
	for _, o in ipairs(objects) do
		if filter(o.parent) then
			self:remove(o.parent)
		end
	end
	for _, l in ipairs(self.lights) do
		if l ~= self.hero.light and distance(x, y, l.x, l.y) < l.original_radius and filter(l) then
			self:remove(l)
		end
	end
end

return Map

