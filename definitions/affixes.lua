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
		melee_damage = 0,
		shield = 0,
		can_roll_for_armor = false,
		can_roll_for_ring = false,
		can_roll_for_weapon = true,
		magic_damage = 1,
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
