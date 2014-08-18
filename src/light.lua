local drystal = require 'drystal'

local sprites = require 'data/sprites'

local Light = {
	name='light',
	x=0,
	y=0,
	radius=4,
	original_radius=4,
	color={255, 255, 255},
	bound_to=nil,
	blink_freq=0,

	diode_timer=0,
	diode_freq=0,

	radius_changeable=false,

	buffer=nil,
	modified=true,
	freed=false,

	remove_me=false,
	is_light=true,
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
	l.buffer = drystal.new_buffer()
	return setmetatable(l, Light)
end

function Light:init()
	return self
end

function Light:destroy()
	if self.buffer then
		self.buffer = nil
		self.remove_me = true
	end
end

function Light:change_radius(new_radius)
	if new_radius ~= self.original_radius then
		self.original_radius = new_radius
		self.radius = new_radius
		self.modified = true
	end
end

function Light:update(dt)
	if self.bound_to then
		local x, y = self.bound_to.body:get_position()
		local delta = 0.1
		if math.abs(x - self.x) > delta or math.abs(y - self.y) > delta then
			self.x = x
			self.y = y
			self.modified = true
		end
	end
	if self.diode_freq > 0 then
		self.diode_timer = self.diode_timer + dt
		if self.diode_timer > self.diode_freq then
			self.diode_timer = 0
			if self.radius == 0 then
				self.radius = self.original_radius
			else
				self.radius = 0
			end
			self.modified = true
		end
	end
	if math.random() < self.blink_freq*dt then
		self.radius = self.radius * 0.8
		self.modified = true
	elseif math.random() < self.blink_freq*dt then
		self.radius = self.original_radius
		self.modified = true
	end
end

local function raycast_callback(body, fraction)
	if body.parent.is_translucent then
		return 1, false
	end
	return fraction, true
end

function Light:old_draw()
	local oldx, oldy, oldangle, oldd = self.x, self.y, 0, 0
	local delta = math.pi / 50

	for angle = delta, math.pi * 2+delta, delta do
		local destx, desty =
					self.x + self.radius * math.cos(angle),
					self.y + self.radius * math.sin(angle)
		local collides, x, y = drystal.raycast(self.x, self.y, destx, desty, raycast_callback)
		if collides then
			destx = x
			desty = y
		end
		local r = sprites.lightmap.w / 2
		local centerx = sprites.lightmap.x + r
		local centery = sprites.lightmap.y + r
		local d = math.sqrt((destx-self.x)^2 + (desty-self.y)^2) / self.radius * r
		drystal.draw_surface(
			centerx, centery,
			centerx+math.cos(angle)*d, centery+math.sin(angle)*d,
			centerx+math.cos(oldangle)*oldd, centery+math.sin(oldangle)*oldd,

			self.x*R, self.y*R,
			destx*R, desty*R,
			oldx*R, oldy*R
		)
		oldx = destx
		oldy = desty
		oldangle = angle
		oldd = d
		if LIGHT_DEBUG then
			drystal.draw_line(self.x*R, self.y*R, destx*R, desty*R)
		end
	end
end

function Light:new_draw()
	local objects = drystal.query(
		self.x - self.radius, self.y - self.radius,
		self.x + self.radius, self.y + self.radius
	)
	local points = {}
	--local penumbra_points = {}
	function distanceto(x, y)
		return math.sqrt((x-self.x)^2 + (y-self.y)^2)
	end
	function projected(p, addangle)
		addangle = addangle or 0
		local destx = self.x + math.cos(p.angle + addangle) * self.radius
		local desty = self.y + math.sin(p.angle + addangle) * self.radius
		local collides, colx, coly = drystal.raycast(self.x, self.y,
									destx, desty, raycast_callback)
		local x, y = colx or destx, coly or desty
		local distance = distanceto(x, y) / self.radius
		local p = {
			x=x,
			y=y,
			angle=p.angle + addangle,
			distance=distance,
		}
		return p
	end
	local debug = LIGHT_DEBUG
	for _, o in ipairs(objects) do
		local parent = o.parent
		if parent.is_wall then
			for i, vertex in ipairs(parent.vertices) do
				local collides, colx, coly = drystal.raycast(self.x, self.y,
							vertex.x, vertex.y, raycast_callback)
				local x, y = colx or vertex.x, coly or vertex.y

				local angle = math.atan2(y - self.y, x - self.x) % (math.pi*2)
				local distance = distanceto(x, y) / self.radius
				local new_point = {x=x, y=y, angle=angle, distance=distance}
				--table.insert(points, new_point)

				if debug then
					--drystal.set_color(255, 0, 0)
					--drystal.draw_line(self.x*R, self.y*R, x*R, y*R)
				end

				local delta = math.pi / 1000
				local proj = projected(new_point, delta)
				local proj2 = projected(new_point, -delta)
				table.insert(points, proj)
				table.insert(points, proj2)

				--if x == vertex.x and y == vertex.y and math.abs(proj2.distance - proj.distance) > 0.02 then
				--	local orientation = proj2.distance < proj.distance and math.pi/10 or -math.pi/10
				--	local consumed = distanceto(x, y)
				--	local newradius = (self.radius - consumed) * .6
				--	table.insert(penumbra_points, {
				--		x=x,
				--		y=y,
				--		angle=angle-orientation,
				--		orientation=orientation,
				--		distance=math.max(proj.distance, proj2.distance)*newradius,
				--	})
				--end

				if debug then
					drystal.set_color(255, 255, 0)
					drystal.draw_line(self.x*R, self.y*R, proj.x*R, proj.y*R)
					drystal.draw_line(self.x*R, self.y*R, proj2.x*R, proj2.y*R)
				end
			end
		end
	end
	table.sort(points, function(p1, p2)
		if p1.angle ~= p2.angle then
			return p1.angle < p2.angle
		end
		return p1.distance < p2.distance
	end)
	if #points > 0 then
		local maxdelta = math.pi / 6

		drystal.set_color(0, 0, 255)
		local p1 = points[1]
		while p1.angle >= maxdelta do
			local proj = projected(p1, -maxdelta)
			table.insert(points, 1, proj)
			p1 = points[1]
			if debug then
				drystal.draw_line(self.x*R, self.y*R, proj.x*R, proj.y*R)
			end
		end

		drystal.set_color(200, 0, 200)
		local pn = points[#points]
		while pn.angle < math.pi*2 - maxdelta do
			local proj = projected(pn, maxdelta)
			table.insert(points, proj)
			pn = points[#points]
			if debug then
				drystal.draw_line(self.x*R, self.y*R, proj.x*R, proj.y*R)
			end
		end

		do
			local i = 1
			while i < #points - 1 do
				local p1 = points[i]
				local p2 = points[i + 1]
				if p1.angle + maxdelta < p2.angle then
					local proj = projected(p1, maxdelta)
					table.insert(points, i + 1, proj)
					if debug then
						drystal.set_color(0, 255, 0)
						drystal.draw_line(self.x*R, self.y*R, proj.x*R, proj.y*R)
					end
				end
				i = i + 1
			end
		end

		drystal.set_color(self.color)
		local r = sprites.lightmap.w / 2
		local centerx = sprites.lightmap.x + r
		local centery = sprites.lightmap.y + r

		local function draw(p1, p2)
			drystal.draw_surface(
				centerx, centery,
				centerx+math.cos(p1.angle)*p1.distance*r, centery+math.sin(p1.angle)*p1.distance*r,
				centerx+math.cos(p2.angle)*p2.distance*r, centery+math.sin(p2.angle)*p2.distance*r,

				self.x*R, self.y*R,
				p1.x*R, p1.y*R,
				p2.x*R, p2.y*R
			)
		end
		for i = 1, #points - 1 do
			draw(points[i], points[i + 1])
		end
		draw(points[1], points[#points])
	else
		local sprite = sprites.lightmap
		local w, h = self.radius*R*2, self.radius*R*2
		drystal.draw_sprite_resized(sprite, self.x*R-w/2, self.y*R-h/2, w, h)
	end

	--if #penumbra_points > 0 then
	--	local sprite = sprites.penumbra
	--	for _, p in ipairs(penumbra_points) do
	--		drystal.draw_surface(
	--			sprite.x, sprite.y,
	--			sprite.x+sprite.w, sprite.y+sprite.h,
	--			sprite.x+sprite.w, sprite.y,

	--			p.x*R, p.y*R,
	--			(p.x+math.cos(p.angle)*p.distance)*R, (p.y+math.sin(p.angle)*p.distance)*R,
	--			(p.x+math.cos(p.angle+p.orientation)*p.distance)*R, (p.y+math.sin(p.angle+p.orientation)*p.distance)*R
	--		)
	--	end
	--end
end
function Light:_draw()
	drystal.set_alpha(140)
	drystal.set_color(self.color)
	if OLD_LIGHT then
		self:old_draw()
	else
		self:new_draw()
	end
end
function Light:draw()
	if self.radius == 0 or self.remove_me then
		return
	end

	if self.modified and not self.freed then
		self.buffer:reset()
		self.buffer:use()
		self:_draw()
		drystal.use_default_buffer()
		if self:is_fastbufferable() then
			self.buffer:upload_and_free()
			self.freed = true
		end
		self.modified = false
	end

	self.buffer:draw()
end

function Light:is_fastbufferable()
	return self.bound_to == nil and self.blink_freq == 0 and self.radius_changeable == false
end

function Light:associate_with(object)
	self.bound_to = object
end


return Light
