abstract AbstractMap

#####################################################
# internal helper functions
#####################################################

world_radius(i) = i
world_radius(m::AbstractMap) = radius(m)
world_radius(c::Config) = c.field_radius

# generate all position in hexagonal neighbourhood of certain radius. Does not check if these positions are valid
function pos_in_range_unchecked(x::Integer, y::Integer, radius::Integer)
  positions = Position[]
  for dx in -radius:radius
    append!(positions, [Position(x + dx, y + dy) for dy in max(-radius, -dx-radius):min(radius, -dx+radius)])
  end
  return positions
end
pos_in_range_unchecked(p::Position, rad::Integer) = pos_in_range_unchecked(p.x, p.y, rad)

# check if position is within playing field
function is_valid_pos(p::Position, radius)
  field = world_radius(radius)
  return -field <= p.x <=field && max(-field, -p.x-field) <= p.y <= min(field, -p.x+field)
end
filter_valid(positions, field) = filter(x->is_valid_pos(x, field), positions)

############################################################
#  interface functions
############################################################

# convenience functions for bots: get fields that an be seen, and fields that can be reached by movement
get_map(world) = pos_in_range_unchecked(0,0, world_radius(world))

pos_in_range(origin,  radius, world)  = filter_valid( pos_in_range_unchecked(position(origin), radius), world_radius(world))
get_view_area(origin,  config::Config) = pos_in_range(origin, config.see,   config)
get_radar_area(origin, config::Config) = pos_in_range(origin, config.radar, config)
get_move_area(origin,  config::Config) = pos_in_range(origin, config.move,  config)
get_damage_area(center,  config::Config) = pos_in_range(center, config.cannon,  config)

# helper data type that contains a map of the world

type Map
  data::Matrix
  radius::Int
end

radius(m::Map) = m.radius

function Map(T::DataType, size::Integer, init = zero(T))
  diameter = 2size + 1
  return Map( fill(init, (diameter, diameter)), size )
end


##################################################
#        indexing, get/set ops
##################################################

# allow direct indexing of underlying matrix
function getindex(m::Map, x, y)
  return m.data[x + m.radius + 1, y + m.radius + 1]
end

function setindex!(m::Map, v, x, y)
  m.data[x + m.radius + 1, y + m.radius + 1] = v
end

# or index with Position type
getindex(m::Map, p::Position) = getindex(m, round(Int, p.x), round(Int, p.y))
setindex!(m::Map, value, p::Position) = setindex!(m, value, round(Int, p.x), round(Int, p.y))

fill!(m::Map, v) = fill!(m.data, v)

##################################################
#          visualization helper
##################################################
function hex2cart(u, v, radius)
  v1 = [0, 1]
  v2 = [sind(60), cosd(60)]
  return v1 * (u + radius + 1) + v2 * (v + radius + 1)
end

function visualize(m::Map; vis = x->x)
  scale = 10
  v1 = [0, 1]
  v2 = [sind(60), cosd(60)]
  mx = round(Int, scale * hex2cart(m.radius, m.radius, m.radius))

  image = zeros((mx+scale)...)

  # converts to a cartesion map
  positions = get_map(m.radius)
  for p in positions
    cp = hex2cart(p.x, p.y, m.radius)
    cp = round(Int, scale * cp)
    v = vis(m[p])
    for x in 0:scale-1, y in 0:scale-1
      image[cp[1]+x, cp[2]+y] = v
    end
  end
  return image
end



function diffuse(map::Map, kernel::Function, D::Real = 1)
  # kernel will be called for each position and should return a collection of target positions
  # to spread to
  cpy = deepcopy(map)
  fill!(cpy, 0)
  for p in get_map(map.radius)
    # neighbours
    t = kernel(p)
    d = map[p] / length(t) * D
    for x in t
      cpy[x] += d
    end
    cpy[p] += map[p] * (1-D)
  end
  return cpy
end

function gather(map::Map, kernel::Function)
  # kernel will be called for each position and should return a collection of target positions
  # to gather from
  cpy = deepcopy(map)
  fill!(cpy, 0)
  for p in get_map(map.radius)
    # neighbours
    t = kernel(p)
    # TODO allow for weighted kernels
    cpy[p] += sum([map[p] for p in t])
  end
  return cpy
end
