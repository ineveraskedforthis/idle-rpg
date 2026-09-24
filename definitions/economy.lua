
---@type Resource[]
Resources = {}
---comment
---@param def Resource
---@return ResourceIndex
local function create_resource(def)
	local next_position = #Resources
	table.insert(Resources, def)
	return {
		value = next_position + 1
	}
end
---@type Recipe[]
Recipes = {}
---comment
---@param def Recipe
---@return RecipeIndex
local function create_recipe(def)
	local next_position = #Recipes
	table.insert(Recipes, def)
	return {
		value = next_position + 1
	}
end

---@type ItemKind[]
local BaseItemTable = {}

---comment
---@param def ItemKind
---@return ItemKindIndex
local function register_item(def)
	local next_position = #BaseItemTable
	table.insert(BaseItemTable, def)
	return {
		value = next_position + 1
	}
end

---comment
---@param id ItemKindIndex
---@return ItemKind
function  GET_ITEM_KIND(id)
	return BaseItemTable[id.value]
end

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
		image_kind = ItemImageSize.Large,
		defense = 0
	}
	return register_item(item)
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
		image_kind = ItemImageSize.Medium,
		defense = 0
	}
	return register_item(item)
end
local function register_body_armor(name, image, speed_modifier, base_shield, base_defense)
	---@type ItemKind
	local item = {
		name = name,
		image = image,
		damage = 0,
		base_attack_speed = 0,
		slot = ItemSlot.Body,
		range = 0,
		defense = base_defense,
		speed_modifier = speed_modifier,
		shield = base_shield,
		image_kind = ItemImageSize.Large,
	}
	return register_item(item)
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
		image_kind = ItemImageSize.Small,
		defense = 0
	}
	return register_item(item)
end

---@class EconomyDefs
---@field rat_body ItemKindIndex
---@field rat_armor ItemKindIndex
---@field buther_rat RecipeIndex
---@field make_rat_armor RecipeIndex
local economy_table = {}

economy_table.rat_body = {
	value = 0
}


function economy_table.load_economy()
	Resources = {}
	BaseItemTable = {}

	local RatSkin = create_resource({
		name = "Rat skin"
	})
	local RatFang = create_resource({
		name = "Rat fang"
	})
	local RatBones = create_resource({
		name = "Rat bones"
	})
	local RatMeat = create_resource({
		name = "Rat meat",
		restore_hp = 1
	})
	local RatSteak = create_resource({
		name = "Rat steak",
		restore_hp = 5
	})
	local OrbMagus = create_resource({
		name = "Orb of Magus",
		restore_shield = 100
	})

	local Boots = register_boots("Boots (Rat)", love.graphics.newImage("boots.png"), 1.1, 5)
	local Knife = register_weapon("Knife (Steel)", love.graphics.newImage("assets/items/knife.png"), 4, 2.25, 0)
	local RatFangWeapon = register_weapon("Fang (Rat)", love.graphics.newImage("assets/items/fang-rat.png"), 2, 2.25, 0)
	local RatBonesArmor = register_body_armor("Armor (Rat)", love.graphics.newImage("assets/items/armor-rat.png"), 0.75, 0, 1)
	local Ring = register_ring("Ring", love.graphics.newImage("ring.png"), 5)
	local RatBody = register_item {
		base_attack_speed = 0,
		damage = 0,
		image = love.graphics.newImage("assets/items/rat.png"),
		image_kind = ItemImageSize.Medium,
		name = "Rat body",
		range = 0,
		shield = 0,
		slot =ItemSlot.None,
		speed_modifier = 0,
		defense = 0
	}

	create_recipe ({
		name = "Cook rat meat",
		inputs = {RatMeat},
		inputs_amount = {1},
		outputs = {RatSteak},
		outputs_amount = {1},
		skill_required = {
			general_magic = 0,
			cooking = 0,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 0
		},
		skill_improvement = {
			general_magic = 0,
			cooking = 1,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 0
		},
		required_weapon = nil,
		inputs_items = {},
		outputs_items = {},
		required_weapon_durability_loss = 0
	})

	local butcher = create_recipe ({
		name = "Butcher rat",
		inputs = {},
		inputs_amount = {},
		inputs_items = {RatBody},
		outputs = {RatMeat, RatSkin, RatFang, RatBones},
		outputs_amount = {2, 1, 2, 2},
		outputs_items = {},
		required_weapon = Knife,
		required_weapon_durability_loss = 0.01,
		skill_improvement = {
			cooking = 1,
			general_magic = 0,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 1
		},
		skill_required = {
			cooking = 0,
			general_magic = 0,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 0
		},
	})

	local process_fang = create_recipe ({
		name = "Rat fang into a weapon",
		inputs = {RatFang},
		inputs_amount = {1},
		inputs_items = {},
		outputs = {},
		outputs_amount = {},
		outputs_items = {RatFangWeapon},
		required_weapon = nil,
		required_weapon_durability_loss = 0,
		skill_improvement = {
			cooking = 0,
			general_magic = 0,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 1
		},
		skill_required = {
			cooking = 0,
			general_magic = 0,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 0
		},
	})

	local make_rat_armor = create_recipe ({
		name = "Make rat armor",
		inputs = {RatBones, RatSkin},
		inputs_amount = {3, 3},
		inputs_items = {},
		outputs = {},
		outputs_amount = {},
		outputs_items = {RatBonesArmor},
		required_weapon = nil,
		required_weapon_durability_loss = 0,
		skill_improvement = {
			cooking = 0,
			general_magic = 0,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 1
		},
		skill_required = {
			cooking = 0,
			general_magic = 0,
			melee_defense = 0,
			melee_weapon = 0,
			boneworking = 10,
		},
	})

	economy_table.rat_body = RatBody
	economy_table.rat_armor = RatBonesArmor
	economy_table.buther_rat = butcher
	economy_table.make_rat_armor = make_rat_armor
end

---@param base_value number?
function EMPTY_INVENTORY(base_value)
	if base_value == nil then
		base_value = 0
	end
	---@type number[]
	local t = {}
	for index, value in ipairs(Resources) do
		t[index] = base_value
	end
	return t
end

---@param base_value number?
function EMPTY_ITEM_KIND_VECTOR(base_value)
	if base_value == nil then
		base_value = 0
	end
	---@type number[]
	local t = {}
	for index, value in ipairs(BaseItemTable) do
		t[index] = base_value
	end
	return t
end

return economy_table