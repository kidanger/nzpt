local drystal = require 'drystal'
local physic = require 'physic'

local Hero = require 'src/hero'
local Wall = require 'src/wall'
local Light = require 'src/light'
local Ghost = require 'src/ghost'
local Door = require 'src/door'
local sprites = require 'data/sprites'

local mouse_x, mouse_y = 0, 0
local SHOW_DARKNESS = true

local Game = {
	map=nil,

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

-- static initialisation
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

function Game.new()
	local game = setmetatable({}, Game)

	drystal.set_filter_mode(drystal.FILTER_NEAREST)
	game.spritesheet = drystal.load_surface(sprites.image)
	local sw, sh = drystal.surface_size(drystal.screen)
	game.map_surface = drystal.new_surface(sw, sh)

	return game
end

function Game:change_map(map)
	self.map = map

	map.hero = map:new_hero()
	map.hero:init(9, 12)
end

function Game:update(dt)
	local map = self.map

	map.hero:update(dt)
	for _, g in ipairs(map.ghosts) do
		g:update(dt)
	end
	for _, d in ipairs(map.doors) do
		d:update(dt)
	end

	physic.update(dt)

	for i, l in ipairs(map.lights) do
		if l.remove_me then
			table.remove(map.lights, i)
		end
	end
	for _, l in ipairs(map.lights) do
		l:update(dt)
	end
end

function Game:draw()
	local map = self.map

	drystal.set_blend_mode(drystal.BLEND_DEFAULT)
	drystal.set_alpha(255)
	if SHOW_DARKNESS then
		drystal.set_color(0, 0, 0)
	else
		drystal.set_color(200, 200, 200)
	end
	drystal.draw_background()

	local sw, sh = drystal.surface_size(drystal.screen)
	local x, y = map.hero:get_screen_position()
	x, y = sw / 2 - x, sh / 2 - y
	drystal.camera.x, drystal.camera.y = x, y
	drystal.camera.zoom = self.zoom

	drystal.set_alpha(255)
	drystal.set_color(0, 0, 0)

	drystal.draw_from(self.spritesheet)
	drystal.set_blend_mode(drystal.BLEND_ADD)
	for _, l in ipairs(map.lights) do
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
	map.hero:draw()
	drystal.set_color(255, 255, 255)
	for _, g in ipairs(map.ghosts) do
		g:draw()
	end
	drystal.set_color(255, 255, 255)
	for _, w in ipairs(map.walls) do
		w:draw()
	end
	for _, d in ipairs(map.doors) do
		d:draw()
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

	do -- draw hud
		drystal.draw_from(self.spritesheet)
		drystal.camera.reset()
		drystal.set_blend_mode(drystal.BLEND_DEFAULT)
		drystal.set_alpha(255)
		drystal.set_color(255, 255, 255)

		for health = 0, map.hero.max_hp - map.hero.damage_taken - 1 do
			drystal.draw_sprite(sprites.perso_null, 20 + health*sprites.perso_null.w, 20)
		end
	end

	-- update camera to be able to use drystal.screen2scene in event callbacks
	drystal.camera.x, drystal.camera.y = x, y
	drystal.camera.zoom = self.zoom
end

function Game:key_press(key)
	local hero = self.map.hero

	if key == 'q' then
		hero:go_left(true)
	elseif key == 'd' then
		hero:go_right(true)
	elseif key == 's' then
		hero:go_down(true)
	elseif key == 'z' then
		hero:go_up(true)
	elseif key == 'e' then
		hero:try_place_teleporter()
	elseif key == 'space' then
		hero:try_use_teleporter()
	elseif key == 'g' then
		local posx = hero:get_x()+math.random(-10, 10)
		local posy = hero:get_y()+math.random(-10, 10)
		self.map:add_ghost(Ghost.new(posx, posy):init())
	elseif key == 'p' then
		local r = math.random() * 255
		local g = math.random() * 255
		local b = math.random() * 255
		self.map:add_light(Light.new(hero:get_x(), hero:get_y(),
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
	local hero = self.map.hero
	if key == 'q' then
		hero:go_left(false)
	elseif key == 'd' then
		hero:go_right(false)
	elseif key == 's' then
		hero:go_down(false)
	elseif key == 'z' then
		hero:go_up(false)
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
		self.map:remove_at(xx, yy)
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
		self.map:add_wall(Wall.new(minx, miny, w, h):init())
		self.editor.doing = false
	end
end

return Game
