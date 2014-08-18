local drystal = require 'drystal'

local Wall = {
	name='wall',
	body=nil,
	x=0,
	y=0,
	w=0,
	h=0,
	is_wall=true,
	vertices={},
}
Wall.__index = Wall

function Wall.new(x, y, w, h)
	local wall = {
		x=x,
		y=y,
		w=w,
		h=h,
	}
	wall.vertices = {
		{x=x, y=y},
		{x=x+w, y=y},
		{x=x+w, y=y+h},
		{x=x, y=y+h},
	}
	return setmetatable(wall, Wall)
end

function Wall:init()
	local shape = drystal.new_shape('box', self.w, self.h)
	self.body = drystal.new_body(false, self.x, self.y, shape)
	self.body.parent = self
	return self
end

function Wall:destroy()
	self.body:destroy()
	self.body = nil
end

function Wall:draw()
	drystal.set_color(0, 0, 0)
	local x, y = self:get_screen_position()
	drystal.draw_rect(x, y, self.w*R, self.h*R)
end

function Wall:get_screen_position()
	return self.x * R, self.y * R
end

return Wall
