local basic_attack = require "skills.melee-attack"
local comet = require "skills.comet"
local aoe = require "effect.aoe-flat"

function CLAMP(x, a, b)
	if (x < a) then
		return a
	end
	if (x > b) then
		return b
	end
	return x
end
---comment
---@param t number
---@return number
function SMOOTHSTEP(t)
	return t * t * (3 - 2 * t)
end

---@param x number
---@return number
function SMOOTHERSTEP(x)
	return x * x * x * (x * (6 * x - 15) + 10);
end

local style = require "ui._style"
local button = require "ui.button"
local panel = require "ui.panel"
local hp_bar = require "ui.hp-bar"
local border = require "ui.border"
local rect_detection = require "ui.rect"


local bg =love.graphics.newImage("bg-1200-500.png")
local player_image = love.graphics.newImage("skeleton.png")
local blob = love.graphics.newImage("blob.png")
local inventory_slot_bg = love.graphics.newImage("inventory_slot.png")

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
local blood_ground_image = love.graphics.newImage("blood-ground.png")

---@class Particle
---@field time_left number
---@field max_time number
---@field size number
---@field position number
---@field image love.Image

---@class VFX
---@field particles Particle[]
---@type VFX
local vfx_manager = {
	particles = {}
}
for i = 1, 100 do
	---@type Particle
	local particle = {
		image = blood_ground_image,
		position = 0,
		size = 1,
		time_left = 0,
		max_time = 1
	}
	table.insert(vfx_manager.particles, particle)
end



---@type number
local timer = 0

local hp = 10
local hp_view = 10
local max_hp = 15
local shield = 20
local speed = 0.2

---@enum SkillEnum
SkillEnum = {
	BasicAttack = 1,
	Comet = 2,
}

---@class PlayerState
---@field attack_range number
---@field melee_damage number
---@field spell_damage number
---@field items Item[]
---@field weapon number|nil
---@field boots number|nil
---@field exp number
---@field level number
---@field current_action SkillEnum?

---@type PlayerState
local player_state = {
	attack_range = 0,
	items = {},
	melee_damage = 0,
	spell_damage = 0,
	exp = 0,
	level = 0
}

---@type ActorModelState
local player_model = {
	position = 0,
	walk_timer = 0,
	walking = false
}

local difficulty = 1

local exp = 0
local level = 1
local magic_dust = 0

local function display_stats(render, x, y)
	panel(render, x, y, 160, 130 )
	if render then
		love.graphics.print("Max HP: " .. tostring(max_hp), x + 10, y + 10)
		love.graphics.print("Shield: " .. tostring(shield), x + 10, y + 30)
		love.graphics.print("Speed: " .. tostring(speed), x + 10, y + 50)
		love.graphics.print("Melee damage: " .. tostring(player_state.melee_damage), x + 10, y + 70)
		love.graphics.print("Spell damage: " .. tostring(player_state.spell_damage), x + 10, y + 90)
	end
end


---@class Enemy
---@field hp number
---@field model ActorModelDescription
---@field position number
---@field damage number
---@field attack_progress number
---@field is_attacking boolean
---@field being_hit boolean
---@field being_hit_animation_progress number
---@field on_kill_triggered boolean

---@class ProjectileDescription
---@field size_x number
---@field size_y number
---@field image love.Image
---@field movement_frames love.Quad[]
---@field impact_frames love.Quad[]

---@class Projectile
---@field desc ProjectileDescription
---@field height number
---@field position number
---@field target number
---@field speed number
---@field size number
---@field impact boolean
---@field impact_progress number
---@field discard boolean
---@field damage number

---@class Stage
---@field distance number
---@field enemies Enemy[]
---@field projectiles Projectile[]

---@type Stage
local stage = {
	distance = 1000,
	enemies = {},
	projectiles = {}
}

---@enum ItemSlot
ItemSlot = {
	Boots = 1,
	Weapon = 2
}

---@enum ItemImageSize
ItemImageSize = {
	Small = 1,
	Medium = 2,
	Large = 3,
}

---@class ItemKind
---@field name string
---@field image love.Image
---@field damage number
---@field speed_modifier number
---@field base_attack_speed number
---@field shield number
---@field slot ItemSlot
---@field range number
---@field image_kind ItemImageSize

---@type ItemKind[]
BaseItemTable = {}

local function register_weapon(name, image, damage, base_attack_speed, speed_modifier)
	---@type ItemKind
	local item = {
		damage = damage,
		name = name,
		image = image,
		base_attack_speed = base_attack_speed,
		slot = ItemSlot.Weapon,
		speed_modifier = speed_modifier,
		range = 10,
		shield = 0,
		image_kind = ItemImageSize.Large
	}

	table.insert(BaseItemTable, item)
