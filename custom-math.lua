
---@param x number
function MASTERY_TO_SKILL (x)
	return (1 - math.pow(2, -x)) * x / 100 / (1 + x * 100)
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

function IN_RANGE(x, left, right)
	return (x - left) * (x - right) <= 0
end

function RANGES_INTERSECT(a, b, c, d)
	return IN_RANGE(a, c, d) or IN_RANGE(b, c, d) or IN_RANGE(c, a, b) or IN_RANGE(d, a, b)
end