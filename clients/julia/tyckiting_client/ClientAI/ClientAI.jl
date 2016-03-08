module ClientAI
  import Base: position

  include("types.jl")
  include("hexgrid.jl")
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

	export AbstractAI

  # general functions and types
  export Position, Config
  export botid, position, to_dict

  # events
  export AbstractEvent, HitEvent, DeathEvent, SightEvent, RadarEvent, DetectionEvent, DamageEvent, MoveEvent, NoActionEvent
  export on_event, event_dispatch

  # actions
  export AbstractAI, MoveAction, RadarAction, CannonAction

  # bot functions
  export AbstractBot
  export is_alive, team, name, hitpoints, make_action

  # grid functions
  export distance, radius, center, circle
  export view_area, radar_area, move_area, damage_area, map_area
end
