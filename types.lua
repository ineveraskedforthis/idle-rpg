
---@class InterfaceRequest
---@field render boolean
---@field mx number
---@field my number
---@field mouse_button number
---@field presses number


---@class (exact) Particle
---@field time_left number
---@field max_time number
---@field size number
---@field position number
---@field image love.Image

---@class (exact) VFX
---@field particles Particle[]


---@class (exact) Action
---@field kind ActionEnum
---@field used_skill SkillEnum?
---@field used_item ItemIndex
---@field progress number
---@field strength number
---@field completed boolean
---@field expected_time number

---@class (exact) EnemyPrototype
---@field hp_max number
---@field attack_experience number
---@field spell_experience number
---@field base_damage number
---@field model_description ActorModelDescription
---@field speed number
---@field loot_resources ResourceIndex[]
---@field loot_amount number[]
---@field loot_items ItemKindIndex[]

---@class (exact) ArmyComposition
---@field unit EnemyPrototype
---@field weight number

---@class (exact) Faction
---@field name string
---@field basic_composition ArmyComposition[]
---@field elite_composition ArmyComposition[]

---@class (exact) FactionState
---@field fear number
---@field respect number
---@field relations number

---@class (exact) Location
---@field name string
---@field x number
---@field y number
---@field display_radius number
---@field controlled_by number
---@field basic_armies number
---@field elite_armies number
---@field background love.Image
---@field local_characters ActorState[]
---@field pack_size number

---@class (exact) LocationState
---@field controlled_by number
---@field basic_armies number
---@field elite_armies number

---@class (exact) MasteryState
---@field melee_weapon number
---@field melee_defense number
---@field general_magic number
---@field cooking number
---@field boneworking number

---@class (exact) MentalState
---@field learning_speed number

---@class (exact) ActorState
---@field melee_damage number
---@field spell_damage number
---@field total_defense number
---@field stash ItemIndex[]
---@field rings ItemIndex[]
---@field weapon ItemIndex
---@field boots ItemIndex
---@field body_armor ItemIndex
---@field mastery MasteryState
---@field mental MentalState
---@field current_action Action
---@field items_queue Action[]
---@field micro_cooldown_item_activation number
---@field item_skills_queue number[]
---@field in_battle boolean
---@field location number|nil
---@field location_last number|nil
---@field model_description ActorModelDescription
---@field model ActorModelState
---@field hp number
---@field hp_view number
---@field hp_max number
---@field shield number
---@field speed number
---@field on_kill_triggered boolean
---@field is_enemy boolean
---@field inventory number[]
---@field price_belief_sell number[]
---@field price_belief_buy number[]
---@field item_kind_price_belief_sell number[]
---@field item_kind_price_belief_buy number[]
---@field loot_resources ResourceIndex[]
---@field loot_amount number[]
---@field loot_items ItemKindIndex[]
---@field faction number|nil
---@field target_recipes RecipeIndex[]
---@field coins number
---@field name string

--[[
---@class (exact) Enemy
---@field hp number
---@field view_hp number
---@field prototype EnemyPrototype
---@field position number
---@field attack_progress number
---@field is_attacking boolean
---@field being_hit boolean
---@field being_hit_animation_progress number
---@field on_kill_triggered boolean
---@field death_progress number
--]]

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
---@field enemies ActorState[]
---@field allies ActorState[]
---@field projectiles Projectile[]
---@field is_elite boolean

---@class (exact) Resource
---@field name string
---@field restore_hp number|nil
---@field restore_shield number|nil

---@class (exact) ItemKindIndex
---@field value number

---@class (exact) RecipeIndex
---@field value number

---@class (exact) ResourceIndex
---@field value number

---@class (exact) ItemKind
---@field name string
---@field image love.Image
---@field damage number
---@field speed_modifier number
---@field base_attack_speed number
---@field shield number
---@field defense number
---@field slot ItemSlot
---@field range number
---@field image_kind ItemImageSize

---@class (exact) Recipe
---@field name string
---@field outputs_items ItemKindIndex[]
---@field outputs ResourceIndex[]
---@field outputs_amount number[]
---@field inputs ResourceIndex[]
---@field inputs_amount number[]
---@field inputs_items ItemKindIndex[]
---@field required_weapon ItemKindIndex|nil
---@field required_weapon_durability_loss number
---@field skill_required MasteryState
---@field skill_improvement MasteryState

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


---@class AffixInstance
---@field amount number
---@field affix_index number

---@class (exact) Item
---@field kind ItemKindIndex
---@field affixes AffixInstance[]
---@field durability number
---@field cooldown number
---@field highlight_opacity number
---@field equipped boolean
---@field invalid boolean


---@class (exact) ActorModelDescription
---@field size_x number
---@field size_y number
---@field image love.Image
---@field image_base_scale number
---@field walk_frames love.Quad[]
---@field walk_timer_mult number
---@field idle_frames love.Quad[]
---@field attack_frames love.Quad[]
---@field dead_frame love.Quad[]



---@class (exact) ActorModelState
---@field position number
---@field state ActorModelStateEnum
---@field walk_timer number
---@field death_timer number
---@field attack_progress number
---@field being_hit_timer number
---@field orientation number


---@enum MouseButton
MouseButton = {
	Left = 1,
	Right = 2,
	Middle = 3,
	None = 4,
}


---@enum ActionEnum
ActionEnum = {
	Nothing = 1,
	ActivateSkill = 2,
	ActivateItem = 3,
	KnockedBack = 4,
}


---@enum ActorModelStateEnum
ActorModelStateEnum = {
	Idle = 1,
	Walking = 2,
	Attacking = 3,
	Dead = 4,
	Attacked = 5,
}


---@enum ItemSlot
ItemSlot = {
	None = 1,
	Boots = 2,
	Weapon = 3,
	Body = 4,
	Ring = 5,
}

---@enum ItemImageSize
ItemImageSize = {
	Small = 1,
	Medium = 2,
	Large = 3,
}