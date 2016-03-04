module AIUtil
  using ClientAI

  import Base: getindex, setindex!, fill!, position

  include("ai_base.jl")
  include("grid.jl")
  include("map.jl")
  include("action_memory.jl")
  include("hex_drawer.jl")

  # area functions
  export pos_in_range, get_view_area, get_radar_area, get_move_area, get_damage_area, get_map
  export Map, diffuse, gather, hex2cart, cart2hex, get_map_values, set_map_values!

  # bot functions
  export filter_valid

  # actions
  export ActionPlan, plan_actions, softmax, sample_action
  export ActionMemory, remember!, get_aim

  # drawer
  export HexDrawer, get_image, draw

  # others
  export event_dispatch, ActionPlan, plan_actions, softmax, sample_action, categorized_action_positions
end
