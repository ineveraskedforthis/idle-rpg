local flat_aoe = require "effect.aoe-flat"

local description = {}

local hit_image = love.graphics.newImage("hit.png")
local hit_quads = {}
for i = 0, 3 do
	local quad = love.graphics.newQuad(i * 40, 0, 40, 40, hit_image:getDimensions())
	table.insert(hit_quads, quad)
end

---comment
---@param x number
---@param y number
---@param data SkillData
---@param actor_model ActorModelDescription
---@param actor_position ActorModelState
---@param camera_shift number
function description.draw(x, y, data, actor_model, actor_position, camera_shift)
	local frame = math.floor(data.progress * 4) % 4
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(hit_image, hit_quads[frame + 1], camera_shift + x + actor_position.position - actor_model.size_x / 2, y - actor_model.size_y)
end



---@param vfx VFX
---@param stage Stage
---@param player PlayerState
---@param dt number
---@param model ActorModelState
---@param data SkillData
function description.update(vfx, stage, player, dt, model, data)
	local attack_range = 10
	if player.weapon then
		local w = player.items[player.weapon]
		local b = BaseItemTable[w.kind]
		attack_range = b.range
	end

	data.progress = data.progress + dt
	if data.progress >= 1 then
		flat_aoe(vfx, stage, model.position, model.position + attack_range, player.melee_damage)
		if (player.weapon) then
			local old_durability = player.items[player.weapon].durability
			local next_durability = old_durability - 0.01
			player.items[player.weapon].durability = math.max(0, next_durability)
		end
		data.progress = 0
		data.completed = true
	end
end

---@param player PlayerState
function description.activation_range(player)
	local attack_range = 10
	if player.weapon then
		local w = player.items[player.weapon]
		local b = BaseItemTable[w.kind]
		attack_range = b.range
	end
	return attack_range / 2
end

return description