# track the movement of ships based on partial knowledge
type ShipTrackMap
  config::Config
  map::Map
  ship_count::Int
end

const DIFFUSION_COEFFICIENT = 0.5

function ShipTrackMap(config::Config)
  fieldcount = length(get_map(config))
  m = Map(Float64, config.field_radius, config.bots / fieldcount)
  # iterate a few times to find equilibrium
  for i in 1:20
    diffuse(m, p->get_move_area(p, config), DIFFUSION_COEFFICIENT)
  end
  return ShipTrackMap(config, m, config.bots)
end

# call this function to signal that the given area was scanned
# (i.e. either radared or seen).
function mark_scan!(track::ShipTrackMap, area)
  set_map_values!(track.map, 0, area)
end

# call this function if you want to signalize that a ship was
# definitely detected as position pos. Optionally, add an id
# to further improve tracking abilities
function detect_ship!(track::ShipTrackMap, pos, id = -1)
  single_detection!(track.map, position(pos))
end

# call this function if you want to signalize that a ship was
# detected within a certain area. Optionally, add an id
# to further improve tracking abilitie.
function detect_ship_in_area!(track::ShipTrackMap, area::Vector, id = -1)
  normalize!(track.map, -1, false)
  for p in area
    track.map[p] += 1 / length(area)
  end
end

# call this to signal the knowledge system that a ship has been killed
# positions is a list of possible positions where the kill could have happened
function notify_kill!(track::ShipTrackMap, positions::Vector)
  # expand area to conver
  area = vcat(map(c->get_damage_area(c, track.config), positions)...)

  if length(area) > 0
    # probability to remove from each grid position
    # TODO should do some weighting here
    reduction = 1 / length(area)
    for s in area
      # TODO we need to rework normalization now, as there is one less enemy bot
      # also, since the coordinate might carry less weight than is to be removed
      # we should also reduce surrounding prob.
      track.map[s] = max(0, track.map[s]-reduction)
    end
  end

  # one ship less
  track.ship_count -= 1
end

# call this function to signal that you are finished adding new information.
# all cached updates are processed then.
function update!(track::ShipTrackMap)
  # renormalize density
  normalize!(track.map, track.ship_count, true)
end

# estimate ship positions after one round, and return new ShipTrack object
function estimate_movement(track::ShipTrackMap)
  # TODO 0.5 is OK or even high for undetected enemys, but I guess after detection they should move
  # more with D = 1
  return ShipTrackMap(track.config, diffuse(track.map, p->get_move_area(p, track.config), DIFFUSION_COEFFICIENT), track.ship_count)
end



# helper functions


function normalize!(m::Map, norm::Real, absolute::Bool = true)
  # renormalize density
  total = sum(get_map_values(m,  get_map(m.radius)))
  if total == 0
    return
  end
  # TODO we need to fix this; enemy bots may be dead
  if absolute
    factor = norm / total
  else
    factor = max(0, (total + norm) / total)
  end
  m.data .*= factor
end

function single_detection!(m::Map, p::Position)
  normalize!(m, -1, false)
  m[p] += 1
end
