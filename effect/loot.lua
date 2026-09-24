--[[
---comment
---@param item Item
---@param affix ItemAffix
---@return boolean
local function legit(item, affix)
	if BaseItemTable[item.kind].slot ==ItemSlot.Boots then
		return affix.can_roll_for_armor
	end
	if BaseItemTable[item.kind].slot == ItemSlot.Weapon then
		return affix.can_roll_for_weapon
	end
	if BaseItemTable[item.kind].slot ==ItemSlot.Ring then
		return affix.can_roll_for_ring
	end
	error()
end

---comment
---@param rarity number
---@return ItemIndex
local function generate_loot(rarity)
	---@type Item
	local item = {
		kind = {
			value = math.floor(#BaseItemTable *love.math.random()) + 1
		},
		affixes = {},
		durability = 1,
		equipped = false,
		cooldown = 0,
		invalid = false,
		highlight_opacity = 1
	}
	local item_index = CREATE_ITEM(item)

	local mods = rarity

	for i = 1, rarity do
		---@type number[]
		local candidates = {}
		local total_weight = 0

		for index, value in ipairs(AffixTable) do
			if legit(item, value) then
				table.insert(candidates, index)
				total_weight = total_weight + 1 / value.rarity
			end
		end
		local candidates_count = #candidates
		if candidates_count == 0 then
			goto continue
		end
		local dice = love.math.random() * total_weight
		local acc = 0
		for index, value in ipairs(candidates) do
			local affix = AffixTable[value]
			acc = acc + 1 / affix.rarity
			if acc >= dice then
				local found = false
				-- check if it is already there :
				for _, aff in ipairs(item.affixes) do
					if aff.affix_index == value then
						aff.amount = aff.amount + 1
						found = true
					end
				end
				if not found then
					---@type AffixInstance
					local to_add = {
						affix_index = value,
						amount = 1
					}
					table.insert(item.affixes, to_add)
				end
				goto continue
			end
		end

		::continue::
	end

	return item_index
end
--]]


---@param killer ActorState
---@param enemy ActorState
local function loot_enemy(killer, enemy)
	-- local inventory = 0
	-- for index, value in ipairs(state.stash) do
	-- 	local item = RETRIEVE_ITEM(value)
	-- 	if item and not item.equipped then
	-- 		inventory = inventory + 1
	-- 	end
	-- end
	-- if love.math.random() < 0.33 and inventory < 15 then
	-- 	local item = generate_loot(love.math.random() * (1 + 10 * MASTERY_TO_SKILL (enemy.mastery.general_magic + enemy.mastery.melee_weapon + enemy.mastery.melee_defense) + enemy.melee_damage / 2 + enemy.spell_damage / 2))
	-- 	table.insert(state.stash, item)
	-- 	return item
	-- end

	for index, value in ipairs(enemy.loot_items) do
		-- local looted_kind = BaseItemTable[value.value]
		---@type Item
		local item = {
			kind = value,
			affixes = {},
			cooldown = 0,
			durability = 1,
			equipped = false,
			highlight_opacity = 0,
			invalid = false
		}
		local item_index = CREATE_ITEM(item)
		table.insert(killer.stash, item_index)
	end

	for index, id in ipairs(enemy.loot_resources) do
		killer.loot_resources[id.value] = killer.loot_resources[id.value] + enemy.loot_amount[id.value]
	end

	return nil
end

return loot_enemy