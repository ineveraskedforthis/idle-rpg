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

---@return ActorState
return function ()
	---@type ActorState
	local res = {
		boots = INVALID_ITEM_INDEX,
		current_action = {
			completed = true,
			kind = ActionEnum.Nothing,
			progress = 0,
			used_item = INVALID_ITEM_INDEX,
			used_skill = nil,
			expected_time = 0,
			strength = 0
		},
		hp = BASE_MAX_HP,
		hp_max = BASE_MAX_HP,
		hp_view = BASE_MAX_HP,
		in_battle = false,
		inventory = EMPTY_INVENTORY(),
		price_belief_buy = EMPTY_INVENTORY(1),
		price_belief_sell = EMPTY_INVENTORY(1),
		item_kind_price_belief_buy = EMPTY_ITEM_KIND_VECTOR(1),
		item_kind_price_belief_sell = EMPTY_ITEM_KIND_VECTOR(1),
		name = "Nameless",
		coins = 0,
		is_enemy = false,
		item_skills_queue = {},
		items_queue = {},
		loot_amount = {},
		loot_items = {},
		loot_resources = {},
		mastery = {
			cooking = 0,
			general_magic = 0,
			melee_defense = 0,
			melee_weapon = 0,
		},
		melee_damage = 1,
		mental = {
			learning_speed = BASE_LEARNING_RATE,
		},
		micro_cooldown_item_activation = 0,
		model = {
			being_hit_timer = 0,
			death_timer = 0,
			orientation = 1,
			position = 0,
			state = ActorModelStateEnum.Idle,
			walk_timer = 0
		},
		model_description = basic_skeleton,
		on_kill_triggered = false,
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
		shield = 0,
		speed = 0,
		spell_damage = 0,
		stash = {},
		weapon = INVALID_ITEM_INDEX,
		target_recipes = {}
	}
	return res
end