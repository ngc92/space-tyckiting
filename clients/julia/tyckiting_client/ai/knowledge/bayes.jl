type BayesShipMap
  ships::Dict{Int, Map} # maps enemy ship ID's to their positional probabilities.
  scan_cache::Vector
end

function BayesShipMap(ships::Vector{Int}, config::Config)
  fieldcount = length(get_map(config))
  m = Map(Float64, config.field_radius, 1 / fieldcount)
  # iterate a few times to find equilibrium
  for i in 1:20
    diffuse(m, p->get_move_area(p, config), DIFFUSION_COEFFICIENT)
  end
  return BayesShipMap(Dict([i=>deepcopy(m) for i in ships]), Any[])
end

##########################################################
#    lowest level bayesian inference functions
##########################################################

# simple bayes update: we found a ship in a certain area
function bayes_update_scan!(m::BayesShipMap, area::Vector, shipid::Integer, found::Bool)
  mp = m.ships[shipid]
  if found
    update = setdiff(get_map(mp), area)
    for p in update
      mp[p] = 0
    end
  else
    for p in area
      mp[p] = 0
    end
  end
end

function S_factor(m::BayesShipMap, position::Position, ind::Int)
  shipids = collect(keys(m.ships))
  S = 0
  for i in 1:length(shipids)
    if i == ind
      continue
    end
    s = 1
    for j = i+1:length(shipids)
      if j == ind
        continue
      end
      t = 1
      for k = j+1:length(shipids)
        if k == ind
          continue
        end
        t -= m.ships[shipids[k]][position]
      end
      s -= m.ships[shipids[j]][position] * t
      # TODO quadruple produts etc
    end
    S += m.ships[shipids[i]][position] * s
  end
  return S
end

function bayes_update_scan!(m::BayesShipMap, position::Position, found::Bool)
  # shit, no info on which ship we found. FUCK!
  # needs more complicated calculations here.
  h = convert(Int, found)

  # now, we would hav eto multiply position by h and everything else by S, but since we have to renormalize in the end anyway, we can
  # divide every value by S

  # we need to calculate the S-values first, only then can we update the first map.
  # if h = 0, the S-value does not matter, so we can skip calculating it.
  if h != 0
    S_values = map(i->S_factor(m, position, i), keys(m.ships))
  else
    S_values = map(i->0.5, keys(m.ships))
  end

  for (i, mp) in enumerate(values(m.ships))
    S = (2h-1)*S_values[i] + (1-h)
    if S != 0
      mp[position] = mp[position] * h / S
    else
      # if S == 0, we need to renormalize right here
      mp.data .*= 0
      mp[position] = 1
    end
  end
end

##############################################################
# higher level functions. these may cache the information
# provided until the next call to update, and then
# use it in a way to gain maximum knowledge.
##############################################################
function push_scan!(m::BayesShipMap, area::Vector, shipid::Integer)
  # if just one possible position, this is precise information. Apply it directly.
  if length(area) == 1
    bayes_update_scan!(m, area, shipid, true)
  else
    push!(m.scan_cache, ()->bayes_update_scan!(m, area, shipid, true))
  end
end
push_scan!(m::BayesShipMap, area::Position, shipid::Integer) = push_scan!(m, Position[area], shipid)

function push_scan!(m::BayesShipMap, position::Position, found::Bool)
  # if we do not find an enemy, this is precise information. Apply it directly.
  if !found
    bayes_update_scan!(m, position, found)
  else
    push!(m.scan_cache, ()->bayes_update_scan!(m, position, found))
  end
end



# call this function after you are finished using bayes updates to renormalize probabilities again
function update!(track::BayesShipMap)
  # apply cached information
  for f in track.scan_cache
    f()
  end

  for m in values(track.ships)
    # renormalize density
    total = sum(get_map_values(m, get_map(m.radius)))
    m.data .*= 1 / total
  end
end



# this function tries to simulate probability spread due to unknown enemy movement
function simulate_movement(bayes::BayesShipMap, config::Config, diffusion::Real)
  dif = v -> diffuse(v, p->get_move_area(p, config), diffusion)
  ns = [i=>dif(v) for (i,v) in bayes.ships]
  return BayesShipMap(Dict(ns), Any[])
end
