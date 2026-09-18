---@param vfx VFX
---@param pos number
---@param size number
---@param image love.Image
---@param time number
return function (vfx, pos, size, image, time)
	for index, value in ipairs(vfx.particles) do
		if value.time_left <= 0 then
			value.image = image
			value.position = pos
			value.size = size
			value.time_left = time
			value.max_time = time
			return
		end
	end
end