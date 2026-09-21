require "skills._manager"
require "custom-math"
require "types"
require "defines"
require "definitions.items"
require "definitions.affixes"

local update_player_values = require "effect.player-update"
local style = require "ui._style"
local button = require "ui.button"
local circle_detection = require "ui.circle"
local panel = require "ui.panel"
local progress_bar = require "ui.progress-bar"
local border = require "ui.border"
local rect_detection = require "ui.rect"
local values = require "values.common"
local reset_player = require "effect.player-reset"

local battle_scene = require "scenes.battle"

---@enum SceneEnum
SceneEnum = {
	MainMenu = 1,
	Map = 2,
	Battle = 3
}
---@type SceneEnum
local scene = SceneEnum.MainMenu

local blob = love.graphics.newImage("blob.png")
local blob_x, blob_y = blob:getDimensions()
local inventory_slot_bg = love.graphics.newImage("inventory_slot.png")
local blood_ground_image = love.graphics.newImage("blood-ground.png")

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

function RESET_ITEMS()
	ITEM_DB.available_id = 1
	ITEM_DB.data_array = {}
	ITEM_DB.generation = {1}
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
---@type EnemyPrototype
local large_rat = {
	attack_skill = 0.01,
	hp_max = 5,
	melee_defense = 0.01,
	spell_defense = 0,
	model_description = {
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
	},
	base_damage = 1
}

---@type Faction[]
Factions = {}

Factions[1] = {
	name = "Duchy of Ledgeroad",
	basic_composition = {
		{
			unit = large_rat,
			weight = 1
		}
	},
	elite_composition = {
		{
			unit = large_rat,
			weight = 1
		}
	}
}

---@type Location[]
Locations = {}

---@type table<number, number[]>
Roads = {}

Locations[1] = {
	name = "Grimtide",
	x = 155,
	y = 187,
	display_radius = 3,
	background = love.graphics.newImage("bg-1200-500.png"),
	controlled_by = 1,
	basic_armies = 10,
	elite_armies = 0
}
Locations[2] = {
	name = "Rat Hills",
	x = 176,
	y = 202,
	display_radius = 3,
	background = love.graphics.newImage("bg-1200-500.png"),
	controlled_by = 1,
	basic_armies = 10,
	elite_armies = 0
}

-- TODO: better registration of roads
Roads[1] = {2}
Roads[2] = {1}

StartingLocation = 1

---@type number[]
local location_highlights = {}

---@type LocationState[]
LocationData = {}


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
		melee_defense = 0,
		general_magic = 0,
	},
	mental = {
		learning_speed = 0.01
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
	item_skills_queue = {},
	in_battle = false,
	model_description = basic_hero,
	model =  {
		position = 0,
		walk_timer = 0,
		state = ActorModelStateEnum.Idle,
		death_timer = 0,
	},
	hp = 0,
	hp_max = 15,
	hp_view = 0,
	shield = 0,
	speed = 1,
}

---@type Stage
local stage = {
	distance = 1000,
	enemies = {},
	projectiles = {},
	is_elite = false,
}

