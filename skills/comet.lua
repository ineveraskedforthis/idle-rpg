local description = {}

local comet_image = love.graphics.newImage("comet.png")
local comet_x = 96
local comet_y = 96

---@type ProjectileDescription
local comet_projectile_desc = {
	image = comet_image,
	movement_frames = {
		love.graphics.newQuad(0, 0, comet_x, comet_y, comet_image)
	},
	impact_frames = {
		love.graphics.newQuad(comet_x * 1, 0, comet_x, comet_y, comet_image),
		love.graphics.newQuad(comet_x * 2, 0, comet_x, comet_y, comet_image),
		love.graphics.newQuad(comet_x * 3, 0, comet_x, comet_y, comet_image)
	},
	size_x = comet_x,
	size_y = comet_y
}

---@type SkillDefinition
local def = {
	activation_range =function (player, model)
		return 600
	end,
	draw = function (x, y, data, actor_model, actor_position, camera_shift)

	end,
	update = function (vfx, stage, player, dt, model, model_description, skip_casting)
		local data = player.current_action
		data.progress = data.progress + dt
		if skip_casting then
			data.progress = 1
		end
		if data.progress >= 1 then
			-- Find target:

			local target = nil
			local closest_target_dist = 400
			for index, value in ipairs(stage.enemies) do
				if value.hp <= 0 then
					goto continue
				end
				local dist = value.position - model.position
				if dist < closest_target_dist then
					closest_target_dist = dist
					target = index
				end
				::continue::
			end
			if target then
				---@type Projectile
				local projectile = {
					desc = comet_projectile_desc,
					height = 300 + (math.random() - 0.5) * 100,
					position = model.position + (math.random() - 0.5) * 50,
					size = 4,
					speed = 1000,
					target = stage.enemies[target].position + (math.random() - 0.5) * 200,
					discard = false,
					impact = false,
					impact_progress = 0,
					damage = player.spell_damage,
				}
				table.insert(stage.projectiles, projectile)
			end

			data.progress = 0
			data.completed = true
		end
	end
}

return def