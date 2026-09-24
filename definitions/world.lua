---@type Faction[]
Factions = {}
---@type FactionState[]
FactionsState  ={}
---@type Location[]
Locations = {}
---@type table<number, number[]>
Roads = {}

StartingLocation = 1

---@param a number
---@param b number
local function register_road_one_side(a, b)
	if Roads[a] == nil then
		Roads[a] = {b}
	else
		table.insert(Roads[a], b)
	end
end

---@param a number
---@param b number
local function register_road(a, b)
	register_road_one_side(a, b)
	register_road_one_side(b, a)
end



local w = {}

---comment
---@param economy EconomyDefs
function w.load(economy)
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
			walk_timer_mult = 1 / 100,
			attack_timer_mult = 1 / 100,
		},
		base_damage = 1,
		attack_experience = 0.1,
		speed = 200,
		spell_experience = 0,
		loot_items = {economy.rat_body},
		loot_amount = {},
		loot_resources = {}
	}

	local baron_rat_image = love.graphics.newImage("assets/rat-baron/base.png")
	local baron_rat_image_x, baron_rat_image_y = baron_rat_image:getDimensions()
	---@type EnemyPrototype
	local rat_baron = {
		attack_skill = 0.1,
		hp_max = 50,
		melee_defense = 0.2,
		spell_defense = 0.1,
		model_description = {
			size_x = baron_rat_image_x,
			size_y = baron_rat_image_y,
			image = baron_rat_image,
			image_base_scale = 0.5,
			walk_frames = {love.graphics.newQuad(0, 0, baron_rat_image_x, baron_rat_image_y, baron_rat_image)},
			idle_frames = {love.graphics.newQuad(0, 0, baron_rat_image_x, baron_rat_image_y, baron_rat_image)},
			attack_frames = {love.graphics.newQuad(0, 0, baron_rat_image_x, baron_rat_image_y, baron_rat_image)},
			dead_frame = {love.graphics.newQuad(0, 0, baron_rat_image_x, baron_rat_image_y, baron_rat_image)},
			walk_timer_mult = 1,
			attack_timer_mult = 1,
		},
		base_damage = 1,
		attack_experience = 1,
		spell_experience = 1,
		speed = 100,
		loot_items = {economy.rat_body},
		loot_amount = {},
		loot_resources = {}
	}

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
				unit = rat_baron,
				weight = 1
			}
		}
	}

	local butcher = require "definitions.characters.blank"()
	butcher.coins = 10
	butcher.name = "Butcher"
	table.insert(butcher.target_recipes, economy.buther_rat)

	Locations[1] = {
		name = "Grimtide",
		x = 155,
		y = 187,
		display_radius = 3,
		background = love.graphics.newImage("assets/bg/ledge.png"),
		controlled_by = 1,
		basic_armies = 2,
		elite_armies = 0,
		local_characters = {
			butcher
		}
	}
	Locations[2] = {
		name = "Rat Hills",
		x = 176,
		y = 202,
		display_radius = 3,
		background = love.graphics.newImage("assets/bg/ledge.png"),
		controlled_by = 1,
		basic_armies = 2,
		elite_armies = 0,
		local_characters = {}
	}
	Locations[3] = {
		name = "Horn of Indifference",
		x = 153,
		y = 227,
		display_radius = 3,
		background = love.graphics.newImage("assets/bg/ledge.png"),
		controlled_by = 1,
		basic_armies = 2,
		elite_armies = 0,
		local_characters = {}
	}
	Locations[4] = {
		name = "Fangford",
		x = 178,
		y = 256,
		display_radius = 3,
		background = love.graphics.newImage("assets/bg/ledge.png"),
		controlled_by = 1,
		basic_armies = 2,
		elite_armies = 0,
		local_characters = {}
	}


	register_road(1, 2)
	register_road(2, 3)
	register_road(3, 4)

	-- TODO: better registration of roads

end

return w