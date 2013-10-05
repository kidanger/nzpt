local drystal = require 'drystal'
local physic = require 'physic'

local Hero = require 'src/hero'
local Wall = require 'src/wall'
local Light = require 'src/light'
local Ghost = require 'src/ghost'
local sprites = require 'data/sprites'

local mouse_x, mouse_y = 0, 0
local SHOW_DARKNESS = true

local Game = {
	hero=nil,
	walls={},
	lights={},
	ghosts={},

	map_surface=nil,
	zoom=1,
	spritesheet=nil,

	editor={
		sx=0,
		sy=0,
		doing=false,
	},
}
Game.__index = Game

function Game:on_enter()
	physic.create_world(0, 0)
	physic.on_collision(
		function (b1, b2)
			if b1.begin_collide then b1:begin_collide(b2) end
			if b2.begin_collide then b2:begin_collide(b1) end
		end,
		function (b1, b2)
			if b1.end_collide then b1:end_collide(b2) end
			if b2.end_collide then b2:end_collide(b1) end
		end
	)
	self.hero = Hero.new(self)
	self.hero:init(9, 12)

	table.insert(self.walls, Wall.new(12.6, 17, 5, 1):init())
	table.insert(self.walls, Wall.new(12, 16, .6, 7):init())
	table.insert(self.walls, Wall.new(9, 6, 5, 5):init())
	-- map borders
	table.insert(self.walls, Wall.new(0, 0, 35, 5):init())
	table.insert(self.walls, Wall.new(35, 0, 5, 40):init())

	local l1 = Light.new(13, 12, 13, {255, 255, 255})
	l1:associate_with(self.hero)
	self:add_light(l1)

	local l2 = Light.new(13, 18.5, 10, {50, 50, 255})
	l2.blink_freq = 2
	self:add_light(l2)

	local l3 = Light.new(12, 16, 1.8, {255, 0, 0})
	-- l3.diode_freq = 0.1
	self:add_light(l3)

	drystal.set_filter_mode(drystal.FILTER_NEAREST)
	self.spritesheet = drystal.load_surface(sprites.image)
	local sw, sh = drystal.surface_size(drystal.screen)
	self.map_surface = drystal.new_surface(sw, sh)
end

function Game:add_light(light)
	table.insert(self.lights, light)
end

function Game:add_ghost(ghost)
	ghost.game = self
	table.insert(self.ghosts, ghost)
end

function Game:update(dt)
	self.hero:update(dt)
	for _, g in ipairs(self.ghosts) do
		g:update(dt)
	end

	physic.update(dt)

	for i, l in ipairs(self.lights) do
		if l.remove_me then
			table.remove(self.lights, i)
		end
	end
	for _, l in ipairs(self.lights) do
		l:update(dt)
	end
end

function Game:draw()
	drystal.set_blend_mode(drystal.BLEND_DEFAULT)
	drystal.set_alpha(255)
	if SHOW_DARKNESS then
		drystal.set_color(0, 0, 0)
	else
		drystal.set_color(200, 200, 200)
	end
	drystal.draw_background()

	local sw, sh = drystal.surface_size(drystal.screen)
	local x, y = self.hero:get_screen_position()
	x, y = sw / 2 - x, sh / 2 - y
	drystal.camera.x, drystal.camera.y = x, y
	drystal.camera.zoom = self.zoom

	drystal.set_alpha(255)
	drystal.set_color(0, 0, 0)

	drystal.draw_from(self.spritesheet)
	drystal.set_blend_mode(drystal.BLEND_ADD)
	for _, l in ipairs(self.lights) do
		l:draw()
	end

	drystal.draw_on(self.map_surface)
	drystal.set_blend_mode(drystal.BLEND_DEFAULT)
	drystal.set_alpha(255)
	drystal.set_color(255, 255, 255)
	drystal.draw_background()
	do
		local startx, starty = drystal.screen2scene(0, 0)
		local endx, endy = drystal.screen2scene(sw, sh)
		local sprite = sprites.parquet
		local ox, oy = x % sprite.w, y % sprite.h
		for x = startx - sprite.w + ox, endx, sprite.w-2 do
			for y = starty - sprite.h + oy, endy, sprite.h-2 do
				drystal.draw_sprite(sprite, x, y)
			end
		end
	end
	self.hero:draw()
	for _, g in ipairs(self.ghosts) do
		g:draw()
	end
	for _, w in ipairs(self.walls) do
		w:draw()
	end

	if self.editor.doing then
		drystal.set_alpha(150)
		drystal.set_color(0, 0, 0)
		local xx, yy = drystal.screen2scene(mouse_x, mouse_y)
		xx = xx - xx % 16
		yy = yy - yy % 16
		local minx = math.min(xx, self.editor.sx*R)
		local miny = math.min(yy, self.editor.sy*R)
		drystal.draw_rect(minx, miny,
							math.abs(xx - self.editor.sx*R),
							math.abs(yy - self.editor.sy*R))
	end

	drystal.draw_on(drystal.screen)
	drystal.draw_from(self.map_surface)
	drystal.camera.reset()
	drystal.set_blend_mode(drystal.BLEND_MULT)
	drystal.set_alpha(255)
	drystal.set_color(255, 255, 255)
	local spmap = {x=0, y=0, w=sw, h=sh}
	drystal.draw_sprite(spmap, 0, 0)

	drystal.camera.x, drystal.camera.y = x, y
	drystal.camera.zoom = self.zoom
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
	elseif key == 'e' then
		self.hero:try_place_teleporter()
	elseif key == 'space' then
		self.hero:try_use_teleporter()
	elseif key == 'g' then
		local posx = self.hero:get_x()+math.random(-10, 10)
		local posy = self.hero:get_y()+math.random(-10, 10)
		self:add_ghost(Ghost.new():init(posx, posy))
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
	elseif key == 'w' then
		SHOW_DARKNESS = not SHOW_DARKNESS
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
function Game:mouse_motion(x, y)
	mouse_x = x
	mouse_y = y
end
function Game:mouse_press(x, y, b)
	local xx, yy = drystal.screen2scene(x, y)
	xx = xx - xx % 16
	yy = yy - yy % 16
	xx = xx / R; yy = yy / R
	if b == 1 then
		self.editor.sx = xx
		self.editor.sy = yy
		self.editor.doing = true
	elseif b == 3 then
		local objects = physic.query(xx-0.1, yy-0.1, xx+0.1, yy+0.1)
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
	elseif b == 4 then
		self.zoom = self.zoom * 1.2
	elseif b == 5 then
		self.zoom = self.zoom / 1.2
	end
end
function Game:mouse_release(x, y, b)
	local xx, yy = drystal.screen2scene(x, y)
	xx = xx - xx % 16
	yy = yy - yy % 16
	xx = xx / R; yy = yy / R
	if b == 1 then
		local minx = math.min(xx, self.editor.sx)
		local miny = math.min(yy, self.editor.sy)
		local w = math.abs(self.editor.sx - xx)
		local h = math.abs(self.editor.sy - yy)
		table.insert(self.walls, Wall.new(minx, miny, w, h):init())
		self.editor.doing = false
	end
end

return setmetatable({}, Game)
