function cse(v::ILVertex)
  cache = Dict{eltype(v),eltype(v)}()
  postwalk(x -> get!(cache, x, x), v)
end

cse(v::AVertex) = cse(il(v))
