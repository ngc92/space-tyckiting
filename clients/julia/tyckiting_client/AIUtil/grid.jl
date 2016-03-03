#
# This file contains functions for working with the hexagonal grid
#


#####################################################
# internal helper functions
#####################################################

world_radius(i) = i
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
