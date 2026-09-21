local progress_bar = require "ui.progress-bar"
local values = require "values.common"
local update_player_values = require "effect.player-update"
local skills = require "skills._manager"
local style = require "ui._style"
local button = require "ui.button"
local panel = require "ui.panel"
local border = require "ui.border"
local rect_detection = require "ui.rect"
local magic_aoe = require "effect.execute-magic-aoe"


local battle_scene = {}

local base_camera_shift = 200.0
local actual_camera = 0.0

---@type number
local timer = 0

local portal_image = love.graphics.newImage("portal.png")
local portal_quads = {}
for i = 0, 4 do
	local quad = love.graphics.newQuad(i * 80, 0, 80, 80, portal_image:getDimensions())
	table.insert(portal_quads, quad)
end

local hit_image = love.graphics.newImage("hit.png")
local hit_quads = {}
for i = 0, 3 do
	local quad = love.graphics.newQuad(i * 40, 0, 40, 40, hit_image:getDimensions())
	table.insert(hit_quads, quad)
end

local blood_hit_image = love.graphics.newImage("blood-hit.png")

---comment
---@param render boolean
---@param x number
---@param y number
---@param player PlayerState
local function character_widget(render, x, y, player)
	panel(render, x, y, 100, 120)

	style.default_font()
	style.default_font_color()

	panel(render, x + 3, y + 3, 94, 94 )
	love.graphics.setColor(1, 1, 1, 1)
	-- love.graphics.draw(player_image, x + 5, y + 5)

	progress_bar(x + 3, y + 99, 94, 17, player.hp, player.hp_view, player.hp_max, player.shield, "blue" )
end

