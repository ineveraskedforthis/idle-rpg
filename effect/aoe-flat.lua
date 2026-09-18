local insert_particle = require "effect-visual.particle"

local blood_hit_image = love.graphics.newImage("blood-hit.png")
local blood_ground_image = love.graphics.newImage("blood-ground.png")

---@param vfx VFX
---@param stage Stage
---@param left_x number
---@param right_x number
---@param damage_value number
return function (vfx, stage, left_x, right_x, damage_value)
	for index, value in ipairs(stage.enemies) do
		if value.position >= left_x and value.position <= right_x and value.hp > 0 then
			value.hp = value.hp - damage_value
			value.being_hit = true
			value.being_hit_animation_progress = 0
			value.position = math.min(stage.distance, value.position + 5)
			insert_particle(vfx, value.position + 0.1 * (love.math.random() - 0.5), 1 + love.math.random(), blood_ground_image, 4)
			insert_particle(vfx, value.position + 0.1 * (love.math.random() - 0.5), 0.25 + love.math.random(), blood_hit_image, 0.25)
		end
	end
end