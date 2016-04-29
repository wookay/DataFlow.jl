cse(v::IVertex, cache = Dict{eltype(v),eltype(v)}()) =
  postwalk(x -> get!(cache, x, x), v)

cse(v::Vertex) = cse(il(v))