end

local function register_boots(name, image, speed_modifier, base_shield)
	---@type ItemKind
	local item = {
		name = name,
		image = image,
		damage = 0,
		base_attack_speed = 0,
		slot = ItemSlot.Boots,
		range = 0,
		speed_modifier = speed_modifier,
		shield = base_shield,
		image_kind = ItemImageSize.Medium
	}
	table.insert(BaseItemTable, item)
end


register_boots("Boots", love.graphics.newImage("boots.png"), 1.1, 5)
register_weapon("Knife", love.graphics.newImage("knife.png"), 2, 2.25, 0)


---@class ItemAffix
---@field name string
---@field speed_modifier number
---@field pack_size number
---@field add_damage number
---@field rarity number
---@field shield number

---@type ItemAffix[]
SuffixTable = {}
---@type ItemAffix[]
PrefixTable = {}

do
	---@type ItemAffix
	local item = {
		name = "Quick",
		pack_size = 0,
		speed_modifier = 0.2,
		rarity = 1,
		add_damage = 0,
		shield = 0
	}
	table.insert(PrefixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "Sharp",
		pack_size = 0,
		speed_modifier = 0,
		rarity = 1,
		add_damage = 1,
		shield = 0
	}
	table.insert(PrefixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "of Tailwind",
		pack_size = 0,
		speed_modifier = 0.4,
		rarity = 1,
		add_damage = 0,
		shield = 0
	}
	table.insert(SuffixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "of Protection",
		pack_size = 0,
		speed_modifier = 0.0,
		rarity = 1,
		add_damage = 0,
		shield = 10
	}
	table.insert(SuffixTable, item)
end

---@class Item
---@field kind number
---@field suffixes number[]
---@field prefixes number[]
---@field durability number

---comment
---@param player PlayerState
---@param item number
---@return integer
local function get_shield(player, item)
	if item == nil then
		return 0
	end

	---@type number
	local result = 0
	local w = player.items[item]
	local b = BaseItemTable[w.kind]
	result = result + b.shield
	for index, value in ipairs(w.prefixes) do
		result = result + PrefixTable[value].shield
	end
	for index, value in ipairs(w.suffixes) do
		result = result + SuffixTable[value].shield
	end

	return result
end

---@param player PlayerState
---@param item number
---@return integer
local function get_damage(player,item)
	if item == nil then
		return 0
	end

	---@type number
	local result = 0
	local w = player.items[item]
	local b = BaseItemTable[w.kind]
	result = result + b.damage
	for index, value in ipairs(w.prefixes) do
		result = result + PrefixTable[value].add_damage
	end
	for index, value in ipairs(w.suffixes) do
		result = result + SuffixTable[value].add_damage
	end

	return result
end

---@param player PlayerState
---@param item number
---@return integer
local function get_speed_mod(player, item)
	if item == nil then
		return 0
	end

	---@type number
	local result = 0
	local w = player.items[item]
	local b = BaseItemTable[w.kind]
	result = result + b.speed_modifier
	for index, value in ipairs(w.prefixes) do
		result = result + PrefixTable[value].speed_modifier
	end
	for index, value in ipairs(w.suffixes) do
		result = result + SuffixTable[value].speed_modifier
	end

	return result
end

---@param player PlayerState
local function update_damage_and_speed(player)
	player.melee_damage = 1 + get_damage(player, player.weapon)
	player.spell_damage = 1 + get_damage(player, player.boots)
	speed = 200 * (1 + get_speed_mod(player, player.weapon) + get_speed_mod(player, player.boots))
end







---@class SkillData
---@field progress number
---@field completed boolean

---@type SkillData
local action_data = {
	progress = 0,
	completed = true,
}


---@class ActorModelDescription
---@field size_x number
---@field size_y number
---@field image love.Image
---@field image_base_scale number
---@field walk_frames love.Quad[]
---@field walk_timer_mult number
---@field idle_frames love.Quad[]

---@class ActorModelState
---@field position number
---@field walking boolean
---@field walk_timer number

local basic = love.graphics.newImage("hero-battle.png")

---@type ActorModelDescription
local basic_skeleton = {
	size_x = 40,
	size_y = 40,
	image = basic,
	image_base_scale = 2,
	walk_frames = {love.graphics.newQuad(0, 0, 40, 40, basic)},
	idle_frames = {love.graphics.newQuad(0, 0, 40, 40, basic)},
	walk_timer_mult = 1
}

local hero = love.graphics.newImage("character-basic.png")

