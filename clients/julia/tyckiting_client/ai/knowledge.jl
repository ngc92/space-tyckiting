# this file contains functions and types related to the knwoledge gathering process of ngcbot

mark_no_enemy(m::Map, positions) = set_map_values!(m, 0, positions)
function normalize!(m::Map, norm::Real, absolute::Bool = true)
  # renormalize density
  total = sum(get_map_values(m,  get_map(m.radius)))
  # TODO we need to fix this; enemy bots may be dead
  if absolute
    factor = norm / total
  else
    factor = (total + norm) / total
  end
  m.data .*= factor
end

function mark_no_enemy(ai::NGCBot, bots::Vector, radars::Vector, shots::Vector)
  for b in bots
    mark_no_enemy(ai.knowledge_map, get_view_area(b, ai.config))
  end

  for r in radars
    mark_no_enemy(ai.knowledge_map, get_radar_area(r, ai.config))
  end

  for s in shots
    mark_no_enemy(ai.knowledge_map, get_damage_area(s, ai.config))
  end

  # renormalize density
  normalize!(ai.knowledge_map, ai.config.bots, true)
end
mark_no_enemy(ai::NGCBot, bots::Vector, memory::ActionMemory) = mark_no_enemy(ai, bots, memory.scans, memory.shots)

function single_detection!(m::Map, p::Position)
  normalize!(m, -1, false)
  m[p] += 1
end