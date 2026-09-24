local update = require "effect.player-update"

---@param player ActorState
---@param model_description ActorModelDescription
return function (player, model_description)
	player.stash = {}
	player.melee_damage = 0
	player.spell_damage = 0
	player.rings = {
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
	}
	player.mastery = {
		melee_weapon = 0,
		melee_defense = 0,
		general_magic = 0,
		cooking = 0,
		boneworking = 0
	}
	player.mental = {
		learning_speed = BASE_LEARNING_RATE
	}
	player.current_action =  {
		kind = ActionEnum.Nothing,
		used_item = INVALID_ITEM_INDEX,
		used_skill = nil,
		progress = 0,
		completed = true,
		expected_time = 0,
		strength = 0
	}
	player.items_queue = {}
	player.weapon = INVALID_ITEM_INDEX
	player.boots = INVALID_ITEM_INDEX
	player.micro_cooldown_item_activation = 0
	player.item_skills_queue = {}
	player.in_battle = false
	player.model_description = model_description
	player.model = {
		position = 0,
		walk_timer = 0,
		state = ActorModelStateEnum.Idle,
		death_timer = 0,
		orientation = 1,
		being_hit_timer = 0,
		attack_progress = 0
	}
	player.hp = BASE_MAX_HP
	player.hp_max = BASE_MAX_HP
	player.hp_view = BASE_MAX_HP
	player.shield = 0
	player.speed = 1

	player.location = StartingLocation
	player.location_last = player.location

	update(player)
end
