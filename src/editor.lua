local drystal = require 'drystal'
local tt = require 'truetype'

local WallElement = require 'src/editor/wall_element'
local LightElement = require 'src/editor/light_element'

local Editor = {
	game=nil,

	activated=false,
	font=nil,

	mouse_x=0,
	mouse_y=0,

	elements={WallElement, LightElement},
	element_num=1,
	element=nil, -- self.elements[self.element_num]
}
Editor.__index = Editor

function Editor.new(game)
	local editor = setmetatable({}, Editor)
	editor.game = game
	editor.font = assert(tt.load('data/font.ttf', 22), "can't load data/font.ttf")
	editor.element = editor.elements[editor.element_num]

	for _, e in ipairs(editor.elements) do
		e.game = game
	end
	return editor
end

function Editor:draw()
	drystal.set_alpha(255)
	drystal.set_color(0, 0, 0)

	self.game:gui_camera()
	local sw, sh = drystal.surface_size(drystal.screen)
	tt.use(self.font)
	tt.draw(self.element.name, 3, sh - 26)

	self.game:game_camera()
	drystal.set_color(150, 0, 0)
	drystal.set_alpha(150)
	self.element:draw()
end

function Editor:update(dt)
end

function Editor:toggle()
	self.activated = not self.activated
	self.game.show_darkness = not self.activated
	if self.activated and self.game.zoom == 1 then
		self.game.zoom = 0.6
	end
	if not self.activated and self.game.zoom == 0.6 then
		self.game.zoom = 1
	end
end

function Editor:get_mouse()
	return self.mouse_x, self.mouse_y
end

function Editor:key_press(key)
	if key == 'a' then
		self.element_num = self.element_num % #self.elements + 1
		self.element = self.elements[self.element_num]
	end
end

function Editor:key_release(key)
end

function Editor:mouse_motion(x, y)
	local xx, yy = self.game:m2g(x, y)
	self.mouse_x = xx
	self.mouse_y = yy
end

function Editor:mouse_press(x, y, b)
	local xx, yy = self.game:m2g(x, y)
	if b == 1 then
		self.element:press(xx, yy)
	elseif b == 3 then
		self.game.map:remove_at(xx, yy, self.element.filter)
	end
end

function Editor:mouse_release(x, y, b)
	local xx, yy = self.game:m2g(x, y)
	if b == 1 then
		self.element:release(xx, yy)
	end
end

return Editor

