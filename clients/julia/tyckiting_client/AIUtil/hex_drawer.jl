immutable HexDrawer
  image::Array{Float64, 3}
  size::Int
  radius::Int
  scale::Float64
end

# coordinate transforms
const s60 = sind(60)
const c60 = cosd(60)
const s3 = sqrt(3)

function hex2cart(u::Real, v::Real)
  return s60*v, u + c60*v
end

function cart2hex(x::Real, y::Real)
  return -s3/3*x+y, 2/3*s3*x
end

function hexround(u::Real, v::Real)
  z = -u-v
  ru = round(Int, u)
  rv = round(Int, v)
  rz = round(Int, z)

  u_diff = abs(ru - u)
  v_diff = abs(rv - v)
  z_diff = abs(rz - z)

  if u_diff > v_diff && u_diff > z_diff
    return -rv - rz, rv
  elseif v_diff > z_diff
    return ru, -ru-rz
  end
  return ru, rv
end

##############################################
# advanced functions, taking into account scaling and shift
##############################################
function cart2hex(d::HexDrawer, x::Real, y::Real)
  px = d.scale*(x-d.size/2)
  py = d.scale*(y-d.size/2)
  return cart2hex(px, py)
end

function hex2cart(d::HexDrawer, u::Real, v::Real)
  px, py = hex2cart(u, v)
  x = px / d.scale + d.size/2
  y = py / d.scale + d.size/2
  return x, y
end

##############################################
#         map drawer functions
##############################################
function HexDrawer(size::Integer, radius::Integer)
  scale = 2radius/ (size-1)
  image = zeros(3, size, size)
  return HexDrawer(image, size, radius, scale)
end

# draw a map to the image
function draw(drawer::HexDrawer, m::Map)
  @assert radius(m) == drawer.radius
  # relay to other information to get specific drawer.image type
  world = map_area(m)
  for y in 1:size(drawer.image, 3)
    for x in 1:size(drawer.image, 2)
      cu, cv = cart2hex(drawer, x, y)
      hxc = hexround(cu, cv)
      if Position(hxc[1], hxc[2]) ∈ world
        drawer.image[:, x, y] = m[hxc[1], hxc[2]]
      end
    end
  end
end

# draw, but apply data transform before that
function draw(drawer::HexDrawer, m::Map, transform::Function)
  transformed = deepcopy(m)
  for p in map_area(m)
    transformed[p] = transform(m[p])
  end
  draw(drawer, transformed)
end

function draw(drawer::HexDrawer, pos::Position, color::Vector)
  cx, cy = hex2cart(drawer, pos.x, pos.y)
  x = round(Int, cx)
  y = round(Int, cy)
  drawer.image[:, x, y] = color
end

function draw(drawer::HexDrawer, pos::Position, mask::Matrix{Bool}, color::Vector)
  cx, cy = hex2cart(drawer, pos.x, pos.y)
  x = round(Int, cx - size(mask, 1) / 2)
  y = round(Int, cy - size(mask, 2) / 2)
  for dx in 1:size(mask, 1), dy in 1:size(mask, 2)
    if mask[dx, dy] && 1 <= x + dx <= size(drawer.image, 2) && 1 <= y + dy <= size(drawer.image, 3)
      drawer.image[:, x+dx, y+dy] = color
    end
  end
end

function get_image(d::HexDrawer)
  return min(1, d.image)
end
