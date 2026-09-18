local rect_detection = require "ui.rect"
local style = require "ui._style"

---@param render boolean
---@param rx number
---@param ry number
---@param rw number
---@param rh number
---@param dark boolean?
return function (render, rx, ry, rw, rh, dark)
	if (render) then
		style.active_element_border()
		love.graphics.rectangle("line", rx, ry, rw, rh, 2, 2)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("line", rx + 1, ry + 1, rw - 2, rh - 2, 2, 2)
		if dark then
			style.dark_panel_bg()
		else
			style.panel_bg()
		end
		love.graphics.rectangle("fill", rx + 3, ry + 3, rw - 6, rh - 6, 2, 2)
		style.default_font_color()
		style.default_font()
	end
	return false
end