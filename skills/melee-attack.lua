local flat_aoe = require "effect.aoe-flat"

local hit_image = love.graphics.newImage("hit.png")
local hit_quads = {}
for i = 0, 3 do
	local quad = love.graphics.newQuad(i * 40, 0, 40, 40, hit_image:getDimensions())
	table.insert(hit_quads, quad)
end

---@type SkillDefinition
local description = {
	activation_range =function (player, player_model)
		local attack_range = 10
		if player.weapon then
			local w = player.items[player.weapon]
			local b = BaseItemTable[w.kind]
			attack_range = b.range
		end
		return attack_range / 2 + player_model.size_x / 2
	end,
	draw = function (x, y, data, actor_model, actor_position, camera_shift)
		local frame = math.floor(data.current_action.progress * 4) % 4
		love.graphics.setColor(1, 1, 1, 1)

		local size_actor = actor_model.size_y
		local scale = size_actor / 40 * actor_model.image_base_scale
		love.graphics.draw(
			hit_image,
			hit_quads[frame + 1],
			camera_shift + x + actor_position.position - actor_model.size_x / 2 * actor_model.image_base_scale,
			y - actor_model.size_y * actor_model.image_base_scale,
			0, scale, scale
		)

	end,
	update =function (vfx, stage, player, dt, model, model_description, skip_casting)
		local attack_range = 10 + model_description.size_x / 2
		if player.weapon then
			local w = player.items[player.weapon]
			local b = BaseItemTable[w.kind]
			attack_range = b.range + model_description.size_x / 2
		end

		local data = player.current_action
		data.progress = data.progress + dt
		if data.progress >= 1 then
			flat_aoe(vfx, stage, model.position - model_description.size_x / 2, model.position + attack_range, player.melee_damage)
			if (player.weapon) then
				local old_durability = player.items[player.weapon].durability
				local next_durability = old_durability - 0.01
				player.items[player.weapon].durability = math.max(0, next_durability)
			end
			data.progress = 0
			data.completed = true
		end
	end
}

return description