
local style = require "ui._style"

---@param colors table[]
local function gradient_h(colors)
	local result = love.image.newImageData(#colors, 1)
	for i, color in ipairs(colors) do
		local x, y = i - 1, 0
		print(x, y)
		result:setPixel(x, y, color[1], color[2], color[3], color[4] or 1)
	end
	local result_image = love.graphics.newImage(result)
	result_image:setFilter('linear', 'linear')
	return result_image
end

local function draw_image_in_rect(img, x, y, w, h, r, ox, oy, kx, ky)
	return love.graphics.draw(img, x, y, r, w / img:getWidth(), h / img:getHeight(), ox, oy, kx, ky)
end

local hp_gradient_ally = gradient_h({{0.7, 0.9, 0.8}, {100 / 255, 190 / 255, 175 / 255}})
local hp_gradient_enemy = gradient_h({{0.95, 0.1, 0.05}, {1, 0.11, 0.05}})

---comment
---@param x number
---@param y number
---@param w number
---@param h number
---@param hp number
---@param hp_view number
---@param max_hp number
---@param shield number
---@param hostile boolean
---@param level number?
return function (x, y, w, h, hp, hp_view, max_hp, shield, hostile, level)
	-- print(hp, hp_view)
	local outerouter = 1
	local outer = 1
	local shield_offset = 1
	local fill = 1
	local inner = 1

	if level then
		love.graphics.setColor(0, 0, 0)
		love.graphics.circle("fill", x - h, y + h / 2, h + 2)
		love.graphics.setColor(1, 1, 1)
		love.graphics.circle("fill", x - h, y + h / 2, h)
		style.default_font()
		style.basic_element_color()
		local font_height = style.default_font_height()
		love.graphics.printf(tostring(level), x - h * 2, y + h / 2 - font_height / 2, h * 2, "center")
	end

	-- outer outer border
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", x, y, w, h)

	-- outer border
	love.graphics.setColor(0.29, 0.35, 0.32)
	love.graphics.rectangle("fill", x + outerouter, y + outerouter, w - outerouter * 2, h - outerouter * 2)

	-- betweeen border fill
	love.graphics.setColor(0.4, 0.4, 0.4)
	love.graphics.rectangle("fill", x + outer + outerouter, y + outer + outerouter, w - (outer + outerouter) * 2, h - (outer + outerouter) * 2)

	-- shield
	local shield_ratio = math.min(1, shield / max_hp / 10)
	love.graphics.setColor(0.95, 0.95, 1)
	love.graphics.rectangle("fill", x + shield_offset, y + shield_offset, (w - shield_offset * 2) * shield_ratio, h - shield_offset * 2)

	-- inner border
	do
		love.graphics.setColor(0.1, 0.15, 0.1)
		local margin = outer + fill
		local _x = x + margin
		local _y = y + margin
		local _w = w - 2 * margin
		local _h = h - 2 * margin

		love.graphics.rectangle("fill", _x, _y, _w, _h)
	end

	-- hp bar
	do
		local hp_ratio_actual = hp / max_hp
		local hp_ratio_view = hp_view / max_hp
		local margin = outer + fill + inner
		local _x = x + margin
		local _y = y + margin
		local _w = w - 2 * margin
		local _h = h - 2 * margin
		love.graphics.setColor(1, 1, 1)
		if hostile then
			draw_image_in_rect(hp_gradient_enemy, _x, _y, _w * hp_ratio_actual, _h, 0)
		else
			draw_image_in_rect(hp_gradient_ally, _x, _y, _w * hp_ratio_actual, _h, 0)
		end

		if hostile then
			love.graphics.setColor(1, 0.8, 0.8, 1)
		else
			love.graphics.setColor(0.35, 0.45, 0.4)
		end

		if hp_ratio_view > hp_ratio_actual then
			love.graphics.rectangle("fill", _x + _w * hp_ratio_actual, _y, _w * (hp_ratio_view - hp_ratio_actual), _h)
		else
			love.graphics.rectangle("fill", _x + _w * hp_ratio_view, _y, _w * (hp_ratio_actual - hp_ratio_view), _h)
		end
	end

	-- inner border
	do
		love.graphics.setColor(0.1, 0.15, 0.1)
		local margin = outer + fill
		local _x = x + margin
		local _y = y + margin
		local _w = w - 2 * margin
		local _h = h - 2 * margin

		-- draw inner border color lines to show hp blocks for every X hp:
		local blocks = max_hp / 200
		local block_size = _w / blocks
		for i = 1, blocks do
			love.graphics.rectangle("fill", _x + i * block_size, _y, 1, _h)
		end
	end

end
