local drystal = require 'drystal'
local physic = require 'physic'

local sprites = require 'data/sprites'

local Ghost = {
	name='ghost',
	game=nil, -- set by Game:add_ghost
	body=nil,
	speed=400,

	radius=0.35,
	sight_radius=90,
	last_seen={x=0, y=0},
	has_seen=false,

	is_translucent=true,
}
Ghost.__index = Ghost

function Ghost.new()
	local ghost = setmetatable({}, Ghost)
	return ghost
end

function Ghost:init(x, y)
	local head_shape = physic.new_shape('circle', self.radius)

	self.body = physic.new_body(true, head_shape)
	self.body:set_position(x, y)

	self.body:set_angular_damping(6)
	self.body:set_linear_damping(15)
	self.body.parent = self
	return self
end

function Ghost:destroy()
	self.body:destroy()
end

local function raycast_callback(body, fraction)
	if body.parent.is_translucent then
		return 1, false
	end
	return fraction, true
end
function Ghost:update(dt)
	local dx, dy = 0, 0
	do
		local x, y = self:get_x(), self:get_y()
		local tx, ty = self.game.hero:get_x(), self.game.hero:get_y()
		if math.abs((x-tx)^2 + (y-ty)^2) < self.sight_radius then
			local collides = physic.raycast(x, y, tx, ty, raycast_callback)
			if collides == nil then
				self.has_seen = true
				self.last_seen = {x=tx, y=ty}
			end
		end
		if self.has_seen then
			dx = self.last_seen.x - x
			dy = self.last_seen.y - y
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

