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

local bg =love.graphics.newImage("bg-600-500.png")
local player_image = love.graphics.newImage("skeleton.png")
local blob = love.graphics.newImage("blob.png")

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

---@type Particle[]
local  particles = {}

for i = 1, 100 do
	---@type Particle
	local particle = {
		image = blood_ground_image,
		position = 0,
		size = 1,
		time_left = 0,
		max_time = 1
	}
	table.insert(particles, particle)
end

local function insert_particle(pos, size, image, time)
	for index, value in ipairs(particles) do
		if value.time_left <= 0 then
			value.image = image
			value.position = pos
			value.size = size
			value.time_left = time
			value.max_time = time
			return
		end
	end
end

local hero_battle = love.graphics.newImage("hero-battle.png")

---@type number
local timer = 0

local hp = 10
local hp_view = 10
local max_hp = 15
local shield = 20
local progress = 1
local speed = 0.2
local damage = 1

local difficulty = 1

local function display_stats(render, x, y)
	panel(render, x, y, 120, 100 )
	if render then
		love.graphics.print("Max HP: " .. tostring(max_hp), x + 10, y + 10)
		love.graphics.print("Shield: " .. tostring(shield), x + 10, y + 30)
		love.graphics.print("Speed: " .. tostring(speed), x + 10, y + 50)
		love.graphics.print("Damage: " .. tostring(damage), x + 10, y + 70)
	end
end

local weapon = nil
local boots = nil

local is_attacking = false
local attack_progress = 0
local attack_speed = 10

---@class Enemy
---@field hp number
---@field image love.Image
---@field position number
---@field damage number
---@field attack_progress number
---@field is_attacking boolean
---@field being_hit boolean
---@field being_hit_animation_progress number

---@type Enemy[]
local enemies = {}

local item_kinds = 2

---@enum ItemSlot
ItemSlot = {
	Boots = 1,
	Weapon = 2
}


---@class ItemKind
---@field name string
---@field image love.Image
---@field damage number
---@field speed_modifier number
---@field base_attack_speed number
---@field shield number
---@field slot ItemSlot

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
		shield = 0
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
		speed_modifier = speed_modifier,
		shield = base_shield
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

---@type Item[]
local items = {}

local function get_shield(item)
	if item == nil then
		return 0
	end

	---@type number
	local result = 0
	local w = items[item]
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
local function get_damage(item)
	if item == nil then
		return 0
	end

	---@type number
	local result = 0
	local w = items[item]
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
local function get_speed_mod(item)
	if item == nil then
		return 0
	end

	---@type number
	local result = 0
	local w = items[item]
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
local function update_damage_and_speed()
	damage = 1 + get_damage(weapon) + get_damage(boots)
	speed = 0.25 * (1 + get_speed_mod(weapon) + get_speed_mod(boots))
	attack_speed = 2
	if weapon then
		attack_speed = BaseItemTable[items[weapon].kind].base_attack_speed
	end
end

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

local function battle_panel(render, x, y)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(bg, x, y)

	do
		local frame = math.floor(timer * 5) % 5
		love.graphics.draw(portal_image, portal_quads[frame + 1], x + 20, y + 180, 0, 1, 1)
	end

	do
		local frame = (math.floor(timer * 5) + 1) % 5
		love.graphics.draw(portal_image, portal_quads[frame + 1], x + 520, y + 180, 0, 1, 1)
	end



	for index, value in ipairs(particles) do
		if value.time_left > 0 then
			love.graphics.setColor(1, 1, 1, value.time_left / value.max_time)
			love.graphics.draw(value.image, x + value.position * 500 + 40, y + 200, 0, value.size, value.size, 40, 40)
		end
	end

	for index, value in ipairs(enemies) do
		if value.hp > 0 then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(value.image, x + 40 + value.position * 500, y + 200)
		else
			-- love.graphics.setColor(1, 0, 0, 1)
			-- love.graphics.circle("fill", x + 60 + value.position * 500, y + 240, 10)
		end
	end

	love.graphics.setColor(1, 0, 0, 1)
	-- love.graphics.circle("line", x + 60 + progress * 500, y + 240, 10)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(hero_battle, x + 40 + progress * 500, y + 200)

	if is_attacking then
		local frame = math.floor(attack_progress * 4) % 4
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(hit_image, hit_quads[frame + 1], x + 40 + progress * 500, y + 200)
	end

	for index, value in ipairs(enemies) do
		if value.is_attacking then
			local frame = math.floor(value.attack_progress * 4) % 4
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(
				hit_image, hit_quads[frame + 1], x + 40 + value.position * 500 + 40, y + 200,
				0, -1, 1
			)
		end
	end

	border (render, x, y, 600, 500)
end

---comment
---@param render boolean
---@param x number
---@param y number
local function inventory(render, x, y, mx, my)
	panel (render, x, y, 320, 320)
