local drystal = require 'drystal'

local Hero = require 'src/hero'
local Wall = require 'src/wall'
local Light = require 'src/light'
local Ghost = require 'src/ghost'
local Door = require 'src/door'
local Editor = require 'src/editor'
local sprites = require 'data/sprites'

local Game = {
	map=nil,

	map_surface=nil,
	zoom=1,
	spritesheet=nil,
	editor=nil,

	show_darkness=true,
}
Game.__index = Game

-- static initialisation
function Game.new()

	drystal.init_physics(0, 0)
	drystal.on_collision(
		function (b1, b2)
			if b1.begin_collide then b1:begin_collide(b2) end
			if b2.begin_collide then b2:begin_collide(b1) end
		end,
		function (b1, b2)
			if b1.end_collide then b1:end_collide(b2) end
			if b2.end_collide then b2:end_collide(b1) end
		end
		)

	local game = setmetatable({}, Game)

	game.spritesheet = assert(drystal.load_surface(sprites.image))
	game.spritesheet:set_filter(drystal.filters.nearest)
	local sw, sh = drystal.screen.w, drystal.screen.h
	game.map_surface = drystal.new_surface(sw, sh, true)

	game.editor = Editor.new(game)
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
	if not self.editor.activated then
		for _, g in ipairs(map.ghosts) do
			g:update(dt)
		end
	end
	for _, d in ipairs(map.doors) do
		d:update(dt)
	end

	drystal.update_physics(dt)

	for i, l in ipairs(map.lights) do
		if l.remove_me then
			table.remove(map.lights, i)
		end
	end
	for _, l in ipairs(map.lights) do
		l:update(dt)
	end

	if self.editor.activated then
		self.editor:update(dt)
	end
end

function Game:draw()
	local sw, sh = drystal.screen.w, drystal.screen.h
	local map = self.map

	drystal.set_blend_mode(drystal.blends.default)
	drystal.set_alpha(255)
	if self.show_darkness then
		drystal.set_color(0, 0, 0)
	else
		drystal.set_color(120, 120, 120)
	end
	drystal.draw_background()

	self:game_camera()

	drystal.set_alpha(255)
	drystal.set_color(0, 0, 0)

	self.spritesheet:draw_from()
	drystal.set_blend_mode(drystal.blends.add)
	for _, l in ipairs(map.lights) do
		l:draw()
	end

	self.map_surface:draw_on()
	drystal.set_blend_mode(drystal.blends.default)
	drystal.set_alpha(255)
	drystal.set_color(255, 255, 255)
	do
		local x, y = drystal.camera.x, drystal.camera.y
		local startx, starty = drystal.screen2scene(0, 0)
		local endx, endy = drystal.screen2scene(sw, sh)
		local sprite = sprites.parquet
		local ox, oy = x % sprite.w, y % sprite.h
		for x = startx - sprite.w - ox, endx, sprite.w-2 do
			for y = starty - sprite.h - oy, endy, sprite.h-2 do
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

	do -- blit map on screen (multiplied)
		drystal.screen:draw_on()
		self.map_surface:draw_from()
		self:gui_camera()
		drystal.set_blend_mode(drystal.blends.mult)
		drystal.set_alpha(255)
		drystal.set_color(255, 255, 255)
		local spmap = {x=0, y=0, w=sw, h=sh}
		drystal.draw_sprite(spmap, 0, 0)
	end

	drystal.set_blend_mode(drystal.blends.default)
	self.spritesheet:draw_from()

	if self.editor.activated then
		self.editor:draw()
	end

	do -- draw hud
		self:gui_camera()
		drystal.set_alpha(255)
		drystal.set_color(255, 255, 255)

		for health = 0, map.hero.max_hp - map.hero.damage_taken - 1 do
			drystal.draw_sprite(sprites.perso_null, 20 + health*sprites.perso_null.w, 20)
		end
	end
end

function Game:m2g(x, y) -- mouse to game
	self:game_camera()
	local xx, yy = drystal.screen2scene(x, y)
	xx = xx / R
	yy = yy / R
	return xx, yy
end
function Game:gui_camera()
	drystal.camera.reset()
end
function Game:game_camera()
	local sw, sh = drystal.screen.w, drystal.screen.h
	local x, y = self.map.hero:get_screen_position()
	x, y = x - sw / 2, y - sh / 2
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
	elseif self.editor.activated then
		self.editor:key_press(key)
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
	elseif key == 'c' then
		self.editor:toggle()
	elseif self.editor.activated then
		self.editor:key_release(key)
	end
end
function Game:mouse_motion(x, y)
	if self.editor.activated then
		self.editor:mouse_motion(x, y)
	end
end
function Game:mouse_press(x, y, b)
	if self.editor.activated then
		self.editor:mouse_press(x, y, b)
	end
	if b == 4 then
		if self.zoom < 3 then
			self.zoom = self.zoom * 1.2
		end
	elseif b == 5 then
		if self.zoom > 0.2 then
			self.zoom = self.zoom / 1.2
		end
	end
end
function Game:mouse_release(x, y, b)
	if self.editor.activated then
		self.editor:mouse_release(x, y, b)
	end
end

return Game
