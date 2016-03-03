module AIUtil
  using ClientAI

  import Base: getindex, setindex!, fill!, position

  include("ai_base.jl")
  include("map.jl")
  include("action_memory.jl")

  # area functions
  export pos_in_range, get_view_area, get_radar_area, get_move_area, get_damage_area, get_map
  export Map, visualize, diffuse, gather, hex2cart

  # bot functions
  export filter_valid

  # actions
  export ActionPlan, plan_actions, softmax, sample_action
  export ActionMemory, remember!, get_aim

  # others
  export event_dispatch, ActionPlan, plan_actions, softmax, sample_action, categorized_action_positions
end