---@type ActorModelDescription
local basic_hero = {
	size_x = 400,
	size_y = 600,
	image = hero,
	image_base_scale = 0.25,
	walk_frames = {
		love.graphics.newQuad(400 * 1, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 2, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 3, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 4, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 5, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 6, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 7, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 8, 0, 400, 600, hero),
	},
	walk_timer_mult = 1 / 200,
	idle_frames = {love.graphics.newQuad(0, 0, 400, 600, hero)},
}

---comment
---@param model ActorModelDescription
---@param state ActorModelState
local function draw_character(x, y, model, state, camera_shift)
	love.graphics.setColor(1, 1, 1, 1)

	if state.walking then
		local frame = math.floor(state.walk_timer * model.walk_timer_mult * #model.walk_frames) % #model.walk_frames
		love.graphics.draw(
			model.image,
			model.walk_frames[frame + 1],
			x + camera_shift + state.position - model.size_x / 2 * model.image_base_scale,
			y - model.size_y *model.image_base_scale,
			0,
			model.image_base_scale,
			model.image_base_scale
		)
	else
		-- replace with per entity timer
		local frame = math.floor(timer / 50 * #model.idle_frames) % #model.idle_frames
		love.graphics.draw(
			model.image,
			model.idle_frames[frame + 1],
			x + camera_shift + state.position - model.size_x / 2 * model.image_base_scale,
			y - model.size_y *model.image_base_scale,
			0,
			model.image_base_scale,
			model.image_base_scale
		)
	end
end

-- local current_skill = nil

local function character_widget(render, x, y)
	panel(render, x, y, 100, 120)

	style.default_font()
	style.default_font_color()
	-- love.graphics.print("Character widget")

	panel(render, x + 3, y + 3, 94, 94 )
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(player_image, x + 5, y + 5)

	hp_bar(x + 3, y + 99, 94, 17, hp, hp_view, max_hp, shield, false )
end

local function status_bar(render, x, y)
	panel (render, x, y, 400, 120)
	love.graphics.print("Skeleton lvl 1", x + 20, y + 20)
end

local base_camera_shift = 10
local actual_camera = 0

local fade_out = true
local fade_in = false
local fade_progress = 1

local function battle_panel(render, x, y)
	local battle_y = y + 240

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(bg, x  - actual_camera % 1200, y)
	love.graphics.draw(bg, x  - actual_camera % 1200+ 1200, y)

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
		if value.hp > 0 then
			draw_character(x, battle_y, basic_skeleton, { position = value.position, walk_timer = timer, walking = not value.is_attacking }, base_camera_shift - actual_camera)
		end
	end

	draw_character(x, battle_y, basic_hero, player_model, base_camera_shift - actual_camera)

	if player_state.current_action ==SkillEnum.BasicAttack then
		basic_attack.draw(x, battle_y, action_data, basic_hero, player_model, base_camera_shift - actual_camera)
	elseif  player_state.current_action == SkillEnum.Comet then
		comet.draw(x, battle_y, action_data, basic_hero, player_model, base_camera_shift - actual_camera)
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
			love.graphics.draw(
				value.desc.image,
				value.desc.impact_frames[frame + 1],
				base_camera_shift + x + value.position - actual_camera - value.desc.size_x / 2 * value.size * value.impact_progress,
				battle_y - value.height - value.desc.size_y / 2 * value.size * value.impact_progress,
				0, value.size * value.impact_progress, value.size * value.impact_progress
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

	love.graphics.setColor(0, 0, 0, fade_progress)
	love.graphics.rectangle("fill", x, y, 1200, 500)
end

local scale = 0.5
local interface_grid = 16 * scale
local right_panel_width = 38 * interface_grid
local right_panel_width_no_margins = 36 * interface_grid
local window_width = 1024
local window_height = 780

local equip_image_height = 41 * interface_grid
local stats_height = 29 * interface_grid
local inventory_height = 23 * interface_grid

local equip_bg = love.graphics.newImage("equip.png")

local function right_side_panel(render, mx, my)
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle("fill", window_width - right_panel_width, 0, right_panel_width, window_height)
	border(render, window_width - right_panel_width, 0, right_panel_width, window_height)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(equip_bg, window_width - right_panel_width + interface_grid, interface_grid, 0, scale, scale)
	border(render,  window_width - right_panel_width + interface_grid, interface_grid, right_panel_width_no_margins, equip_image_height)

	style.header_font()

	love.graphics.setColor(0, 0, 0)
	love.graphics.printf("Equipment", window_width - right_panel_width, interface_grid * 1.5, right_panel_width, "center")

	panel(
		render,
		window_width - right_panel_width + interface_grid,
		interface_grid + equip_image_height + interface_grid,
		right_panel_width_no_margins,
		stats_height,
		true
	)

	panel(
		render,
		window_width - right_panel_width + interface_grid,
		interface_grid + equip_image_height + interface_grid + stats_height + interface_grid,
		right_panel_width_no_margins,
		inventory_height,
		true
	)

	love.graphics.setColor(1, 1, 1)
	if player_state.weapon then
		local item = player_state.items[player_state.weapon]
		local img = BaseItemTable[item.kind].image
		love.graphics.draw(img, window_width - right_panel_width + interface_grid *2, interface_grid * 6, 0, scale, scale)
	end

	if player_state.boots then
		local item = player_state.items[player_state.boots]
		local img = BaseItemTable[item.kind].image
		love.graphics.draw(img, window_width - interface_grid *8, interface_grid *19, 0, scale, scale)
	end

	local row = 0
	local column = 0

	local x = window_width - right_panel_width + interface_grid + interface_grid
	local y = interface_grid + equip_image_height + interface_grid + stats_height + interface_grid + interface_grid

	for index, value in ipairs(player_state.items) do
		local item_x = x + column * interface_grid * 7
		local item_y = y + row * interface_grid * 7

		local affixes_count = #value.prefixes + #value.suffixes

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(inventory_slot_bg, item_x, item_y, 0, scale, scale)

		if affixes_count == 0 then
			love.graphics.setColor(0, 0, 0)
		elseif affixes_count <= 2 then
			love.graphics.setColor(0, 0, 0.5)
		else
			love.graphics.setColor(0.6, 0.1, 0)
		end


		love.graphics.setColor(1, 1, 1)
		local kind = BaseItemTable[value.kind]
		if kind.image_kind ==ItemImageSize.Small then
			love.graphics.draw(kind.image, item_x, item_y)
		elseif kind.image_kind == ItemImageSize.Medium then
			love.graphics.draw(kind.image, item_x, item_y, 0, 0.5, 0.5)
		elseif kind.image_kind == ItemImageSize.Large then
			love.graphics.draw(kind.image, item_x + interface_grid * 1.5, item_y, 0, 0.25, 0.25)
		end
		border(render, item_x, item_y, interface_grid * 6,  interface_grid * 6)

		if player_state.weapon == index or player_state.boots == index then
			border(render, item_x + 5, item_y + 5, interface_grid * 6 - 10, interface_grid * 6 - 10)
		end

		if (not render) and rect_detection(item_x, item_y, interface_grid * 6, interface_grid * 6, mx, my) then
			if BaseItemTable[value.kind].slot ==ItemSlot.Boots then
				player_state.boots = index
			end
			if BaseItemTable[value.kind].slot ==ItemSlot.Weapon then
				player_state.weapon = index
			end
			update_damage_and_speed(player_state)
		end

		hp_bar(item_x + 5, item_y + interface_grid * 6 - 10, interface_grid * 6 - 10, 7, value.durability, value.durability, 1, 0, false)

		column = column + 1
		if column >= 5 then
			column = 0
			row = row + 1
		end

	end
end

local function change_difficulty(render, x, y, mx, my)
	panel(render, x, y, 80, 80)
	if button(render, "+", x+5, y+5, 30, 30, mx, my, false) then
		difficulty = difficulty + 1
	end
	if button(render, "-", x+45, y+5, 30, 30, mx, my, false) then
		difficulty = math.max(1, difficulty - 1)
	end
	love.graphics.print("Level: " .. tostring(difficulty), x + 5, y + 37)
end

local function  interface(render, mx, my)
	character_widget(render, 10, 10)
	status_bar(render, 210, 10)
	battle_panel(render, 0, 160)
	change_difficulty(render, 110, 10, mx, my)

	right_side_panel(render, mx, my)
	display_stats(render, 630, 400)
end

local function generate_enemies()
	stage.enemies = {}
	stage.projectiles = {}

	for i = 1, difficulty do
		---@type Enemy
		local starting_enemy = {
			hp = 3 + difficulty,
			model = basic_skeleton,
			position = math.sqrt(love.math.random() + 0.5) * stage.distance,
			damage = difficulty,
			attack_progress = 0,
			is_attacking = false,
			being_hit = false,
			being_hit_animation_progress = 0,
			on_kill_triggered = false
		}
		table.insert(stage.enemies, starting_enemy)
	end
end

function love.load()
	love.window.setTitle("Endless Ledge")
	generate_enemies()
end

local reset_stage = true
local enemy_speed = 200

---comment
---@param dt number
function love.update(dt)

	timer = timer + dt

	local distance_from_camera = player_model.position - actual_camera

	local t = math.min(1, math.max(0, math.abs(distance_from_camera) / 50 - 1))
	if (not fade_in) then
		actual_camera = actual_camera + SMOOTHERSTEP(t) * dt * distance_from_camera * 2
	elseif hp > 0 then
		distance_from_camera = stage.distance - actual_camera
		actual_camera = actual_camera + SMOOTHERSTEP(t) * dt * distance_from_camera * 2
	end
	actual_camera = math.min(actual_camera, stage.distance - 600)

	if player_model.position >= stage.distance or hp <= 0 then
		reset_stage = true
		fade_in = true
		player_model.position = 0
		hp = max_hp
		shield = get_shield(player_state, player_state.weapon) + get_shield(player_state, player_state.boots)
		stage.distance = math.sqrt(difficulty) * 1000
	end

	if reset_stage then
		if fade_in then
			fade_progress = fade_progress + dt
			if fade_progress >= 1 then
				fade_out = true
				fade_in = false
				actual_camera = player_model.position
			end
		else
			player_model.position = 0
			reset_stage = false
			update_damage_and_speed(player_state)
			generate_enemies()
		end

		return
	end

	if (fade_out) then
		fade_progress = fade_progress - dt
		if fade_progress <= 0 then
			fade_progress = 0
			fade_out = false
		end
	end

	for index, value in ipairs(stage.enemies) do
		if value.hp <= 0 and not value.on_kill_triggered then
			value.on_kill_triggered = true
			require "triggered.on_kill"(player_state, difficulty)
		end
	end

	for index, value in ipairs(vfx_manager.particles) do
		value.time_left = value.time_left - dt
	end

	for index, value in ipairs(stage.projectiles) do
		if value.discard then
		elseif value.impact then
			value.impact_progress = value.impact_progress + dt * 5
			if value.impact_progress >= 1 then
				-- do something
				value.impact_progress = 1
				value.discard = true
				aoe(vfx_manager, stage, value.position - value.desc.size_x / 2 * value.size, value.position + value.desc.size_x / 2 * value.size, value.damage)
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
		if value.position < player_model.position + 20 and value.hp > 0 then
			value.is_attacking = true
			value.attack_progress = value.attack_progress + dt
			if value.attack_progress >= 1 then
				local enemy_damage = value.damage
				if enemy_damage >= shield then
					enemy_damage = enemy_damage - shield
					shield = 0
				end
				if shield >= enemy_damage then
					shield = shield - enemy_damage
					enemy_damage = 0
				end
				hp = hp - enemy_damage
				if hp <= 0 then
					return
				end
				value.attack_progress = 0
			end
		else
			value.attack_progress = 0
			value.is_attacking = false
			value.position = value.position - dt * enemy_speed
		end
	end


	player_model.walking = false
	if player_state.current_action == nil then
		-- Can we do a basic attack?
		local action_chosen = false
		for index, value in ipairs(stage.enemies) do
			if value.hp <= 0 then
				goto continue
			end

			if value.position < player_model.position + basic_attack.activation_range(player_state) then
				player_state.current_action = SkillEnum.BasicAttack
				action_data.completed = false
				action_data.progress = 0
				action_chosen = true
				break
			elseif  value.position < player_model.position + comet.activation_range(player_state) then
				player_state.current_action = SkillEnum.Comet
				action_data.completed = false
				action_data.progress = 0
				action_chosen = true
				break
			end

			::continue::
		end
		if not action_chosen then
			local move = dt * speed
			player_model.walk_timer = player_model.walk_timer + move
			player_model.walking = true
			for index, value in ipairs(stage.enemies) do
				local shift = value.position - player_model.position
				if shift - 5 <= move and value.hp > 0 then
					move = shift - 4
				end
			end
			player_model.position = player_model.position + move
		end
	elseif player_state.current_action ==SkillEnum.BasicAttack then
		basic_attack.update(vfx_manager, stage, player_state, dt, player_model, action_data)
		if action_data.completed then
			action_data.progress = 0
			action_data.completed = false
			player_state.current_action = nil
		end
	elseif player_state.current_action ==SkillEnum.Comet then
		comet.update(vfx_manager, stage, player_state, dt, player_model, action_data)
		if action_data.completed then
			action_data.progress = 0
			action_data.completed = false
			player_state.current_action = nil
		end
	end

	local decay = math.exp(-dt * 10)
	hp_view = hp_view * decay + hp * (1 - decay)
end

function love.draw()
	love.graphics.setBackgroundColor(0.75, 0.75, 0.75, 1)
	local x, y = love.mouse.getPosition()
	interface(true, x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
	interface(false, x, y)
end