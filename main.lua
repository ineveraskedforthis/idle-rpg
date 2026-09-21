-- local basic_attack = require "skills.melee-attack"
-- local comet = require "skills.comet"
local aoe = require "effect.aoe-flat"

local skills = require "skills._manager"

ITEM_BASE_COOLDOWN = 0.3
MICROCOOLDOWN = 1 / 60

---@class InterfaceRequest
---@field render boolean
---@field mx number
---@field my number
---@field mouse_button number
---@field presses number


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
local progress_bar = require "ui.progress-bar"
local border = require "ui.border"
local rect_detection = require "ui.rect"


local bg =love.graphics.newImage("bg-1200-500.png")
local player_image = love.graphics.newImage("skeleton.png")
local blob = love.graphics.newImage("blob.png")

local blob_x, blob_y = blob:getDimensions()

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

---@class (exact) Particle
---@field time_left number
---@field max_time number
---@field size number
---@field position number
---@field image love.Image

---@class (exact) VFX
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

---@enum ActionEnum
ActionEnum = {
	Nothing = 1,
	ActivateSkill = 2,
	ActivateItem = 3
}

---@class (exact) Action
---@field kind ActionEnum
---@field used_skill SkillEnum?
---@field used_item ItemIndex
---@field progress number
---@field completed boolean

---@class ItemDatabase
---@field data_array Item[]
---@field generation number[]
---@field available_id number

---@class ItemIndex
---@field id number
---@field generation number

---@type ItemDatabase
local ITEM_DB = {
	data_array = {},
	generation = {1},
	available_id = 1
}

---@type ItemIndex
INVALID_ITEM_INDEX = {
	generation = 0,
	id = 0
}

local selected_item = INVALID_ITEM_INDEX

local function UPDATE_AVAILABLE_ID()
	local id_found = false
	for i = 1, #ITEM_DB.generation, 1 do
		if ITEM_DB.data_array[i] == nil or ITEM_DB.data_array[i].invalid then
			ITEM_DB.available_id = i
			id_found = true
			break
		end
	end
	if not id_found then
		ITEM_DB.available_id = #ITEM_DB.generation + 1
		ITEM_DB.generation[ITEM_DB.available_id] = 1
	end
	print("AVAILABLE", ITEM_DB.available_id)
end

---comment
---@param item Item
---@return ItemIndex
function CREATE_ITEM(item)
	---@type ItemIndex
	local result = {
		id = ITEM_DB.available_id,
		generation = ITEM_DB.generation[ITEM_DB.available_id]
	}
	print("CREATE", ITEM_DB.available_id)
	ITEM_DB.data_array[ITEM_DB.available_id] = item
	UPDATE_AVAILABLE_ID()
	return result
end

---comment
---@param index ItemIndex
function DELETE_ITEM(index)
	assert(ITEM_DB.generation[index.id] == index.generation)
	print("DELETE", index.id)
	ITEM_DB.generation[index.id] = ITEM_DB.generation[index.id] + 1
	ITEM_DB.data_array[index.id].invalid = true
	UPDATE_AVAILABLE_ID()
end

---comment
---@param index ItemIndex
local function print_index(index)
	print("ID: ", index.id, " | Generation: ", index.generation)
end

---comment
---@param index ItemIndex|nil
---@return Item|nil
function  RETRIEVE_ITEM(index)
	if index == nil then
		return nil
	end
	if index.id == 0 then
		return nil
	end
	if index.generation ~= ITEM_DB.generation[index.id] then
		return nil
	end
	return ITEM_DB.data_array[index.id]
end

---@class (exact) PlayerState
---@field attack_range number
---@field melee_damage number
---@field spell_damage number
---@field stash ItemIndex[]
---@field rings ItemIndex[]
---@field weapon ItemIndex
---@field boots ItemIndex
---@field mastery MasteryState
---@field current_action Action
---@field items_queue Action[]
---@field micro_cooldown_item_activation number
---@field item_skills_queue number[]

---@class (exact) MasteryState
---@field melee_weapon number
---@field general_magic number


---@type PlayerState
local player_state = {
	attack_range = 0,
	stash = {},
	melee_damage = 0,
	spell_damage = 0,
	rings = {
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
		INVALID_ITEM_INDEX,
	},
	mastery = {
		melee_weapon = 0,
		general_magic = 0
	},
	current_action = {
		kind = ActionEnum.Nothing,
		used_item = INVALID_ITEM_INDEX,
		used_skill = nil,
		progress = 0,
		completed = true,
	},
	items_queue = {},
	weapon = INVALID_ITEM_INDEX,
	boots = INVALID_ITEM_INDEX,
	micro_cooldown_item_activation = 0,
	item_skills_queue = {}
}

