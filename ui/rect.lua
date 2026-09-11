---@param rx number
---@param ry number
---@param rw number
---@param rh number
---@param x number
---@param y number
return function (rx, ry, rw, rh, x, y)
	if x < rx then
		return false
	end
	if x > rx + rw then
		return false
	end
	if y < ry then
		return false
	end
	if y > ry + rh then
		return false
	end
	return true
end