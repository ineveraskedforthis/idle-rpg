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
register_ring("Ring", love.graphics.newImage("ring.png"), 5)
