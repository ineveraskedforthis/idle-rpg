---@class (exact) SkillDefinition
---@field draw fun(x: number, y: number, data: PlayerState, actor_model: ActorModelDescription, actor_position: ActorModelState, camera_shift: number)
---@field update fun(vfx: VFX, stage: Stage, player: PlayerState, dt: number, model: ActorModelState, model_description: ActorModelDescription, skip_casting : boolean, magnitude : number)
---@field activation_range fun(player: PlayerState) : number

---@type table<SkillEnum, SkillDefinition>
local SkillDefinitions = {}

---@enum SkillEnum
SkillEnum = {
	MeleeAttack = "melee-attack",
	Comet = "comet"
}

SkillDefinitions["melee-attack"] = require "skills.melee-attack"
SkillDefinitions["comet"] = require "skills.comet"

return SkillDefinitions