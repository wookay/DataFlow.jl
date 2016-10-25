cse(v::IVertex, cache = Dict{typeof(v),typeof(v)}()) =
  postwalk(x -> get!(cache, x, x), v)

cse(v::Vertex, cache = d()) = cse(il(v), cache)

function cse(vs::Vector)
  cache = d()
  [cse(v, cache) for v in vs]
end

function Base.contains(haystack::IVertex, needle::IVertex)
  result = false
  prewalk(haystack) do v
    result |= v == needle
    v
  end
  return result
end

Base.contains(v::Vertex, w::Vertex) = contains(il(v), il(w))

function common(v::IVertex, w::IVertex, seen = OSet())
  w in seen && return Set{typeof(w)}()
  push!(seen, w)
  if contains(v, w)
    Set{typeof(w)}((w,))
  else
    union((common(v, w′, seen) for w′ in inputs(w))...)
  end
end

common(v::Vertex, w::Vertex) = common(il(v), il(w))
