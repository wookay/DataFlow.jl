export Vertex, DVertex, IVertex, thread!, topo

import Base: copy, hash, ==, <, <<

abstract Vertex{T}

Base.eltype{T}(::Vertex{T}) = T

include("set.jl")
include("dlgraph.jl")
include("ilgraph.jl")
include("conversions.jl")

thread!(to::Vertex, from) = thread!(to, convert(typeof(to), from))

thread!(v::Vertex, xs...) = reduce(thread!, v, xs)

(::Type{T}){T<:Vertex}(x, args...) = thread!(T(x), args...)

head(v::Vertex) = typeof(v)(value(v))

nin(v::Vertex) = length(inputs(v))

function nout(v::Vertex)
  n = 0
  for o in outputs(v), i in inputs(o)
    i ≡ v && (n += 1)
  end
  return n
end

isfinal(v::Vertex) = nout(v) == 0

Base.getindex(v::Vertex, i::Integer) = inputs(v)[i]
Base.getindex(v::Vertex, is::Integer...) = reduce(getindex, v, is)

function collectv(v::Vertex, vs = OASet{typeof(v)}())
  v ∈ vs && return collect(vs)
  push!(vs, v)
  foreach(v′ -> collectv(v′, vs), inputs(v))
  foreach(v′ -> collectv(v′, vs), outputs(v))
  return collect(vs)
end

function topo_up(v::Vertex, vs, seen)
  v ∈ seen && return vs
  push!(seen, v)
  foreach(v′ -> topo_up(v′, vs, seen), inputs(v))
  push!(vs, v)
end

function topo(v::Vertex)
  seen, vs = OSet{typeof(v)}(), typeof(v)[]
  for v in sort!(collectv(v), by = x -> x ≡ v)
    topo_up(v, vs, seen)
  end
  return vs
end

# function isreaching(from::Vertex, to::Vertex, seen = OSet())
#   to ∈ seen && return false
#   push!(seen, to)
#   any(v -> v ≡ from || isreaching(from, v, seen), inputs(to))
# end
#
# Base.isless(a::Vertex, b::Vertex) = isreaching(a, b)
#
# <<(a::Vertex, b::Vertex) = a < b && !(a > b)
#
# ↺(v::Vertex) = v < v
# ↺(a::Vertex, b::Vertex) = a < b && b < a
