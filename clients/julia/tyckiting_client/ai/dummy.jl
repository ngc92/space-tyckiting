module Dummy_AI

using ClientAI

# include several AI utility functions and classes.
include("../AIUtil/AIUtil.jl")
using .AIUtil

type DummyAI <: AbstractAI
  config::Config
  bots::Vector{AbstractBot}
end

function init_round(ai::DummyAI, bots::Vector{AbstractBot}, events::Vector{AbstractEvent}, round_id::Integer)
  ai.bots = bots
end

function decide(ai::DummyAI)
  bots = filter_valid(ai.bots)
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
	return DummyAI(config, AbstractBot[])
end

end