local right_panel_width = 38 * INTERFACE_GRID
local right_panel_width_no_margins = 36 * INTERFACE_GRID
local equip_image_height = 41 * INTERFACE_GRID
local stats_height = 29 * INTERFACE_GRID
local inventory_height = 23 * INTERFACE_GRID

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
	update_player_values(player_state)
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
	update_player_values(player_state)
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

	local scale_mult = UI_SCALE
	local size_y = INTERFACE_GRID * 6
	local size_x = INTERFACE_GRID * 6
	local durability_offset = size_y - 7
	local durability_width = size_x
	local offset_x = 0
	local slot = BaseItemTable[item_data.kind].slot
	local border_width = INTERFACE_GRID * 6
	local border_height = INTERFACE_GRID * 6
	if true_size then
		if  slot ==ItemSlot.Ring then
			scale_mult = UI_SCALE * 1 / 3
			size_y = INTERFACE_GRID * 2
			size_x = INTERFACE_GRID * 2
			---@type number
			durability_offset = INTERFACE_GRID * 2
			durability_width = INTERFACE_GRID * 2
			border_height = INTERFACE_GRID * 2
			border_width = INTERFACE_GRID *2
		elseif  slot ==ItemSlot.Weapon then
			size_y = INTERFACE_GRID * 12
			durability_offset = size_y - 7
			border_height = INTERFACE_GRID * 12
		end
	else
		if slot == ItemSlot.Boots then
		elseif slot ==ItemSlot.Weapon then
			size_x = size_x / 2
			size_y = size_y / 2
			scale_mult = UI_SCALE / 2
			offset_x = size_x / 2
		end
	end

	if req.render and draw_bg then
		love.graphics.setColor(1, 1, 1)
		local affixes_count = values.calculate_affixes(item)
		if affixes_count == 0 then
			love.graphics.setColor(1, 1, 1)
		elseif affixes_count <= 2 then
			love.graphics.setColor(1, 1, 1.5)
		else
			love.graphics.setColor(1.6, 1.1, 1)
		end
		love.graphics.draw(inventory_slot_bg, x, y, 0, UI_SCALE, UI_SCALE)
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
	panel(req.render, x, y, INTERFACE_GRID * 34, INTERFACE_GRID * 21 )
	if req.render then
		style.dense_information_font()
		love.graphics.print("Max HP: " .. tostring(player_state.hp_max), x + INTERFACE_GRID, y + INTERFACE_GRID)
		love.graphics.print("Shield: " .. tostring(player_state.shield), x + INTERFACE_GRID, y + INTERFACE_GRID * 3)
		love.graphics.print("Speed: " .. tostring(player_state.speed), x + INTERFACE_GRID, y + INTERFACE_GRID * 5)
		love.graphics.print("Melee damage: " .. tostring(player_state.melee_damage), x + INTERFACE_GRID, y + INTERFACE_GRID * 7)
		love.graphics.print("Spell damage: " .. tostring(player_state.spell_damage), x + INTERFACE_GRID, y + INTERFACE_GRID * 9)
	end
end

local function progress_bar_detailed(x, y, name, value_bar, value_true)
	love.graphics.print(name, x, y)
	progress_bar(x + INTERFACE_GRID * 10, y, INTERFACE_GRID * 15, INTERFACE_GRID * 2, value_bar, value_bar, 1, 0, "yellow")
	love.graphics.printf(value_true, x + INTERFACE_GRID * 25, y, INTERFACE_GRID * 7, "right"  )
end



---comment
---@param req InterfaceRequest
---@param x number
---@param y number
local function display_skill(req, x, y)
	panel(req.render, x, y, INTERFACE_GRID * 34, INTERFACE_GRID * 21 )
	if req.render then
		style.dense_information_font()
		progress_bar_detailed(x + INTERFACE_GRID, y + INTERFACE_GRID, "Melee", MASTERY_TO_SKILL(player_state.mastery.melee_weapon), string.format("%.2f%%", MASTERY_TO_SKILL(player_state.mastery.melee_weapon) * 100) )
		progress_bar_detailed(x + INTERFACE_GRID, y + INTERFACE_GRID * 3, "Melee Def.", MASTERY_TO_SKILL(player_state.mastery.melee_defense), string.format("%.2f%%", MASTERY_TO_SKILL(player_state.mastery.melee_defense) * 100) )
		progress_bar_detailed(x + INTERFACE_GRID, y + INTERFACE_GRID * 5, "Magic", MASTERY_TO_SKILL(player_state.mastery.general_magic), string.format("%.2f%%", MASTERY_TO_SKILL(player_state.mastery.general_magic) * 100) )
	end
end

