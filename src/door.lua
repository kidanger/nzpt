local drystal = require 'drystal'

local Door = {
	game=nil,
	name='door',
	body=nil,
	joint=nil,

	x=0,
	y=0,
	w=1.7,
	h=0.3,
	small_radius=.22,

	is_translucent=true,
	is_door=true,
}
Door.__index = Door

function Door.new(x, y)
	local door = setmetatable({
		x=x,
		y=y,
	}, Door)
	return door
end

function Door:init()
	local x, y = self.x + self.w/2, self.y + self.h/2

	local shape = drystal.new_shape('box', self.w, self.h, -self.w/2, -self.h/2)
	self.body = drystal.new_body(true, x, y, shape)
	self.body.parent = self

	local shape2 = drystal.new_shape('circle', self.small_radius)
	self.body2 = drystal.new_body(false, x, y, shape2)
	self.body2.parent = self

	self.joint = drystal.new_joint('revolute', self.body, self.body2,
									-self.w/2, 0, 0, 0, false)
	self.joint:set_angle_limits(0, math.pi*.6)
	return self
end

function Door:destroy()
	self.joint:destroy()
	self.body:destroy()
	self.body = nil
	self.body2:destroy()
	self.body2 = nil
end

function Door:update()
	local angle = self.body:get_angle()
	if angle ~= 0 then
		self.joint:set_motor_speed(angle * 6, 20)
	end
end

function Door:draw()
	drystal.set_color(255, 255, 0)
	local x, y = self.body:get_position()
	local angle = self.body:get_angle()
	drystal.draw_rect_rotated((x-self.w/2)*R, (y-self.h/2)*R, self.w*R, self.h*R, angle)

	drystal.set_color(255, 200, 50)
	local x, y = self.body2:get_position()
	drystal.draw_circle(x*R, y*R, self.small_radius*R)
end

return Door

