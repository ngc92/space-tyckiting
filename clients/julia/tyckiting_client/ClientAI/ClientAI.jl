module ClientAI
  import Base: position

  include("types.jl")
  include("bot.jl")
  include("actions.jl")
  include("events.jl")
  include("ai.jl")

  macro checked(ex)
    return quote
      try
        $(esc(ex))
      catch e
        showerror(STDERR, e)
        Base.show_backtrace(STDOUT, catch_backtrace())
      end
    end
  end
  export @checked

	export AbstractAI, AbstractAction, AbstractEvent, AbstractBot, Position, Config
	export to_dict, MoveAction, RadarAction, CannonAction, move

  # event types
  export HitEvent, DeathEvent, SightEvent, RadarEvent, DetectionEvent, DamageEvent, MoveEvent, NoActionEvent, on_event, event_dispatch

  # bot functions
  export is_alive, team, botid, name, position, hitpoints, make_action
end