---comment
---@param req InterfaceRequest
---@param x any
---@param y any
local function display_item_description(req, x, y)
	panel(req.render, x, y, INTERFACE_GRID * 34, INTERFACE_GRID * 21 )

	local selected = RETRIEVE_ITEM(selected_item)
	assert (selected)

	local kind = BaseItemTable[selected.kind]

	draw_item(req, x + INTERFACE_GRID, y + INTERFACE_GRID, selected_item, false, true, true)

	-- border(req.render, x + INTERFACE_GRID, y + INTERFACE_GRID * 8, INTERFACE_GRID * 32, INTERFACE_GRID * 6)
	-- border(req.render, x + INTERFACE_GRID, y + INTERFACE_GRID * 14, INTERFACE_GRID * 32, INTERFACE_GRID * 6)


	if req.render then
		love.graphics.setColor(0, 0, 0, 1)
		-- style.font(1)
		local name = ""

		for index, value in ipairs(selected.affixes) do
			local data = AffixTable[value.affix_index]
			if data.is_prefix then
				name = name .. data.name .. " (" .. tostring(value.amount) .. ") "
			end
		end

		name = name .. kind.name .. " "

		for index, value in ipairs(selected.affixes) do
			local data = AffixTable[value.affix_index]
			if not data.is_prefix then
				name = name .. data.name .. " (" .. tostring(value.amount) .. ") "
			end
		end

		style.dense_information_font()
		love.graphics.printf(name, x + INTERFACE_GRID, y + INTERFACE_GRID * 14, INTERFACE_GRID * 32, "center")

		love.graphics.print("Shield: ", x + INTERFACE_GRID, y + INTERFACE_GRID * 8)
		love.graphics.printf(values.get_shield(selected_item), x + INTERFACE_GRID, y + INTERFACE_GRID * 8, INTERFACE_GRID * 14, "right")
		love.graphics.print("Speed: ", x + INTERFACE_GRID, y + INTERFACE_GRID * 10)
		love.graphics.printf(values.get_speed_mod(selected_item), x + INTERFACE_GRID, y + INTERFACE_GRID * 10, INTERFACE_GRID * 14, "right")
		love.graphics.print("MDMG: ", x + INTERFACE_GRID * 18, y + INTERFACE_GRID * 8)
		love.graphics.printf(values.get_melee_damage(selected_item), x + INTERFACE_GRID * 18, y + INTERFACE_GRID * 8, INTERFACE_GRID * 14, "right")
		love.graphics.print("SDMG: ", x + INTERFACE_GRID * 18, y + INTERFACE_GRID * 10)
		love.graphics.printf(values.get_magic_damage(selected_item), x + INTERFACE_GRID * 18, y + INTERFACE_GRID * 10, INTERFACE_GRID * 14, "right")
	end

	if selected.equipped then
		if button(req.render, "Unequip", x + INTERFACE_GRID * (8 ), y + INTERFACE_GRID * (1), INTERFACE_GRID * 10, INTERFACE_GRID * 3, req.mx, req.my) then
			unequip_item(selected_item)
		end
	else
		if button(req.render, "Equip", x + INTERFACE_GRID * (8), y + INTERFACE_GRID * (1), INTERFACE_GRID * 10, INTERFACE_GRID * 3, req.mx, req.my) then
			equip_item(selected_item)
		end
	end

	if button(req.render, "Destroy", x + INTERFACE_GRID * (8), y + INTERFACE_GRID + INTERFACE_GRID * 3, INTERFACE_GRID * 10, INTERFACE_GRID * 3, req.mx, req.my) then
		selected.durability = 0
	end
end

---@param req InterfaceRequest
---@param x number
---@param y number
local function information_window(req, x, y)
	local tabs_height = INTERFACE_GRID * 6

	local spacing = INTERFACE_GRID * 4
	local padding_left = INTERFACE_GRID

	if button(req.render, "Status", padding_left + x, y, INTERFACE_GRID * 8, INTERFACE_GRID * 4, req.mx, req.my ) then
		current_tab = StatusTab.Overview
		selected_item = INVALID_ITEM_INDEX
	end
	if button(req.render, "Skills", padding_left + x + INTERFACE_GRID * 8 + spacing, y, INTERFACE_GRID * 8, INTERFACE_GRID * 4, req.mx, req.my) then
		current_tab = StatusTab.Skills
		selected_item = INVALID_ITEM_INDEX
	end
	if button(req.render, "Guilds", padding_left + x + INTERFACE_GRID * 16 + spacing * 2, y, INTERFACE_GRID * 8, INTERFACE_GRID * 4, req.mx, req.my) then
		current_tab = StatusTab.Guilds
		selected_item = INVALID_ITEM_INDEX
	end


	local selected = RETRIEVE_ITEM(selected_item)
	if selected then
		current_tab = StatusTab.Item
	elseif current_tab == StatusTab.Item then
		current_tab = StatusTab.Overview
	end

	if current_tab == StatusTab.Item then
		display_item_description(req, x, y + tabs_height)
	elseif current_tab == StatusTab.Overview then
		display_stats(req, x, y + tabs_height)
	elseif current_tab == StatusTab.Skills then
		display_skill(req, x, y + tabs_height)
	elseif current_tab == StatusTab.Guilds then

	end
