local drystal = require 'drystal'
local physic = require 'physic'

local sprites = require 'data/sprites'

local Hero = {
	body=nil,
	up=false,
	down=false,
	left=false,
	right=false,
	speed=700,

	radius=0.35,
	shoulders_width=.4,
	shoulders_height=1.4,

	anim_state=1,
	anim_speed=0.11,
	anim_timer=0,
	anim=sprites.perso_anim,

	is_translucent=true,
}
Hero.__index = Hero

function Hero.new()
	return setmetatable({}, Hero)
end

function Hero:init(x, y)
	local head_shape = physic.new_shape('circle', self.radius, .05, 0)
	local shoulders_shape = physic.new_shape('box',
			self.shoulders_width, self.shoulders_height, -.15, 0)

	self.body = physic.new_body(true, head_shape, shoulders_shape)
	self.body:set_position(x, y)

	self.body:set_angular_damping(6)
	self.body:set_linear_damping(15)
	self.body.parent = self
end

function Hero:update(dt)
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
end

function Hero:draw()
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
	local x, y = self.body:get_position()
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

return Hero