---comment
---@param x number
---@param y number
---@param model ActorModelDescription
---@param state ActorModelState
---@param camera_shift number
---@param orientation number
local function draw_character(x, y, model, state, camera_shift, orientation)
	love.graphics.setColor(1, 1, 1, 1)

	---@type number
	local model_x = x + camera_shift + state.position - model.size_x / 2 * model.image_base_scale
	if orientation < 0 then
		model_x = model_x + model.size_x * model.image_base_scale
	end

	local model_y = y - model.size_y *model.image_base_scale

	if state.state ==ActorModelStateEnum.Walking then
		local frame = math.floor(state.walk_timer * model.walk_timer_mult * #model.walk_frames) % #model.walk_frames
		love.graphics.draw(
			model.image,
			model.walk_frames[frame + 1],
			model_x, model_y,
			0,
			model.image_base_scale * orientation,
			model.image_base_scale
		)
	elseif state.state == ActorModelStateEnum.Idle then
		-- TODO: replace with per entity timer
		local frame = math.floor(timer / 50 * #model.idle_frames) % #model.idle_frames
		love.graphics.draw(
			model.image,
			model.idle_frames[frame + 1],
			model_x, model_y,
			0,
			model.image_base_scale * orientation,
			model.image_base_scale
		)
	elseif state.state == ActorModelStateEnum.Attacking then
		-- replace with per entity timer
		local frame = math.floor(timer * model.attack_timer_mult * #model.idle_frames) % #model.idle_frames
		love.graphics.draw(
			model.image,
			model.attack_frames[frame + 1],
			model_x, model_y,
			0,
			model.image_base_scale * orientation,
			model.image_base_scale
		)
	elseif  state.state ==ActorModelStateEnum.Dead then
		if state.death_timer < 0.5 then
			love.graphics.setColor(2, 2 * math.sin(state.death_timer * 16 *math.pi), 2 * math.sin(state.death_timer * 16 *math.pi))
			local frame = math.floor(timer / 50 * #model.idle_frames) % #model.idle_frames
			love.graphics.draw(
				model.image,
				model.idle_frames[frame + 1],
				model_x, model_y,
				0,
				model.image_base_scale * orientation,
				model.image_base_scale
			)
		else
			-- replace with per entity timer
			local frame = math.floor(timer * model.attack_timer_mult * #model.idle_frames) % #model.idle_frames
			love.graphics.draw(
				model.image,
				model.dead_frame[frame + 1],
				model_x, model_y,
				0,
				model.image_base_scale * orientation,
				model.image_base_scale
			)
		end
	end
end

local camera_quad = love.graphics.newQuad(0, 0, INTERFACE_GRID * 88, INTERFACE_GRID * 71, 1200, 800)

---@param req InterfaceRequest
---@param x number
---@param y number
---@param player PlayerState
---@param vfx_manager VFX
---@param stage Stage
function battle_scene.top(req, x, y, player, vfx_manager, stage)
	if not req.render then
		return
	end

	local battle_y = y + 240

	love.graphics.setColor(1, 1, 1, 1)
	local bg = Locations[player.location].background

	camera_quad:setViewport(actual_camera - base_camera_shift, 0, INTERFACE_GRID * 88, INTERFACE_GRID * 71, 1200, 800)
	love.graphics.draw(bg, camera_quad, x, y)
	-- love.graphics.draw(bg, x  - actual_camera % 1200, y)
	-- love.graphics.draw(bg, x  - actual_camera % 1200+ 1200, y)
	do
		local frame = math.floor(timer * 5) % 5
		love.graphics.draw(portal_image, portal_quads[frame + 1], base_camera_shift + x - actual_camera, y + 180, 0, 1, 1)
	end

	do
		local frame = (math.floor(timer * 5) + 1) % 5
		love.graphics.draw(portal_image, portal_quads[frame + 1], base_camera_shift + x + stage.distance - actual_camera, y + 180, 0, 1, 1)
	end

	for index, value in ipairs(vfx_manager.particles) do
		if value.time_left > 0 then
			love.graphics.setColor(1, 1, 1, value.time_left / value.max_time)
			love.graphics.draw(value.image, base_camera_shift + x + value.position  - actual_camera, y + 200, 0, value.size, value.size, 40, 40)
		end
	end

	for index, value in ipairs(stage.enemies) do
		local model = value.prototype.model_description
		if value.hp > 0 then
			local enemy_state = ActorModelStateEnum.Walking
			if value.is_attacking then
				enemy_state = ActorModelStateEnum.Attacking
			end
			draw_character(x, battle_y, model, { position = value.position, walk_timer = timer, state = enemy_state, death_timer = 0 }, base_camera_shift - actual_camera, -1)
			local bar_x = x + base_camera_shift - actual_camera + value.position - model.size_x / 4 *model.image_base_scale
			local bar_width = model.size_x *model.image_base_scale / 2
			local bar_y = battle_y - model.size_y *model.image_base_scale
			progress_bar(bar_x, bar_y, bar_width, 7, value.hp, value.view_hp, value.prototype.hp_max, 0, "red")
		else
			draw_character(x, battle_y, model, { position = value.position, walk_timer = timer, state = ActorModelStateEnum.Dead, death_timer = value.death_progress }, base_camera_shift - actual_camera, -1)
		end
	end

	if player.hp > 0 then

		local hero = player.model_description
		draw_character(x, battle_y, hero, player.model, base_camera_shift - actual_camera, 1)
		local bar_x = x + base_camera_shift - actual_camera + player.model.position - hero.size_x / 4 *hero.image_base_scale
		local bar_width = hero.size_x *hero.image_base_scale / 2
		local bar_y = battle_y - hero.size_y *hero.image_base_scale
		progress_bar(bar_x, bar_y, bar_width, 7, player.hp, player.hp_view, player.hp_max, 0, "blue")

		local action = player.current_action.used_skill
		if action then
			local skill = skills[action]
			skill.draw(x, battle_y, player, player.model_description, player.model, base_camera_shift - actual_camera)
		end
	end

	for index, value in ipairs(stage.enemies) do
		if value.is_attacking then
			local frame = math.floor(value.attack_progress * 4) % 4
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(
				hit_image, hit_quads[frame + 1], base_camera_shift + x + value.position - actual_camera + 20, y + 200,
				0, -1, 1
			)
		end
	end

	for index, value in ipairs(stage.projectiles) do
		love.graphics.setColor(1, 1, 1, 1)
		if value.impact and not value.discard then
			local frame = math.floor(value.impact_progress * #value.desc.impact_frames)
			local size_scale = value.size * (0.4 +0.6 * value.impact_progress)
			love.graphics.draw(
				value.desc.image,
				value.desc.impact_frames[frame + 1],
				base_camera_shift + x + value.position - actual_camera - value.desc.size_x / 2 * size_scale,
				battle_y - value.height - value.desc.size_y / 2 * size_scale,
				0, size_scale, size_scale
			)
		elseif not value.discard then
			local frame = 1
			love.graphics.draw(
				value.desc.image,
				value.desc.movement_frames[frame],
				base_camera_shift + x + value.position - actual_camera - value.desc.size_x / 2,
				battle_y - value.height - value.desc.size_y / 2
			)
		end
	end

end


---comment
---@param player PlayerState
---@param enemy Enemy
---@param skill SkillDefinition
---@return boolean
local function can_use_skill (player, enemy, skill)
	return enemy.position < player.model.position + skill.activation_range(player)
end



---comment
---@param player PlayerState
---@param action ActionEnum
---@param skill SkillEnum?
---@param item ItemIndex
local function switch_action (player, action, skill, item)
	player.current_action.kind = action
	player.current_action.used_item = item
	player.current_action.used_skill = skill
	player.current_action.completed = false
	player.current_action.progress = 0

	-- TODO: if spell, use spellcasting animation
	player.model.state =ActorModelStateEnum.Attacking
end

---@param player PlayerState
---@param item ItemIndex
local function schedule_item_action (player, item)
	assert(RETRIEVE_ITEM(item))
	---@type Action
	local action = {
		completed = false,
		progress = 0,
		kind = ActionEnum.ActivateItem,
		used_item = item
	}
	table.insert(player.items_queue, action)
end

---@param player PlayerState
local function reset_action (player)
	player.current_action.kind = ActionEnum.Nothing
	player.current_action.used_item = INVALID_ITEM_INDEX
	player.current_action.used_skill = nil
	player.current_action.progress = 0
	player.current_action.completed = false
end

---comment
---@param player PlayerState
---@param item ItemIndex
---@param target Enemy
local function process_item_skills(player, item, target)

	if player.micro_cooldown_item_activation > 0 then
		return false
	end

	local data = RETRIEVE_ITEM(item)
	if not data then
		return
	end
	if data.cooldown > 0 then
		return false
	end


	for _, affix in ipairs(data.affixes) do
		local skill = AffixTable[affix.affix_index].allows_skill
		if skill and can_use_skill (player, target, skills[skill]) then
			schedule_item_action(player, item)
			data.cooldown = ITEM_BASE_COOLDOWN
			player.micro_cooldown_item_activation = player.micro_cooldown_item_activation + MICROCOOLDOWN
			return true
		end
	end

	return false
end

---@param player PlayerState
---@param stage Stage
local function schedule_skill_activations_from_items(player, stage)
	if player.micro_cooldown_item_activation > 0 then
		return false
	end

	for index, target in ipairs(stage.enemies) do
		if target.hp <= 0 then
			goto continue
		end

		-- From rings
		for i = 1, 10, 1 do
			local ring_index = player.rings[i]
			if process_item_skills(player, ring_index, target) then
				return true
			end
		end

		::continue::
	end

	return false
end

---@param stage Stage
---@param location_index number
function battle_scene.generate_enemies(stage, location_index)
	stage.enemies = {}
	stage.projectiles = {}

	local loc_desc = Locations[location_index]
	local loc_data = LocationData[location_index]
	local faction = Factions[loc_data.controlled_by]


	---@type number
	local total_weight = 0.0
	for index, value in ipairs(faction.basic_composition) do
		total_weight = total_weight + value.weight
	end


	for i = 1, 5 do
		---@type number
		local dice = total_weight * love.math.random()
		local selected_unit = 1

		local acc = 0
		for index, value in ipairs(faction.basic_composition) do
			acc = acc + value.weight
			if dice < acc then
				selected_unit = index
				break
			end
		end

		local prot = faction.basic_composition[selected_unit].unit

		---@type Enemy
		local starting_enemy = {
			prototype = prot,
			hp = prot.hp_max,
			view_hp = prot.hp_max,
			position = math.sqrt(love.math.random() + 0.15) * stage.distance,
			damage = 2,
			attack_progress = 0,
			is_attacking = false,
			being_hit = false,
			being_hit_animation_progress = 0,
			on_kill_triggered = false,
			death_progress = 0,
			difficulty_melee = 0.05,
			difficulty_spell = 0.01,
			skill = 0.05,
		}
		table.insert(stage.enemies, starting_enemy)
	end
end

local enemy_speed = 200

---@param dt number
---@param vfx VFX
---@param player PlayerState
---@param stage Stage
---@return boolean
function battle_scene.update(dt, vfx, player, stage)
	---@type number
	timer = timer + dt


	local distance_from_camera = player.model.position - actual_camera
	local t = math.min(1, math.max(0, math.abs(distance_from_camera) / 50 - 1))
	---@type number
	actual_camera = actual_camera + SMOOTHERSTEP(t) * dt * distance_from_camera * 2
	actual_camera = math.min(actual_camera, stage.distance - 600)


	if player.model.position >= stage.distance or player.hp <= 0 then
		return true
	end

	for index, value in ipairs(stage.enemies) do
		if value.hp <= 0 and not value.on_kill_triggered then
			value.on_kill_triggered = true
			require "triggered.on-kill"(player, value.prototype)
		end

		if value.hp <= 0 then
			value.death_progress = value.death_progress + dt
		end
	end


	for index, value in ipairs(stage.projectiles) do
		if value.discard then
		elseif value.impact then
			value.impact_progress = value.impact_progress + dt * 5
			if value.impact_progress >= 1 then
				-- do something
				value.impact_progress = 1
				value.discard = true
				magic_aoe(vfx, stage, value.position - value.desc.size_x / 2 * value.size, value.position + value.desc.size_x / 2 * value.size, value.damage, player)
			end
		else
			local dx = value.target - value.position
			local dy = -value.height
			local n = math.sqrt(dx * dx + dy * dy)
			local true_distance = math.sqrt(dx * dx + dy * dy)
			local move = value.speed * dt
			if (move >= true_distance) then
				value.target = value.position
				value.height = 0
				value.impact = true
				value.impact_progress = 0
			else
				value.position = value.position + dx / n * move
				value.height = value.height + dy / n * move
			end
		end
	end

	for index, value in ipairs(stage.enemies) do
		if value.being_hit and value.being_hit_animation_progress < 1 then
			value.being_hit_animation_progress = value.being_hit_animation_progress + dt
		end
		if value.position < player.model.position + 20 and value.hp > 0 then
			value.is_attacking = true
			value.attack_progress = value.attack_progress + dt
			if value.attack_progress >= 1 then
				local enemy_damage = value.prototype.base_damage
				local skill_diff = value.prototype.attack_skill - player.mastery.melee_defense
				local success = love.math.random() < skill_diff / 0.5 + 0.5
				if not success then
					enemy_damage =math.floor(enemy_damage / 10)
				else
					player.mastery.melee_defense = player.mastery.melee_defense + player.mental.learning_speed
				end
				if enemy_damage >= player.shield then
					enemy_damage = enemy_damage - player.shield
					player.shield = 0
				end
				if player.shield >= enemy_damage then
					player.shield = player.shield - enemy_damage
					enemy_damage = 0
				end
				player.hp = player.hp - enemy_damage
				if player.hp <= 0 then
					return true
				end
				value.attack_progress = 0
			end
		elseif value.hp > 0 then
			value.attack_progress = 0
			value.is_attacking = false
			value.position = value.position - dt * enemy_speed
		end
	end


	player.model.state = ActorModelStateEnum.Idle

	player.micro_cooldown_item_activation = player.micro_cooldown_item_activation - dt

	if #player.items_queue == 0 then
		while schedule_skill_activations_from_items (player, stage) do end
	end

	player.micro_cooldown_item_activation = math.max (0, player.micro_cooldown_item_activation)

	local action = player.current_action
	if action.kind == ActionEnum.Nothing then
		-- Can we do a basic attack?
		local action_chosen = false
		for index, value in ipairs(stage.enemies) do
			if value.hp <= 0 then
				goto continue
			end
			-- check all available skills
			-- Inherent:
			if value.position < player.model.position + skills[SkillEnum.MeleeAttack].activation_range(player) then
				switch_action(player, ActionEnum.ActivateSkill, SkillEnum.MeleeAttack, INVALID_ITEM_INDEX)
				action_chosen = true
				break
			end

			if action_chosen then
				break
			end

			::continue::
		end
		if not action_chosen then
			local move = dt * player.speed
			player.model.walk_timer = player.model.walk_timer + move
			player.model.state = ActorModelStateEnum.Walking
			for index, value in ipairs(stage.enemies) do
				local shift = value.position - player.model.position
				if shift - 5 <= move and value.hp > 0 then
					move = shift - 4
				end
			end
			player.model.position = player.model.position + move
		end
	elseif player.current_action.kind ==ActionEnum.ActivateSkill then
		local skill_index = action.used_skill
		assert(skill_index ~= nil)
		local skill = skills[skill_index]
		skill.update(vfx, stage, player, dt, player.model,  player.model_description, false, 1)
		if player.current_action.completed then
			reset_action(player)
		end
	end

	for index, value in ipairs(player.items_queue) do
		local item_index = value.used_item
		local item = RETRIEVE_ITEM(item_index)
		assert(item)
		item.durability = item.durability - 0.01
		item.cooldown = ITEM_BASE_COOLDOWN
		for index, value in ipairs(item.affixes) do
			local skill_index = AffixTable[value.affix_index].allows_skill
			if skill_index then
				local skill = skills[skill_index]
				skill.update(vfx, stage, player, dt, player.model, player.model_description, true, value.amount)
			end
		end
	end
	player.items_queue = {}

	return false
end


return battle_scene