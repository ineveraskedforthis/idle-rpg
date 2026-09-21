
---@param x number
function MASTERY_TO_SKILL (x)
	return (1 - math.pow(2, -x)) * x / (1 + x)
end

function CLAMP(x, a, b)
	if (x < a) then
		return a
	end
	if (x > b) then
		return b
	end
	return x
end
---comment
---@param t number
---@return number
function SMOOTHSTEP(t)
	return t * t * (3 - 2 * t)
end

---@param x number
---@return number
function SMOOTHERSTEP(x)
	return x * x * x * (x * (6 * x - 15) + 10);
end