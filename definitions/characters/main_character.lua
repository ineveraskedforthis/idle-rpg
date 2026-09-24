local hero = love.graphics.newImage("character-basic.png")

---@type ActorModelDescription
local basic_hero = {
	size_x = 400,
	size_y = 600,
	image = hero,
	image_base_scale = 0.25,
	walk_frames = {
		love.graphics.newQuad(400 * 1, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 2, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 3, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 4, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 5, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 6, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 7, 0, 400, 600, hero),
		love.graphics.newQuad(400 * 8, 0, 400, 600, hero),
	},
	walk_timer_mult = 1 / 200,
	attack_timer_mult = 1 / 100,
	idle_frames = {love.graphics.newQuad(0, 0, 400, 600, hero)},
	attack_frames =  {love.graphics.newQuad(0, 0, 400, 600, hero)},
	dead_frame =  {love.graphics.newQuad(0, 0, 400, 600, hero)},
}

---@return ActorState
return function ()
	local b = require "definitions.characters.blank"()
	b.model_description = basic_hero
	return b
end