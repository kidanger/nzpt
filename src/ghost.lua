local drystal = require 'drystal'

local sprites = require 'data/sprites'

local Ghost = {
	name='ghost',
	map=nil, -- set by Map:add_ghost
	body=nil,
	speed=400,

	radius=0.35,
	sight_radius=90,
	last_seen={x=0, y=0},
	last_seen_timer=0,

	last_random_dx=0,
	last_random_dy=0,

	touch_hero=false,

	is_translucent=true,
}
Ghost.__index = Ghost

function Ghost.new(x, y)
	local ghost = setmetatable({
		x=x,
		y=y,
	}, Ghost)
	return ghost
end

function Ghost:init()
	local head_shape = drystal.new_shape('circle', self.radius)

	self.body = drystal.new_body(true, head_shape)
	self.body:set_position(self.x, self.y)

	self.body:set_angular_damping(6)
	self.body:set_linear_damping(15)
	self.body.parent = self

	self.body.begin_collide = function(body, other)
		if other.parent == self.map.hero then
			self.touch_hero = true
		end
	end
	self.body.end_collide = function(body, other)
		if other.parent == self.map.hero then
			self.touch_hero = false
		end
	end
	return self
end

function Ghost:destroy()
	self.body:destroy()
end

local function raycast_callback(body, fraction)
	if not (body.parent.is_wall or body.parent.is_door) then
		return 1, false
	end
	return fraction, true
end
function Ghost:update(dt)
	if self.touch_hero then
		self.map.hero:take_damage(self)
	end
	local dx, dy = 0, 0
	do
		local x, y = self:get_x(), self:get_y()
		local tx, ty = self.map.hero:get_x(), self.map.hero:get_y()
		if math.abs((x-tx)^2 + (y-ty)^2) < self.sight_radius then
			local collides = drystal.raycast(x, y, tx, ty, raycast_callback)
			if collides == nil then
				self.last_seen_timer = 6
				self.last_seen = {x=tx, y=ty}
			end
		end
		if self.last_seen_timer > 0 then
			self.last_seen_timer = self.last_seen_timer - dt
			dx = self.last_seen.x - x
			dy = self.last_seen.y - y
		else
			dx = self.last_random_dx + math.random(-2, 2)/10
			dy = self.last_random_dy + math.random(-2, 2)/10
			self.last_random_dx = dx
			self.last_random_dy = dy
		end
	end
	do
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
end

function Ghost:draw()
	local sprite = sprites.ombre_null

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

function Ghost:get_x()
	return self.body:get_position()
end
function Ghost:get_y()
	local _, y = self.body:get_position()
	return y
end
function Ghost:get_screen_position()
	local x, y = self.body:get_position()
	return x * R, y * R
end

return Ghost

