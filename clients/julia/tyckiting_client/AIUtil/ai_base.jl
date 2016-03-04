#################################################################
#                       actions                                 #
import ClientAI: botid, make_action
using StatsBase: sample, WeightVec

immutable ActionPlan <: AbstractAction
  name::ASCIIString
	pos::Position
  weight::Float64 # weight of chosing this action
end

botid(a::ActionPlan) = error("Action plans do not yet have an associated bot!")
make_action(a::ActionPlan, bot::Int) = make_action(bot, position(a), name(a))
make_action(a::ActionPlan, bot::AbstractBot) = make_action(a, botid(bot))

plan_actions(name::ASCIIString, pos::Vector{Position}, weight::Vector{Float64}) = [ActionPlan(name, p, w) for (p,w) in zip(pos, weight)]
# new action plans based on old ones, just shifting weights
plan_actions(old::Vector{ActionPlan}, shift::Real) = map(t->ActionPlan(t.name, t.pos, t.weight + shift), old)
function plan_actions(old::Vector{ActionPlan}, shift::Vector{Float64})
  result =  map(x->ActionPlan(x[1].name, x[1].pos, x[1].weight + x[2]), zip(old, shift))
  return convert(Vector{ActionPlan}, result)
end
function softmax(values, λ = 1.0)
  E = exp(values .* λ)
  return E / sum(E)
end

function sample_action(actions::Vector{ActionPlan}, λ = 1.0)
  weights = [a.weight for a in actions]
  probs = softmax(weights, λ)
  index = sample( WeightVec(probs) )
  return actions[index]
end

best_actions(actions::Vector{ActionPlan}, N::Integer = 1) = sort(actions, by = a->a.weight, rev=true)[1:N]

#################################################################
#   other convenience functions
#################################################################

# filter out all dead bots
filter_valid{T <: AbstractBot}(bots::Vector{T}) = filter(is_alive, bots)
