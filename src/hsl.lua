return function (hue, saturation, lightness)
	if hue < 0 or hue > 360 then
		return {0, 0, 0}
	end
	if saturation < 0 or saturation > 1 then
		return {0, 0, 0}
	end
	if lightness < 0 or lightness > 1 then
		return {0, 0, 0}
	end
	local chroma = (1 - math.abs(2 * lightness - 1)) * saturation
	local h = hue/60
	local x =(1 - math.abs(h % 2 - 1)) * chroma
	local r, g, b = 0, 0, 0
	if h < 1 then
		r,g,b=chroma,x,0
	elseif h < 2 then
		r,b,g=x,chroma,0
	elseif h < 3 then
		r,g,b=0,chroma,x
	elseif h < 4 then
		r,g,b=0,x,chroma
	elseif h < 5 then
		r,g,b=x,0,chroma
	else
		r,g,b=chroma,0,x
	end
	local m = lightness - chroma/2
	return {(r+m)*255,(g+m)*255,(b+m)*255}
end
