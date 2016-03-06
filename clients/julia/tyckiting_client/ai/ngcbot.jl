
module NGC_Bot
using ClientAI
using Images
import ClientAI: on_event
include("../AIUtil/AIUtil.jl")
using .AIUtil

include("knowledge_bayes.jl")

type NGCBot <: AbstractAI
  config::Config
  knowledge_map::ShipTrackMap          # what do we know about enemy positions
  enemy_knowledge_map::ShipTrackMap    # what we expect the enemy knows about us
  own_bots::Vector

  last_actions::ActionMemory
  turn_counter::Integer
  scan_results::Vector{DetectionResult}
end

const RADAR_DISCOUNT_FACTOR = 0.5 * 0.75

function init_round(ai::NGCBot, bots::Vector{AbstractBot}, events::Vector{AbstractEvent}, round_id::Integer)
  ai.own_bots = bots
  ai.turn_counter = round_id

  # TODO: find out if bot actions were ignored.
end

function decide(ai::NGCBot)
  bots = filter_valid(ai.own_bots)
  scan_positions = map(r->get_radar_area(r, ai.config), ai.last_actions.scans)
  append!(scan_positions, map(b->get_view_area(b, ai.config), bots)...)
  input_scans!(ai.knowledge_map, vcat(scan_positions...), ai.scan_results)

  # OK, at this point all events and old info has been processed, so we can update our knowledge
  update!(ai.knowledge_map)
  update!(ai.enemy_knowledge_map)

  attack_map = estimate_movement(ai.knowledge_map)
  # info for radaring: we can exclude positions that we will
  # be revealed by the position of our ships
  radar_map = deepcopy(attack_map)
#  for b in bots
#    mark_scan!(radar_map, get_view_area(b, ai.config))
#  end

  targets = get_shoot_targets(attack_map, ai.config, bots)
  scans = get_radar_targets(radar_map, ai.config)

  actions = AbstractAction[]
  for b in bots
    curthreat = get_threat_level(b, ai.enemy_knowledge_map, ai.config)
    mpos = get_move_area(b, ai.config)
    moves = plan_actions("move", mpos, zeros(size(mpos)))

    # correct for threat
    targets_c = best_actions(plan_actions(targets, -curthreat), 5)
    scans_c = best_actions(plan_actions(scans, -curthreat), 5)
    threats =  map(x->get_threat_level(b, ai.enemy_knowledge_map, ai.config, position(x)), moves)
    moves_c = best_actions(plan_actions(moves, -threats), 5)

    action = sample_action(vcat(targets_c, scans_c, moves_c), 10.0)
    # update other radar actions after we initialize one, to prevent overlapping
    # radaring
    if action.name == "radar"
      mark_scan!(radar_map, get_view_area(position(action), ai.config))
      scans = get_radar_targets(radar_map, ai.config)
    end
    println(name(action), " @ ", action.weight)
    push!(actions, make_action(action, b))
  end

  remember!(ai.last_actions, actions)

  ai.knowledge_map = attack_map
  ai.enemy_knowledge_map = estimate_movement(ai.enemy_knowledge_map)

  # debugging
  # predict enemy movement
  # THIS debugging can take up around 100 ms or so.
  drawer = HexDrawer(400, attack_map.config.field_radius)
  draw(drawer, ship_density(attack_map), sqrt)
  # TODO best way to incorporate this info?
  #draw(drawer, ai.enemy_knowledge_map, sqrt, channel=2)

  # mark shots on the map
  for s in ai.last_actions.shots
    mask = ones(Bool, 4, 4)
    draw(drawer, s, mask, Float64[1,0,0])
  end
  for s in ai.last_actions.scans
    mask = ones(Bool, 4, 4)
    draw(drawer, s, mask, Float64[0,0,1])
  end
  for b in bots
    mask = ones(Bool, 4, 4)
    draw(drawer, position(b), mask, Float64[0,1,0])
  end
  save("debug/map$(ai.turn_counter).png", colorim(get_image(drawer)))
	return actions
end

#########################################################
#                  event handling
#########################################################
function on_event(ai::NGCBot, event::SightEvent)
  # register a ship detection
  info("bot $(event.source) saw bot $(botid(event)) @$(position(event)).")
  push!(ai.scan_results, DetectionResult(position(event), botid(event)))