end

---@param req InterfaceRequest
local function right_side_panel(req)
	if req.render then
		love.graphics.setColor(0.1, 0.15, 0.1)
		love.graphics.rectangle("fill", WINDOWS_WIDTH - right_panel_width, 0, right_panel_width, WINDOWS_HEIGHT)
		border(req.render, WINDOWS_WIDTH - right_panel_width, 0, right_panel_width, WINDOWS_HEIGHT)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(equip_bg, WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID, INTERFACE_GRID, 0, UI_SCALE, UI_SCALE)
		border(req.render,  WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID, INTERFACE_GRID, right_panel_width_no_margins, equip_image_height)
		style.header_font()
		love.graphics.setColor(0, 0, 0)
		love.graphics.printf("Equipment", WINDOWS_WIDTH - right_panel_width, INTERFACE_GRID * 1.5, right_panel_width, "center")
		panel(
			req.render,
			WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID,
			INTERFACE_GRID + equip_image_height + INTERFACE_GRID,
			right_panel_width_no_margins,
			stats_height,
			true
		)
		panel(
			req.render,
			WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID,
			INTERFACE_GRID + equip_image_height + INTERFACE_GRID + stats_height + INTERFACE_GRID,
			right_panel_width_no_margins,
			inventory_height,
			true
		)
	end

	draw_item(req, WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID *2, INTERFACE_GRID * 6, player_state.weapon, true, false, false)
	draw_item(req, WINDOWS_WIDTH - INTERFACE_GRID *8, INTERFACE_GRID *19, player_state.boots, true, false, false)
	for i = 1, 10, 1 do
		local item_x  = WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID + INTERFACE_GRID * ring_xy[i][1]
		local item_y = INTERFACE_GRID  + INTERFACE_GRID * ring_xy[i][2]
		draw_item(req, item_x, item_y, player_state.rings[i], true, false, false)
	end

	information_window(req, WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID * 2, INTERFACE_GRID * 44)

	local row = 0
	local column = 0

	local x = WINDOWS_WIDTH - right_panel_width + INTERFACE_GRID + INTERFACE_GRID
	local y = INTERFACE_GRID + equip_image_height + INTERFACE_GRID + stats_height + INTERFACE_GRID + INTERFACE_GRID

	for index, value in ipairs(player_state.stash) do
		local item = RETRIEVE_ITEM(value)
		if not item or item.equipped then
			goto continue
		end

		local item_x = x + column * INTERFACE_GRID * 7
		local item_y = y + row * INTERFACE_GRID * 7
		draw_item(req, item_x, item_y, value, false, true, false)

		column = column + 1
		if column >= 5 then
			column = 0
			row = row + 1
		end

		::continue::
	end
end

local map_image = love.graphics.newImage("map.png")
local map_view_quad = love.graphics.newQuad(0, 0, INTERFACE_GRID * 88, INTERFACE_GRID * 71, map_image)
local map_view_origin_x = 0
local map_view_origin_y = 0

local fade_in = false
local fade_out = false
local fade_progress = 0
local transition_to_scene = SceneEnum.Battle

---comment
---@param next_scene SceneEnum
local function start_transition(next_scene)
	fade_progress = 1
	fade_in = true
	transition_to_scene = next_scene
end

