const DIFFUSION_COEFFICIENT = 0.5
import Base.position

include("knowledge/bayes.jl")

immutable DetectionResult
  pos::Position
  id::Int
end
position(d::DetectionResult) = d.pos


# track the movement of ships based on partial knowledge
type ShipTrackMap
  config::Config
  ships::BayesShipMap
  ship_count::Int
end

function ShipTrackMap(config::Config, enemies::Vector{Int})
  return ShipTrackMap(config, BayesShipMap(enemies, config), config.bots)
end

function input_scans!(t::ShipTrackMap, scan_area::Vector{Position}, scan_results::Vector{DetectionResult})
  # remove overlap from scans
  result_area = map(position, scan_results)
  scan_area = setdiff(unique(scan_area), result_area)

  # all positions where the scan returned nothing
  for p in scan_area
    push_scan!(t.ships, p, false)
  end

  # all successful scans
  for scan in scan_results
    if scan.id == -1
      push_scan!(t.ships, position(scan), true)
    else
      push_scan!(t.ships, position(scan), scan.id)
    end
  end
end

function missed_shot!(t::ShipTrackMap, p::Position)
  for x in get_damage_area(p, t.config)
    push_scan!(t.ships, x, false)
  end
end

function hit_shot!(t::ShipTrackMap, p::Position, v::Int)
  push_scan!(t.ships, get_damage_area(p, t.config), v)
end


# call this to signal the knowledge system that a ship has been killed
# positions is a list of possible positions where the kill could have happened
function notify_kill!(track::ShipTrackMap, positions::Vector)
  # TODO remove that ship from BayesShipMap
end

# call this function to signal that you are finished adding new information.
# all cached updates are processed then.
function update!(track::ShipTrackMap)
  # renormalize density
  update!(track.ships)
end

# estimate ship positions after one round, and return new ShipTrack object
function estimate_movement(track::ShipTrackMap)
  # TODO 0.5 is OK or even high for undetected enemys, but I guess after detection they should move
  # more with D = 1
  return ShipTrackMap(track.config, simulate_movement(track.ships, track.config, DIFFUSION_COEFFICIENT), track.ship_count)
end

function ship_density(track::ShipTrackMap)
  result = Map(Float64, track.config.field_radius, 0.0)
  for (i, v) in track.ships.ships
    result.data += v.data
  end
  return result
end