end

function on_event(ai::NGCBot, event::RadarEvent)
  # register a ship detection
  push!(ai.scan_results, DetectionResult(position(event), -1))
end

function on_event(ai::NGCBot, event::HitEvent)
  # find out if it was own bot or enemy.
  victim = botid(event)
  if victim ∈ map(botid, ai.own_bots)
    info("Own bot $victim was hit!")
    return
  end

  # OK, we hit an enemy
  aim = get_aim(ai.last_actions, event.source)
  if aim == nothing
    # this might happen if our last instructions did not come through or went in too late
    warn("could not find shooter that hit $(victim)! Lag?")
    return
  end
  info("enemy bot $victim was hit @ $(aim)!")

  detect_ship_in_area!(ai.knowledge_map, get_damage_area(aim, ai.config))
end

function on_event(ai::NGCBot, event::DetectionEvent)
  # find out where we were seen
  victim = botid(event)
  bot = filter(b->botid(b) == victim, ai.own_bots)[1]
  pos = position(bot)
  info("own bot $victim was detected @ $pos")

  detect_ship!(ai.enemy_knowledge_map, pos, botid(bot))
end

function on_event(ai::NGCBot, event::DamageEvent)
  victim = botid(event)
  bot = filter(b->botid(b) == victim, ai.own_bots)[1]
  info("Own bot $victim was hit by $(event.damage) @ $(position(bot))!")

  # TODO we could estimate the enemies certainty by the damage value
  detect_ship!(ai.enemy_knowledge_map, position(bot), botid(bot))
end

function on_event(ai::NGCBot, event::DeathEvent)
  victim = botid(event)

  # check if it was one of our own
  bot = filter(b->botid(b) == victim, ai.own_bots)
  if length(bot) == 1
    info("Own bot $victim was killed!")
    return
  end

  # otherwise, we killed an enemy
  shots = ai.last_actions.shots
  if length(shots) > 0
    notify_kill!(ai.knowledge_map, shots)
    info("killed enemy bot $(victim)!")
  else
    warn("Killed an enemy, but did not shoot. Something fishy here!")
  end
end

function get_shoot_targets(emap::ShipTrackMap, config::Config, bots)
  pos = get_map(emap.config.field_radius)
  # TODO we need to weight this here, actually
  total_hit = gather(ship_density(emap), p->get_damage_area(p, config))
  # take into account both direct damage value (1) and detection (RADAR_DISCOUNT_FACTOR),
  # but detection is imprecise, so reduce its weight
  SHOOT_FACTOR = (1 + RADAR_DISCOUNT_FACTOR / 2)
  weights = Float64[total_hit[p] for p in pos] .* SHOOT_FACTOR

  # check for friendly fire
  botp = map(position, bots)
  for (i,p) in enumerate(pos)
    area = get_damage_area(p, config)
    if length(intersect(area, botp)) != 0
      weights[i] = 0
    end
  end

  return plan_actions("cannon", pos, weights)
end

function get_radar_targets(emap::ShipTrackMap, config::Config)
  pos = get_map(emap.config.field_radius)
  # this gives the certainty with which we assume that an enemy is somewhere
  # inside the radar territority.
  total_hit = gather(ship_density(emap), p->get_radar_area(p, config))
  weights = Float64[total_hit[p] for p in pos] .* RADAR_DISCOUNT_FACTOR
  return plan_actions("radar", pos, weights)
end

function get_threat_level(bot::AbstractBot, knowledge::ShipTrackMap, config::Config, pos::Position = position(bot))
  return 0.0
  #=area = get_damage_area(pos, config)
  return knowledge_map.ship_count * mapreduce(p->knowledge.map[p], +, area)
  =#
end


function create(team_id, config::Config)
	info("create ngcbot for team $team_id")

  # clear debug data
  if isdir("debug")
    rm("debug", recursive = true)
  end
  mkdir("debug")

	return NGCBot(config,ShipTrackMap(config, [1,2,3]), ShipTrackMap(config, [1,2,3]), Any[], ActionMemory(), 0, DetectionResult[])
end
end
