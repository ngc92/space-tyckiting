# helper class used to remember your actions of the last round
type ActionMemory
  moves::Vector{Position}
  scans::Vector{Position}
  shots::Vector{Position}
  shooters::Vector{Int}
end

function ActionMemory()
  return ActionMemory(Position[], Position[], Position[], Int[])
end

function filter_by_name(Name::AbstractString, data)
  return filter(d->name(d)==Name, data)
end

function remember!{T <: AbstractAction}(mem::ActionMemory, actions::Vector{T})
  mem.moves = map(position, filter_by_name("move", actions))
  mem.shots = map(position, filter_by_name("cannon", actions))
  mem.scans = map(position, filter_by_name("radar", actions))
  mem.shooters = map(botid, filter_by_name("cannon", actions))
end

function get_aim(mem::ActionMemory, bot::Int)
  for (i, s) in enumerate( mem.shooters )
    if s == bot
      return mem.shots[i]
    end
  end
  warn("Could not find shooting target of bot $(bot)!")
end