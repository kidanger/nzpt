local drystal = require 'drystal'
local physic = require 'physic'

local sprites = require 'data/sprites'

local Light = {
	x=0,
	y=0,
	radius=4,
	original_radius=4,
	color={255, 255, 255},
	bound_to=nil,
	blink_freq=0,
}
Light.__index = Light

function Light.new(x, y, radius, color)
	radius = radius or Light.radius
	color = color or Light.color
	local l = {
		x=x,
		y=y,
		radius=radius,
		original_radius=radius,
		color=color,
	}
	return setmetatable(l, Light)
end

function Light:init()
	return self
end

function Light:update(dt)
	if self.bound_to then
		local x, y = self.bound_to.body:get_position()
		self.x = x
		self.y = y
	end
	if math.random() < self.blink_freq*dt then
		self.radius = self.radius * 0.8
	elseif math.random() < self.blink_freq*dt then
		self.radius = self.original_radius
	end
end

function Light:old_draw()
	if self.radius == 0 then
		return
	end
	drystal.set_alpha(140)
	drystal.set_color(self.color)
	local oldx, oldy, oldangle, oldd = self.x, self.y, 0, 0
	local delta = math.pi / 50

	local function raycast_callback(body, fraction)
		if body.parent.is_translucent then
			return 1, false
		end
		return fraction, true
	end

	for angle = delta, math.pi * 2+delta, delta do
		local destx, desty =
					self.x + self.radius * math.cos(angle),
					self.y + self.radius * math.sin(angle)
		local collides, x, y = physic.raycast(self.x, self.y, destx, desty, raycast_callback)
		if collides then
			destx = x
			desty = y
		end
		local r = sprites.lightmap.w / 2
		local centerx = sprites.lightmap.x + r
		local centery = sprites.lightmap.y + r
		local d = math.sqrt((destx-self.x)^2 + (desty-self.y)^2) / self.radius * r
		drystal.draw_freeshape(
			centerx, centery,
			centerx+math.cos(angle)*d, centery+math.sin(angle)*d,
			centerx+math.cos(angle)*d, centery+math.sin(angle)*d,
			centerx+math.cos(oldangle)*oldd, centery+math.sin(oldangle)*oldd,

			self.x*R, self.y*R,
			destx*R, desty*R,
			destx*R, desty*R,
			oldx*R, oldy*R
		)
		oldx = destx
		oldy = desty
		oldangle = angle
		oldd = d
	end
end
function Light:new_draw()
	--foreach wall
	--	??
	--end
end
function Light:draw()
	self:old_draw()
	self:new_draw()
end

function Light:associate_with(object)
	self.bound_to = object
end


return Light
