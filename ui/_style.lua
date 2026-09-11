local base_unit = 5

local font_path = "assets/alte-din-1451-mittelschrift/din1451alt.ttf"

local readable_font = "assets/Baskervville/static/Baskervville-Regular.ttf"

---@type love.Font[]
local font_by_size = {}

local size = 16

for i = 1, 10, 1 do
	font_by_size[i] = love.graphics.newFont(font_path, math.floor(size))
	size = size * 1.618
end

-- local default_font = font_by_size[1]
local default_font = love.graphics.newFont(readable_font, 16)
local conversation_font = love.graphics.newFont("assets/Baskervville/static/Baskervville-Italic.ttf", 16)
local header_font = love.graphics.newFont(readable_font, math.floor(16 * 1.618))

return {
	battle_actors_spacing = 120,
	base_margin = base_unit,
	action_bar_item_height = 8 * base_unit,
	action_bar_item_width = 13 * base_unit,

	action_bar_current_item_height = 10 * base_unit,
	action_bar_current_item_width = 10 / 8 * 13 * base_unit,

	skill_button_size = 70,
	energy_point_h = 20,
	energy_point_w = 30,

	basic_bg_color = function ()
		love.graphics.setBackgroundColor(0.5, 0.5, 0.5, 1)
	end,

	basic_element_color = function ()
		love.graphics.setColor(0, 0, 0, 1)
	end,

	active_element_border = function ()
		love.graphics.setColor(0.9, 0.4, 0.1, 1)
	end,

	active_element_bg_passive = function ()
		love.graphics.setColor(0.9, 0.9, 0.9, 0.95)
	end,

	panel_bg = function ()
		love.graphics.setColor(0.9, 0.9, 0.9, 0.95)
	end,

	active_element_bg_hover = function ()
		love.graphics.setColor(0.95, 0.95, 0.5, 1)
	end,

	default_font = function ()
		love.graphics.setFont(default_font)
	end,

	conversation_font = function ()
		love.graphics.setFont(conversation_font)
	end,

	default_font_color = function ()
		love.graphics.setColor(0, 0, 0, 1)
	end,

	default_font_height = function ()
		return default_font:getHeight( )
	end,

	header_font = function ()
		love.graphics.setFont(header_font)
	end,

	font = function (x)
		love.graphics.setFont(font_by_size[math.max(1, math.min(math.floor(x), 10))])
	end
}