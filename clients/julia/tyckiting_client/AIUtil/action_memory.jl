# helper class used to remember your actions of the last round
type ActionMemory
  actions::Vector{AbstractAction}
  moves::Vector{Position}
  scans::Vector{Position}
  shots::Vector{Position}
  shooters::Vector{Int}
end

function ActionMemory()
  return ActionMemory(AbstractAction[], Position[], Position[], Position[], Int[])
end

function filter_by_name(Name::AbstractString, data)
  return filter(d->name(d)==Name, data)
end

function remember!{T <: AbstractAction}(mem::ActionMemory, actions::Vector{T})
  mem.actions = convert(Vector{AbstractAction}, actions)
end

# pass the list of events of the last round. Looks for skip
# events and removes those actions from the action list
function validate!(mem::ActionMemory, events::Vector{AbstractEvent})
  # TODO we probably should also check for move events
  # TODO ensure that validate is actually called...
  event_dispatch(mem, events)

  # then fill the data fields
  mem.moves = map(position, filter_by_name("move", mem.actions))
  mem.shots = map(position, filter_by_name("cannon", mem.actions))
  mem.scans = map(position, filter_by_name("radar", mem.actions))
  mem.shooters = map(botid, filter_by_name("cannon", mem.actions))
end

# ignore most events
on_event(mem::ActionMemory, event::AbstractEvent) = 0
function on_event(mem::ActionMemory, event::NoActionEvent)
  filter!(a->botid(a) != botid(event), mem.actions)
end

function get_aim(mem::ActionMemory, bot::Int)
  for (i, s) in enumerate( mem.shooters )
    if s == bot
      return mem.shots[i]
    end
  end
  warn("Could not find shooting target of bot $(bot)!")
end
