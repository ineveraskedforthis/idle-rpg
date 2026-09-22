local insert_particle = require "effect-visual.particle"

local magic_particle = love.graphics.newImage("assets/effects/magic-particle.png")
local blood_ground_image = love.graphics.newImage("assets/effects/blood-ground.png")

---@param vfx VFX
---@param stage Stage
---@param left_x number
---@param right_x number
---@param damage_value number
---@param attacker ActorState
return function (vfx, stage, left_x, right_x, damage_value, attacker)
	local targets = stage.enemies
	if attacker.is_enemy then
		targets = stage.allies
	end
	for index, value in ipairs(targets) do
		local model_left = value.model.position - value.model_description.size_x  * value.model_description.image_base_scale / 2
		local model_right = value.model.position + value.model_description.size_x * value.model_description.image_base_scale / 2

		if RANGES_INTERSECT(model_left, model_right, left_x, right_x) and value.hp > 0 then
			local difficulty = value.mastery.general_magic
			local skill = MASTERY_TO_SKILL(attacker.mastery.general_magic)

			local skill_diff = skill - difficulty
			local success_probability = skill_diff / 0.1 + 0.5
			local success = love.math.random() < success_probability

			local actual_damage = damage_value
			if not success then
				actual_damage = math.floor(damage_value * 0.1)
				attacker.mastery.general_magic = attacker.mastery.general_magic + attacker.mental.learning_speed
			end

			value.hp = value.hp - actual_damage

			-- value.being_hit = true
			-- value.being_hit_animation_progress = 0
			-- value.model.position = math.min(stage.distance, value.model.position + 5)
			insert_particle(vfx, value.model.position + 50 * (love.math.random() - 0.5), 0.5 + love.math.random(), blood_ground_image, 4)
			insert_particle(vfx, value.model.position + 50 * (love.math.random() - 0.5), 0.5 + love.math.random(), magic_particle, 0.25)
			insert_particle(vfx, value.model.position + 50 * (love.math.random() - 0.5), 0.5 + love.math.random(), magic_particle, 0.25)
			insert_particle(vfx, value.model.position + 50 * (love.math.random() - 0.5), 0.5 + love.math.random(), magic_particle, 0.25)
			insert_particle(vfx, value.model.position + 50 * (love.math.random() - 0.5), 0.5 + love.math.random(), magic_particle, 0.25)
		end
	end
end