---@param req InterfaceRequest
---@param x number
---@param y number
local function map(req, x, y)
	if req.render then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(map_image, map_view_quad, INTERFACE_GRID, INTERFACE_GRID)

		do
			love.graphics.setColor(2, 1, 0.5, 0.4 + math.sin(timer * 3) * 0.2)
			local value = Locations[player_state.location]
			local loc_x = x + value.x - map_view_origin_x
			local loc_y = y + value.y - map_view_origin_y
			love.graphics.draw(blob, loc_x - blob_x / 2 / 5, loc_y - blob_y / 2 / 5, 0, 1 / 5, 1 / 5)
		end

		for index, value in ipairs(Locations) do
			local loc_x = x + value.x - map_view_origin_x
			local loc_y = y + value.y - map_view_origin_y
			love.graphics.setColor(1, 1, 1)
			love.graphics.circle("fill", loc_x, loc_y, value.display_radius)
			love.graphics.setColor(1, 1, 1, location_highlights[index])
			love.graphics.draw(blob, loc_x - blob_x / 2 / 5, loc_y - blob_y / 2 / 5, 0, 1 / 5, 1 / 5)
		end
	else
		for index, value in ipairs(Locations) do
			if circle_detection(x + value.x - map_view_origin_x, value.display_radius * 2, y + value.y - map_view_origin_y, req.mx, req.my) then

			end
		end
	end
end

---@param req InterfaceRequest
---@param x number
---@param y number
local function map_control(req, x, y)
	panel(req.render, x + INTERFACE_GRID, y + INTERFACE_GRID, INTERFACE_GRID * 25, INTERFACE_GRID * 21)
	local loc_id = player_state.location
	assert(loc_id)
	local cur = Locations[loc_id]
	local cur_data = LocationData[loc_id]
	local controller = Factions[cur.controlled_by]
	local controller_name = "None"
	if controller then
		controller_name = controller.name
	end
	local can_move = true
	local can_move_description = "I can move freely from this location."
	if cur_data.basic_armies > 0 or cur_data.elite_armies > 0 then
		can_move = false
		can_move_description = string.format("%d waves of hostile creatures block my way.", cur_data.basic_armies + cur_data.elite_armies)
	end
	if req.render then
		local description = string.format("Location: %s.\nControlled by: %s.\n%s", cur.name, controller_name, can_move_description)
		style.dense_information_font()
		love.graphics.printf(description, x + INTERFACE_GRID * 2, y + INTERFACE_GRID * 2, INTERFACE_GRID * 23, "center")
	end

	if can_move then
		local button_x = x + INTERFACE_GRID * (25 + 1)
		local button_y = y + INTERFACE_GRID
		for index, value in ipairs(Roads[loc_id]) do
			local next_destination = Locations[value]
			if button(req.render, next_destination.name, button_x, button_y, INTERFACE_GRID * 20, INTERFACE_GRID *3, req.mx, req.my) then
				-- TODO: non-instant movement
				player_state.location = value
			end
			button_y = button_y + INTERFACE_GRID * 3
		end
	else
		-- panel(req.render, x + INTERFACE_GRID * (25 + 1), y + INTERFACE_GRID, INTERFACE_GRID * 20, INTERFACE_GRID * 21)
		if button(req.render, "Clean up the location", x + INTERFACE_GRID * (25 + 1), y + INTERFACE_GRID, INTERFACE_GRID * 20, INTERFACE_GRID * 21, req.mx, req.my) then
			battle_scene.generate_enemies(stage, player_state.location)
			player_state.model.position = 0
			start_transition(SceneEnum.Battle)
		end
	end
end

