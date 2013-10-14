local Hero = require 'src/hero'
local Wall = require 'src/wall'
local Light = require 'src/light'
local Ghost = require 'src/ghost'
local Door = require 'src/door'

local walls = {
	Wall.new(12.6, 17, 5, 1),
	Wall.new(12, 16, .6, 7),
	Wall.new(9, 6, 5, 5),

	Wall.new(0, 0, 35, 5),
	Wall.new(35, 0, 5, 40),
}

local lights = {
	Light.new(12, 16, 1.8, {255, 0, 0}),
	Light.new(13, 18.5, 10, {50, 50, 255}),
}

local doors = {
	Door.new(2, 10),
}

local ghosts = {
	Ghost.new(16, 22),
}

local function load_into(map)
	for _, w in ipairs(walls) do
		map:add_wall(w:init())
	end
	for _, d in ipairs(doors) do
		map:add_door(d:init())
	end
	for _, l in ipairs(lights) do
		map:add_light(l:init())
	end
	for _, g in ipairs(ghosts) do
		map:add_ghost(g:init())
	end
end

return {load_into=load_into}
