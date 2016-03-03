abstract AbstractAI

function move(ai::AbstractAI, bots::Vector{AbstractBot}, events::Vector{AbstractEvent})
  error("method move not found for $(typeof(ai)). Be sure to import it!")
end

# default event handlers: warn for important events that they are missed
on_event(ai::AbstractAI, event::AbstractEvent) = warn("Event of type $(typeof(event)) not processed by $(typeof(ai))!")
on_event(ai::AbstractAI, event::NoActionEvent) = warn("Bot $(botid(event)) dit not act last round!")
on_event(ai::AbstractAI, event::MoveEvent) = false
