local drystal = require 'drystal'

local Wall = require 'src/wall'

local WallElement = {
	name='Wall',
	game=nil,

	sx=0,
	sy=0,
	doing=false,
}
WallElement.__index = WallElement

function WallElement:draw()
	if self.doing then
		local x, y = self.game.editor:get_mouse()
		x = math.floor(x+.5)
		y = math.floor(y+.5)
		local minx = math.min(x, self.sx)
		local miny = math.min(y, self.sy)
		local w = math.abs(self.sx - x)
		local h = math.abs(self.sy - y)
		drystal.draw_rect(minx*R, miny*R, w*R, h*R)

		drystal.draw_circle(self.sx*R, self.sy*R, R/4)
	end
end

function WallElement:press(x, y)
	x = math.floor(x+.5)
	y = math.floor(y+.5)
	self.sx = x
	self.sy = y
	self.doing = true
end

function WallElement:release(x, y)
	x = math.floor(x+.5)
	y = math.floor(y+.5)
	local minx = math.min(x, self.sx)
	local miny = math.min(y, self.sy)
	local w = math.abs(self.sx - x)
	local h = math.abs(self.sy - y)
	if w > 0 and h > 0 then
		self.game.map:add_wall(Wall.new(minx, miny, w, h):init())
	end
	self.doing = false
end

function WallElement.filter(object)
	return object.is_wall
end

return WallElement

