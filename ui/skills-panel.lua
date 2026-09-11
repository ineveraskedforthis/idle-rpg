
local STAGE = require "fights._stages"

local style = require "ui._style"
local rect = require "ui.rect"


local offset_x = style.action_bar_item_width * 2
local description_offset_x = 200
local description_offset_y = 200


---comment
---@param battle BattleState
---@param acting_actor Actor
---@param offset_x number
---@param shift_panel number
local function render(battle, acting_actor, offset_x, shift_panel)
	-- draw character art on top
	local window_size = love.graphics.getWidth()
	local window_h = love.graphics.getHeight()
	local art_h = 100
	local width = 200

	local padding = 5
	local x = window_size - width - padding

	if (acting_actor.definition.image_skills) then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(acting_actor.definition.image_skills, x, padding)
	end

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("line", x, 0 + padding, width, art_h)

	local reserve_points = 0

	do
		local offset_y = style.skill_button_size + style.base_margin
		local current_x = offset_x
		for key, value in ipairs(acting_actor.definition.inherent_skills) do
			if render_skill(current_x, window_h - offset_y + shift_panel, width, acting_actor, value) then
				reserve_points = value.required_energy
			end
			current_x = current_x + style.skill_button_size
		end
		if (acting_actor.wrapper) then
			for key, value in ipairs(acting_actor.wrapper.skills) do
				if render_skill(current_x, window_h - offset_y + shift_panel, width, acting_actor, value) then
					reserve_points = value.required_energy
				end
				---@type number
				current_x = current_x + style.skill_button_size
			end
		end
	end
end

---comment
---@param state GameState
---@param battle BattleState
---@param x number
---@param y number
---@param acting_actor Actor
---@param selected_actor Actor
local function on_click(state, battle, x, y, acting_actor, selected_actor)
	local window_size = love.graphics.getWidth()
	local window_h = love.graphics.getHeight()
	local art_h = 100
	local width = 200

	local padding = 5
	local _x = window_size - width - padding

	if battle.stage == STAGE.AWAIT_TURN then
		local offset_y = style.skill_button_size + style.base_margin
		local current_x = offset_x
		local true_size = style.skill_button_size - style.base_margin * 2

		for key, value in ipairs(acting_actor.definition.inherent_skills) do
			local can_use = CAN_USE_SKILL(state, battle, acting_actor, selected_actor, value)
			if rect(current_x + style.base_margin, window_h - offset_y + style.base_margin, true_size, true_size, x, y) and can_use then
				USE_SKILL(state, battle, acting_actor, selected_actor, value)
				battle.stage = STAGE.PROCESS_EFFECTS_AFTER_TURN
				return
			end
			current_x = current_x + style.skill_button_size
		end

		if (acting_actor.wrapper) then
			for key, value in ipairs(acting_actor.wrapper.skills) do
				local can_use = CAN_USE_SKILL(state, battle, acting_actor, selected_actor, value)
				if rect(current_x + style.base_margin, window_h - offset_y + style.base_margin, true_size, true_size, x, y) and can_use then
					USE_SKILL(state, battle, acting_actor, selected_actor, value)
					battle.stage = STAGE.PROCESS_EFFECTS_AFTER_TURN
					return
				end
				---@type number
				current_x = current_x + style.skill_button_size
			end
		end
	end
end

return {
	render = render,
	on_click = on_click,
	update = function (state, dt)

	end
}