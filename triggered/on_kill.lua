---@param player PlayerState
---@param difficulty number
return function (player, difficulty)
	require "effect.loot"(player, difficulty)
	player.exp = player.exp + difficulty
end