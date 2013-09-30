local drystal = require 'drystal'
local physic = require 'physic'

local Hero = require 'src/hero'
local Wall = require 'src/wall'
local Light = require 'src/light'
local sprites = require 'data/sprites'

local Game = {
	hero=nil,
	walls={},
	lights={},

	zoom=1,
	spritesheet=nil,
}
Game.__index = Game

function Game:on_enter()
	physic.create_world(0, 0)
	self.hero = Hero.new()
	self.hero:init(9, 12)

	table.insert(self.walls, Wall.new(12.6, 17, 5, 1):init())
	table.insert(self.walls, Wall.new(12, 16, .6, 7):init())
	table.insert(self.walls, Wall.new(9, 6, 5, 5):init())
	-- map borders
	table.insert(self.walls, Wall.new(0, 0, 35, 5):init())
	table.insert(self.walls, Wall.new(35, 0, 5, 40):init())

	local l1 = Light.new(13, 12, 13, {255, 255, 255})
	l1:associate_with(self.hero)
	table.insert(self.lights, l1)

	local l2 = Light.new(13, 18.5, 10, {150, 150, 255})
	l2.blink_freq = 2
	table.insert(self.lights, l2)

	local l3 = Light.new(10, 17, 4, {255, 0, 0})
	table.insert(self.lights, l3)

	drystal.set_filter_mode(drystal.FILTER_NEAREST)
	self.spritesheet = drystal.load_surface(sprites.image)
	drystal.draw_from(self.spritesheet)
end

function Game:update(dt)
	self.hero:update(dt)

	physic.update(dt)

	for _, l in ipairs(self.lights) do
		l:update(dt)
	end
end

function Game:draw()
	drystal.set_blend_mode(drystal.BLEND_DEFAULT)
	drystal.set_alpha(255)
	drystal.set_color(0, 0, 0)
	drystal.draw_background()

	local sw, sh = drystal.surface_size(drystal.screen)
	local x, y = self.hero:get_screen_position()
	x, y = sw / 2 - x, sh / 2 - y
	drystal.camera.x, drystal.camera.y = x, y
	drystal.camera.zoom = self.zoom

	drystal.set_alpha(255)
	drystal.set_color(0, 0, 0)

	drystal.set_blend_mode(drystal.BLEND_ADD)
	for _, l in ipairs(self.lights) do
		l:draw()
	end

	drystal.set_blend_mode(drystal.BLEND_MULT)
	drystal.set_alpha(255)
	drystal.set_color(255, 255, 255)
	self.hero:draw()
	for _, w in ipairs(self.walls) do
		w:draw()
	end

	drystal.camera.reset()
end

function Game:key_press(key)
	if key == 'q' then
		self.hero:go_left(true)
	elseif key == 'd' then
		self.hero:go_right(true)
	elseif key == 's' then
		self.hero:go_down(true)
	elseif key == 'z' then
		self.hero:go_up(true)
	elseif key == 'p' then
		local r = math.random() * 255
		local g = math.random() * 255
		local b = math.random() * 255
		table.insert(self.lights, Light.new(self.hero:get_x(), self.hero:get_y(),
									math.random(4, 14), {r, g, b}):init())
	elseif key == 'o' then
		OLD_LIGHT = not (OLD_LIGHT or false)
	elseif key == 'l' then
		LIGHT_DEBUG = not (LIGHT_DEBUG or false)
	end
end
function Game:key_release(key)
	if key == 'q' then
		self.hero:go_left(false)
	elseif key == 'd' then
		self.hero:go_right(false)
	elseif key == 's' then
		self.hero:go_down(false)
	elseif key == 'z' then
		self.hero:go_up(false)
	end
end
function Game:mouse_press(x, y, b)
	if b == 4 then
		self.zoom = self.zoom * 1.2
	elseif b == 5 then
		self.zoom = self.zoom / 1.2
	end
end

return setmetatable({}, Game)
