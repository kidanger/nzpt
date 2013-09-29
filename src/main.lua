local drystal = require 'drystal'

local gamestate = require 'src/game'

local state

R = 32

function switch_state(newstate)
	state = newstate
	state:on_enter()
end

function drystal.init()
	drystal.resize(600, 480)
	switch_state(gamestate)
end

function drystal.update(dt)
	dt = dt / 1000
	state:update(dt)
end
function drystal.draw()
	state:draw()
	drystal.flip()
end

function drystal.key_press(key)
	if key == 'a' then
		drystal.engine_stop()
	end
	if state.key_press then
		state:key_press(key)
	end
end
function drystal.key_release(key)
	if state.key_release then
		state:key_release(key)
	end
end
function drystal.mouse_press(x, y, b)
	if state.mouse_press then
		state:mouse_press(x, y, b)
	end
end
