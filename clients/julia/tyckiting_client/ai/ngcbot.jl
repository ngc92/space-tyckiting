
module NGC_Bot
using ClientAI
using Images
import ClientAI: on_event
include("../AIUtil/AIUtil.jl")
using .AIUtil

type NGCBot <: AbstractAI
  config::Config
  knowledge_map::Map          # what do we know about enemy positions
  enemy_knowledge_map::Map    # what we expect the enemy knows about us
  own_bots::Vector

  last_actions::ActionMemory
  turn_counter::Integer
end

include("knowledge.jl")

const RADAR_DISCOUNT_FACTOR = 0.5 * 0.75

function init_round(ai::NGCBot, bots::Vector{AbstractBot}, events::Vector{AbstractEvent}, round_id::Integer)
  ai.own_bots = bots
  ai.turn_counter = round_id

  # mark on the map all positions where we would have detected an enemy if there were one
  # as enemy free. The found enemies are then set during the event dispatch.
  mark_no_enemy(ai, filter_valid(bots), ai.last_actions)

end

function decide(ai::NGCBot)
  bots = filter_valid(ai.own_bots)
  attack_map = diffuse_probability(ai.knowledge_map, ai.config)

  targets = get_shoot_targets(attack_map, ai.config, bots)
  scans = get_radar_targets(attack_map, ai.config)

  actions = AbstractAction[]
  for b in bots
    curthreat = get_threat_level(b, ai.enemy_knowledge_map, ai.config)
    mpos = get_move_area(b, ai.config)
    moves = plan_actions("move", mpos, zeros(size(mpos)))

    # correct for threat
    targets_c = map(t->ActionPlan(t.name, t.pos, t.weight - curthreat), targets)
    scans_c = map(t->ActionPlan(t.name, t.pos, t.weight - curthreat), scans)
    moves_c = map(t->ActionPlan(t.name, t.pos, t.weight - get_threat_level(b, ai.enemy_knowledge_map, ai.config, position(t))), moves)

    action = sample_action(vcat(targets_c, scans_c, moves_c), 20.0)
    println(name(action), " @ ", action.weight)
    push!(actions, make_action(action, b))
  end

  remember!(ai.last_actions, actions)

  ai.knowledge_map = attack_map
  ai.enemy_knowledge_map = diffuse_probability(ai.enemy_knowledge_map, ai.config)

  # debugging
  # predict enemy movement
  # THIS debugging can take up around 100 ms or so.
  drawer = HexDrawer(400, attack_map.radius)
  draw(drawer, attack_map, sqrt)
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
  e

	return actions
end

########################################
#      event handling
#######################################
function on_event(ai::NGCBot, event::SightEvent)
  # register a ship detection
  single_detection!(ai.knowledge_map, position(event))
end

function on_event(ai::NGCBot, event::RadarEvent)
  # register a ship detection
  single_detection!(ai.knowledge_map, position(event))
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

  # remove density of total one from the map
  normalize!(ai.knowledge_map, -1, false)

  damage_area = get_damage_area(aim, ai.config)
  for p in damage_area
    ai.knowledge_map[p] += 1 / length(damage_area)
  end
end

function on_event(ai::NGCBot, event::DetectionEvent)
  # find out where we were seen
  victim = botid(event)
  bot = filter(b->botid(b) == victim, ai.own_bots)[1]
  pos = position(bot)
  info("own bot $victim was detected @ $pos")

  single_detection!(ai.enemy_knowledge_map, pos)
end

function on_event(ai::NGCBot, event::DamageEvent)
  victim = botid(event)
  bot = filter(b->botid(b) == victim, ai.own_bots)[1]
  info("Own bot $victim was hit by $(event.damage) @ $(position(bot))!")

  # TODO we could estimate the enemies certainty by the damage value
  single_detection!(ai.enemy_knowledge_map, position(bot))
end

# TODO 0.5 is OK or even high for undetected enemys, but I guess after detection they should move
# more with D = 1
diffuse_probability(map::Map, config::Config) = diffuse(map, p->get_move_area(p, config), 0.5)

function get_shoot_targets(emap::Map, config::Config, bots)
  pos = get_map(emap.radius)
  # TODO we need to weight this here, actually
  total_hit = gather(emap, p->get_damage_area(p, config))
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

function get_radar_targets(emap::Map, config::Config)
  pos = get_map(emap.radius)
  # this gives the certainty with which we assume that an enemy is somewhere
  # inside the radar territority.
  total_hit = gather(emap, p->get_radar_area(p, config))
  weights = Float64[total_hit[p] for p in pos] .* RADAR_DISCOUNT_FACTOR
  return plan_actions("radar", pos, weights)
end

function get_threat_level(bot::AbstractBot, knowledge::Map, config::Config, pos::Position = position(bot))
  area = get_damage_area(pos, config)
  return mapreduce(p->knowledge[p], +, area)
end


function create(team_id, config::Config)
	info("create ngcbot for team $team_id")
  fieldcount = length(get_map(config))
  m = Map(Float64, config.field_radius, config.bots / fieldcount)

  # iterate a few times to find equilibrium
  for i in 1:10
    diffuse_probability(m, config)
  end

  # clear debug data
  if isdir("debug")
    rm("debug", recursive = true)
  end
  mkdir("debug")

	return NGCBot(config, m, deepcopy(m), Any[], ActionMemory(), 0)
end
end
