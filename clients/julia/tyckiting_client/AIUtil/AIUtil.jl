module AIUtil
  using ClientAI

  import Base: getindex, setindex!, fill!, position
  import ClientAI: on_event

  include("map.jl")
  include("action_memory.jl")
  include("hex_drawer.jl")

  # map functions
  export Map, diffuse, gather, hex2cart, cart2hex, get_map_values, set_map_values!

  # action memory
  export ActionMemory, remember!, get_aim, validate!

  # drawer
  export HexDrawer, get_image, draw
end
