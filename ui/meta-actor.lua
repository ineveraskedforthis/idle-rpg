ACTOR_WIDTH = 50
ACTOR_HEIGHT = 70

local style = require "ui._style"

---comment
---@param x number
---@param y number
---@param actor MetaActor?
---@param unlocked boolean
---@param position number
return function (x, y, actor, unlocked, position)
	if actor then
		style.default_font()
		if unlocked then
			love.graphics.setColor(0, 0, 0, 1)
		else
			love.graphics.setColor(0.5, 0.5, 0.5, 1)
		end
		love.graphics.print(actor.name, x, y - 20)
		if unlocked then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(0.5, 0.5, 0.5, 1)
		end
		love.graphics.draw(actor.image, x, y, 0)
	end
	if position > 0 then
		love.graphics.setColor(1, 1, 1, 0.75)
		love.graphics.rectangle("fill", x + ACTOR_WIDTH - 20, y + ACTOR_HEIGHT - 20, 20, 20)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print(tostring(position), x + ACTOR_WIDTH - 10, y + ACTOR_HEIGHT - 20)

		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("line", x - 4, y - 4, ACTOR_WIDTH + 8, ACTOR_HEIGHT + 8)
	end
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("line", x, y, ACTOR_WIDTH, ACTOR_HEIGHT)
end