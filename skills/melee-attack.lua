local flat_aoe = require "effect.execute-melee-aoe"

local hit_image = love.graphics.newImage("assets/effects/hit.png")
local hit_quads = {}
for i = 0, 3 do
	local quad = love.graphics.newQuad(i * 40, 0, 40, 40, hit_image:getDimensions())
	table.insert(hit_quads, quad)
end

---@type SkillDefinition
local description = {
	activation_range =function (player)
		local attack_range = 10
		local weapon = RETRIEVE_ITEM(player.weapon)
		if weapon then
			local b = GET_ITEM_KIND(weapon.kind)
			attack_range = b.range
		end
		return attack_range / 2 + player.model_description.size_x / 2 * player.model_description.image_base_scale
	end,
	draw = function (x, y, data, actor_model, actor_position, camera_shift)
		local frame = math.floor(data.current_action.progress * 4) % 4
		love.graphics.setColor(1, 1, 1, 1)

		local scale_x = actor_model.size_x / 40 * actor_model.image_base_scale
		local scale_y = actor_model.size_y / 40 * actor_model.image_base_scale

		local shift_x = -actor_model.size_x * actor_model.image_base_scale / 2
		if actor_position.orientation < 0 then
			shift_x = actor_model.size_x * actor_model.image_base_scale / 2
		end

		love.graphics.draw(
			hit_image,
			hit_quads[frame + 1],
			camera_shift + x + actor_position.position + shift_x,
			y - actor_model.size_y * actor_model.image_base_scale,
			0, scale_x * actor_position.orientation, scale_y
		)

	end,
	update =function (vfx, stage, player, dt, model, model_description, skip_casting, magnitude)
		local attack_range = 10 + model_description.size_x / 2
		local weapon = RETRIEVE_ITEM(player.weapon)
		if weapon then
			local b = GET_ITEM_KIND(weapon.kind)
			attack_range = b.range + model_description.size_x / 2 *model_description.image_base_scale
		end

		local data = player.current_action
		data.progress = data.progress + dt

		local attack_range_start = model.position - model_description.size_x / 2 *model_description.image_base_scale * model.orientation
		local attack_range_end = model.position + attack_range * model.orientation
		if data.progress >= 1 then
			flat_aoe(
				vfx,
				stage,
				attack_range_start,
				attack_range_end,
				player.melee_damage,
				player
			)
			if (weapon) then
				local old_durability = weapon.durability
				local next_durability = old_durability - 0.01
				weapon.durability = math.max(0, next_durability)
			end
			data.progress = 0
			data.completed = true
		end
	end
}

return description