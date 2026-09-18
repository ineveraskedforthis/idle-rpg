---comment
---@param rarity number
local function generate_loot(rarity)
	---@type Item
	local item = {
		kind = math.floor(#BaseItemTable *love.math.random()) + 1,
		suffixes = {},
		prefixes = {},
		durability = 1
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

---@param state PlayerState
---@param difficulty number
local function loot_enemy(state, difficulty)
	if love.math.random() < 0.2 and #state.items < 15 then
		local item = generate_loot(love.math.random() * 4 * difficulty)
		table.insert(state.items, item)
	end
end

return loot_enemy