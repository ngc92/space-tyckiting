module Dummy_AI

using ClientAI

# include several AI utility functions and classes.
include("../AIUtil/AIUtil.jl")
using .AIUtil

type DummyAI <: AbstractAI
  config::Config
end

function move(ai::DummyAI, bots::Vector{AbstractBot}, events::Vector{AbstractEvent})
  # this funtion calls on_event for all events in the list
  event_dispatch(ai, events)

  bots = filter_valid(bots)
  actions = AbstractAction[]
  for b in bots
    push!(actions, MoveAction(botid(b), rand(get_move_area(b, ai.config))))
  end
  return actions
end

# ignore all events
ClientAI.on_event(ai::DummyAI, event::AbstractEvent) = false

# this function is called from main to create the AI
function create(team_id, config::Config)
	info("create ai $team_id")
	return DummyAI(config)
end

end