---@enum ActorModelStateEnum
ActorModelStateEnum = {
	Idle = 1,
	Walking = 2,
	Attacking = 3,
	Dead = 4
}

---@type ActorModelState
local player_model = {
	position = 0,
	walk_timer = 0,
	state = ActorModelStateEnum.Idle,
	death_timer = 0,
}

local difficulty = 1

local exp = 0
local level = 1
local magic_dust = 0

---@class (exact) Enemy
---@field hp number
---@field view_hp number
---@field max_hp number
---@field model ActorModelDescription
---@field position number
---@field damage number
---@field attack_progress number
---@field is_attacking boolean
---@field being_hit boolean
---@field being_hit_animation_progress number
---@field on_kill_triggered boolean
---@field death_progress number

---@class (exact) ProjectileDescription
---@field size_x number
---@field size_y number
---@field image love.Image
---@field movement_frames love.Quad[]
---@field impact_frames love.Quad[]

---@class (exact) Projectile
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

---@class (exact) Stage
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
	Weapon = 2,
	Ring = 3
}

---@enum ItemImageSize
ItemImageSize = {
	Small = 1,
	Medium = 2,
	Large = 3,
}

---@class (exact) ItemKind
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


local function register_ring(name, image, base_shield)
	---@type ItemKind
	local item = {
		name = name,
		image = image,
		damage = 0,
		base_attack_speed = 0,
		slot = ItemSlot.Ring,
		range = 0,
		speed_modifier = 0,
		shield = base_shield,
		image_kind = ItemImageSize.Small
	}
	table.insert(BaseItemTable, item)
end

register_boots("Boots", love.graphics.newImage("boots.png"), 1.1, 5)
register_weapon("Knife", love.graphics.newImage("knife.png"), 2, 2.25, 0)
register_ring("ShieldRing", love.graphics.newImage("ring.png"), 5)


---@class (exact) ItemAffix
---@field name string
---@field speed_modifier number
---@field pack_size number
---@field melee_damage number
---@field magic_damage number
---@field rarity number
---@field shield number
---@field allows_skill SkillEnum|nil
---@field can_roll_for_weapon boolean
---@field can_roll_for_armor boolean
---@field can_roll_for_ring boolean
---@field is_prefix boolean

---@type ItemAffix[]
AffixTable = {}

do
	---@type ItemAffix
	local item = {
		name = "Quick",
		pack_size = 0,
		speed_modifier = 0.05,
		rarity = 1,
		melee_damage = 0,
		magic_damage = 0,
		can_roll_for_armor = true,
		can_roll_for_weapon = false,
		can_roll_for_ring = false,
		shield = 0,
		is_prefix = true
	}
	table.insert(AffixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "Sharp",
		pack_size = 0,
		speed_modifier = 0,
		rarity = 1,
		melee_damage = 1,
		shield = 0,
		can_roll_for_armor = false,
		can_roll_for_ring = false,
		can_roll_for_weapon = true,
		magic_damage = 0,
		is_prefix = true
	}
	table.insert(AffixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "Mystic",
		pack_size = 0,
		speed_modifier = 0,
		rarity = 1,
		melee_damage = 1,
		shield = 0,
		can_roll_for_armor = false,
		can_roll_for_ring = false,
		can_roll_for_weapon = true,
		magic_damage = 0,
		is_prefix = true
	}
	table.insert(AffixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "of Tailwind",
		pack_size = 0,
		speed_modifier = 0.1,
		rarity = 10,
		add_damage = 0,
		shield = 0,
		can_roll_for_armor =true,
		can_roll_for_ring =false,
		can_roll_for_weapon =false,
		magic_damage = 0,
		melee_damage =0,
		is_prefix = false
	}
	table.insert(AffixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "of Protection",
		pack_size = 0,
		speed_modifier = 0.0,
		rarity = 1,
		add_damage = 0,
		shield = 10,
		can_roll_for_armor =true,
		can_roll_for_ring = true,
		can_roll_for_weapon = false,
		magic_damage = 0,
		melee_damage = 0,
		is_prefix = false
	}
	table.insert(AffixTable, item)
end
do
	---@type ItemAffix
	local item = {
		name = "of Skyfall",
		pack_size = 0,
		speed_modifier = 0.0,
		rarity = 1,
		add_damage = 0,
		shield = 10,
		can_roll_for_armor = false,
		can_roll_for_ring = true,
		can_roll_for_weapon = false,
		magic_damage = 1,
		melee_damage = 0,
		allows_skill = SkillEnum.Comet,
		is_prefix = false
	}
	table.insert(AffixTable, item)
