local drystal = require 'drystal'
local physic = require 'physic'

local Light = require 'src/light'
local sprites = require 'data/sprites'

local Teleporter = {
	name='teleporter',
	x=0,
	y=0,
	radius=0.5,

	light=nil,
	light_radius=4,
	light_color={50, 200, 50},
	light_diode_freq=.3,
	light_state=0,

	is_loaded=false, -- ready to use
	load_speed=4, -- seconds to load fully
}
Teleporter.__index = Teleporter

function Teleporter.new()
	local teleporter =  setmetatable({}, Teleporter)
	return teleporter
end

function Teleporter:init(x, y)
	self.x, self.y = x, y
	self.light = Light.new(x, y, 0, self.light_color)
	self.light.radius_changeable = true
	self.light:init()
	return self
end

function Teleporter:destroy()
	self.light:destroy()
	self.light = nil
	self.is_loaded = false
end

function Teleporter:update(dt)
	if self.light_state == 0 then
		local speed = self.light_radius / self.load_speed
		self.light:change_radius(self.light.radius + dt*speed)
		if self.light.radius >= self.light_radius then
			self.light_state = 1
		end
	elseif self.light_state == 1 then
		self.light.diode_freq = self.light_diode_freq
		self.light_state = 2
		self.is_loaded = true
	end
end

function Teleporter:draw()
	local sprite = sprites.balise
	local x, y = self.x * R, self.y * R
	local w, h = (R * self.radius * 2), (R * self.radius * 2) * sprite.h/sprite.w
	local transform = {
		angle=0,
		wfactor=w / sprite.w,
		hfactor=h / sprite.h,
	}

	drystal.draw_sprite(sprite, x-w/2, y-h/2, transform)
end

function Teleporter:use(hero)
	hero.body:set_position(self.x, self.y)
end

return Teleporter
