local drystal = require 'drystal'

local Light = require 'src/light'
local Teleporter = require 'src/teleporter'
local Ghost = require 'src/ghost'
local sprites = require 'data/sprites'

local Hero = {
	name='hero',
	map=nil,
	body=nil,
	up=false,
	down=false,
	left=false,
	right=false,
	speed=700,

	damage_taken=0,
	max_hp=2,
	took_damage_timer=0,

	radius=0.35,
	shoulders_width=.4,
	shoulders_height=1.4,

	anim_state=1,
	anim_speed=0.11,
	anim_timer=0,
	anim=sprites.perso_anim,

	teleporter=nil,

	light_radius=13,
	light=nil,

	is_translucent=true,
}
Hero.__index = Hero

function Hero.new()
	local hero = setmetatable({}, Hero)

	hero.light = Light.new(0, 0, hero.light_radius, {255, 255, 255})
	return hero
end

function Hero:init(x, y)
	local head_shape = drystal.new_shape('circle', self.radius, .05, 0)
	local shoulders_shape = drystal.new_shape('box',
			self.shoulders_width, self.shoulders_height, -self.shoulders_width / 2 - .15, -self.shoulders_height / 2)

	self.body = drystal.new_body(true, x, y, head_shape, shoulders_shape)

	self.body:set_angular_damping(6)
	self.body:set_linear_damping(15)
	self.body.parent = self

	self.light:init()
	self.map:add_light(self.light)
	self.light:associate_with(self)
	return self
end

function Hero:update(dt)
	self.took_damage_timer = math.max(self.took_damage_timer - dt, 0)

	local moving = false

	local dx, dy = self.body:get_linear_velocity()
	local oldspeed = math.abs(dx)+math.abs(dy)

	do
		local dx, dy = 0, 0
		if self.up then
			dy = dy - 1
		end
		if self.down then
			dy = dy + 1
		end
		if self.left then
			dx = dx - 1
		end
		if self.right then
			dx = dx + 1
		end

		local d = math.sqrt(dx^2 + dy^2)
		if d ~= 0 then
			dx = dx / d
			dy = dy / d
			moving = true
		end
		
		local speed = self.speed * dt

		if moving then
			self.body:set_linear_velocity(dx*speed, dy*speed)

			local desire_angle = math.atan2(dy, dx) % (math.pi*2)
			local angle = (self.body:get_angle()) % (math.pi*2)
			-- little hack to make angle works as expected (search shorter angle)
			local delta1 = desire_angle - angle
			local delta2 = desire_angle - math.pi*2 - angle
			local delta3 = desire_angle - (angle-math.pi*2)
			local delta_angle = delta1
			for _, d in ipairs({delta1, delta2, delta3}) do
				if math.abs(d) < math.abs(delta_angle) then
					delta_angle = d
				end
			end
			self.body:set_angular_velocity(delta_angle*10)
		else
			self.body:set_angular_velocity(0)
		end
	end
	do
		if moving then
			oldspeed = math.min(oldspeed/10, 1)
			self.anim_timer = self.anim_timer + dt * oldspeed
			if self.anim_timer >= self.anim_speed then
				self.anim_state = 1 + ((self.anim_state + 1) % #self.anim)
				self.anim_timer = 0
			end
		else
			self.anim_state = 1
		end
	end

	if self.teleporter then
		self.teleporter:update(dt)
	end
end

function Hero:draw()
	if self.teleporter then
		self.teleporter:draw()
	end

	if self.took_damage_timer > .2 then
		drystal.set_color(255, 0, 0)
	end

	local sprite = self.anim[self.anim_state]

	local angle = self.body:get_angle() + math.pi/2
	local x, y = self:get_screen_position()
	local radius = .8
	local w, h = (R * radius * 2), (R * radius * 2) * sprite.h/sprite.w
	local transform = {
		angle=angle,
		wfactor=w / sprite.w,
		hfactor=h / sprite.h,
	}
	drystal.draw_sprite(sprite, x-w/2, y-h/2, transform)
end

function Hero:get_x()
	return self.body:get_position()
end
function Hero:get_y()
	local _, y = self.body:get_position()
	return y
end
function Hero:get_screen_position()
	local x, y = self.body:get_center_position()
	return x * R, y * R
end

function Hero:go_up(bool)
	self.up = bool
end
function Hero:go_down(bool)
	self.down = bool
end
function Hero:go_left(bool)
	self.left = bool
end
function Hero:go_right(bool)
	self.right = bool
end

function Hero:take_damage(from)
	if self.took_damage_timer == 0 then
		self.damage_taken = self.damage_taken + 1
		local dx = self:get_x() - from:get_x()
		local dy = self:get_y() - from:get_y()
		self.body:apply_linear_impulse(dx*30, dy*30)
		self.took_damage_timer = 1
	end
end

function Hero:try_grab_teleporter()
	if self.teleporter then
		local dist = math.sqrt((self.teleporter.x-self:get_x())^2 + (self.teleporter.y-self:get_y())^2)
		if dist < self.radius + self.teleporter.radius then
			self.teleporter:destroy()
			self.teleporter = nil
			return true
		end
	end
	return false
end

function Hero:try_place_teleporter()
	if self.teleporter then
		self:try_grab_teleporter()
	else
		self.teleporter = Teleporter.new()
		self.teleporter:init(self:get_x(), self:get_y())
		self.map:add_light(self.teleporter.light)
	end
end

function Hero:try_use_teleporter()
	if self.teleporter ~= nil and self.teleporter.is_loaded then
		self.teleporter:use(self)
		self:try_grab_teleporter()

		-- spawn a ghost
		local posx = self:get_x()+math.random(-10, 10)
		local posy = self:get_y()+math.random(-10, 10)
		local ghost = Ghost.new(posx, posy):init()
		self.map:add_ghost(ghost)
	end
end

return Hero