---comment
---@param req InterfaceRequest
local function  interface(req)
	-- character_widget(req, 10, 10)
	-- status_bar(req, 210, 10)
	-- battle_panel(req, 0, 160)
	-- change_difficulty(req, 110, 10)

	-- 90 x 97 left side
	love.graphics.setColor(0.1, 0.15, 0.1)
	love.graphics.rectangle("fill", 0, 0, INTERFACE_GRID * 90, INTERFACE_GRID * 97)
	border(req.render, 0, 0, INTERFACE_GRID * 90, INTERFACE_GRID * 97)


	if scene == SceneEnum.MainMenu then
		panel(req.render, INTERFACE_GRID, INTERFACE_GRID, INTERFACE_GRID * 88, INTERFACE_GRID * 71, true)

		if button(req.render, "Start new game", INTERFACE_GRID * 2, INTERFACE_GRID * 2, INTERFACE_GRID * 20, INTERFACE_GRID * 4, req.mx, req.my) then
			reset_player(player_state, basic_hero)
			assert(player_state.location)
			start_transition(SceneEnum.Map)
		end
	elseif  scene ==SceneEnum.Map then
		map(req, INTERFACE_GRID, INTERFACE_GRID)
		border(req.render, INTERFACE_GRID, INTERFACE_GRID, INTERFACE_GRID * 88, INTERFACE_GRID * 71)
	elseif  scene ==SceneEnum.Battle then
		battle_scene.top(req, INTERFACE_GRID, INTERFACE_GRID, player_state, vfx_manager, stage)
		border(req.render, INTERFACE_GRID, INTERFACE_GRID, INTERFACE_GRID * 88, INTERFACE_GRID * 71)
	end

	panel(req.render, INTERFACE_GRID, INTERFACE_GRID * 73, INTERFACE_GRID * 88, INTERFACE_GRID * 23, true)

	if scene ==SceneEnum.Map then
		map_control(req, INTERFACE_GRID, INTERFACE_GRID * 73)
	end

	love.graphics.setColor(0, 0, 0, fade_progress)
	love.graphics.rectangle("fill", INTERFACE_GRID, INTERFACE_GRID, INTERFACE_GRID * 88, INTERFACE_GRID * 71)

	right_side_panel(req)
end

function love.load()
	love.window.setTitle("Endless Ledge")

	for index, value in ipairs(Locations) do
		location_highlights[index] = 0
		LocationData[index] = {
			basic_armies = value.basic_armies,
			controlled_by = value.controlled_by,
			elite_armies = value.elite_armies
		}
		value.background:setWrap("repeat")
	end

	RESET_ITEMS()
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
---@param dt number
function love.update(dt)
	validate_items()
	timer = timer + dt
	for index, value in ipairs(ITEM_DB.data_array) do
		value.highlight_opacity = math.max(value.highlight_opacity - dt, 0)
	end
	for index, value in ipairs(vfx_manager.particles) do
		value.time_left = value.time_left - dt
	end
	local decay = math.exp(-dt * 10)
	player_state.hp_view = player_state.hp_view * decay + player_state.hp * (1 - decay)
	for index, value in ipairs(stage.enemies) do
		value.view_hp = value.view_hp * decay + value.hp * (1 - decay)
	end
	for index, value in ipairs(ITEM_DB.data_array) do
		value.cooldown = math.max(value.cooldown - dt, 0)
	end


	if fade_in then
		fade_progress = fade_progress + dt
		if fade_progress >= 1 then
			fade_out = true
			fade_in = false
			scene = transition_to_scene
			if scene == SceneEnum.MainMenu and player_state.hp <= 0 then
				reset_player(player_state, basic_hero)
			end
		end
	end

	if fade_out then
		fade_progress = fade_progress - dt
		if fade_progress <= 0 then
			fade_progress = 0
			fade_out = false
		end
	end


	if scene == SceneEnum.MainMenu then
	elseif  scene ==SceneEnum.Map then
	elseif  scene ==SceneEnum.Battle then
		local completed = battle_scene.update(dt, vfx_manager, player_state, stage)
		local loc = LocationData[player_state.location]

		if completed and player_state.hp > 0 then
			scene = SceneEnum.Map
			if stage.is_elite then
				loc.elite_armies = loc.elite_armies - 1
			else
				loc.basic_armies = loc.basic_armies - 1
			end
		elseif completed and player_state.hp <= 0 then
			start_transition(SceneEnum.MainMenu)
			-- reset_player(player_state, basic_hero)
			love.load()
		end
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