--[[
	for index, value in ipairs(items) do
		local affixes_count = #value.prefixes + #value.suffixes

		if affixes_count == 0 then
			love.graphics.setColor(0, 0, 0)
		elseif affixes_count <= 2 then
			love.graphics.setColor(0, 0, 0.5)
		else
			love.graphics.setColor(0.6, 0.1, 0)
		end

		local name = ""
		for _, prefix in ipairs(value.prefixes) do
			name = name .. PrefixTable[prefix].name .. " "
		end
		name = name .. BaseItemTable[value.kind].name .. " "
		for _, suffix in ipairs(value.suffixes) do
			name = name .. SuffixTable[suffix].name .. " "
		end

		love.graphics.printf(name, x + 10, y + 10 + 20 * (index - 1), 280)

	end
--]]

	local row = 0
	local column = 0
	local grid_unit = 80

	for index, value in ipairs(items) do
		local item_x = x + column * grid_unit
		local item_y = y + row * grid_unit

		local affixes_count = #value.prefixes + #value.suffixes

		if affixes_count == 0 then
			love.graphics.setColor(0, 0, 0)
		elseif affixes_count <= 2 then
			love.graphics.setColor(0, 0, 0.5)
		else
			love.graphics.setColor(0.6, 0.1, 0)
		end
		love.graphics.draw(blob, item_x, item_y)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(BaseItemTable[value.kind].image, item_x, item_y)
		border(render, item_x, item_y, grid_unit, grid_unit)
		if weapon == index or boots == index then
			border(render, item_x + 5, item_y + 5, grid_unit - 10, grid_unit - 10)
		end

		if button(render, "E", item_x, item_y, 30, 30, mx, my, false) then
			if BaseItemTable[value.kind].slot ==ItemSlot.Boots then
				boots = index
			end
			if BaseItemTable[value.kind].slot ==ItemSlot.Weapon then
				weapon = index
			end
			update_damage_and_speed()
		end

		column = column + 1
		if column * grid_unit >= 320 then
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
	battle_panel(render, 10, 160)
	inventory(render, 630, 10, mx, my)
	display_stats(render, 630, 400)
	change_difficulty(render, 110, 10, mx, my)
end

local function generate_enemies()
	enemies = {}

	for i = 1, difficulty do
		---@type Enemy
		local starting_enemy = {
			hp = 3 + difficulty,
			image = hero_battle,
			position = math.sqrt(love.math.random()),
			damage = difficulty,
			attack_progress = 0,
			is_attacking = false,
			being_hit = false,
			being_hit_animation_progress = 0
		}
		table.insert(enemies, starting_enemy)
	end
end

---comment
---@param rarity number
local function generate_loot(rarity)
	---@type Item
	local item = {
		kind = math.floor(#BaseItemTable *love.math.random()) + 1,
		suffixes = {},
		prefixes = {}
	}

	local mods = rarity

	for i = 1, rarity do
		---@type number[]
		local candidates = {}
		local is_suffix = love.math.random() > 0.5
		local total_weight = 0

		if is_suffix then
			for index, value in ipairs(SuffixTable) do
				table.insert(candidates, index)
				total_weight = total_weight + 1 / value.rarity
			end
			local candidates_count = #candidates
			if candidates_count == 0 then
				goto continue
			end
			local dice = love.math.random() * total_weight
			local acc = 0
			for index, value in ipairs(candidates) do
				local affix = SuffixTable[value]
				acc = acc + 1 / affix.rarity
				if acc >= dice then
					table.insert(item.suffixes, value)
					goto continue
				end
			end
		else
			for index, value in ipairs(PrefixTable) do
				table.insert(candidates, index)
				total_weight = total_weight + 1 / value.rarity
			end
			local candidates_count = #candidates
			if candidates_count == 0 then
				goto continue
			end
			local dice = love.math.random() * total_weight
			local acc = 0
			for index, value in ipairs(candidates) do
				local affix = PrefixTable[value]
				acc = acc + 1 / affix.rarity
				if acc >= dice then
					table.insert(item.prefixes, value)
					goto continue
				end
			end
		end
		::continue::
	end

	return item
end

function love.load()
	love.window.setTitle("Endless Ledge")
	generate_enemies()
end


function love.update(dt)


	if progress >= 1 then
		progress = 0
		hp = max_hp
		shield = get_shield(weapon) + get_shield(boots)
		update_damage_and_speed()
		generate_enemies()
	end

	timer = timer + dt

	for index, value in ipairs(enemies) do
		if value.position < progress + 0.05 and value.hp > 0 then
			is_attacking = true
			break
		else
			is_attacking = false
		end
	end

	for index, value in ipairs(particles) do
		value.time_left = value.time_left - dt
	end

	for index, value in ipairs(enemies) do
		if value.being_hit and value.being_hit_animation_progress < 1 then
			value.being_hit_animation_progress = value.being_hit_animation_progress + dt
		end
		if value.position < progress + 0.05 and value.hp > 0 then
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
					progress = 1
				end
				value.attack_progress = 0
			end
		else
			value.attack_progress = 0
			value.is_attacking = false
		end
	end


	if is_attacking then
		attack_progress = attack_progress + dt * attack_speed
		if attack_progress >= 1 then
			for index, value in ipairs(enemies) do
				if value.position < progress + 0.05 and value.hp > 0 then
					value.hp = value.hp - damage
					if value.hp <= 0 and love.math.random() < 0.2 and #items < 16 then
						local item = generate_loot(love.math.random() * 4 * difficulty)
						table.insert(items, item)
					end
					value.being_hit = true
					value.being_hit_animation_progress = 0
					value.position = math.min(1, value.position + 0.01)

					insert_particle(value.position + 0.1 * (love.math.random() - 0.5), 1 + love.math.random(), blood_ground_image, 4)

					insert_particle(value.position + 0.1 * (love.math.random() - 0.5), 0.25 + love.math.random(), blood_hit_image, 0.25)
				end
			end
			attack_progress = 0
		end
	else
		local move = dt * speed
		for index, value in ipairs(enemies) do
			local shift = value.position - progress
			if shift - 0.05 <= move and value.hp > 0 then
				move = shift - 0.04
			end
		end
		progress = progress + move
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