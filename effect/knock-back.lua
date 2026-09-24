---@param actor  ActorState
---@param strength number
return function (actor, strength)
	if actor.current_action ~= ActionEnum.KnockedBack then
		actor.current_action.progress = 0
		actor.current_action.kind =ActionEnum.KnockedBack
		actor.current_action.used_skill = nil
		actor.current_action.completed = false
		actor.current_action.strength = strength
	else
		actor.current_action.strength = actor.current_action.strength + strength
	end
end