local drystal = require 'drystal'

local Light = require 'src/light'
local hsl = require 'src/hsl'

local LightElement = {
	name='Light',
	game=nil,

	sx=0,
	sy=0,
	doing=false,
}
LightElement.__index = LightElement

local function distance(x, y, x2, y2)
	return math.sqrt((x2-x)^2 + (y2-y)^2)
end

function LightElement:draw()
	if self.doing then
		local x, y = self.game.editor:get_mouse()
		local radius = distance(self.sx, self.sy, x, y)
		local color = self:get_color(x, y)

		drystal.set_line_width(R/2)
		drystal.draw_line(self.sx*R, self.sy*R, x*R, y*R)
		drystal.set_color(color)
		drystal.draw_circle(self.sx*R, self.sy*R, radius*R)
	end
end

function LightElement:press(x, y)
	self.sx = x
	self.sy = y
	self.doing = true
end

function LightElement:get_color(x, y)
	local hue = math.deg(math.atan2(self.sy - y, self.sx - x)) % 360
	return hsl(hue, .4, .4)
end

function LightElement:release(x, y)
	local radius = distance(self.sx, self.sy, x, y) * 1.5
	local color = self:get_color(x, y)
	if radius > 0 then
		self.game.map:add_light(Light.new(self.sx, self.sy, radius, color):init())
	end
	self.doing = false
end

function LightElement.filter(object)
	return object.is_light
end

return LightElement

