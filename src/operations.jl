cse(v::IVertex, cache = Dict{typeof(v),typeof(v)}()) =
  postwalk(x -> get!(cache, x, x), v)

cse(v::Vertex) = cse(il(v))
