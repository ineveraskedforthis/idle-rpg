---@param sx number
---@param sy number
---@param sr number
---@param x number
---@param y number
return function (sx, sy, sr,  x, y)
	local dx = sx - x
	local dy = sy - y
	local r2 = dx * dx +  dy * dy
	local r = math.sqrt(r2)
	return r <= sr
end