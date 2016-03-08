abstract AbstractMap

# helper data type that contains a map of the world

type Map
  data::Matrix
  radius::Int
  function Map(data::Matrix, radius::Integer)
    diameter = 2radius + 1
    @assert size(data, 1) == diameter
    @assert size(data, 2) == diameter
    return new( data, radius )
  end

end

world_radius(m::Map) = m.radius

function Map(T::DataType, size::Integer, init = zero(T))
  diameter = 2size + 1
  return Map( fill(init, (diameter, diameter)), size )
end

##################################################
#        indexing, get/set ops
##################################################

# allow direct indexing of underlying matrix
function getindex(m::Map, x::Integer, y::Integer)
  return m.data[x + m.radius + 1, y + m.radius + 1]
end

function setindex!(m::Map, v, x::Integer, y::Integer)
  m.data[x + m.radius + 1, y + m.radius + 1] = v
end

# or index with Position type
getindex(m::Map, p::Position) = getindex(m, round(Int, p.x), round(Int, p.y))
setindex!(m::Map, value, p::Position) = setindex!(m, value, round(Int, p.x), round(Int, p.y))

# get/set multiple values at once
# TODO find a way to do that with [] operations
function get_map_values(m::Map, multi)
  return [m[i] for i in multi]
end

function set_map_values!(m::Map, value, multi)
  for i in multi
    m[i] = value
  end
end


fill!(m::Map, v) = fill!(m.data, v)

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
