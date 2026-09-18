local description = {}

local comet_image = love.graphics.newImage("comet.png")
local comet_x = 96
local comet_y = 96


---comment
---@param x number
---@param y number
---@param data SkillData
---@param actor_model ActorModelDescription
---@param actor_position ActorModelState
---@param camera_shift number
function description.draw(x, y, data, actor_model, actor_position, camera_shift)
end

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

---@param vfx VFX
---@param stage Stage
---@param player PlayerState
---@param dt number
---@param model ActorModelState
---@param data SkillData
function description.update(vfx, stage, player, dt, model, data)
	data.progress = data.progress + dt
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
				height = 100,
				position = model.position,
				size = player.spell_damage *2,
				speed = 1000,
				target = stage.enemies[target].position,
				discard = false,
				impact = false,
				impact_progress = 0,
				damage = player.spell_damage * 10
			}
			table.insert(stage.projectiles, projectile)
		end

		data.progress = 0
		data.completed = true
	end
end

---@param player PlayerState
function description.activation_range(player)
	return 600
end

return description