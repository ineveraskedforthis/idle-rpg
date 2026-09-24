local insert_particle = require "effect-visual.particle"
local knock_back = require "effect.knock-back"

local blood_hit_image = love.graphics.newImage("assets/effects/blood-hit.png")
local blood_ground_image = love.graphics.newImage("assets/effects/blood-ground.png")



---@param vfx VFX
---@param stage Stage
---@param left_x number
---@param right_x number
---@param damage_value number
---@param attacker ActorState
return function (vfx, stage, left_x, right_x, damage_value, attacker)
	local orientation = 1
	if right_x < left_x then
		orientation = -1
	end
	local targets = stage.enemies
	if attacker.is_enemy then
		targets = stage.allies
	end
	for index, value in ipairs(targets) do
		local model_left = value.model.position - value.model_description.size_x  * value.model_description.image_base_scale / 2
		local model_right = value.model.position + value.model_description.size_x * value.model_description.image_base_scale / 2
		if RANGES_INTERSECT(model_left, model_right, left_x, right_x) and value.hp > 0 then
			local difficulty = MASTERY_TO_SKILL(value.mastery.melee_defense)
			local skill = MASTERY_TO_SKILL(attacker.mastery.melee_weapon)

			local skill_diff = skill - difficulty
			local success_probability = skill_diff / 0.1
			local critical_success_probability = skill_diff / 0.1 - 0.5

			-- print(success_probability, damage_value)
			local success = love.math.random() < success_probability
			local critical_success = false
			if success then
				critical_success = love.math.random() < critical_success_probability
			end

			local actual_damage = damage_value
			if success then
				actual_damage = damage_value * 2
				if critical_success then
					actual_damage = damage_value * 5
				end
				value.mastery.melee_defense = value.mastery.melee_defense + value.mental.learning_speed * 2
			else
				attacker.mastery.melee_weapon = attacker.mastery.melee_weapon + attacker.mental.learning_speed
			end

			local def = value.total_defense * (1 + difficulty)

			local blocked = false
			if def >= actual_damage then
				blocked = true
			else
				if love.math.random() < def / actual_damage then
					blocked = true
				end
			end

			if blocked then
				actual_damage = 0
				local armor = RETRIEVE_ITEM(value.body_armor)
				if armor then
					armor.durability = armor.durability - 0.001
				end
			end

			if value.shield > actual_damage then
				actual_damage = 0
			else
				actual_damage = actual_damage - value.shield
			end

			value.hp = value.hp - actual_damage
			value.mastery.melee_defense = value.mastery.melee_defense + value.mental.learning_speed

			if critical_success then
				knock_back(value, attacker.model_description.size_x * attacker.model_description.image_base_scale)
			end

			if success then
				insert_particle(vfx, value.model.position + 0.1 * (love.math.random() - 0.5), 1 + love.math.random(), blood_ground_image, 4)
			else
				insert_particle(vfx, value.model.position + 0.1 * (love.math.random() - 0.5), 0.75, blood_ground_image, 4)
			end
			insert_particle(vfx, value.model.position + 0.1 * (love.math.random() - 0.5), 0.25 + love.math.random(), blood_hit_image, 0.25)
		end
	end
end