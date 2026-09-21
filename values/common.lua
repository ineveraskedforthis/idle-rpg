local t = {}

---@param item ItemIndex
---@return integer
function t.calculate_affixes(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	for index, value in ipairs(w.affixes) do
		result = result + value.amount
	end
	return result
end

---@param item ItemIndex
---@return integer
function t.get_shield(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.shield
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].shield * value.amount
	end

	return result
end

---@param item ItemIndex
---@return integer
function t.get_melee_damage(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.damage
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].melee_damage * value.amount
	end

	return result
end

---@param item ItemIndex
---@return integer
function t.get_magic_damage(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.damage
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].magic_damage * value.amount
	end

	return result
end

---@param item ItemIndex
---@return integer
function t.get_speed_mod(item)
	---@type number
	local result = 0
	local w = RETRIEVE_ITEM(item)
	if not w then
		return 0
	end
	local b = BaseItemTable[w.kind]
	result = result + b.speed_modifier
	for index, value in ipairs(w.affixes) do
		result = result + AffixTable[value.affix_index].speed_modifier * value.amount
	end

	return result
end


return t