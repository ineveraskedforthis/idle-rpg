local values = require "values.common"

---@param player PlayerState
return function(player)
	player.melee_damage = 1 + values.get_melee_damage(player.weapon)
	player.spell_damage = 1 + values.get_magic_damage(player.boots) + values.get_magic_damage(player.weapon)
	for i = 1, 10, 1 do
		player.spell_damage = player.spell_damage + values.get_magic_damage(player.rings[i])
	end
	player.speed = 200 * (1 + values.get_speed_mod(player.weapon) + values.get_speed_mod(player.boots))
end