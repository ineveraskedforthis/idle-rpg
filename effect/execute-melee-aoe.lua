local insert_particle = require "effect-visual.particle"

local blood_hit_image = love.graphics.newImage("blood-hit.png")
local blood_ground_image = love.graphics.newImage("blood-ground.png")

---@param vfx VFX
---@param stage Stage
---@param left_x number
---@param right_x number
---@param damage_value number
---@param attacker PlayerState
return function (vfx, stage, left_x, right_x, damage_value, attacker)
	for index, value in ipairs(stage.enemies) do
		if value.position >= left_x and value.position <= right_x and value.hp > 0 then
			local difficulty = value.difficulty_melee
			local skill = MASTERY_TO_SKILL(attacker.mastery.melee_weapon)

			local skill_diff = skill - difficulty
			local success_probability = skill_diff / 0.1 + 0.5

			-- print(success_probability, damage_value)
			local success = love.math.random() < success_probability

			local actual_damage = damage_value
			if not success then
				actual_damage = math.floor(damage_value * 0.1)
				attacker.mastery.melee_weapon = attacker.mastery.melee_weapon + attacker.mental.learning_speed
			end

			value.hp = value.hp - actual_damage
			value.being_hit = true
			value.being_hit_animation_progress = 0
			value.position = math.min(stage.distance, value.position + 5)
			insert_particle(vfx, value.position + 0.1 * (love.math.random() - 0.5), 1 + love.math.random(), blood_ground_image, 4)
			insert_particle(vfx, value.position + 0.1 * (love.math.random() - 0.5), 0.25 + love.math.random(), blood_hit_image, 0.25)
		end
	end
end