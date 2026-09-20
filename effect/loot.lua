
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
		kind = math.floor(#BaseItemTable *love.math.random()) + 1,
		suffixes = {},
		prefixes = {},
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
		local is_suffix = love.math.random() > 0.5
		local total_weight = 0

		if is_suffix then
			for index, value in ipairs(SuffixTable) do
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
				local affix = SuffixTable[value]
				acc = acc + 1 / affix.rarity
				if acc >= dice then
					table.insert(item.suffixes, value)
					goto continue
				end
			end
		else
			for index, value in ipairs(PrefixTable) do
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

	return item_index
end

---@param state PlayerState
---@param difficulty number
local function loot_enemy(state, difficulty)
	local inventory = 0
	for index, value in ipairs(state.stash) do
		local item = RETRIEVE_ITEM(value)
		if item and not item.equipped then
			inventory = inventory + 1
		end
	end
	if love.math.random() < 0.33 and inventory < 15 then
		local item = generate_loot(love.math.random() * 4 * difficulty)
		table.insert(state.stash, item)
		return item
	end
	return nil
end

return loot_enemy