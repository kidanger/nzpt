local drystal = require 'drystal'

local Game = require 'src/game'
local Map = require 'src/map'

local gamestate
local state

R = 32

function switch_state(newstate)
	state = newstate
	if state.on_enter then
		state:on_enter()
	end
end

function drystal.init()
	drystal.resize(700, 540)
	gamestate = Game.new()
	local map = Map.load_from_file('test')
	gamestate:change_map(map)
	switch_state(gamestate)
end

function drystal.update(dt)
	dt = dt / 1000
	state:update(dt)
end
function drystal.draw()
	state:draw()
end

function drystal.key_press(key)
	if state.key_press then
		state:key_press(key)
	end
end
function drystal.key_release(key)
	if state.key_release then
		state:key_release(key)
	end
end
function drystal.mouse_motion(x, y)
	if state.mouse_motion then
		state:mouse_motion(x, y)
	end
end
function drystal.mouse_press(x, y, b)
	if state.mouse_press then
		state:mouse_press(x, y, b)
	end
end
function drystal.mouse_release(x, y, b)
	if state.mouse_release then
		state:mouse_release(x, y, b)
	end
end
