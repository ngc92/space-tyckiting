abstract AbstractBot

immutable Position
	x::Int
	y::Int
end

function Position(d::Dict)
  return Position(Int(d["x"]), Int(d["y"]))
end

to_dict(p::Position) = Dict("x" => p.x, "y" => p.y)
position(p::Position) = p # this seems a little strange, but it means that we can now easily build functions
                          # that takes positional objects or positions as parameters and just call this function to
                          # get the actual position
position(t::Tuple{Float64, Float64}) = Position(t[1], t[2])

immutable Config
  bots::Int
  field_radius::Int
  move::Int
  start_hp::Int
  cannon::Int
  radar::Int
  see::Int
  max_count::Int
  loop_time::Int
  function Config(bots::Integer=3, fieldRadius::Integer=14, move=2, startHp=10, cannon=1,
                 radar=3, see=2, maxCount=200, loopTime=300)
    new(bots, fieldRadius, move, startHp, cannon, radar, see, maxCount, loopTime)
  end
end

function Config(dict::Dict)
  params = [dict["bots"], dict["fieldRadius"], dict["move"], dict["startHp"], dict["cannon"], dict["radar"],
                dict["see"], dict["maxCount"], dict["loopTime"]]
  params = map(Int, params)
  return Config(params...)
end

