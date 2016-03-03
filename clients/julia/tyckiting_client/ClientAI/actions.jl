abstract AbstractAction
botid(a::AbstractAction) = a.bot_id
name(a::AbstractAction) = a.name
position(a::AbstractAction) = a.pos

immutable PosAction <: AbstractAction
	bot_id::Int
	pos::Position
	name::ASCIIString
end

function to_dict(a::PosAction)
	return Dict("botId" => botid(a), "type" => name(a), "pos" => position(a))
end

function make_action(bot_id::Int, x::Int, y::Int, name)
	return PosAction(bot_id, Position(x, y), name)
end

function make_action(bot_id::Int, p::Position, name)
	return PosAction(bot_id, p, name)
end

function MoveAction(args...)
	return make_action(args..., "move")
end

function RadarAction(args...)
	return make_action(args..., "radar")
end

function CannonAction(args...)
	return make_action(args..., "cannon")
end