end

---@class AffixInstance
---@field amount number
---@field affix_index number

---@class (exact) Item
---@field kind number
---@field affixes AffixInstance[]
---@field durability number
---@field cooldown number
---@field highlight_opacity number
---@field equipped boolean
---@field invalid boolean

---@param item ItemIndex
---@return integer
local function calculate_affixes(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	for index, value in ipairs(w.affixes) do
		result = result + value.amount
	end
	return result
end

---@param item ItemIndex
---@return integer
local function get_shield(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.shield
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].shield * value.amount
	end

	return result
end

---@param item ItemIndex
---@return integer
local function get_melee_damage(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.damage
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].melee_damage * value.amount
	end

	return result
end

---@param item ItemIndex
---@return integer
local function get_magic_damage(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.damage
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].magic_damage * value.amount
	end

	return result
end

---@param item ItemIndex
---@return integer
local function get_speed_mod(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.speed_modifier
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].speed_modifier * value.amount
	end

	return result
end

---@param player PlayerState
local function update_damage_and_speed(player)
	player.melee_damage = 1 + get_melee_damage(player.weapon)
	player.spell_damage = 1 + get_magic_damage(player.boots)
	for i = 1, 10, 1 do
		player.spell_damage = player.spell_damage + get_magic_damage(player.rings[i])
	end
	speed = 200 * (1 + get_speed_mod(player.weapon) + get_speed_mod(player.boots))
end


---@class (exact) ActorModelDescription
---@field size_x number
---@field size_y number
---@field image love.Image
---@field image_base_scale number
---@field walk_frames love.Quad[]
---@field walk_timer_mult number
---@field idle_frames love.Quad[]
---@field attack_timer_mult number
---@field attack_frames love.Quad[]
---@field dead_frame love.Quad[]



---@class (exact) ActorModelState
---@field position number
---@field state ActorModelStateEnum
---@field walk_timer number
---@field death_timer number

local basic = love.graphics.newImage("hero-battle.png")

---@type ActorModelDescription
local basic_skeleton = {
	size_x = 40,
	size_y = 40,
	image = basic,
	image_base_scale = 2,
	walk_frames = {love.graphics.newQuad(0, 0, 40, 40, basic)},
	idle_frames = {love.graphics.newQuad(0, 0, 40, 40, basic)},
	attack_frames = {love.graphics.newQuad(0, 0, 40, 40, basic)},
	walk_timer_mult = 1,
	attack_timer_mult =1,
	dead_frame = {love.graphics.newQuad(40, 0, 40, 40, basic)},
}

local big_rat_image =love.graphics.newImage("assets/rat-big/base.png")

---@type ActorModelDescription
local big_rat = {
	size_x = 300,
	size_y = 300,
	image = big_rat_image,
	image_base_scale = 0.25,
	walk_frames = {love.graphics.newQuad(0, 0, 300, 300, big_rat_image), love.graphics.newQuad(300, 0, 300, 300, big_rat_image)},
	idle_frames = {love.graphics.newQuad(300, 0, 300, 300, big_rat_image)},
	attack_frames = {love.graphics.newQuad(0, 300, 300, 300, big_rat_image)},
	dead_frame = {love.graphics.newQuad(300, 300, 300, 300, big_rat_image)},
	walk_timer_mult = 1,
	attack_timer_mult = 1,
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
	attack_timer_mult = 1 / 100,
	idle_frames = {love.graphics.newQuad(0, 0, 400, 600, hero)},
	attack_frames =  {love.graphics.newQuad(0, 0, 400, 600, hero)},
	dead_frame =  {love.graphics.newQuad(0, 0, 400, 600, hero)},
}

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

local function character_widget(render, x, y)
	panel(render, x, y, 100, 120)

	style.default_font()
	style.default_font_color()

	panel(render, x + 3, y + 3, 94, 94 )
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(player_image, x + 5, y + 5)

	progress_bar(x + 3, y + 99, 94, 17, hp, hp_view, max_hp, shield, "blue" )
end

---@param req InterfaceRequest
---@param x number
---@param y number
local function status_bar(req, x, y)
	panel (req.render, x, y, 400, 120)
	love.graphics.print("Skeleton lvl 1", x + 20, y + 20)
end

local base_camera_shift = 10
local actual_camera = 0

local fade_out = true
local fade_in = false
local fade_progress = 1

---comment
---@param req InterfaceRequest
---@param x number
---@param y number
local function battle_panel(req, x, y)
	if not req.render then
		return
	end

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
			local enemy_state = ActorModelStateEnum.Walking
			if value.is_attacking then
				enemy_state = ActorModelStateEnum.Attacking
			end
			draw_character(x, battle_y, value.model, { position = value.position, walk_timer = timer, state = enemy_state, death_timer = 0 }, base_camera_shift - actual_camera, -1)
			local bar_x = x + base_camera_shift - actual_camera + value.position - value.model.size_x / 4 *value.model.image_base_scale
			local bar_width = value.model.size_x *value.model.image_base_scale / 2
			local bar_y = battle_y - value.model.size_y *value.model.image_base_scale
			progress_bar(bar_x, bar_y, bar_width, 7, value.hp, value.view_hp, value.max_hp, 0, "red")
		else
			draw_character(x, battle_y, value.model, { position = value.position, walk_timer = timer, state = ActorModelStateEnum.Dead, death_timer = value.death_progress }, base_camera_shift - actual_camera, -1)
		end
	end

	do
		draw_character(x, battle_y, basic_hero, player_model, base_camera_shift - actual_camera, 1)
		local bar_x = x + base_camera_shift - actual_camera + player_model.position - basic_hero.size_x / 4 *basic_hero.image_base_scale
		local bar_width = basic_hero.size_x *basic_hero.image_base_scale / 2
		local bar_y = battle_y - basic_hero.size_y *basic_hero.image_base_scale
		progress_bar(bar_x, bar_y, bar_width, 7, hp, hp_view, max_hp, 0, "blue")
	end

	local action = player_state.current_action.used_skill
	if action then
		local skill = skills[action]
		skill.draw(x, battle_y, player_state, basic_hero, player_model, base_camera_shift - actual_camera)
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

local ring_xy = {
	{1, 25},
	{4, 26},
	{7, 27},
	{8, 24},
	{8, 21},
	{26, 21},
	{26, 24},
	{27, 27},
	{30, 26},
	{33, 25},
}

---@param item ItemIndex
local function unequip_item(item)
	local inventory = 0
	for index, value in ipairs(player_state.stash) do
		local item = RETRIEVE_ITEM(value)
		if item and not item.equipped then
			inventory = inventory + 1
		end
	end

	if inventory >= 15 then
		return
	end

	local data = RETRIEVE_ITEM(item)
	if data == nil then
		return
	end
	if not data.equipped then
		return
	end
	local slot = BaseItemTable[data.kind].slot
	if slot ==ItemSlot.Boots then
		if player_state.boots.id == item.id then
			data.equipped = false
			player_state.boots = INVALID_ITEM_INDEX
		end
	end
	if slot ==ItemSlot.Weapon then
		if player_state.weapon.id == item.id then
			data.equipped = false
			player_state.weapon = INVALID_ITEM_INDEX
		end
	end
	if slot == ItemSlot.Ring then
		for i = 1, 10, 1 do
			if player_state.rings[i].id == item.id then
				data.equipped = false
				player_state.rings[i] = INVALID_ITEM_INDEX
			end
		end
	end
	update_damage_and_speed(player_state)
end

---@param item ItemIndex
local function equip_item(item)
	local data = RETRIEVE_ITEM(item)
	if data == nil then
		return
	end
	if data.equipped then
		return
	end
	local slot = BaseItemTable[data.kind].slot
	if slot ==ItemSlot.Boots then
		local current_boots = RETRIEVE_ITEM(player_state.boots)
		if current_boots then
			current_boots.equipped = false
		end
		player_state.boots = item
		data.equipped = true
	end
	if slot ==ItemSlot.Weapon then
		local current_weapon = RETRIEVE_ITEM(player_state.weapon)
		if current_weapon then
			current_weapon.equipped = false
		end
		player_state.weapon = item
		data.equipped = true
	end
	if slot == ItemSlot.Ring then
		for i = 1, 10, 1 do
			local ring = RETRIEVE_ITEM (player_state.rings[i])
			if not ring then
				player_state.rings[i] = item
				data.equipped = true
				break
			end
		end
	end
	update_damage_and_speed(player_state)
end


---comment
---@param req InterfaceRequest
---@param x number
---@param y number
---@param item ItemIndex
---@param true_size boolean
---@param draw_border boolean
---@param draw_bg boolean
local function draw_item(req, x, y, item, true_size, draw_border, draw_bg)
	local item_data = RETRIEVE_ITEM(item)
	if not item_data then
		return
	end

	local scale_mult = scale
	local size_y = interface_grid * 6
	local size_x = interface_grid * 6
	local durability_offset = size_y - 7
	local durability_width = size_x
	local offset_x = 0
	local slot = BaseItemTable[item_data.kind].slot
	local border_width = interface_grid * 6
	local border_height = interface_grid * 6
	if true_size then
		if  slot ==ItemSlot.Ring then
			scale_mult = scale * 1 / 3
			size_y = interface_grid * 2
			size_x = interface_grid * 2
			---@type number
			durability_offset = interface_grid * 2
			durability_width = interface_grid * 2
			border_height = interface_grid * 2
			border_width = interface_grid *2
		elseif  slot ==ItemSlot.Weapon then
			size_y = interface_grid * 12
			durability_offset = size_y - 7
			border_height = interface_grid * 12
		end
	else
		if slot == ItemSlot.Boots then
		elseif slot ==ItemSlot.Weapon then
			size_x = size_x / 2
			size_y = size_y / 2
			scale_mult = scale / 2
			offset_x = size_x / 2
		end
	end

	if req.render and draw_bg then
		love.graphics.setColor(1, 1, 1)
		local affixes_count = calculate_affixes(item)
		if affixes_count == 0 then
			love.graphics.setColor(1, 1, 1)
		elseif affixes_count <= 2 then
			love.graphics.setColor(1, 1, 1.5)
		else
			love.graphics.setColor(1.6, 1.1, 1)
		end
		love.graphics.draw(inventory_slot_bg, x, y, 0, scale, scale)
	end


	if req.render and item.id == selected_item.id then
		border(req.render, x + 3, y + 3, border_width - 6, border_height - 6)
		love.graphics.setColor(1, 1, 1, SMOOTHERSTEP(item_data.highlight_opacity) + 0.40 + 0.10 * math.sin(timer * 5))
		love.graphics.draw(blob, x - 3, y - 3, 0, (border_width + 6) / blob_x, (border_height + 6) / blob_y)
	end

	if req.render then
		love.graphics.setColor(0.9, 0.9, 0, SMOOTHERSTEP(item_data.highlight_opacity) * 0.5)
		love.graphics.draw(blob, x - 3, y - 3, 0, (border_width + 6) / blob_x, (border_height + 6) / blob_y)
	end

	if req.render then
		if rect_detection(x, y, border_width, border_height, req.mx, req.my) then
			item_data.highlight_opacity = 0.5
		end
		local img = BaseItemTable[item_data.kind].image
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(img, x + offset_x, y, 0, scale_mult, scale_mult)
	else
		if rect_detection(x, y, border_width, border_height, req.mx, req.my) then
			print (req.mouse_button, req.presses)
			if req.mouse_button == MouseButton.Left  then
				if req.presses <= 1 then
					selected_item = item
				else
					equip_item(item)
				end
			end
			item_data.highlight_opacity = 0.75
		end
	end

	if req.render and draw_border then
		border(req.render, x, y, border_width, border_height)
	end


	if req.render then
		progress_bar(x, y + durability_offset, durability_width, 7, item_data.durability, item_data.durability, 1, 0, "blue")
	end
end

---@enum StatusTab
StatusTab = {
	Overview = 1,
	Skills = 2,
	Guilds = 3,
	Item = 4,
}

---@type StatusTab
local current_tab = StatusTab.Overview

---comment
---@param req InterfaceRequest
---@param x any
---@param y any
local function display_stats(req, x, y)
	panel(req.render, x, y, interface_grid * 34, interface_grid * 21 )
	if req.render then
		love.graphics.print("Max HP: " .. tostring(max_hp), x + 10, y + 10)
		love.graphics.print("Shield: " .. tostring(shield), x + 10, y + 30)
		love.graphics.print("Speed: " .. tostring(speed), x + 10, y + 50)
		love.graphics.print("Melee damage: " .. tostring(player_state.melee_damage), x + 10, y + 70)
		love.graphics.print("Spell damage: " .. tostring(player_state.spell_damage), x + 10, y + 90)
	end
end

---comment
---@param req InterfaceRequest
---@param x any
---@param y any
local function display_item_description(req, x, y)
	panel(req.render, x, y, interface_grid * 34, interface_grid * 21 )

	local selected = RETRIEVE_ITEM(selected_item)
	assert (selected)

	local kind = BaseItemTable[selected.kind]

	draw_item(req, x + interface_grid, y + interface_grid, selected_item, false, true, true)

	border(req.render, x + interface_grid * 8, y + interface_grid, interface_grid * 16, interface_grid * 6)
	-- border (req.render, x + interface_grid * (8 + 16 + 1), y + interface_grid, interface_grid * 8, interface_grid * 3)
	-- border (req.render, x + interface_grid * (8 + 16 + 1), y + interface_grid + interface_grid * 3, interface_grid * 8, interface_grid * 3)

	if req.render then
		love.graphics.setColor(0, 0, 0, 1)
		style.header_font()
		love.graphics.printf(kind.name, x + interface_grid * 8, y + interface_grid * 2, interface_grid * 16, "center")
		style.font(1)
	end

	if selected.equipped then
		if button(req.render, "Unequip", x + interface_grid * (8 + 16 + 1), y + interface_grid * (1), interface_grid * 8, interface_grid * 3, req.mx, req.my) then
			unequip_item(selected_item)
		end
	else
		if button(req.render, "Equip", x + interface_grid * (8 + 16 + 1), y + interface_grid * (1), interface_grid * 8, interface_grid * 3, req.mx, req.my) then
			equip_item(selected_item)
		end
	end

	if button(req.render, "Destroy", x + interface_grid * (8 + 16 + 1), y + interface_grid + interface_grid * 3, interface_grid * 8, interface_grid * 3, req.mx, req.my) then
		selected.durability = 0
	end
end

---@param req InterfaceRequest
---@param x number
---@param y number
local function information_window(req, x, y)
	local tabs_height = interface_grid * 6

	local spacing = interface_grid * 4
	local padding_left = interface_grid

	if button(req.render, "Status", padding_left + x, y, interface_grid * 8, interface_grid * 4, req.mx, req.my ) then
		current_tab = StatusTab.Overview
		selected_item = INVALID_ITEM_INDEX
	end
	if button(req.render, "Skills", padding_left + x + interface_grid * 8 + spacing, y, interface_grid * 8, interface_grid * 4, req.mx, req.my) then
		current_tab = StatusTab.Skills
		selected_item = INVALID_ITEM_INDEX
	end
	if button(req.render, "Guilds", padding_left + x + interface_grid * 16 + spacing * 2, y, interface_grid * 8, interface_grid * 4, req.mx, req.my) then
		current_tab = StatusTab.Guilds
		selected_item = INVALID_ITEM_INDEX
	end


	local selected = RETRIEVE_ITEM(selected_item)
	if selected then
		current_tab = StatusTab.Item
	else
		current_tab = StatusTab.Overview
	end

	if current_tab == StatusTab.Item then
		display_item_description(req, x, y + tabs_height)
	elseif current_tab == StatusTab.Overview then
		display_stats(req, x, y + tabs_height)
	elseif current_tab == StatusTab.Skills then

	elseif current_tab == StatusTab.Guilds then

	end
end

---@param req InterfaceRequest
local function right_side_panel(req)
	if req.render then
		love.graphics.setColor(0.1, 0.1, 0.1)
		love.graphics.rectangle("fill", window_width - right_panel_width, 0, right_panel_width, window_height)
		border(req.render, window_width - right_panel_width, 0, right_panel_width, window_height)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(equip_bg, window_width - right_panel_width + interface_grid, interface_grid, 0, scale, scale)
		border(req.render,  window_width - right_panel_width + interface_grid, interface_grid, right_panel_width_no_margins, equip_image_height)
		style.header_font()
		love.graphics.setColor(0, 0, 0)
		love.graphics.printf("Equipment", window_width - right_panel_width, interface_grid * 1.5, right_panel_width, "center")
		panel(
			req.render,
			window_width - right_panel_width + interface_grid,
			interface_grid + equip_image_height + interface_grid,
			right_panel_width_no_margins,
			stats_height,
			true
		)
		panel(
			req.render,
			window_width - right_panel_width + interface_grid,
			interface_grid + equip_image_height + interface_grid + stats_height + interface_grid,
			right_panel_width_no_margins,
			inventory_height,
			true
		)
	end

	draw_item(req, window_width - right_panel_width + interface_grid *2, interface_grid * 6, player_state.weapon, true, false, false)
	draw_item(req, window_width - interface_grid *8, interface_grid *19, player_state.boots, true, false, false)
	for i = 1, 10, 1 do
		local item_x  = window_width - right_panel_width + interface_grid + interface_grid * ring_xy[i][1]
		local item_y = interface_grid  + interface_grid * ring_xy[i][2]
		draw_item(req, item_x, item_y, player_state.rings[i], true, false, false)
	end

	information_window(req, window_width - right_panel_width + interface_grid * 2, interface_grid * 44)

	local row = 0
	local column = 0

	local x = window_width - right_panel_width + interface_grid + interface_grid
	local y = interface_grid + equip_image_height + interface_grid + stats_height + interface_grid + interface_grid

	for index, value in ipairs(player_state.stash) do
		local item = RETRIEVE_ITEM(value)
		if not item or item.equipped then
			goto continue
		end

		local item_x = x + column * interface_grid * 7
		local item_y = y + row * interface_grid * 7
		draw_item(req, item_x, item_y, value, false, true, false)

		column = column + 1
		if column >= 5 then
			column = 0
			row = row + 1
		end

		::continue::
	end
end

---comment
---@param req InterfaceRequest
---@param x any
---@param y any
local function change_difficulty(req, x, y)
	panel(req.render, x, y, 80, 80)
	if button(req.render, "+", x+5, y+5, 30, 30, req.mx, req.my, false) then
		difficulty = difficulty + 1
	end
	if button(req.render, "-", x+45, y+5, 30, 30, req.mx, req.my, false) then
		difficulty = math.max(1, difficulty - 1)
	end
	if req.render then
		love.graphics.print("Level: " .. tostring(difficulty), x + 5, y + 37)
	end
end

---comment
---@param req InterfaceRequest
local function  interface(req)
	character_widget(req, 10, 10)
	status_bar(req, 210, 10)
	battle_panel(req, 0, 160)
	change_difficulty(req, 110, 10)
	right_side_panel(req)
end

local function generate_enemies()
	stage.enemies = {}
	stage.projectiles = {}

	for i = 1, difficulty do
		---@type Enemy
		local starting_enemy = {
			hp = 3 + difficulty,
			view_hp = 3 + difficulty,
			max_hp = 3 + difficulty,
			model = big_rat,
			position = math.sqrt(love.math.random() + 0.5) * stage.distance,
			damage = difficulty,
			attack_progress = 0,
			is_attacking = false,
			being_hit = false,
			being_hit_animation_progress = 0,
			on_kill_triggered = false,
			death_progress = 0
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
	player_model.state =ActorModelStateEnum.Attacking
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

local function validate_items()
	---@type ItemIndex[]
	local items_to_remove = {}
	for index, value in ipairs(ITEM_DB.data_array) do
		if value.durability <= 0 and not value.invalid then
			---@type ItemIndex
			local to_remove = {
				id = index,
				generation = ITEM_DB.generation[index]
			}
			table.insert(items_to_remove, to_remove)
		end
	end

	-- clear all references to removed items:
	-- datacontainer-sama, save me...
	for index, value in ipairs(items_to_remove) do
		if player_state.boots.id == value then
			player_state.boots = INVALID_ITEM_INDEX
		end
		if player_state.weapon.id == value then
			player_state.weapon = INVALID_ITEM_INDEX
		end
		for ring_number = 1, 10, 1 do
			if player_state.rings[ring_number].id == value then
				player_state.rings[ring_number] = INVALID_ITEM_INDEX
			end
		end

		local in_stash = nil
		for stash_index, existing_value in ipairs(player_state.stash) do
			if existing_value.id == value then
				in_stash = stash_index
			end
		end

		if in_stash then
			table.remove(player_state.stash, in_stash)
		end

		if selected_item.id == value.id then
			selected_item = INVALID_ITEM_INDEX
		end

		DELETE_ITEM(value)
	end
end

---comment
---@param enemy Enemy
---@param skill SkillDefinition
---@return boolean
local function can_use_skill (enemy, skill)
	return enemy.position < player_model.position + skill.activation_range(player_state, basic_hero)
end

---comment
---@param item ItemIndex
---@param target Enemy
local function process_item_skills(item, target)

	if player_state.micro_cooldown_item_activation > 0 then
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
		if skill and can_use_skill (target, skills[skill]) then
			schedule_item_action(player_state, item)
			data.cooldown = ITEM_BASE_COOLDOWN
			player_state.micro_cooldown_item_activation = player_state.micro_cooldown_item_activation + MICROCOOLDOWN
			return true
		end
	end

	return false
end

local function schedule_skill_activations_from_items()
	if player_state.micro_cooldown_item_activation > 0 then
		return false
	end

	for index, target in ipairs(stage.enemies) do
		if target.hp <= 0 then
			goto continue
		end

		-- From rings
		for i = 1, 10, 1 do
			local ring_index = player_state.rings[i]
			if process_item_skills(ring_index, target) then
				return true
			end
		end

		::continue::
	end

	return false
end

---comment
---@param dt number
function love.update(dt)
	validate_items()

	timer = timer + dt

	for index, value in ipairs(ITEM_DB.data_array) do
		value.highlight_opacity = math.max(value.highlight_opacity - dt, 0)
	end

	local distance_from_camera = player_model.position - actual_camera

	local t = math.min(1, math.max(0, math.abs(distance_from_camera) / 50 - 1))
	if (not fade_in) then
		actual_camera = actual_camera + SMOOTHERSTEP(t) * dt * distance_from_camera * 2
	elseif hp > 0 then
		---@type number
		distance_from_camera = stage.distance - actual_camera
		actual_camera = actual_camera + SMOOTHERSTEP(t) * dt * distance_from_camera * 2
	end
	actual_camera = math.min(actual_camera, stage.distance - 600)

	if player_model.position >= stage.distance or hp <= 0 then
		reset_stage = true
		fade_in = true
		player_model.position = 0
		hp = max_hp
		shield = get_shield(player_state.weapon) + get_shield(player_state.boots)
		for i = 1, 10, 1 do
			shield = shield + get_shield(player_state.rings[i])
		end
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
			require "triggered.on-kill"(player_state, difficulty)
		end

		if value.hp <= 0 then
			value.death_progress = value.death_progress + dt
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
		elseif value.hp > 0 then
			value.attack_progress = 0
			value.is_attacking = false
			value.position = value.position - dt * enemy_speed
		end
	end


	player_model.state = ActorModelStateEnum.Idle

	player_state.micro_cooldown_item_activation = player_state.micro_cooldown_item_activation - dt

	if #player_state.items_queue == 0 then
		while schedule_skill_activations_from_items () do end
	end

	player_state.micro_cooldown_item_activation = math.max (0, player_state.micro_cooldown_item_activation)

	local action = player_state.current_action
	if action.kind == ActionEnum.Nothing then
		-- Can we do a basic attack?
		local action_chosen = false
		for index, value in ipairs(stage.enemies) do
			if value.hp <= 0 then
				goto continue
			end
			-- check all available skills
			-- Inherent:
			if value.position < player_model.position + skills[SkillEnum.MeleeAttack].activation_range(player_state, basic_hero) then
				switch_action(player_state, ActionEnum.ActivateSkill, SkillEnum.MeleeAttack, INVALID_ITEM_INDEX)
				action_chosen = true
				break
			end

			if action_chosen then
				break
			end

			::continue::
		end
		if not action_chosen then
			local move = dt * speed
			player_model.walk_timer = player_model.walk_timer + move
			player_model.state = ActorModelStateEnum.Walking
			for index, value in ipairs(stage.enemies) do
				local shift = value.position - player_model.position
				if shift - 5 <= move and value.hp > 0 then
					move = shift - 4
				end
			end
			player_model.position = player_model.position + move
		end
	elseif player_state.current_action.kind ==ActionEnum.ActivateSkill then
		local skill_index = action.used_skill
		assert(skill_index ~= nil)
		local skill = skills[skill_index]
		skill.update(vfx_manager, stage, player_state, dt, player_model, basic_hero, false, 1)
		if player_state.current_action.completed then
			reset_action(player_state)
		end
	end

	for index, value in ipairs(player_state.items_queue) do
		local item_index = value.used_item
		local item = RETRIEVE_ITEM(item_index)
		assert(item)
		item.durability = item.durability - 0.01
		item.cooldown = ITEM_BASE_COOLDOWN
		for index, value in ipairs(item.affixes) do
			local skill_index = AffixTable[value.affix_index].allows_skill
			if skill_index then
				local skill = skills[skill_index]
				skill.update(vfx_manager, stage, player_state, dt, player_model, basic_hero, true, value.amount)
			end
		end
	end
	player_state.items_queue = {}

	local decay = math.exp(-dt * 10)
	hp_view = hp_view * decay + hp * (1 - decay)

	for index, value in ipairs(stage.enemies) do
		value.view_hp = value.view_hp * decay + value.hp * (1 - decay)
	end


	for index, value in ipairs(ITEM_DB.data_array) do
		value.cooldown = math.max(value.cooldown - dt, 0)
	end
end

function love.draw()
	love.graphics.setBackgroundColor(0.75, 0.75, 0.75, 1)
	local x, y = love.mouse.getPosition()
	local button_pressed = MouseButton.None
	if love.mouse.isDown(1) then
		button_pressed = MouseButton.Left
	end
	interface({
		mouse_button = button_pressed,
		mx = x, my = y,
		presses = 0,
		render = true
	})
end

---@enum MouseButton
MouseButton = {
	Left = 1,
	Right = 2,
	Middle = 3,
	None = 4,
}

---comment
---@param x number
---@param y number
---@param mouse_button MouseButton
---@param istouch boolean
---@param presses number
function love.mousepressed(x, y, mouse_button, istouch, presses)
	interface({
		mouse_button = mouse_button,
		mx = x,
		my = y,
		presses = presses,
		render = false
	})
end