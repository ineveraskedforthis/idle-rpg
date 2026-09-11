local rect_detection = require "ui.rect"
local style = require "ui._style"

---@param render boolean
---@param text string
---@param rx number
---@param ry number
---@param rw number
---@param rh number
---@param x number
---@param y number
---@param conversation? boolean
return function (render, text, rx, ry, rw, rh, x, y, conversation)
	local detected = rect_detection(rx, ry, rw, rh, x, y)
	if (render) then
		style.active_element_border()
		love.graphics.rectangle("fill", rx, ry, rw, rh, 2, 2)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("fill", rx + 1, ry + 1, rw - 2, rh - 2, 2, 2)
		if (detected) then
			style.active_element_bg_hover()
		else
			style.active_element_bg_passive()
		end
		love.graphics.rectangle("fill", rx + 3, ry + 3, rw - 6, rh - 6, 2, 2)
		style.default_font_color()
		if conversation then
			style.conversation_font()
		else
			style.default_font()
		end
		local height = style.default_font_height()
		love.graphics.printf(text, rx, ry + rh / 2 - height / 2, rw, "center")
	end
	if not render then
		return detected
	end
end